require 'spec_helper'

describe RemoteResource::Querying::PersistenceMethods do

  module RemoteResource
    module Querying
      class PersistenceMethodsDummy
        include RemoteResource::Base

        self.site = 'https://foobar.com'

        attr_accessor :name

        def params
          { foo: 'bar' }
        end
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
      allow(dummy_class).to receive(:handle_response)                     { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :post, attributes, {}).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.create attributes
    end

    it 'handles the RemoteResource::Response' do
      expect(dummy_class).to receive(:handle_response).with response
      dummy_class.create attributes
    end
  end

  describe '#save' do
    let(:params) { dummy.params }

    before do
      allow(dummy).to receive(:create_or_update) { dummy }
      allow(dummy).to receive(:success?)
    end

    it 'calls #create_or_update with the params' do
      expect(dummy).to receive(:create_or_update).with(params, {})
      dummy.save
    end

    context 'when the save was successful' do
      it 'returns true' do
        allow(dummy).to receive(:success?) { true }

        expect(dummy.save).to eql true
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

end