describe "Acceptance::AssessmentSummary::Supplement::DEC" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(nonDomesticDec: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_dec(Samples.xml("CEPC-8.0.0", "dec"), scheme_id)
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )

    second_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec"))
    second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
    second_assessment.at("E-Mail").remove
    second_assessment.at("Telephone-Number").remove
    lodge_dec(second_assessment.to_xml, scheme_id)
    @second_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )
  end

  context "when getting the assessor data supplement" do
    it "Adds scheme details" do
      scheme = @regular_summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "Returns lodged email and phone values by default" do
      contact_details = @regular_summary.dig(:data, :assessor, :contactDetails)
      expect(contact_details).to eq({ telephone: "0921-19037", email: "a@b.c" })
    end

    it "Overrides missing assessor email and phone values with DB values" do
      expect(@second_summary.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephone: "010199991010101" },
      )
    end
  end

  context "when getting the related certificates" do
    it "Returns an empty list when there are no related certificates" do
      expect(@regular_summary.dig(:data, :relatedAssessments)).to eq([])
    end

    it "Returns assessments lodged against the same address" do
      related_assessments = @second_summary.dig(:data, :relatedAssessments)
      expect(related_assessments.count).to eq(1)
      expect(related_assessments[0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end
  end
end

def lodge_dec(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "CEPC-8.0.0",
  )
end