describe "Acceptance::AddressSearch" do
  include RSpecAssessorServiceMixin

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

  context "with an invalid combination of parameters" do
    describe "no parameters" do
      let(:response) do
        assertive_get(
          "/api/search/addresses",
          [422],
          true,
          nil,
          %w[address:search],
        )
          .body
      end

      it "returns a validation error" do
        expect(response).to include "INVALID_REQUEST"
      end
    end
  end

  context "with invalid auth details" do
    describe "with no authentication token" do
      it "returns a 401" do
        assertive_get("/api/search/addresses", [401], false, nil, nil)
      end
    end

    describe "without the scope address:search" do
      it "returns a 403" do
        assertive_get("/api/search/addresses", [403], true, nil, nil)
      end
    end
  end

  context "with an incomplete address" do
    describe "an address with only line1, town, and postcode" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(
          assertive_get(
            "/api/search/addresses?postcode=A0%200AA",
            [200],
            true,
            nil,
            %w[address:search],
          )
            .body,
          symbolize_names: true,
        )
      end

      before do
        add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

        lodge_assessment(
          assessment_body: valid_rdsap_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
        )
      end

      it "has nil for line2" do
        expect(response[:data][:addresses][0][:line2]).to be_nil
      end

      it "has nil for line3" do
        expect(response[:data][:addresses][0][:line3]).to be_nil
      end
    end
  end
end