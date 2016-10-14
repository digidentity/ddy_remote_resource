require 'spec_helper'

RSpec.describe RemoteResource::Collection do

  module RemoteResource
    class CollectionDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      attr_accessor :name
    end
  end

  let(:dummy_class) { RemoteResource::CollectionDummy }
  let(:dummy)       { dummy_class.new }

  let(:request) { instance_double(RemoteResource::Request) }
  let(:response) { instance_double(RemoteResource::Response) }
  let(:options) do
    { last_request: request, last_response: response, meta: { 'total' => 10 } }
  end

  let(:resources_collection) do
    [
      { 'id' => 1, 'name' => 'mies_1' },
      { 'id' => 2, 'name' => 'mies_2' }
    ]
  end

  let(:collection) { described_class.new(dummy_class, resources_collection, options) }

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
      it 'instantiates each element in the resources_collection as resource with the given options' do
        expect(dummy_class).to receive(:new).with(resources_collection[0].merge(options)).and_call_original
        expect(dummy_class).to receive(:new).with(resources_collection[1].merge(options)).and_call_original
        collection.all?
      end

      it 'returns an Enumerable' do
        expect(collection).to be_an Enumerable
      end

      context 'Enumerable' do
        it 'includes the resources' do
          aggregate_failures do
            expect(collection[0]).to be_a RemoteResource::CollectionDummy
            expect(collection[1]).to be_a RemoteResource::CollectionDummy
          end
        end

        it 'includes the instantiated resources' do
          aggregate_failures do
            expect(collection[0].id).to eql 1
            expect(collection[0].name).to eql 'mies_1'

            expect(collection[1].id).to eql 2
            expect(collection[1].name).to eql 'mies_2'
          end
        end

        it 'includes the last request, last response and meta information in the instantiated resources' do
          aggregate_failures do
            expect(collection[0].last_request).to eql request
            expect(collection[0].last_response).to eql response
            expect(collection[0].meta).to eql({ 'total' => 10 })

            expect(collection[1].last_request).to eql request
            expect(collection[1].last_response).to eql response
            expect(collection[1].meta).to eql({ 'total' => 10 })
          end
        end
      end

      it 'returns the same objects each time' do
        expected = collection.collect(&:object_id)
        actual   = collection.collect(&:object_id)

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
    context 'when last response is successful' do
      it 'returns true' do
        collection.last_response = instance_double(RemoteResource::Response, success?: true)

        expect(collection.success?).to eql true
      end
    end

    context 'when last response is NOT successful' do
      it 'returns false' do
        collection.last_response = instance_double(RemoteResource::Response, success?: false)

        expect(collection.success?).to eql false
      end
    end
  end

  describe '#last_request' do
    context 'when last request is in the options' do
      it 'returns the last request of the options' do
        expect(collection.last_request).to eql request
      end
    end

    context 'when last request is set' do
      let(:other_request) { instance_double(RemoteResource::Request) }

      it 'returns the set request' do
        collection.last_request = other_request

        expect(collection.last_request).to eql other_request
      end
    end
  end

  describe '#last_response' do
    context 'when last response is in the options' do
      it 'returns the last response of the options' do
        expect(collection.last_response).to eql response
      end
    end

    context 'when last response is set' do
      let(:other_response) { instance_double(RemoteResource::Response) }

      it 'returns the set response' do
        collection.last_response = other_response

        expect(collection.last_response).to eql other_response
      end
    end
  end

  describe '#meta' do
    context 'when meta information is in the options' do
      it 'returns the meta information of the options' do
        expect(collection.meta).to eql({ 'total' => 10 })
      end
    end

    context 'when meta is set' do
      it 'returns the set meta information' do
        collection.meta = { 'total' => 15 }

        expect(collection.meta).to eql({ 'total' => 15 })
      end
    end
  end

  describe '#_response' do
    it 'warns that the method is deprecated' do
      expect(collection).to receive(:warn).with('[DEPRECATION] `._response` is deprecated. Please use `.last_response` instead.')
      collection._response
    end
  end

end
