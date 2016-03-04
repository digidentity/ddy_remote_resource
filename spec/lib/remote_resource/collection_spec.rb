require 'spec_helper'

describe RemoteResource::Collection do

  module RemoteResource
    class CollectionDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      attr_accessor :username
    end
  end

  let(:dummy_class) { RemoteResource::CollectionDummy }
  let(:dummy)       { dummy_class.new }

  let(:response) { RemoteResource::Response.new double.as_null_object }
  let(:response_meta) { { total: '1' } }
  let(:response_hash) do
    { _response: response, meta: response_meta }
  end

  let(:resources_collection) do
    [
      { id: 1, username: 'mies_1' },
      { id: 2, username: 'mies_2' }
    ]
  end

  let(:collection) { described_class.new dummy_class, resources_collection, response_hash }

  specify { expect(described_class).to include Enumerable }

  describe '#[]' do
    let(:to_a) { collection.dup.to_a }

    it 'delegates to the #to_a' do
      expect(collection[0].id).to eql to_a[0].id
    end
  end

  describe '#at' do
    let(:to_a) { collection.dup.to_a }

    it 'delegates to the #to_a' do
      expect(collection.at(0).id).to eql to_a.at(0).id
    end
  end

  describe '#reverse' do
    let(:to_a) { collection.dup.to_a }

    it 'delegates to the #to_a' do
      expect(collection.reverse[0].id).to eql to_a.reverse[0].id
    end
  end

  describe '#size' do
    let(:to_a) { collection.dup.to_a }

    it 'delegates to the #to_a' do
      expect(collection.size).to eql to_a.size
    end
  end

  describe '#each' do
    context 'when the resources_collection is an Array' do
      it 'instantiates each element in the resources_collection as resource' do
        expect(dummy_class).to receive(:new).with(resources_collection[0].merge(response_hash)).and_call_original
        expect(dummy_class).to receive(:new).with(resources_collection[1].merge(response_hash)).and_call_original
        collection.all?
      end

      it 'returns an Enumerable' do
        expect(collection).to be_an Enumerable
      end

      context 'Enumerable' do
        it 'includes the resources' do
          expect(collection[0]).to be_a RemoteResource::CollectionDummy
          expect(collection[1]).to be_a RemoteResource::CollectionDummy
        end

        it 'includes the instantiated resources' do
          expect(collection[0].username).to eql 'mies_1'
          expect(collection[1].username).to eql 'mies_2'
        end

        it 'includes the responses in the instantiated resources' do
          expect(collection[0]._response).to eql response
          expect(collection[1]._response).to eql response
        end
      end

      it 'returns the same objects each time' do
        expected = collection.collect(&:object_id)
        actual = collection.collect(&:object_id)

        aggregate_failures do
          expect(expected.length).to eq(2)
          expect(expected).to eql(actual)
        end
      end
    end

    context 'when the resources_collection is NOT an Array' do
      let(:resources_collection) { {} }

      it 'returns nil' do
        expect(collection.each).to be_nil
      end
    end
  end

  describe '#empty?' do
    context 'when the resources_collection is nil' do
      let(:resources_collection) { nil }

      it 'returns true' do
        expect(collection.empty?).to eql true
      end
    end

    context 'when the resources_collection is blank' do
      let(:resources_collection) { '' }

      it 'returns true' do
        expect(collection.empty?).to eql true
      end
    end

    context 'when the resources_collection is NOT nil or blank' do
      it 'returns false' do
        expect(collection.empty?).to eql false
      end
    end
  end

  describe '#success?' do
    context 'when response is successful' do
      before { allow(response).to receive(:success?) { true } }

      it 'returns true' do
        expect(collection.success?).to eql true
      end
    end

    context 'when response is NOT successful' do
      before { allow(response).to receive(:success?) { false } }

      it 'returns false' do
        expect(collection.success?).to eql false
      end
    end
  end

  describe '#meta' do
    it 'returns :meta' do
      expect(collection.meta).to eql(response_meta)
    end
  end

  describe '#record_count' do
    context 'when response contains :meta and has key :total' do
      let(:response_meta) { { total: '4' } }

      it 'return the :total' do
        expect(collection.record_count).to eql(4)
      end

      context 'but with empty value' do
        let(:response_meta) { { total: '' } }

        it 'return the :total' do
          expect(collection.record_count).to eql(nil)
        end
      end
    end

    context 'when response contains :meta but does NOT have key :total' do
      let(:response_meta) { { pagination: { next: 2 } } }

      it 'return the :total' do
        expect(collection.record_count).to eql(nil)
      end
    end

    context 'when response does NOT contain :meta' do
      let(:response_meta) { nil }

      it 'return the :total' do
        expect(collection.record_count).to eql(nil)
      end
    end
  end

end
