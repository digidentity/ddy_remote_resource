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

  pending 'RemoteResource::CONFIG must be implemented first' '.app_host' do
    context 'when the env is given as an argument' do
      it 'uses the host specified in the application CONFIG for the given env' do
        stub_const("CONFIG", { development: { apps: { dummy: 'https://foobar.development.com' } } })

        expect(dummy_class.app_host 'dummy', 'development').to eql 'https://foobar.development.com'
      end
    end

    context 'when the env is NOT given as an argument' do
      it 'uses the host specified in the application CONFIG' do
        stub_const("CONFIG", { test: { apps: { dummy: 'https://foobar.test.com' } } })

        expect(dummy_class.app_host 'dummy').to eql 'https://foobar.test.com'
      end
    end
  end

  describe '.base_url' do
    it 'uses the RemoteResource::UrlNamingDetermination class to determine the base_url' do
      expect(RemoteResource::UrlNamingDetermination).to receive(:new).with(dummy_class).and_call_original
      dummy_class.base_url
    end

    it 'returns the determined base_url' do
      expect(dummy_class.base_url).to eql 'https://foobar.com/url_naming_dummy'
    end
  end

  describe '.use_relative_model_naming?' do
    it 'returns true' do
      expect(dummy_class.use_relative_model_naming?).to eql true
    end
  end

end