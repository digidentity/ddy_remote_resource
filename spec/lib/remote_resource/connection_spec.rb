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

  describe '.extra_headers=' do
    it 'warns that the method is deprecated' do
      expect(dummy_class).to receive(:warn).with('[DEPRECATION] `.extra_headers=` is deprecated. Please overwrite the .headers method to set custom headers.')
      dummy_class.extra_headers = '.json'
    end
  end

  describe '.extra_headers' do
    it 'warns that the method is deprecated' do
      expect(dummy_class).to receive(:warn).with('[DEPRECATION] `.extra_headers` is deprecated. Please overwrite the .headers method to set custom headers.')
      dummy_class.extra_headers
    end
  end

  describe '.headers=' do
    it 'warns that the method is not used to set custom headers' do
      expect(dummy_class).to receive(:warn).with('[WARNING] `.headers=` can not be used to set custom headers. Please overwrite the .headers method to set custom headers.')
      dummy_class.headers = { 'Foo' => 'Bar' }
    end
  end

  describe '.headers' do
    it 'returns an empty Hash' do
      expect(dummy_class.headers).to eql({})
    end
  end

end
