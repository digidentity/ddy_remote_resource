require 'spec_helper'

describe RemoteResource::Querying::FinderMethods do

  module RemoteResource
    module Querying
      class FinderMethodsDummy
        include RemoteResource::Base

        self.site = 'https://foobar.com'

      end
    end
  end

  let(:dummy_class) { RemoteResource::Querying::FinderMethodsDummy }
  let(:dummy)       { dummy_class.new }

  describe '.find' do
    let(:response) { instance_double(RemoteResource::Response) }

    before do
      allow(dummy_class).to receive(:handle_response)                     { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request with the connection_options no_params' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, { id: '12' }, { no_params: true }).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.find '12'
    end

    it 'handles the RemoteResource::Response' do
      expect(dummy_class).to receive(:handle_response).with response
      dummy_class.find '12'
    end
  end

  describe '.find_by' do
    let(:response) { instance_double(RemoteResource::Response) }
    let(:params) do
      { id: '12' }
    end

    before do
      allow(dummy_class).to receive(:handle_response)                     { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, params, {}).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.find_by params
    end

    it 'handles the RemoteResource::Response' do
      expect(dummy_class).to receive(:handle_response).with response
      dummy_class.find_by params
    end
  end

  describe '.all' do
    let(:response) { instance_double(RemoteResource::Response) }

    before do
      allow(dummy_class).to receive(:handle_response)                     { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request with the connection_options collection' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, {}, { collection: true }).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.all
    end

    it 'handles the RemoteResource::Response' do
      expect(dummy_class).to receive(:handle_response).with response
      dummy_class.all
    end
  end

end