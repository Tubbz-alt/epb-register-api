describe "Acceptance::AddressSearch::ByPostcode" do
  include RSpecAssessorServiceMixin

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(EPC).xml"
  end

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-19.01.xml"
  end

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { domesticRdSap: "ACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  context "an address that has a report lodged" do
    before(:each) do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      doc = Nokogiri.XML valid_rdsap_xml

      assessment_id = doc.at("RRN")
      assessment_id.children = "0000-0000-0000-0000-0001"

      address_line_one = doc.search("Address-Line-1")[1]
      address_line_one.children = "2 Some Street"

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      non_domestic_xml = Nokogiri.XML valid_cepc_xml

      assessment_id = non_domestic_xml.at("//CEPC:RRN")
      assessment_id.children = "0000-0000-0000-0000-0002"

      address_line_one = non_domestic_xml.at("//CEPC:Address-Line-1")
      address_line_one.children = "3 Other Street"

      scheme_assessor_id = non_domestic_xml.at("//CEPC:Certificate-Number")
      scheme_assessor_id.children = "TEST000000"

      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )

      third_assessment_id = doc.at("RRN")
      third_assessment_id.children = "0000-0000-0000-0000-0003"

      address_line_one = doc.search("Address-Line-1")[1]
      address_line_one.children = "The House"
      address_line_two = Nokogiri::XML::Node.new "Address-Line-2", doc
      address_line_two.content = "123 Test Street"
      address_line_one.add_next_sibling address_line_two

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      fourth_assessment_id = doc.at("RRN")
      fourth_assessment_id.children = "0000-0000-0000-0000-0004"

      assessment_date = doc.at("Inspection-Date")
      assessment_date.children = Date.today.prev_day.strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    describe "searching by postcode" do
      context "when an invalid postcode is provided" do
        it "returns an unprocessable entity response" do
          assertive_get(
            "/api/search/addresses?postcode=INVALID_POSTCODE",
            [422],
            true,
            {},
            %w[address:search],
          )
        end
      end

      context "when a valid postcode is provided" do
        context "with an expired assessment" do
          it "returns the address" do
            response =
              JSON.parse(
                assertive_get(
                  "/api/search/addresses?postcode=A0%200AA",
                  [200],
                  true,
                  {},
                  %w[address:search],
                )
                  .body,
              )

            expect(response["data"]["addresses"].length).to eq 5
            expect(
              response["data"]["addresses"][0]["buildingReferenceNumber"],
            ).to eq "RRN-0000-0000-0000-0000-0000"
            expect(
              response["data"]["addresses"][0]["line1"],
            ).to eq "1 Some Street"
            expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
            expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
            expect(
              response["data"]["addresses"][0]["source"],
            ).to eq "PREVIOUS_ASSESSMENT"
            expect(
              response["data"]["addresses"][0]["existingAssessments"],
            ).to eq [
              "assessmentId" => "0000-0000-0000-0000-0000",
              "assessmentStatus" => "EXPIRED",
              "assessmentType" => "RdSAP",
            ]
          end
        end

        context "with an entered assessment" do
          it "returns the expected address" do
            response =
              JSON.parse(
                assertive_get(
                  "/api/search/addresses?postcode=A0%200AA",
                  [200],
                  true,
                  {},
                  %w[address:search],
                )
                  .body,
              )

            expect(response["data"]["addresses"].length).to eq 5
            expect(
              response["data"]["addresses"][4]["buildingReferenceNumber"],
            ).to eq "RRN-0000-0000-0000-0000-0004"
            expect(response["data"]["addresses"][4]["line1"]).to eq "The House"
            expect(response["data"]["addresses"][4]["town"]).to eq "Post-Town1"
            expect(response["data"]["addresses"][4]["postcode"]).to eq "A0 0AA"
            expect(
              response["data"]["addresses"][4]["source"],
            ).to eq "PREVIOUS_ASSESSMENT"
            expect(
              response["data"]["addresses"][4]["existingAssessments"],
            ).to eq [
              "assessmentId" => "0000-0000-0000-0000-0004",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "RdSAP",
            ]
          end
        end
      end

      context "when there is no space in the postcode" do
        it "returns the address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A00AA",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 5
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0000"
          expect(
            response["data"]["addresses"][0]["line1"],
          ).to eq "1 Some Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
          expect(
            response["data"]["addresses"][0]["source"],
          ).to eq "PREVIOUS_ASSESSMENT"
          expect(
            response["data"]["addresses"][0]["existingAssessments"],
          ).to eq [
            "assessmentId" => "0000-0000-0000-0000-0000",
            "assessmentStatus" => "EXPIRED",
            "assessmentType" => "RdSAP",
          ]
        end
      end

      context "when building name or number is supplied" do
        describe "with a building number" do
          it "returns the address" do
            response =
              JSON.parse(
                assertive_get(
                  "/api/search/addresses?postcode=A0%200AA&buildingNameNumber=2",
                  [200],
                  true,
                  {},
                  %w[address:search],
                )
                  .body,
              )

            expect(response["data"]["addresses"].length).to eq 1
            expect(
              response["data"]["addresses"][0]["buildingReferenceNumber"],
            ).to eq "RRN-0000-0000-0000-0000-0001"
            expect(
              response["data"]["addresses"][0]["line1"],
            ).to eq "2 Some Street"
            expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
            expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
            expect(
              response["data"]["addresses"][0]["source"],
            ).to eq "PREVIOUS_ASSESSMENT"
            expect(
              response["data"]["addresses"][0]["existingAssessments"],
            ).to eq [
              "assessmentId" => "0000-0000-0000-0000-0001",
              "assessmentStatus" => "EXPIRED",
              "assessmentType" => "RdSAP",
            ]
          end
        end

        describe "with a building number on address line 2" do
          it "returns the address" do
            response =
              JSON.parse(
                assertive_get(
                  "/api/search/addresses?postcode=A0%200AA&buildingNameNumber=123",
                  [200],
                  true,
                  {},
                  %w[address:search],
                )
                  .body,
              )

            expect(response["data"]["addresses"].length).to eq 2
            expect(
              response["data"]["addresses"][0]["buildingReferenceNumber"],
            ).to eq "RRN-0000-0000-0000-0000-0003"
            expect(response["data"]["addresses"][0]["line1"]).to eq "The House"
            expect(
              response["data"]["addresses"][0]["line2"],
            ).to eq "123 Test Street"
            expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
            expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
            expect(
              response["data"]["addresses"][0]["source"],
            ).to eq "PREVIOUS_ASSESSMENT"
            expect(
              response["data"]["addresses"][0]["existingAssessments"],
            ).to eq [
              "assessmentId" => "0000-0000-0000-0000-0003",
              "assessmentStatus" => "EXPIRED",
              "assessmentType" => "RdSAP",
            ]
          end
        end
      end

      context "when an invalid address type is provided" do
        it "returns status 422" do
          assertive_get(
            "/api/search/addresses?postcode=A0%200AA&addressType=asdf",
            [422],
            true,
            {},
            %w[address:search],
          )
        end
      end

      context "when an address type of domestic is provided" do
        it "returns the correct address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA&addressType=DOMESTIC",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 4
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0000"
          expect(
            response["data"]["addresses"][0]["line1"],
          ).to eq "1 Some Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
          expect(
            response["data"]["addresses"][0]["source"],
          ).to eq "PREVIOUS_ASSESSMENT"
          expect(
            response["data"]["addresses"][0]["existingAssessments"],
          ).to eq [
            "assessmentId" => "0000-0000-0000-0000-0000",
            "assessmentStatus" => "EXPIRED",
            "assessmentType" => "RdSAP",
          ]
        end
      end

      context "when an address type of commercial is provided" do
        it "returns the correct address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA&addressType=COMMERCIAL",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 1
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0002"
          expect(
            response["data"]["addresses"][0]["line1"],
          ).to eq "3 Other Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
          expect(
            response["data"]["addresses"][0]["source"],
          ).to eq "PREVIOUS_ASSESSMENT"
          expect(
            response["data"]["addresses"][0]["existingAssessments"],
          ).to eq [
            "assessmentId" => "0000-0000-0000-0000-0002",
            "assessmentStatus" => "EXPIRED",
            "assessmentType" => "CEPC",
          ]
        end
      end
    end
  end
end
