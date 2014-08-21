require 'spec_helper'

describe RemoteResource::Response do

  describe "#original_response" do
    it "is private" do
      expect(described_class.private_method_defined?(:original_response)).to be_truthy
    end
  end

  describe "#original_request" do
    it "is private" do
      expect(described_class.private_method_defined?(:original_request)).to be_truthy
    end
  end

  describe "Typhoeus::Response" do
    let(:typhoeus_options)  { { body: 'typhoeus_response_body', code: 200 } }
    let(:typhoeus_response) { Typhoeus::Response.new typhoeus_options }
    let(:response)          { described_class.new typhoeus_response }

    describe "#success?" do
      it "calls the Typhoeus::Response#success?" do
        expect(typhoeus_response).to receive(:success?)
        response.success?
      end
    end

    describe "#response_body" do
      it "returns the response body of the original response" do
        expect(response.response_body).to eql 'typhoeus_response_body'
      end
    end

    describe "#response_code" do
      it "returns the response code of the original response" do
        expect(response.response_code).to eql 200
      end
    end
  end

  describe "#unprocessable_entity?" do
    let(:response) { described_class.new double.as_null_object }

    context "when the response code is 422" do
      it "returns true" do
        allow(response).to receive(:response_code) { 422 }

        expect(response.unprocessable_entity?).to be_truthy
      end
    end

    context "when the response code is NOT 422" do
      it "returns false" do
        allow(response).to receive(:response_code) { 200 }

        expect(response.unprocessable_entity?).to be_falsey
      end
    end
  end

  describe "#sanitized_response_body" do
    let(:response) { described_class.new double.as_null_object }

    before { allow(response).to receive(:response_body) { response_body } }

    context "when response_body is nil" do
      let(:response_body) { nil }

      it "returns an empty Hash" do
        expect(response.sanitized_response_body).to eql({})
      end
    end

    context "when response_body is empty" do
      let(:response_body) { '' }

      it "returns an empty Hash" do
        expect(response.sanitized_response_body).to eql({})
      end
    end

    context "when response_body is NOT parseable" do
      let(:response_body) { 'foo' }

      before { allow(JSON).to receive(:parse).and_raise JSON::ParserError }

      it "returns an empty Hash" do
        expect(response.sanitized_response_body).to eql({})
      end
    end

    context "when response_body is parseable" do
      context "and the connection_options contain a root_element" do
        let(:connection_options) { { root_element: :foobar } }
        let(:response)           { described_class.new double.as_null_object, connection_options }

        let(:response_body)      { '{"foobar":{"id":"12"}}' }

        it "returns the parsed response_body unpacked from the root_element" do
          expect(response.sanitized_response_body).to match({ "id" => "12" })
        end
      end

      context "and the connection_options do NOT contain a root_element" do
        let(:response_body) { '{"id":"12"}' }

        it "returns the parsed response_body" do
          expect(response.sanitized_response_body).to match({ "id" => "12" })
        end
      end
    end
  end

  describe '#error_messages_response_body' do
    let(:response) { described_class.new double.as_null_object }

    before { allow(response).to receive(:response_body) { response_body } }

    context 'when response_body is nil' do
      let(:response_body) { nil }

      it 'returns an empty Hash' do
        expect(response.error_messages_response_body).to eql({})
      end
    end

    context 'when response_body is empty' do
      let(:response_body) { '' }

      it 'returns an empty Hash' do
        expect(response.error_messages_response_body).to eql({})
      end
    end

    context 'when response_body is NOT parseable' do
      let(:response_body) { 'foo' }

      before { allow(JSON).to receive(:parse).and_raise JSON::ParserError }

      it 'returns an empty Hash' do
        expect(response.error_messages_response_body).to eql({})
      end
    end

    context 'when response_body is parseable' do
      context 'and the connection_options contain a root_element' do
        let(:connection_options) { { root_element: :foobar } }
        let(:response)           { described_class.new double.as_null_object, connection_options }

        context 'and the response_body contains an error key' do
          let(:response_body) { '{"errors":{"foo":["is required"]}}' }

          it 'returns the error_messages in the parsed response_body' do
            expect(response.error_messages_response_body).to eql({ "foo"=>["is required"] })
          end
        end

        context 'and the response_body contains an error key packed in the root_element' do
          let(:response_body) { '{"foobar":{"errors":{"foo":["is required"]}}}' }

          it 'returns the error_messages in the parsed response_body unpacked from the root_element' do
            expect(response.error_messages_response_body).to eql({ "foo"=>["is required"] })
          end
        end

        context 'and the response_body does NOT contain an error key' do
          let(:response_body) { '{"id":"12"}' }

          it 'returns an empty Hash' do
            expect(response.error_messages_response_body).to eql({})
          end
        end
      end

      context 'and the connection_options do NOT contain a root_element' do
        context 'and the response_body contains an error key' do
          let(:response_body) { '{"errors":{"foo":["is required"]}}' }

          it 'returns the error_messages in the parsed response_body' do
            expect(response.error_messages_response_body).to eql({ "foo"=>["is required"] })
          end
        end

        context 'and the response_body does NOT contain an error key' do
          let(:response_body) { '{"id":"12"}' }

          it 'returns an empty Hash' do
            expect(response.error_messages_response_body).to eql({})
          end
        end
      end
    end
  end

end