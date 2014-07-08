require 'spec_helper'

describe RemoteResource::Response do

  describe "Typhoeus::Response" do
    let(:typhoeus_options)  { { body: 'typhoeus_response_body', code: 200 } }
    let(:typhoeus_response) { Typhoeus::Response.new typhoeus_options }
    let(:response)          { described_class.new typhoeus_response }

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

end