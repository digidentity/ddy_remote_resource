require 'spec_helper'

describe RemoteResource::UrlNaming do

  module RemoteResource
    class UrlNamingDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

    end
  end

  let(:dummy_class) { RemoteResource::UrlNamingDummy }
  let(:dummy)       { dummy_class.new }

  describe '.collection' do
    let!(:original_collection) { dummy_class.collection }

    context 'when collection is set' do
      it 'returns the given collection' do
        dummy_class.collection = true

        expect(dummy_class.collection).to eql true

        dummy_class.collection = original_collection
      end
    end

    context 'when NO collection is set' do
      it 'returns the default collection' do
        expect(dummy_class.collection).to eql false
      end
    end
  end

  describe '.app_host' do
    it 'warns that the method is deprecated' do
      expect(dummy_class).to receive(:warn).with('[DEPRECATION] `.app_host` is deprecated. Please use a different method to determine the site.')
      dummy_class.app_host('dummy', 'test')
    end
  end

  describe '.base_url' do
    it 'warns that the method is deprecated' do
      expect(dummy_class).to receive(:warn).with('[DEPRECATION] `.base_url` is deprecated. Please use the connection_options[:base_url] when querying instead.')
      dummy_class.base_url
    end
  end

  describe '.use_relative_model_naming?' do
    it 'returns true' do
      expect(dummy_class.use_relative_model_naming?).to eql true
    end
  end

end
