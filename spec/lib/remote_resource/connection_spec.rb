require 'spec_helper'

describe RemoteResource::Connection do

  module RemoteResource
    class ConnectionDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

    end
  end

  let(:dummy_class) { RemoteResource::ConnectionDummy }
  let(:dummy)       { dummy_class.new }

  describe '.connection' do
    it 'uses Typhoeus::Request' do
      expect(dummy_class.connection).to eql Typhoeus::Request
    end
  end

  describe '.default_headers' do
    it 'returns an empty Hash' do
      expect(dummy_class.default_headers).to eql({})
    end
  end

  describe '.extra_headers' do
    it 'returns an empty Hash' do
      expect(dummy_class.extra_headers).to eql({})
    end
  end

  describe '.content_type=' do
    it 'warns that the method is deprecated' do
      expect(dummy_class).to receive(:warn).with('[DEPRECATION] `.content_type=` is deprecated. Please use `.extension=` instead.')
      dummy_class.content_type = '.json'
    end
  end

  describe '.content_type' do
    it 'warns that the method is deprecated' do
      expect(dummy_class).to receive(:warn).with('[DEPRECATION] `.content_type` is deprecated. Please use `.extension` instead.')
      dummy_class.content_type
    end
  end

  describe '.headers' do
    before { dummy_class.default_headers = { 'X-Locale' => 'nl' } }
    after { dummy_class.default_headers = {} }

    context 'when .extra_headers are set' do
      it 'returns the default headers merged with the set .extra_headers' do
        dummy_class.extra_headers = { 'Foo' => 'Bar' }

        expect(dummy_class.headers).to eql({ 'X-Locale' => 'nl', 'Foo' => 'Bar' })

        dummy_class.extra_headers = {}
      end
    end

    context 'when NO .extra_headers are set' do
      it 'returns the default headers' do
        expect(dummy_class.headers).to eql({ 'X-Locale' => 'nl' })
      end
    end
  end

end
