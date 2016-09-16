require 'spec_helper'

RSpec.describe RemoteResource::REST do

  module RemoteResource
    class RESTDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

    end
  end

  let(:dummy_class) { RemoteResource::RESTDummy }
  let(:dummy)       { dummy_class.new }

  let(:attributes) do
    { name: 'Mies' }
  end
  let(:params) do
    { id: '12' }
  end
  let(:connection_options) do
    {
      version: '/v1',
      path_prefix: '/api'
    }
  end

  let(:response) { instance_double(RemoteResource::Response) }

  before { allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response } }

  describe '.get' do
    it 'performs a RemoteResource::Request with the http_action :get' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, params, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.get params, connection_options
    end
  end

  describe '.put' do
    it 'performs a RemoteResource::Request with the http_action :put' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :put, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.put attributes, connection_options
    end
  end

  describe '.patch' do
    it 'performs a RemoteResource::Request with the http_action :patch' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :patch, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.patch attributes, connection_options
    end
  end

  describe '.post' do
    it 'performs a RemoteResource::Request with the http_action :post' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :post, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.post attributes, connection_options
    end
  end

  describe '.delete' do
    it 'performs a RemoteResource::Request with the http_action :delete' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :delete, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.delete(attributes, connection_options)
    end
  end

  describe '#get' do
    it 'performs a RemoteResource::Request with the http_action :get' do
      expect(RemoteResource::Request).to receive(:new).with(dummy, :get, params, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy.get params, connection_options
    end
  end

  describe '#put' do
    it 'performs a RemoteResource::Request with the http_action :put' do
      expect(RemoteResource::Request).to receive(:new).with(dummy, :put, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy.put attributes, connection_options
    end
  end

  describe '#patch' do
    it 'performs a RemoteResource::Request with the http_action :patch' do
      expect(RemoteResource::Request).to receive(:new).with(dummy, :patch, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy.patch attributes, connection_options
    end
  end

  describe '#post' do
    it 'performs a RemoteResource::Request with the http_action :post' do
      expect(RemoteResource::Request).to receive(:new).with(dummy, :post, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy.post attributes, connection_options
    end
  end

  describe '#delete' do
    it 'performs a RemoteResource::Request with the http_action :delete' do
      expect(RemoteResource::Request).to receive(:new).with(dummy, :delete, attributes, connection_options).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy.delete(attributes, connection_options)
    end
  end

end
