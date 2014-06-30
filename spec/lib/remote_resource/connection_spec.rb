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

end