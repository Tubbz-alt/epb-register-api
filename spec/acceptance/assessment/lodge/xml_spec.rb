# frozen_string_literal: true

describe "Acceptance::LodgeAssessment::XML" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/acic.xml"
  end

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  let(:cleaned_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/CLEANED-CEPC-7.11(ACIC).xml"
  end

  let(:cleaned_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/CLEANED-SAP-17.11.xml"
  end

  def get_stored_xml(assessment_id)
    results =
      ActiveRecord::Base.connection.execute(
        "SELECT xml FROM assessments_xml WHERE assessment_id = '" +
          ActiveRecord::Base.sanitize_sql(assessment_id) +
          "'",
      )

    xml = ""
    results.each { |row| xml = row["xml"] }
    xml
  end

  let(:scheme_id) { add_scheme_and_get_id }

  before do
    add_assessor(
      scheme_id,
      "JASE000000",
      fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "ACTIVE"),
    )
    lodge_assessment(
      assessment_body: valid_cepc_xml,
      accepted_responses: [201],
      auth_data: { scheme_ids: [scheme_id] },
      schema_name: "CEPC-7.1",
    )
  end

  context "when storing xml to the assessments_xml table" do
    it "will remove the <Formatted-Report> element" do
      database_xml = get_stored_xml("0000-0000-0000-0000-0000")

      expect(valid_cepc_xml).to include("<Formatted-Report>")
      expect(cleaned_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end

    it "will remove the <PDF> element" do
      add_assessor(
        scheme_id,
        "JASE000000",
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )
      lodge_assessment(
        assessment_body: valid_sap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-17.1",
      )

      database_xml = get_stored_xml("1000-0000-0000-0000-0000")

      expect(valid_sap_xml).to include("<PDF>")
      expect(cleaned_sap_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end
  end
end
