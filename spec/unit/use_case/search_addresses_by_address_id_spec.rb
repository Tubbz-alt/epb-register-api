describe UseCase::SearchAddressesByAddressId do
  context "addresses without a lodged assessment" do
    let(:use_case) { described_class.new AddressSearchGatewayFake.new }

    describe "by RRN" do
      it "does not return any results" do
        results = use_case.execute address_id: "RRN-0000-0000-0000-0000-0000"

        expect(results).to eq []
      end
    end
  end

  context "addresses with a lodged assessment" do
    let(:gateway) do
      gateway = AddressSearchGatewayFake.new

      gateway.add(
        {
          address_id: "RRN-0000-0000-0000-0000-0000",
          line1: "127 Home Road",
          line2: nil,
          line3: nil,
          line4: nil,
          town: "Placeville",
          postcode: "PL4 V11",
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_status: "ENTERED",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway.add(
        {
          address_id: "RRN-0000-0000-0000-0000-0001",
          line1: "128 Home Road",
          line2: nil,
          line3: nil,
          line4: nil,
          town: "Placeville",
          postcode: "PL4 V12",
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0001",
              assessment_status: "ENTERED",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway
    end
    let(:use_case) { described_class.new gateway }

    describe "by RRN" do
      let(:results) do
        use_case.execute address_id: "RRN-0000-0000-0000-0000-0000"
      end
      it "returns a single address" do
        expect(results.length).to eq 1
      end

      it "returns the expected building reference" do
        expect(results[0].address_id).to eq "RRN-0000-0000-0000-0000-0000"
      end

      it "returns the correct first line" do
        expect(results[0].line1).to eq "127 Home Road"
      end

      it "returns an empty second line" do
        expect(results[0].line2).to be_nil
      end

      it "returns an empty third line" do
        expect(results[0].line3).to be_nil
      end

      it "returns an empty fourth line" do
        expect(results[0].line4).to be_nil
      end

      it "returns the expected town" do
        expect(results[0].town).to eq "Placeville"
      end

      it "returns the expected postcode" do
        expect(results[0].postcode).to eq "PL4 V11"
      end

      it "returns the expected address source" do
        expect(results[0].source).to eq "PREVIOUS_ASSESSMENT"
      end

      it "returns the expected list of existing assessments" do
        expect(results[0].existing_assessments.length).to eq 1
      end

      it "returns an existing assessment with the expected RRN" do
        expect(
          results[0].existing_assessments[0][:assessment_id],
        ).to eq "0000-0000-0000-0000-0000"
      end

      it "returns an existing assessment with the expected status" do
        expect(
          results[0].existing_assessments[0][:assessment_status],
        ).to eq "ENTERED"
      end

      it "returns an existing assessment of the expected type" do
        expect(
          results[0].existing_assessments[0][:assessment_type],
        ).to eq "RdSAP"
      end
    end
  end
end
