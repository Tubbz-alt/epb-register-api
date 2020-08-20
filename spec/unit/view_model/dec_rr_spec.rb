require_relative "xml_view_test_helper"

describe ViewModel::DecRrWrapper do
  context "Testing the DEC-RR schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-NI-8.0.0",
        xml: Samples.xml("CEPC-NI-8.0.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-7.1",
        xml: Samples.xml("CEPC-7.1", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
      },
    ].freeze

    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "2",
      type_of_assessment: "DEC-RR",
      date_of_expiry: "2028-05-03",
      address: {
        address_line1: "1 Lonely Street",
        address_line2: nil,
        address_line3: nil,
        address_line4: nil,
        town: "Post-Town0",
        postcode: "A0 0AA",
      },
      short_payback_recommendations: [
        {
          code: "1",
          text:
            "Consider thinking about maybe possibly getting a solar panel but only one.",
          cO2Impact: "MEDIUM",
        },
        {
          code: "2",
          text:
            "Consider introducing variable speed drives (VSD) for fans, pumps and compressors.",
          cO2Impact: "LOW",
        },
      ],
      medium_payback_recommendations: [
        {
          code: "3",
          text:
            "Engage experts to propose specific measures to reduce hot waterwastage and plan to carry this out.",
          cO2Impact: "LOW",
        },
      ],
      long_payback_recommendations: [
        {
          code: "4",
          text: "Consider replacing or improving glazing",
          cO2Impact: "LOW",
        },
      ],
      other_recommendations: [
        { code: "5", text: "Add a big wind turbine", cO2Impact: "HIGH" },
      ],
      technical_information: {
        building_environment: "Air Conditioning", floor_area: "10"
      },
      related_rrn: "0000-0000-0000-0000-1111",
    }.freeze

    it "should read the appropriate values from the XML doc" do
      test_xml_doc(supported_schema, asserted_keys)
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::DecRrWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
