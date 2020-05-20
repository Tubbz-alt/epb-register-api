describe "searching for an address by address type" do
  include RSpecAssessorServiceMixin

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11 (EPC).xml"
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
      qualifications: { domesticRdSap: "ACTIVE", nonDomesticNos3: "ACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  context "when a report has been lodged for an address" do
    before(:each) do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      non_domestic_xml = Nokogiri.XML valid_cepc_xml

      assessment_id = non_domestic_xml.at("//CEPC:RRN")
      assessment_id.children = "0000-0000-0000-0000-0001"

      address_line_one = non_domestic_xml.at("//CEPC:Address-Line-1")
      address_line_one.children = "2 Other Street"

      scheme_assessor_id = non_domestic_xml.at("//CEPC:Certificate-Number")
      scheme_assessor_id.children = "TEST000000"

      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0001",
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    describe "searching by domestic address type" do
      context "with postcode" do
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

          expect(response["data"]["addresses"].length).to eq 1
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0000"
          expect(
            response["data"]["addresses"][0]["line1"],
          ).to eq "1 Some Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
        end
      end
    end
  end
end
