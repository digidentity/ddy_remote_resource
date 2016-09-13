require 'spec_helper'

describe RemoteResource::ConnectionOptions do

  module RemoteResource
    class ConnectionOptionsDummy
      include RemoteResource::Base

      self.site              = 'https://foobar.com'
      self.extension         = ''
      self.default_headers   = { 'Accept' => 'application/vnd+json' }
      self.version           = '/v1'
      self.path_prefix       = '/prefix'
      self.path_postfix      = '/postfix'
      self.collection_prefix = '/parent/:parent_id'
      self.collection        = true
      self.root_element      = :test_dummy

      def self.headers
        { 'Authorization' => 'Bearer <token>' }
      end

    end
  end

  let(:dummy_class) { RemoteResource::ConnectionOptionsDummy }
  let(:dummy)       { dummy_class.new }

  let(:connection_options) { described_class.new dummy_class }

  describe '#initialize' do
    it 'assigns the given class as #base_class' do
      allow_any_instance_of(described_class).to receive(:initialize_connection_options)

      expect(connection_options.base_class).to eql RemoteResource::ConnectionOptionsDummy
    end

    context 'RemoteResource::ConnectionOptions::AVAILABLE_OPTIONS' do
      it 'calls #initialize_connection_options' do
        expect_any_instance_of(described_class).to receive(:initialize_connection_options)
        connection_options
      end

      it 'sets the accessor of the option from the RemoteResource::ConnectionOptions::AVAILABLE_OPTIONS' do
        RemoteResource::ConnectionOptions::AVAILABLE_OPTIONS.each do |option|
          expect(connection_options).to respond_to "#{option}"
          expect(connection_options).to respond_to "#{option}="
        end
      end

      it 'assigns the value of the option from the RemoteResource::ConnectionOptions::AVAILABLE_OPTIONS' do
        RemoteResource::ConnectionOptions::AVAILABLE_OPTIONS.each do |option|
          expect(connection_options.public_send(option)).to eql dummy_class.public_send(option)
        end
      end
    end
  end

  describe '#merge' do
    let(:custom_connection_options) do
      {
        site: 'https://dummy.foobar.com',
        version: '/api/v2',
        root_element: :test_dummy_api
      }
    end

    it 'merges the custom connection_options in the connection_options' do
      connection_options.merge custom_connection_options

      expect(connection_options.site).to eql 'https://dummy.foobar.com'
      expect(connection_options.version).to eql '/api/v2'
      expect(connection_options.root_element).to eql :test_dummy_api
    end

    it 'returns self' do
      expect(connection_options.merge custom_connection_options).to eql connection_options
    end
  end

  describe '#to_hash' do
    let(:connection_options_hash) do
      {
        site:              'https://foobar.com',
        default_headers:   { 'Accept' => 'application/vnd+json' },
        headers:           { 'Authorization' => 'Bearer <token>' },
        version:           '/v1',
        path_prefix:       '/prefix',
        path_postfix:      '/postfix',
        extension:         '',
        collection_prefix: '/parent/:parent_id',
        collection:        true,
        collection_name:   nil,
        root_element:      :test_dummy
      }
    end

    it 'returns the connection_options as Hash' do
      expect(connection_options.to_hash).to eql connection_options_hash
    end
  end

  describe '#reload' do
    it 'does NOT return self' do
      expect(connection_options.reload).not_to eql connection_options
    end

    context 'RemoteResource::ConnectionOptions::AVAILABLE_OPTIONS' do
      it 'calls #initialize_connection_options' do
        expect_any_instance_of(described_class).to receive(:initialize_connection_options).twice
        connection_options.reload
      end
    end
  end

  describe '#reload!' do
    it 'returns self' do
      expect(connection_options.reload!).to eql connection_options
    end

    context 'RemoteResource::ConnectionOptions::AVAILABLE_OPTIONS' do
      it 'calls #initialize_connection_options' do
        expect_any_instance_of(described_class).to receive(:initialize_connection_options).twice
        connection_options.reload!
      end
    end
  end

end
