# frozen_string_literal: true

describe "Acceptance::Assessment::FetchRenewableHeatIncentive" do
  include RSpecRegisterApiServiceMixin

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  let(:valid_sap_xml) { Samples.xml "SAP-Schema-18.0.0" }

  context "security" do
    it "rejects a request that is not authenticated" do
      fetch_renewable_heat_incentive "123", [401], false
    end

    it "rejects a request with the wrong scopes" do
      fetch_renewable_heat_incentive "124", [403], true, {}, %w[wrong:scope]
    end
  end

  context "when a domestic assessment does not exist" do
    let(:response) do
      JSON.parse(
        fetch_renewable_heat_incentive("DOESNT-EXIST", [404]).body,
        symbolize_names: true,
      )
    end

    it "returns status 404 for a get" do
      fetch_renewable_heat_incentive "DOESNT-EXIST", [404]
    end

    it "returns the expected error response" do
      expect(response[:errors][0][:title]).to eq "Assessment not found"
    end
  end

  context "when a domestic assessment has been cancelled" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:response) do
      JSON.parse(
        fetch_renewable_heat_incentive("0000-0000-0000-0000-0000", [410]).body,
        symbolize_names: true,
      )
    end

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   AssessorStub.new.fetch_request_body(domesticRdSap: "ACTIVE")

      lodge_assessment assessment_body: valid_rdsap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] }

      update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                               assessment_status_body: {
                                 "status": "CANCELLED",
                               },
                               accepted_responses: [200],
                               auth_data: { scheme_ids: [scheme_id] }
    end

    it "returns the expected error response" do
      expect(response[:errors][0][:title]).to eq "Assessment not for issue"
    end
  end

  context "when fetching a Renewable Heat Incentive" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:response) { fetch_renewable_heat_incentive "0000-0000-0000-0000-0000" }

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   AssessorStub.new.fetch_request_body(
                     domesticRdSap: "ACTIVE", domesticSap: "ACTIVE",
                   )

      lodge_assessment assessment_body: valid_rdsap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] }
    end

    it "returns status 200" do
      expect(response.status).to eq 200
    end

    context "with an RdSAP assessment type" do
      let(:response) do
        JSON.parse(
          fetch_renewable_heat_incentive("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      end

      it "returns the expected response" do
        expect(response[:data][:assessment]).to eq(
          epcRrn: "0000-0000-0000-0000-0000",
          assessorName: "Someone Muddle Person",
          reportType: "RdSAP",
          inspectionDate: "2020-05-04",
          lodgementDate: "2020-05-04",
          dwellingType: "Dwelling-Type0",
          postcode: "A0 0AA",
          propertyAgeBand: "K",
          tenure: "Owner-occupied",
          totalFloorArea: 1.0,
          cavityWallInsulation: false,
          loftInsulation: false,
          spaceHeating: 30.0,
          waterHeating: 60.0,
          secondaryHeating: "Description13",
          energyEfficiency: {
            currentRating: 50,
            currentBand: "e",
            potentialRating: 50,
            potentialBand: "e",
          },
        )
      end

      context "with improvement type A" do
        let(:assessment) { Nokogiri.XML valid_rdsap_xml }
        let(:assessment_id) { assessment.at "RRN" }
        let(:improvement_type) { assessment.search("Improvement-Type")[1] }

        let(:response) do
          JSON.parse(
            fetch_renewable_heat_incentive("1000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )
        end

        before do
          assessment_id.children = "1000-0000-0000-0000-0000"
          improvement_type.children = "A"

          lodge_assessment assessment_body: assessment.to_xml,
                           accepted_responses: [201],
                           auth_data: { scheme_ids: [scheme_id] }
        end

        it "returns true for loftInsulation" do
          expect(response[:data][:assessment][:loftInsulation]).to eq true
        end
      end

      context "with improvement type B" do
        let(:assessment) { Nokogiri.XML valid_rdsap_xml }
        let(:assessment_id) { assessment.at "RRN" }
        let(:improvement_type) { assessment.search("Improvement-Type")[1] }

        let(:response) do
          JSON.parse(
            fetch_renewable_heat_incentive("1000-0000-0000-0000-0001").body,
            symbolize_names: true,
          )
        end

        before do
          assessment_id.children = "1000-0000-0000-0000-0001"
          improvement_type.children = "B"

          lodge_assessment assessment_body: assessment.to_xml,
                           accepted_responses: [201],
                           auth_data: { scheme_ids: [scheme_id] }
        end

        it "returns true for cavityWallInsulation" do
          expect(response[:data][:assessment][:cavityWallInsulation]).to eq true
        end
      end
    end

    context "with a SAP assessment type" do
      let(:assessment) { Nokogiri.XML valid_sap_xml }
      let(:assessment_id) { assessment.at "RRN" }

      let(:response) do
        JSON.parse(
          fetch_renewable_heat_incentive("2000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      end

      before do
        assessment_id.children = "2000-0000-0000-0000-0000"

        lodge_assessment assessment_body: assessment.to_xml,
                         accepted_responses: [201],
                         schema_name: "SAP-Schema-18.0.0",
                         auth_data: { scheme_ids: [scheme_id] }
      end

      it "returns the expected response" do
        expect(response[:data][:assessment]).to eq(
          epcRrn: "2000-0000-0000-0000-0000",
          assessorName: "Someone Muddle Person",
          reportType: "SAP",
          inspectionDate: "2020-05-04",
          lodgementDate: "2020-05-04",
          dwellingType: "Dwelling-Type0",
          postcode: "A0 0AA",
          propertyAgeBand: "1750",
          tenure: "Owner-occupied",
          totalFloorArea: 10.0,
          cavityWallInsulation: false,
          loftInsulation: false,
          spaceHeating: 30.0,
          waterHeating: 60.0,
          secondaryHeating: "Electric heater",
          energyEfficiency: {
            currentRating: 50,
            currentBand: "e",
            potentialRating: 50,
            potentialBand: "e",
          },
        )
      end

      context "with improvement type A" do
        let(:assessment) { Nokogiri.XML valid_sap_xml }
        let(:assessment_id) { assessment.at "RRN" }
        let(:improvement_type) { assessment.at "Improvement-Type" }

        let(:response) do
          JSON.parse(
            fetch_renewable_heat_incentive("2000-0000-0000-0000-0001").body,
            symbolize_names: true,
          )
        end

        before do
          assessment_id.children = "2000-0000-0000-0000-0001"
          improvement_type.children = "A"

          lodge_assessment assessment_body: assessment.to_xml,
                           accepted_responses: [201],
                           schema_name: "SAP-Schema-18.0.0",
                           auth_data: { scheme_ids: [scheme_id] }
        end

        it "returns false for loftInsulation" do
          expect(response[:data][:assessment][:loftInsulation]).to eq false
        end
      end

      context "with improvement type B" do
        let(:assessment) { Nokogiri.XML valid_sap_xml }
        let(:assessment_id) { assessment.at "RRN" }
        let(:improvement_type) { assessment.at "Improvement-Type" }

        let(:response) do
          JSON.parse(
            fetch_renewable_heat_incentive("2000-0000-0000-0000-0002").body,
            symbolize_names: true,
          )
        end

        before do
          assessment_id.children = "2000-0000-0000-0000-0002"
          improvement_type.children = "B"

          lodge_assessment assessment_body: assessment.to_xml,
                           accepted_responses: [201],
                           schema_name: "SAP-Schema-18.0.0",
                           auth_data: { scheme_ids: [scheme_id] }
        end

        it "returns false for loftInsulation" do
          expect(
            response[:data][:assessment][:cavityWallInsulation],
          ).to eq false
        end
      end

      context "with construction age band" do
        let(:assessment) { Nokogiri.XML valid_sap_xml }
        let(:assessment_id) { assessment.at "RRN" }
        let(:construction_year) { assessment.at("Construction-Year") }

        let(:construction_age_band) do
          Nokogiri::XML::Node.new "Construction-Age-Band", assessment
        end

        let(:response) do
          JSON.parse(
            fetch_renewable_heat_incentive("2000-0000-0000-0000-0003").body,
            symbolize_names: true,
          )
        end

        before do
          assessment_id.children = "2000-0000-0000-0000-0003"
          construction_age_band.content = "K"
          construction_year.add_next_sibling construction_age_band

          lodge_assessment assessment_body: assessment.to_xml,
                           accepted_responses: [201],
                           schema_name: "SAP-Schema-18.0.0",
                           auth_data: { scheme_ids: [scheme_id] }
        end

        it "returns false for loftInsulation" do
          expect(response[:data][:assessment][:propertyAgeBand]).to eq "1750"
        end
      end
    end

    context "with property summary descriptions" do
      let(:assessment) { Nokogiri.XML valid_sap_xml }
      let(:assessment_id) { assessment.at "RRN" }

      let(:response) do
        JSON.parse(
          fetch_renewable_heat_incentive("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )
      end

      before do
        assessment_id.children = "0000-0000-0000-0000-0001"

        lodge_assessment assessment_body: assessment.to_xml,
                         accepted_responses: [201],
                         schema_name: "SAP-Schema-18.0.0",
                         auth_data: { scheme_ids: [scheme_id] }
      end

      it "returns the assessment details" do
        expect(response[:data][:assessment]).to eq(
          epcRrn: "0000-0000-0000-0000-0001",
          assessorName: "Someone Muddle Person",
          reportType: "SAP",
          inspectionDate: "2020-05-04",
          lodgementDate: "2020-05-04",
          dwellingType: "Dwelling-Type0",
          postcode: "A0 0AA",
          propertyAgeBand: "1750",
          tenure: "Owner-occupied",
          totalFloorArea: 10.0,
          cavityWallInsulation: false,
          loftInsulation: false,
          spaceHeating: 30.0,
          waterHeating: 60.0,
          secondaryHeating: "Electric heater",
          energyEfficiency: {
            currentRating: 50,
            currentBand: "e",
            potentialRating: 50,
            potentialBand: "e",
          },
        )
      end
    end

    context "without suggested improvements" do
      let(:assessment) { Nokogiri.XML valid_rdsap_xml }
      let(:assessment_id) { assessment.at "RRN" }

      let(:response) do
        JSON.parse(
          fetch_renewable_heat_incentive("3000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      end

      before do
        assessment_id.children = "3000-0000-0000-0000-0000"
        assessment.at("Suggested-Improvements").remove

        lodge_assessment assessment_body: assessment.to_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] }
      end

      it "returns false for loftInsulation" do
        expect(response[:data][:assessment][:loftInsulation]).to eq false
      end

      it "returns false for cavityWallInsulation" do
        expect(response[:data][:assessment][:cavityWallInsulation]).to eq false
      end
    end
  end
end
