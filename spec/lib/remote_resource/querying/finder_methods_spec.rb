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
      allow(dummy_class).to receive(:build_resource_from_response)        { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request with the connection_options no_attributes' do
      stub_request(:get, 'https://foobar.com/finder_methods_dummy/12.json').to_return(status: 200, body: {}.to_json)
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, { id: '12' }, { no_attributes: true }).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform).and_call_original
      dummy_class.find('12')
    end

    it 'builds the resource from the RemoteResource::Response' do
      expect(dummy_class).to receive(:build_resource_from_response).with response
      dummy_class.find('12')
    end

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { dummy_class.find('12', connection_options) }.not_to change { connection_options }.from({ headers: { 'Foo' => 'Bar' } })
    end

    context 'with extra params' do
      it 'performs a RemoteResource::Request with params' do
        stub_request(:get, 'https://foobar.com/finder_methods_dummy/12.json?skip_associations=true').to_return(status: 200, body: {}.to_json)
        expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, { id: '12' }, { params: { skip_associations: true }, no_attributes: true }).and_call_original
        expect_any_instance_of(RemoteResource::Request).to receive(:perform).and_call_original
        dummy_class.find('12', params: { skip_associations: true })
      end
    end
  end

  describe '.find_by' do
    let(:response) { instance_double(RemoteResource::Response) }
    let(:params) do
      { id: '12' }
    end

    before do
      allow(dummy_class).to receive(:build_resource_from_response)        { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, params, {}).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.find_by params
    end

    it 'builds the resource from the RemoteResource::Response' do
      expect(dummy_class).to receive(:build_resource_from_response).with response
      dummy_class.find_by params
    end

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { dummy_class.find_by(params, connection_options) }.not_to change { connection_options }.from({ headers: { 'Foo' => 'Bar' } })
    end
  end

  describe '.all' do
    let(:response) { instance_double(RemoteResource::Response) }

    before do
      allow(dummy_class).to receive(:build_collection_from_response)      { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request with the connection_options collection' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, {}, { collection: true }).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.all
    end

    it 'builds the resources from the RemoteResource::Response' do
      expect(dummy_class).to receive(:build_collection_from_response).with response
      dummy_class.all
    end

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { dummy_class.all(connection_options) }.not_to change { connection_options }.from({ headers: { 'Foo' => 'Bar' } })
    end
  end

  describe '.where' do
    let(:response) { instance_double(RemoteResource::Response) }
    let(:params) do
      { username: 'mies' }
    end

    before do
      allow(dummy_class).to receive(:build_collection_from_response)      { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request with the connection_options collection' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, params, { collection: true }).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.where params
    end

    it 'builds the resources from the RemoteResource::Response' do
      expect(dummy_class).to receive(:build_collection_from_response).with response
      dummy_class.where params
    end

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { dummy_class.where(params, connection_options) }.not_to change { connection_options }.from({ headers: { 'Foo' => 'Bar' } })
    end
  end

end
