# frozen_string_literal: true

describe "Acceptance::LodgeAC-CERT+AC-REPORTNIEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/ac-cert+ac-report-ni.xml"
  end

  context "when lodging an AC-CERT+AC-REPORT assessment (post)" do
    context "when an assessor is inactive" do
      let(:scheme_id) { add_scheme_and_get_id }

      context "when unqualified for AC-CERT" do
        it "returns status 400 with the correct error response" do
          add_assessor(
            scheme_id,
            "SPEC000000",
            fetch_assessor_stub.fetch_request_body(
              nonDomesticCc4: "INACTIVE", nonDomesticSp3: "ACTIVE",
            ),
          )

          response =
            JSON.parse(
              lodge_assessment(
                assessment_body: valid_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "CEPC-NI-8.0.0",
              ).body,
            )

          expect(response["errors"][0]["title"]).to eq(
            "Assessor is not active.",
          )
        end
      end

      context "when unqualified for AC-REPORT" do
        it "returns status 400 with the correct error response" do
          add_assessor(
            scheme_id,
            "SPEC000000",
            fetch_assessor_stub.fetch_request_body(
              nonDomesticCc4: "ACTIVE", nonDomesticSp3: "INACTIVE",
            ),
          )
          response =
            JSON.parse(
              lodge_assessment(
                assessment_body: valid_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "CEPC-NI-8.0.0",
              ).body,
            )

          expect(response["errors"][0]["title"]).to eq(
            "Assessor is not active.",
          )
        end
      end
    end

    it "returns status 201" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(
          nonDomesticCc4: "ACTIVE", nonDomesticSp3: "ACTIVE",
        ),
      )

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-8.0.0",
      )
    end

    context "when saving a (AC-CERT+AC-REPORT) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_xml }
      let(:response_acic) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end
      let(:response_acir) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0001").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticCc4: "ACTIVE", nonDomesticSp3: "ACTIVE",
          ),
        )
      end

      it "returns the data that was lodged" do
        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-8.0.0",
        )

        expected_acic_response = {
          "addressId" => "UPRN-432167890000",
          "addressLine1" => "A. Shop",
          "addressLine2" => "The High Street",
          "addressLine3" => "",
          "addressLine4" => "",
          "assessmentId" => "0000-0000-0000-0000-0000",
          "assessor" => {
            "contactDetails" => {
              "email" => "person@person.com",
              "telephoneNumber" => "010199991010101",
            },
            "dateOfBirth" => "1991-02-25",
            "firstName" => "Someone",
            "lastName" => "Person",
            "middleNames" => "Muddle",
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "INACTIVE",
              "nonDomesticCc4" => "ACTIVE",
              "nonDomesticSp3" => "ACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
              "gda" => "INACTIVE",
            },
            "address" => {},
            "companyDetails" => {},
            "registeredBy" => {
              "name" => "test scheme", "schemeId" => scheme_id
            },
            "schemeAssessorId" => "SPEC000000",
            "searchResultsComparisonPostcode" => "",
          },
          "currentCarbonEmission" => 0.0,
          "currentEnergyEfficiencyBand" => "a",
          "currentEnergyEfficiencyRating" => 99,
          "optOut" => false,
          "dateOfAssessment" => "2019-05-20",
          "dateOfExpiry" => "2030-05-19",
          "dateRegistered" => "2019-05-20",
          "dwellingType" => nil,
          "heatDemand" => {
            "currentSpaceHeatingDemand" => 0.0,
            "currentWaterHeatingDemand" => 0.0,
            "impactOfCavityInsulation" => nil,
            "impactOfLoftInsulation" => nil,
            "impactOfSolidWallInsulation" => nil,
          },
          "postcode" => "AB12 2AA",
          "potentialCarbonEmission" => 0.0,
          "potentialEnergyEfficiencyBand" => "a",
          "potentialEnergyEfficiencyRating" => 99,
          "totalFloorArea" => 0.0,
          "town" => "London",
          "typeOfAssessment" => "AC-CERT",
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => nil,
          "recommendedImprovements" => [],
          "propertySummary" => [],
          "relatedAssessments" => [
            {
              "assessmentExpiryDate" => "2030-05-19",
              "assessmentId" => "0000-0000-0000-0000-0001",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "AC-REPORT",
            },
            {
              "assessmentExpiryDate" => "2030-05-19",
              "assessmentId" => "0000-0000-0000-0000-0000",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "AC-CERT",
            },
          ],
          "status" => "ENTERED",
        }

        expect(response_acic["data"]).to eq(expected_acic_response)

        expected_acir_response = {
          "addressId" => "UPRN-432167890000",
          "addressLine1" => "A. Shop",
          "addressLine2" => "The High Street",
          "addressLine3" => "",
          "addressLine4" => "",
          "assessmentId" => "0000-0000-0000-0000-0001",
          "assessor" => {
            "contactDetails" => {
              "email" => "person@person.com",
              "telephoneNumber" => "010199991010101",
            },
            "dateOfBirth" => "1991-02-25",
            "firstName" => "Someone",
            "lastName" => "Person",
            "middleNames" => "Muddle",
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "INACTIVE",
              "nonDomesticCc4" => "ACTIVE",
              "nonDomesticSp3" => "ACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
              "gda" => "INACTIVE",
            },
            "address" => {},
            "companyDetails" => {},
            "registeredBy" => {
              "name" => "test scheme", "schemeId" => scheme_id
            },
            "schemeAssessorId" => "SPEC000000",
            "searchResultsComparisonPostcode" => "",
          },
          "currentCarbonEmission" => 0.0,
          "currentEnergyEfficiencyBand" => "a",
          "currentEnergyEfficiencyRating" => 99,
          "optOut" => false,
          "dateOfAssessment" => "2019-05-20",
          "dateOfExpiry" => "2030-05-19",
          "dateRegistered" => "2019-05-20",
          "dwellingType" => nil,
          "heatDemand" => {
            "currentSpaceHeatingDemand" => 0.0,
            "currentWaterHeatingDemand" => 0.0,
            "impactOfCavityInsulation" => nil,
            "impactOfLoftInsulation" => nil,
            "impactOfSolidWallInsulation" => nil,
          },
          "postcode" => "AB12 2AA",
          "potentialCarbonEmission" => 0.0,
          "potentialEnergyEfficiencyBand" => "a",
          "potentialEnergyEfficiencyRating" => 99,
          "totalFloorArea" => 0.0,
          "town" => "London",
          "typeOfAssessment" => "AC-REPORT",
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => nil,
          "recommendedImprovements" => [],
          "propertySummary" => [],
          "relatedAssessments" => [
            {
              "assessmentExpiryDate" => "2030-05-19",
              "assessmentId" => "0000-0000-0000-0000-0001",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "AC-REPORT",
            },
            {
              "assessmentExpiryDate" => "2030-05-19",
              "assessmentId" => "0000-0000-0000-0000-0000",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "AC-CERT",
            },
          ],
          "status" => "ENTERED",
        }

        expect(response_acir["data"]).to eq(expected_acir_response)
      end
    end

    context "when failing so save AC-REPORT as AC-CERT went through" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticCc4: "ACTIVE", nonDomesticSp3: "INACTIVE",
          ),
        )
      end

      it "does not save any lodgement" do
        lodge_assessment(
          assessment_body: valid_xml,
          accepted_responses: [400],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-8.0.0",
        )

        fetch_assessment("0000-0000-0000-0000-0000", [404])

        fetch_assessment("0000-0000-0000-0000-0001", [404])
      end
    end
  end
end