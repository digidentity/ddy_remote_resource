require 'spec_helper'

describe RemoteResource::Connection do

  module RemoteResource
    class ConnectionDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::ConnectionDummy }
  let(:dummy)       { dummy_class.new }

  describe '.connection' do
    it 'uses Typhoeus::Request' do
      expect(dummy_class.connection).to eql Typhoeus::Request
    end
  end

  describe '.content_type' do
    let!(:original_content_type) { dummy_class.content_type }

    context 'when content_type is set' do
      it 'returns the given content_type' do
        dummy_class.content_type = '.html'

        expect(dummy_class.content_type).to eql '.html'

        dummy_class.content_type = original_content_type
      end
    end

    context 'when NO content_type is set' do
      it 'returns the default content_type' do
        expect(dummy_class.content_type).to eql '.json'
      end
    end
  end

  describe '.headers' do
    context 'when .extra_headers are set' do
      it 'returns the default headers merged with the set .extra_headers' do
        dummy_class.extra_headers = { "Foo" => "Bar" }

        expect(dummy_class.headers).to eql({ "Accept" => "application/json", "Foo" => "Bar" })

        dummy_class.extra_headers = nil
      end
    end

    context 'when NO .extra_headers are set' do
      it 'returns the default headers' do
        expect(dummy_class.headers).to eql({ "Accept" => "application/json" })
      end
    end
  end

end