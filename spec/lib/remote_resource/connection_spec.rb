require 'spec_helper'

describe RemoteResource::Connection do

  module RemoteResource
    class Dummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::Dummy }
  let(:dummy)       { dummy_class.new }

  describe ".connection" do
    it "uses Typhoeus::Request" do
      expect(dummy_class.connection).to eql Typhoeus::Request
    end
  end

  describe ".headers" do
    context "when headers are set" do
      it "returns the default headers merged with the set headers" do
        dummy_class.headers = { "Foo" => "Bar" }

        expect(dummy_class.headers).to eql({ "Accept"=>"application/json", "Foo" => "Bar" })

        dummy_class.headers = nil
      end
    end

    context "when NO headers are set" do
      it "returns the default headers" do
        expect(dummy_class.headers).to eql({ "Accept"=>"application/json" })
      end
    end
  end

end