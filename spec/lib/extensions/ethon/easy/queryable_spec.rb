require 'ethon'
require_relative '../../../../../lib/extensions/ethon/easy/queryable'

describe Ethon::Easy::Queryable, order: :defined do

  let(:hash)    { {} }
  let!(:easy)   { Ethon::Easy.new }
  let(:params)  { Ethon::Easy::Params.new(easy, hash) }

  describe "#build_query_pairs" do
    let(:pairs) { params.method(:build_query_pairs).call(hash) }

    context "when params is empty" do
      it "returns empty array" do
        expect(pairs).to eq([])
      end
    end

    context "when params is string" do
      let(:hash) { "{a: 1}" }

      it "wraps it in an array" do
        expect(pairs).to eq([hash])
      end
    end

    context "when params is simple hash" do
      let(:hash) { {:a => 1, :b => 2} }

      it "transforms" do
        expect(pairs).to include([:a, 1])
        expect(pairs).to include([:b, 2])
      end
    end

    context "when params is a nested hash" do
      let(:hash) { {:a => 1, :b => {:c => 2}} }

      it "transforms" do
        expect(pairs).to include([:a, 1])
        expect(pairs).to include(["b[c]", 2])
      end
    end

    context "when params contains an array" do
      let(:hash) { {:a => 1, :b => [2, 3]} }

      it "transforms" do
        expect(pairs).to include([:a, 1])
        expect(pairs).to include(["b[]", 2])
        expect(pairs).to include(["b[]", 3])
      end
    end

    context "when params contains something nested in an array" do
      context "when string" do
        let(:hash) { {:a => {:b => ["hello", "world"]}} }

        it "transforms" do
          expect(pairs).to eq([["a[b][]", "hello"], ["a[b][]", "world"]])
        end
      end

      context "when hash" do
        let(:hash) { {:a => {:b => [{:c =>1}, {:d => 2}]}} }

        it "transforms" do
          expect(pairs).to eq([["a[b][][c]", 1], ["a[b][][d]", 2]])
        end
      end

      context "when file" do
        let(:file) { File.open("spec/fixtures/text_file.txt") }
        let(:file_info) { params.method(:file_info).call(file) }
        let(:hash) { {:a => {:b => [file]}} }
        let(:mime_type) { file_info[1] }

        it "transforms" do
          expect(pairs).to eq([["a[b][]", file_info]])
        end

        context "when MIME" do
          context "when mime type" do
            it "sets mime type to text" do
              expect(mime_type).to eq("text/plain")
            end
          end

          context "when no mime type" do
            let(:file) { Tempfile.new("fubar") }

            it "sets mime type to default application/octet-stream" do
              Object.send(:remove_const, :MIME)
              expect(mime_type).to eq("application/octet-stream")
            end
          end
        end

        context "when no MIME" do
          it "sets mime type to default application/octet-stream" do
            expect(mime_type).to eq("application/octet-stream")
          end
        end
      end
    end


    context "when params contains file" do
      let(:file) { Tempfile.new("fubar") }
      let(:file_info) { params.method(:file_info).call(file) }
      let(:hash) { {:a => 1, :b => file} }

      it "transforms" do
        expect(pairs).to include([:a, 1])
        expect(pairs).to include([:b, file_info])
      end
    end

    context "when params key contains a null byte" do
      let(:hash) { {:a => "1\0" } }

      it "preserves" do
        expect(pairs).to eq([[:a, "1\0"]])
      end
    end

    context "when params value contains a null byte" do
      let(:hash) { {"a\0" => 1 } }

      it "preserves" do
        expect(pairs).to eq([["a\0", 1]])
      end
    end
  end
end
