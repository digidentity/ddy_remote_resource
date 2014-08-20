require 'spec_helper'

describe RemoteResource::Request do

  module RemoteResource
    class RequestDummy
      include RemoteResource::Base

      attr_accessor :name

    end
  end

  let(:dummy_class) { RemoteResource::RequestDummy }
  let(:dummy)       { dummy_class.new id: '12' }

  let(:resource)           { dummy_class }
  let(:rest_action)        { :get }
  let(:connection_options) { {} }
  let(:attributes) do
    { name: 'Mies' }
  end

  let(:request) { described_class.new resource, rest_action, attributes, connection_options }

  describe '#perform' do
    let(:connection)             { Typhoeus::Request }
    let(:determined_request_url) { '/request_dummy.json' }
    let(:determined_attributes)  { attributes }
    let(:determined_headers)     { { "Accept"=>"application/json" } }

    before { allow(RemoteResource::Response).to receive(:new) }

    context 'when the rest_action is :get' do
      let(:rest_action) { 'get' }

      it 'makes a GET request with the attributes as params' do
        expect(connection).to receive(:get).with(determined_request_url, params: determined_attributes, headers: determined_headers)
        request.perform
      end

      skip 'returns a RemoteResource::Response' do
        expect(RemoteResource::Response).to receive(:new)
        request.perform
      end
    end

    context 'when the rest_action is :put' do
      let(:rest_action) { 'put' }

      it 'makes a PUT request with the attributes as body' do
        expect(connection).to receive(:put).with(determined_request_url, body: determined_attributes, headers: determined_headers)
        request.perform
      end

      skip 'returns a RemoteResource::Response' do
        expect(RemoteResource::Response).to receive(:new)
        request.perform
      end
    end

    context 'when the rest_action is :put' do
      let(:rest_action) { 'put' }

      it 'makes a PUT request with the attributes as body' do
        expect(connection).to receive(:put).with(determined_request_url, body: determined_attributes, headers: determined_headers)
        request.perform
      end

      skip 'returns a RemoteResource::Response' do
        expect(RemoteResource::Response).to receive(:new)
        request.perform
      end
    end

    context 'when the rest_action is :patch' do
      let(:rest_action) { 'patch' }

      it 'makes a PATCH request with the attributes as body' do
        expect(connection).to receive(:patch).with(determined_request_url, body: determined_attributes, headers: determined_headers)
        request.perform
      end

      skip 'returns a RemoteResource::Response' do
        expect(RemoteResource::Response).to receive(:new)
        request.perform
      end
    end

    context 'when the rest_action is :post' do
      let(:rest_action) { 'post' }

      it 'makes a POST request with the attributes as body' do
        expect(connection).to receive(:post).with(determined_request_url, body: determined_attributes, headers: determined_headers)
        request.perform
      end

      skip 'returns a RemoteResource::Response' do
        expect(RemoteResource::Response).to receive(:new)
        request.perform
      end
    end

    context 'when the rest_action is unknown' do
      let(:rest_action) { 'foo' }

      it 'raises the RemoteResource::Request::RESTActionUnknown error' do
        expect{ request.perform }.to raise_error RemoteResource::Request::RESTActionUnknown, "for action: 'foo'"
      end
    end
  end

  describe '#connection' do
    it 'uses the Typhoeus::Request' do
      expect(request.connection).to eql Typhoeus::Request
    end
  end

  describe '#determined_request_url' do
    context 'the attributes contain an id' do
      let(:attributes) do
        { id: 12, name: 'Mies' }
      end

      it 'uses the id for the request url' do
        expect(request.determined_request_url).to eql '/request_dummy/12.json'
      end
    end

    context 'the attributes do NOT contain an id' do
      it 'does NOT use the id for the request url' do
        expect(request.determined_request_url).to eql '/request_dummy.json'
      end
    end

    context 'the given connection_options contain a base_url' do
      let(:connection_options) do
        { base_url: 'http://www.foo.com/api' }
      end

      it 'uses the base_url for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foo.com/api.json'
      end
    end

    context 'the given connection_options do NOT contain a base_url' do
      it 'does NOT use the base_url for the request url' do
        expect(request.determined_request_url).to eql '/request_dummy.json'
      end
    end

    context 'the given connection_options contain a content_type' do
      let(:connection_options) do
        { content_type: '' }
      end

      it 'uses the content_type for the request url' do
        expect(request.determined_request_url).to eql '/request_dummy'
      end
    end

    context 'the given connection_options do NOT contain a content_type' do
      it 'does NOT use the content_type for the request url' do
        expect(request.determined_request_url).to eql '/request_dummy.json'
      end
    end
  end

  describe '#determined_attributes' do
    context 'the given connection_options contain a root_element' do
      let(:connection_options) do
        { root_element: 'foobar' }
      end

      let(:packed_up_attributes) do
        { 'foobar' => { name: 'Mies' } }
      end

      it 'packs up the attributes with the root_element' do
        expect(request.determined_attributes).to eql packed_up_attributes
      end
    end

    context 'the given connection_options do NOT contain a root_element' do
      it 'does NOT pack up the attributes with the root_element' do
        expect(request.determined_attributes).to eql attributes
      end
    end
  end

  describe '#determined_headers' do
    let(:headers) do
      { 'Baz' => 'FooBar' }
    end

    context 'the given connection_options contain a default_headers' do
      let(:default_headers) do
        { 'Foo' => 'Bar' }
      end

      context 'and the given connection_options contain a headers' do
        let(:connection_options) do
          { default_headers: default_headers, headers: headers }
        end

        it 'uses the default_headers for the request headers' do
          expect(request.determined_headers).to eql({ "Foo"=>"Bar" })
        end
      end

      context 'and the given connection_options do NOT contain a headers' do
        let(:connection_options) do
          { default_headers: default_headers }
        end

        it 'uses the default_headers for the request headers' do
          expect(request.determined_headers).to eql({ "Foo"=>"Bar" })
        end
      end
    end

    context 'the given connection_options do NOT contain a default_headers' do
      context 'and the given connection_options contain a headers' do
        let(:connection_options) do
          { headers: headers }
        end

        it 'uses the headers for the request headers' do
          expect(request.determined_headers).to eql({ "Accept"=>"application/json", "Baz"=>"FooBar" })
        end
      end

      context 'and the given connection_options do NOT contain a headers' do
        it 'does NOT use the headers for the request headers' do
          expect(request.determined_headers).to eql({ "Accept"=>"application/json" })
        end
      end
    end
  end

end