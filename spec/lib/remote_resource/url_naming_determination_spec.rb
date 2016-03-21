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

    context 'collection_prefix' do
      context 'when the connection_options contain a collection_prefix' do
        let(:connection_options) do
          { collection_prefix: '/parent/:parent_id', collection_options: { parent_id: 696 } }
        end

        it 'uses the collection_prefix of the connection_options' do
          expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/parent/696/url_naming_determination_dummy'
        end

        context 'when collection_options is NOT present' do
          let(:connection_options) do
            { collection_prefix: '/parent/:parent_id' }
          end

          it 'returns base_url with variable' do
            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/parent/:parent_id/url_naming_determination_dummy'
          end

          context 'when check_collection_options is true' do
            it 'raises an exception' do
              expect { url_naming_determination.base_url(nil, check_collection_options: true) }.to raise_error(RemoteResource::CollectionOptionKeyError)
            end
          end
        end

        context 'when collection_prefix variable is not set in the collection_options' do
          let(:connection_options) do
            { collection_prefix: '/parent/:parent_id', collection_options: { other_id: 696 } }
          end

          it 'returns base_url with variable' do
            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/parent/:parent_id/url_naming_determination_dummy'
          end

          context 'when check_collection_options is true' do
            it 'raises an exception' do
              expect { url_naming_determination.base_url(nil, check_collection_options: true) }.to raise_error(RemoteResource::CollectionOptionKeyError)
            end
          end
        end
      end

      context 'when the connection_options do NOT contain a collection_prefix' do
        context 'and the resource_klass contains a collection_prefix' do
          before { dummy_class.collection_prefix = '/parent/:parent_id' }
          after { dummy_class.collection_prefix = nil }

          context 'when connection_options includes collection_options with key parent_id' do
            let(:connection_options) do
              { collection_options: { parent_id: 696 } }
            end

            it 'uses the collection_prefix of the resource_klass' do
              expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/parent/696/url_naming_determination_dummy'
            end
          end

          context 'when connection_options does NOT include collection_options' do
            it 'returns base_url with variable' do
              expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/parent/:parent_id/url_naming_determination_dummy'
            end

            context 'when check_collection_options is true' do
              it 'raises an exception' do
                expect { url_naming_determination.base_url(nil, check_collection_options: true) }.to raise_error(RemoteResource::CollectionOptionKeyError)
              end
            end
          end
        end

        context 'and the resource_klass does NOT contain a collection_prefix' do
          it 'does NOT use the collection_prefix' do
            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy'
          end
        end
      end
    end

    context 'id' do
      context 'when an id is specified' do
        it 'uses that id in the base url' do
          expect(url_naming_determination.base_url(:id)).to eql 'http://www.foobar.com/url_naming_determination_dummy/id'
        end
      end

      context 'when an id is NOT specified' do
        it 'creates a base url without it' do
          expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy'
        end
      end
    end

    context 'path_postfix' do
      context 'when the connection_options contain a path_postfix' do
        let(:connection_options) do
          { path_postfix: '/custom' }
        end

        it 'uses the path_postfix of the connection_options' do
          expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy/custom'
        end

        context 'and an id is specified' do
          it 'uses the path_postfix of the connection_options and places the id before it' do
            expect(url_naming_determination.base_url(:id)).to eql 'http://www.foobar.com/url_naming_determination_dummy/id/custom'
          end
        end
      end

      context 'when the connection_options do NOT contain a path_postfix' do
        context 'and the resource_klass contains a path_postfix' do
          it 'uses the path_postfix of the resource_klass' do
            dummy_class.path_postfix = '/cancel'

            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy/cancel'

            dummy_class.path_postfix = nil
          end

          context 'and an id is specified' do
            it 'uses the path_postfix of the resource_klass and places the id before it' do
              dummy_class.path_postfix = '/cancel'

              expect(url_naming_determination.base_url(:id)).to eql 'http://www.foobar.com/url_naming_determination_dummy/id/cancel'

              dummy_class.path_postfix = nil
            end
          end
        end

        context 'and the resource_klass does NOT contain a path_postfix' do
          it 'does NOT use the path_postfix' do
            expect(url_naming_determination.base_url).to eql 'http://www.foobar.com/url_naming_determination_dummy'
          end

          context 'and an id is specified' do
            it 'places the id after the url safe relative name' do
              expect(url_naming_determination.base_url(:id)).to eql 'http://www.foobar.com/url_naming_determination_dummy/id'
            end
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
