require 'spec_helper'

RSpec.describe RemoteResource::UrlNaming do

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
    it 'returns the base URL which will be used to make the request URL' do
      aggregate_failures do
        expect(dummy_class.base_url).to eql 'https://foobar.com/url_naming_dummy'
        expect(dummy_class.base_url(version: '/api/v2')).to eql 'https://foobar.com/api/v2/url_naming_dummy'
        expect(dummy_class.base_url(id: 10, collection: true)).to eql 'https://foobar.com/url_naming_dummies/10'
        expect(dummy_class.base_url(id: 10, collection: true, collection_prefix: '/parent/:parent_id' )).to eql 'https://foobar.com/parent/:parent_id/url_naming_dummies/10'
        expect(dummy_class.base_url(id: 10, collection: true, collection_prefix: '/parent/:parent_id', collection_options: { parent_id: 18 } )).to eql 'https://foobar.com/parent/18/url_naming_dummies/10'
      end
    end
  end

  describe '.use_relative_model_naming?' do
    it 'returns true' do
      expect(dummy_class.use_relative_model_naming?).to eql true
    end
  end

end
