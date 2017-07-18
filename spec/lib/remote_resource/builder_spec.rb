require 'spec_helper'

RSpec.describe RemoteResource::Builder do

  module RemoteResource
    class BuilderDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      attr_accessor :name

    end
  end

  let(:dummy_class) { RemoteResource::BuilderDummy }
  let(:dummy)       { dummy_class.new }

  let(:request) { instance_double(RemoteResource::Request) }
  let(:response) { instance_double(RemoteResource::Response, request: request, attributes: {}, meta: { 'total' => 10 }) }

  describe '.build_resource_from_response' do
    let(:response) { instance_double(RemoteResource::Response, request: request, attributes: { 'id' => 12, 'name' => 'Mies' }, meta: { 'total' => 10 }) }

    it 'returns the instantiated resource from the response' do
      result = dummy_class.build_resource_from_response(response)

      aggregate_failures do
        expect(result).to be_a dummy_class
        expect(result.id).to eql 12
        expect(result.name).to eql 'Mies'
      end
    end

    it 'includes the last request, last response and meta information in the instantiated resource' do
      result = dummy_class.build_resource_from_response(response)

      aggregate_failures do
        expect(result.last_request).to eql request
        expect(result.last_response).to eql response
        expect(result.meta).to eql({ 'total' => 10 })
      end
    end
  end

  describe '.build_resource' do
    let(:collection) do
      { 'id' => 12, 'name' => 'Mies' }
    end

    it 'instantiates the resource from the given collection and options' do
      expect(dummy_class).to receive(:new).with(collection.merge({ meta: 'meta' })).and_call_original
      dummy_class.build_resource(collection, { meta: 'meta' })
    end

    it 'returns the instantiated resource' do
      result = dummy_class.build_resource(collection)

      aggregate_failures do
        expect(result).to be_a dummy_class
        expect(result.id).to eql 12
        expect(result.name).to eql 'Mies'
      end
    end

    context 'when the given collection is NOT a Hash' do
      it 'returns nil' do
        aggregate_failures do
          expect(dummy_class.build_resource(nil)).to be_nil
          expect(dummy_class.build_resource([])).to be_nil
          expect(dummy_class.build_resource('')).to be_nil
        end
      end
    end
  end

  describe '.build_collection_from_response' do
    let(:attributes) do
      [
        { 'id' => 10, 'name' => 'Mies' },
        { 'id' => 11, 'name' => 'Aap' },
        { 'id' => 12, 'name' => 'Noot' }
      ]
    end
    let(:response) { instance_double(RemoteResource::Response, request: request, attributes: attributes, meta: { 'total' => 10 }) }

    it 'returns the collection of instantiated resources from the response' do
      result = dummy_class.build_collection_from_response(response)

      aggregate_failures do
        expect(result).to be_a RemoteResource::Collection
        expect(result[0]).to be_a dummy_class
        expect(result[0].id).to eql 10
        expect(result[0].name).to eql 'Mies'
        expect(result[1]).to be_a dummy_class
        expect(result[1].id).to eql 11
        expect(result[1].name).to eql 'Aap'
        expect(result[2]).to be_a dummy_class
        expect(result[2].id).to eql 12
        expect(result[2].name).to eql 'Noot'
      end
    end

    it 'includes the last request, last response and meta information in the collection of instantiated resources' do
      result = dummy_class.build_collection_from_response(response)

      aggregate_failures do
        expect(result.last_request).to eql request
        expect(result.last_response).to eql response
        expect(result.meta).to eql({ 'total' => 10 })
      end
    end
  end

  describe '.build_collection' do
    let(:collection) do
      [
        { 'id' => 10, 'name' => 'Mies' },
        { 'id' => 11, 'name' => 'Aap' },
        { 'id' => 12, 'name' => 'Noot' }
      ]
    end

    it 'instantiates collection of resources from the given collection and options' do
      expect(RemoteResource::Collection).to receive(:new).with(dummy_class, collection, { meta: 'meta' }).and_call_original
      dummy_class.build_collection(collection, { meta: 'meta' })
    end

    it 'returns the collection of instantiated resources' do
      result = dummy_class.build_collection(collection)

      aggregate_failures do
        expect(result).to be_a RemoteResource::Collection
        expect(result[0]).to be_a dummy_class
        expect(result[0].id).to eql 10
        expect(result[0].name).to eql 'Mies'
        expect(result[1]).to be_a dummy_class
        expect(result[1].id).to eql 11
        expect(result[1].name).to eql 'Aap'
        expect(result[2]).to be_a dummy_class
        expect(result[2].id).to eql 12
        expect(result[2].name).to eql 'Noot'
      end
    end

    context 'when the given collection is NOT an Array' do
      it 'returns an empty Array' do
        aggregate_failures do
          expect { dummy_class.build_collection(nil) }.to raise_error(ArgumentError, '`collection` must be an Array')
          expect { dummy_class.build_collection({}) }.to raise_error(ArgumentError, '`collection` must be an Array')
          expect { dummy_class.build_collection('') }.to raise_error(ArgumentError, '`collection` must be an Array')
        end
      end
    end
  end

  describe '#rebuild_resource_from_response' do
    let(:response) { instance_double(RemoteResource::Response, request: request, attributes: { 'name' => 'Mies' }, meta: { 'total' => 10 }) }

    before { dummy.id = 12 }

    it 'returns the same resource' do
      expected_object_id = dummy.object_id

      result = dummy.rebuild_resource_from_response(response)

      expect(result.object_id).to eql expected_object_id
    end

    it 'updates the resource from the response' do
      aggregate_failures do
        expect(dummy.id).to eql 12
        expect(dummy.name).to be_blank
      end

      dummy.rebuild_resource_from_response(response)

      aggregate_failures do
        expect(dummy.id).to eql 12
        expect(dummy.name).to eql 'Mies'
      end
    end

    it 'includes the last request, last response and meta information in the resource' do
      aggregate_failures do
        expect(dummy.last_request).to be_blank
        expect(dummy.last_response).to be_blank
        expect(dummy.meta).to be_blank
      end

      dummy.rebuild_resource_from_response(response)

      aggregate_failures do
        expect(dummy.last_request).to eql request
        expect(dummy.last_response).to eql response
        expect(dummy.meta).to eql({ 'total' => 10 })
      end
    end
  end

  describe '#rebuild_resource' do
    let(:collection) do
      { 'name' => 'Mies' }
    end

    before { dummy.id = 12 }

    it 'returns the same resource' do
      expected_object_id = dummy.object_id

      result = dummy.rebuild_resource(collection)

      expect(result.object_id).to eql expected_object_id
    end

    it 'updates the resource, using mass-assignment, from the given collection and options' do
      expect(dummy).to receive(:attributes=).with(collection.merge({ meta: 'meta' })).and_call_original
      dummy.rebuild_resource(collection, { meta: 'meta' })
    end

    it 'updates the resource' do
      aggregate_failures do
        expect(dummy.id).to eql 12
        expect(dummy.name).to be_blank
      end

      dummy.rebuild_resource(collection)

      aggregate_failures do
        expect(dummy.id).to eql 12
        expect(dummy.name).to eql 'Mies'
      end
    end

    context 'when the given collection is NOT a Hash' do
      it 'does NOT update the resource' do
        aggregate_failures do
          expect { dummy.rebuild_resource(nil) }.not_to change { dummy.attributes }.from({ id: 12 })
          expect { dummy.rebuild_resource([]) }.not_to change { dummy.attributes }.from({ id: 12 })
          expect { dummy.rebuild_resource('') }.not_to change { dummy.attributes }.from({ id: 12 })
        end
      end
    end

    context 'when the given collection is NOT a Hash and options are given' do
      it 'updates the resource with only the options' do
        aggregate_failures do
          dummy.meta = nil
          expect { dummy.rebuild_resource(nil, meta: { 'total' => 10 }) }.to change { dummy.meta }.to({ 'total' => 10 })
          dummy.meta = nil
          expect { dummy.rebuild_resource([], meta: { 'total' => 10 }) }.to change { dummy.meta }.to({ 'total' => 10 })
          dummy.meta = nil
          expect { dummy.rebuild_resource('', meta: { 'total' => 10 }) }.to change { dummy.meta }.to({ 'total' => 10 })
        end
      end
    end
  end

end
