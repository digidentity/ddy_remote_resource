require 'spec_helper'

describe RemoteResource::UrlNaming do

  module RemoteResource
    class UrlNamingDummy
      include RemoteResource::Base

      self.site         = 'https://foobar.com'
      self.content_type = ''

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::UrlNamingDummy }
  let(:dummy)       { dummy_class.new }

  describe ".collection" do
    let!(:original_collection) { dummy_class.collection }

    context "when collection is set" do
      it "returns the given collection" do
        dummy_class.collection = true

        expect(dummy_class.collection).to be_truthy
        expect(dummy_class.collection).to eql(true)

        dummy_class.collection = original_collection
      end
    end

    context "when NO collection is set" do
      it "returns the default collection" do
        expect(dummy_class.collection).to be_falsey
        expect(dummy_class.collection).to eql(false)
      end
    end
  end

  pending "RemoteResource::CONFIG must be implemented first" ".app_host" do
    context "when the env is given as an argument" do
      it "uses the host specified in the application CONFIG for the given env" do
        stub_const("CONFIG", { development: { apps: { dummy: 'https://foobar.development.com' } } })

        expect(dummy_class.app_host 'dummy', 'development').to eql 'https://foobar.development.com'
      end
    end

    context "when the env is NOT given as an argument" do
      it "uses the host specified in the application CONFIG" do
        stub_const("CONFIG", { test: { apps: { dummy: 'https://foobar.test.com' } } })

        expect(dummy_class.app_host 'dummy').to eql 'https://foobar.test.com'
      end
    end
  end

  describe ".base_url" do
    context "without additional options" do
      it "returns the url" do
        expect(dummy_class.base_url).to eql 'https://foobar.com/url_naming_dummy'
      end
    end

    context "with additional options" do
      context ".version" do
        it "returns the url with the version" do
          dummy_class.version = '/api/v2'

          expect(dummy_class.base_url).to eql 'https://foobar.com/api/v2/url_naming_dummy'

          dummy_class.version = nil
        end
      end

      context ".path_prefix" do
        it "returns the url with the path_prefix" do
          dummy_class.path_prefix = '/registration'

          expect(dummy_class.base_url).to eql 'https://foobar.com/registration/url_naming_dummy'

          dummy_class.path_prefix = nil
        end
      end

      context ".path_postfix" do
        it "returns the url with the path_postfix" do
          dummy_class.path_postfix = '/refresh'

          expect(dummy_class.base_url).to eql 'https://foobar.com/url_naming_dummy/refresh'

          dummy_class.path_postfix = nil
        end
      end
    end
  end

  describe ".url_safe_relative_name" do
    context "when .collection is set truthy" do
      it "returns the url for a plural resource" do
        dummy_class.collection = true

        expect(dummy_class.base_url).to eql 'https://foobar.com/url_naming_dummies'

        dummy_class.collection = nil
      end
    end

    context "when .collection is set falsely" do
      it "returns the url for a singular resource" do
        dummy_class.collection = false

        expect(dummy_class.base_url).to eql 'https://foobar.com/url_naming_dummy'

        dummy_class.collection = nil
      end
    end
  end

  describe ".relative_name" do
    context "when .collection_name is specified" do
      it "returns the relative name of the class without the module" do
        expect(dummy_class.relative_name).not_to eql 'RemoteResource::UrlNamingDummy'
        expect(dummy_class.relative_name).to eql 'UrlNamingDummy'
      end
    end

    context "when .collection_name is NOT specified" do
      it "returns the .collection_name" do
        dummy_class.collection_name = :crash_dummy

        expect(dummy_class.relative_name).to eql 'crash_dummy'

        dummy_class.collection_name = nil
      end
    end
  end

  describe ".use_relative_model_naming?" do
    it "returns true" do
      expect(dummy_class.use_relative_model_naming?).to be_truthy
    end
  end

end