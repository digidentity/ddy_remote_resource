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

  describe ".headers=" do
    it "sets the headers as thread variable" do
      expect(Thread.current['remote_resource.headers']).to eql({})

      dummy_class.headers = { "Foo" => "Bar" }

      expect(Thread.current['remote_resource.headers']).to eql({ "Foo" => "Bar" })
    end
  end

  describe ".headers" do
    before { dummy_class.headers = nil }

    context "when headers are given" do
      it "returns the merged headers with the default headers" do
        dummy_class.headers = { "Foo" => "Bar" }

        expect(dummy_class.headers).to eql({ "Foo" => "Bar", "Accept"=>"application/json" })
      end
    end

    context "when NO headers are given" do
      it "returns the default headers" do
        expect(dummy_class.headers).to eql({ "Accept"=>"application/json" })
      end
    end
  end

end