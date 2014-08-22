require 'spec_helper'

describe RemoteResource::UrlNamingDetermination do

  module RemoteResource
    class UrlNamingDeterminationDummy
      include RemoteResource::Base

      self.site = 'http://www.foobar.com'

    end
  end

  let(:dummy_class) { RemoteResource::UrlNamingDeterminationDummy }

  let(:connection_options)       { {} }
  let(:url_naming_determination) { described_class.new dummy_class, connection_options }

  describe '#base_url' do
    context 'site' do
      context 'when the connection_options contain a site' do
        let(:connection_options) do
          { site: 'http://www.bazbar.com' }
        end

        it 'uses the site of the connection_options' do
          expect(url_naming_determination.base_url).to eql 'http://www.bazbar.com/url_naming_determination_dummy'
        end
      end

      context 'when the connection_options do NOT contain a site' do
        it 'uses the site of the resource_klass' do
          expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy'
        end
      end
    end

    context 'version' do
      context 'when the connection_options contain a version' do
        let(:connection_options) do
          { version: '/v2' }
        end

        it 'uses the version of the connection_options' do
          expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/v2/url_naming_determination_dummy'
        end
      end

      context 'when the connection_options do NOT contain a version' do
        context 'and the resource_klass contains a version' do
          it 'uses the version of the resource_klass' do
            dummy_class.version = '/version_4'

            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/version_4/url_naming_determination_dummy'

            dummy_class.version = nil
          end
        end

        context 'and the resource_klass does NOT contain a version' do
          it 'does NOT use the version' do
            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy'
          end
        end
      end
    end

    context 'path_prefix' do
      context 'when the connection_options contain a path_prefix' do
        let(:connection_options) do
          { path_prefix: '/api' }
        end

        it 'uses the path_prefix of the connection_options' do
          expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/api/url_naming_determination_dummy'
        end
      end

      context 'when the connection_options do NOT contain a path_prefix' do
        context 'and the resource_klass contains a path_prefix' do
          it 'uses the path_prefix of the resource_klass' do
            dummy_class.path_prefix = '/external_endpoint'

            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/external_endpoint/url_naming_determination_dummy'

            dummy_class.path_prefix = nil
          end
        end

        context 'and the resource_klass does NOT contain a path_prefix' do
          it 'does NOT use the path_prefix' do
            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy'
          end
        end
      end
    end

    context 'path_postfix' do
      context 'when the connection_options contain a path_postfix' do
        let(:connection_options) do
          { path_postfix: '/index' }
        end

        it 'uses the path_postfix of the connection_options' do
          expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy/index'
        end
      end

      context 'when the connection_options do NOT contain a path_postfix' do
        context 'and the resource_klass contains a path_postfix' do
          it 'uses the path_postfix of the resource_klass' do
            dummy_class.path_postfix = '/cancel'

            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy/cancel'

            dummy_class.path_postfix = nil
          end
        end

        context 'and the resource_klass does NOT contain a path_postfix' do
          it 'does NOT use the path_postfix' do
            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy'
          end
        end
      end
    end
  end

  describe '#url_safe_relative_name' do
    context 'when the connection_options contain a collection' do
      let(:connection_options) do
        { collection: true }
      end

      it 'uses the underscored, downcased and pluralized relative_name' do
        expect(url_naming_determination.url_safe_relative_name).to eql 'url_naming_determination_dummies'
      end
    end

    context 'when the connection_options do NOT contain a collection' do
      context 'and the resource_klass contains a collection' do
        it 'uses the underscored, downcased and pluralized relative_name' do
          dummy_class.collection = true

          expect(url_naming_determination.url_safe_relative_name).to eql 'url_naming_determination_dummies'

          dummy_class.collection = false
        end
      end

      context 'and the resource_klass does NOT contain a collection' do
        it 'uses the underscored and downcased relative_name' do
          expect(url_naming_determination.url_safe_relative_name).to eql 'url_naming_determination_dummy'
        end
      end
    end
  end

  describe '#relative_name' do
    context 'when the connection_options contain a collection_name' do
      let(:connection_options) do
        { collection_name: 'people' }
      end

      it 'uses the collection_name of the connection_options' do
        expect(url_naming_determination.relative_name).to eql 'people'
      end
    end

    context 'when the connection_options do NOT contain a collection_name' do
      context 'and the resource_klass contains a collection_name' do
        it 'uses the collection_name of the resource_klass' do
          dummy_class.collection_name = 'cars'

          expect(url_naming_determination.relative_name).to eql 'cars'

          dummy_class.collection_name = nil
        end
      end

      context 'and the resource_klass does NOT contain a collection_name' do
        it 'uses the demodulized name of the resource_klass' do
          expect(url_naming_determination.relative_name).to eql 'UrlNamingDeterminationDummy'
        end
      end
    end
  end

end