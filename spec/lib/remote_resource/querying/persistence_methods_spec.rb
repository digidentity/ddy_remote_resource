require 'spec_helper'

describe RemoteResource::Querying::PersistenceMethods do

  module RemoteResource
    module Querying
      class PersistenceMethodsDummy
        include RemoteResource::Base

        self.site = 'https://foobar.com'

        attribute :name

      end
    end
  end

  let(:dummy_class) { RemoteResource::Querying::PersistenceMethodsDummy }
  let(:dummy)       { dummy_class.new }

  describe '.create' do
    let(:response) { instance_double(RemoteResource::Response) }
    let(:attributes) do
      { name: 'Mies' }
    end

    before do
      allow_any_instance_of(dummy_class).to receive(:handle_response)
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'instantiates the resource with the attributes' do
      expect(dummy_class).to receive(:new).with(attributes).and_call_original
      dummy_class.create attributes
    end

    it 'performs a RemoteResource::Request' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :post, attributes, {}).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.create attributes
    end

    it 'handles the RemoteResource::Response' do
      expect_any_instance_of(dummy_class).to receive(:handle_response).with response
      dummy_class.create attributes
    end
  end

  describe '.destroy' do
    let(:response) { instance_double(RemoteResource::Response) }

    before do
      allow_any_instance_of(dummy_class).to receive(:handle_response)
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'instantiates the resource without attributes' do
      expect(dummy_class).to receive(:new).with(no_args()).and_call_original
      dummy_class.destroy('15')
    end

    it 'performs a RemoteResource::Request' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :delete, { id: '15' }, { no_attributes: true }).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.destroy('15')
    end

    it 'handles the RemoteResource::Response' do
      expect_any_instance_of(dummy_class).to receive(:handle_response).with response
      dummy_class.destroy('15')
    end

    context 'request' do
      let(:response) { { status: 200, body: '' } }
      before { allow_any_instance_of(RemoteResource::Request).to receive(:perform).and_call_original }

      it 'generates correct request url' do
        stub_request(:delete, 'https://foobar.com/persistence_methods_dummy/15.json').with(body: nil).to_return(response)
        dummy_class.destroy('15')
      end

      it 'includes params' do
        stub_request(:delete, 'https://foobar.com/persistence_methods_dummy/15.json?pseudonym=3s8e3j').with(body: nil).to_return(response)
        dummy_class.destroy('15', params: { pseudonym: '3s8e3j' })
      end
    end
  end

  describe '#update_attributes' do
    let(:dummy) { dummy_class.new id: 10 }

    let(:attributes) do
      { name: 'Noot' }
    end

    before do
      allow(dummy).to receive(:create_or_update) { dummy }
      allow(dummy).to receive(:success?)
    end

    it 'rebuilds the resource with the attributes' do
      expect(dummy).to receive(:rebuild_resource).with(attributes).and_call_original
      dummy.update_attributes attributes
    end

    context 'when the id is given in the attributes' do
      let(:attributes) do
        { id: 14, name: 'Noot' }
      end

      it 'calls #create_or_update with the attributes and given id' do
        expect(dummy).to receive(:create_or_update).with(attributes, {})
        dummy.update_attributes attributes
      end
    end

    context 'when the id is NOT given in the attributes' do
      it 'calls #create_or_update with the attributes and #id of resource' do
        expect(dummy).to receive(:create_or_update).with(attributes.merge(id: dummy.id), {})
        dummy.update_attributes attributes
      end
    end

    context 'when the save was successful' do
      it 'returns the resource' do
        allow(dummy).to receive(:success?) { true }

        expect(dummy.update_attributes attributes).to eql dummy
      end
    end

    context 'when the save was NOT successful' do
      it 'returns false' do
        allow(dummy).to receive(:success?) { false }

        expect(dummy.update_attributes attributes).to eql false
      end
    end
  end

  describe '#save' do
    let(:attributes) { dummy.attributes }

    before do
      allow(dummy).to receive(:create_or_update) { dummy }
      allow(dummy).to receive(:success?)
    end

    it 'calls #create_or_update with the attributes' do
      expect(dummy).to receive(:create_or_update).with(attributes, {})
      dummy.save
    end

    context 'when the save was successful' do
      it 'returns the resource' do
        allow(dummy).to receive(:success?) { true }

        expect(dummy.save).to eql dummy
      end
    end

    context 'when the save was NOT successful' do
      it 'returns false' do
        allow(dummy).to receive(:success?) { false }

        expect(dummy.save).to eql false
      end
    end
  end

  describe '#create_or_update' do
    let(:response) { instance_double(RemoteResource::Response) }

    before do
      allow(dummy).to receive(:handle_response)                           { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    context 'when the attributes contain an id' do
      let(:attributes) do
        { id: 10, name: 'Kees' }
      end

      it 'performs a RemoteResource::Request with rest_action :patch' do
        expect(RemoteResource::Request).to receive(:new).with(dummy, :patch, attributes, {}).and_call_original
        expect_any_instance_of(RemoteResource::Request).to receive(:perform)
        dummy.create_or_update attributes
      end

      it 'handles the RemoteResource::Response' do
        expect(dummy).to receive(:handle_response).with response
        dummy.create_or_update attributes
      end
    end

    context 'when the attributes do NOT contain an id' do
      let(:attributes) do
        { name: 'Mies' }
      end

      it 'performs a RemoteResource::Request with rest_action :post' do
        expect(RemoteResource::Request).to receive(:new).with(dummy, :post, attributes, {}).and_call_original
        expect_any_instance_of(RemoteResource::Request).to receive(:perform)
        dummy.create_or_update attributes
      end

      it 'handles the RemoteResource::Response' do
        expect(dummy).to receive(:handle_response).with response
        dummy.create_or_update attributes
      end
    end
  end

  describe '#destroy' do
    let(:dummy) { dummy_class.new(id: 18) }

    let(:response) { instance_double(RemoteResource::Response) }

    before do
      allow(dummy).to receive(:handle_response)                           { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
      allow(dummy).to receive(:success?)
    end

    it 'performs a RemoteResource::Request with rest_action :delete' do
      expect(RemoteResource::Request).to receive(:new).with(dummy, :delete, { id: dummy.id }, { no_attributes: true }).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy.destroy
    end

    it 'handles the RemoteResource::Response' do
      expect(dummy).to receive(:handle_response).with response
      dummy.destroy
    end

    context 'request' do
      let(:response) { { status: 200, body: '' } }
      before { allow_any_instance_of(RemoteResource::Request).to receive(:perform).and_call_original }

      it 'generates correct request url' do
        stub_request(:delete, 'https://foobar.com/persistence_methods_dummy/18.json').with(body: nil).to_return(response)
        dummy.destroy
      end

      it 'includes params' do
        stub_request(:delete, 'https://foobar.com/persistence_methods_dummy/18.json?pseudonym=3s8e3j').with(body: nil).to_return(response)
        dummy.destroy(params: { pseudonym: '3s8e3j' })
      end
    end

    context 'when the destroy was successful' do
      it 'returns the resource' do
        allow(dummy).to receive(:success?) { true }

        expect(dummy.destroy).to eql dummy
      end
    end

    context 'when the destroy was NOT successful' do
      it 'returns false' do
        allow(dummy).to receive(:success?) { false }

        expect(dummy.destroy).to eql false
      end
    end

    context 'when the id is NOT present' do
      let(:dummy) { dummy_class.new }

      it 'raises the RemoteResource::IdMissingError error' do
        expect { dummy.destroy }.to raise_error(RemoteResource::IdMissingError, "`id` is missing from resource")
      end
    end
  end

end
