describe Helper::RegexHelper do
  describe "validating postcodes" do
    context "with a valid postcode" do
      describe "A0 0AA" do
        it "validates" do
          expect("A0 0AA").to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00AA" do
        it "validates" do
          expect("A00AA").to match Regexp.new described_class::POSTCODE
        end
      end
    end

    context "with an invalid postcode" do
      describe "INVALID" do
        it "does not validate" do
          expect("INVALID").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00" do
        it "does not validate" do
          expect("A00").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00 0AAB" do
        it "does not validate" do
          expect("A00 0AAB").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A000AAB" do
        it "does not validate" do
          expect("A000AAB").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A000 0AA" do
        it "does not validate" do
          expect("A000 0AA").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A0000AA" do
        it "does not validate" do
          expect("A0000AA").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A0 0AAA" do
        it "does not validate" do
          expect("A0 0AAA").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00AAA" do
        it "does not validate" do
          expect("A00AAA").not_to match Regexp.new described_class::POSTCODE
        end
      end
    end
  end
end
