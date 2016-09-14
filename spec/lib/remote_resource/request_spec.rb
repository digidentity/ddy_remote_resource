require 'spec_helper'

describe RemoteResource::Request do

  module RemoteResource
    class RequestDummy
      include RemoteResource::Base

      self.site = 'http://www.foobar.com'

      attr_accessor :name

    end

    class RequestDummyWithCollectionPrefix < RequestDummy
      self.collection_prefix = '/parent/:parent_id'
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

  let(:request) { described_class.new(resource, rest_action, attributes, connection_options) }

  specify { expect(described_class).to include RemoteResource::HTTPErrors }

  describe '#resource_klass' do
    context 'when the resource is a RemoteResource class' do
      let(:resource) { dummy_class }

      it 'returns the resource' do
        expect(request.send :resource_klass).to eql RemoteResource::RequestDummy
      end
    end

    context 'when the resource is a RemoteResource object' do
      let(:resource) { dummy }

      it 'returns the Class of the resource' do
        expect(request.send :resource_klass).to eql RemoteResource::RequestDummy
      end
    end
  end

  describe '#connection' do
    it 'uses the connection of the resource_klass' do
      expect(request.connection).to eql Typhoeus::Request
    end
  end

  describe '#connection_options' do
    around(:each) do |example|
      dummy_class.site    = 'From Klass.site'
      dummy_class.version = 'From Klass.version'

      dummy_class.with_connection_options(block_connection_options) do
        example.run
      end

      dummy_class.site    = 'http://www.foobar.com'
      dummy_class.version = nil
    end

    let(:block_connection_options) do
      {
        root_element: 'From .with_connection_options',
        version:      'From .with_connection_options',
        path_prefix:  'From .with_connection_options'
      }
    end

    let(:connection_options) do
      {
        root_element: 'From connection_options[]',
        path_postfix: 'From connection_options[]'
      }
    end

    let(:expected_connection_options) do
      {
        site:              'From Klass.site',
        root_element:      'From connection_options[]',
        version:           'From .with_connection_options',
        path_prefix:       'From .with_connection_options',
        path_postfix:      'From connection_options[]',
        collection:        false,
        collection_name:   nil,
        collection_prefix: nil,
        default_headers:   {},
        headers:           {},
        extension:         nil,
      }
    end

    it 'returns default connection options with are defined on the resource while overwriting the connection options according to the correct precedence' do
      expect(request.connection_options).to eql expected_connection_options
    end
  end

  describe '#perform' do
    let(:connection) { Typhoeus::Request }
    let(:expected_request_url) { 'http://www.foobar.com/request_dummy.json' }
    let(:expected_params) do
      attributes
    end
    let(:expected_headers) do
      described_class::DEFAULT_HEADERS
    end
    let(:expected_body) do
      JSON.generate(attributes)
    end
    let(:expected_connection_options) do
      request.connection_options
    end

    let(:typhoeus_request)  { Typhoeus::Request.new(expected_request_url) }
    let(:typhoeus_response) do
      response = Typhoeus::Response.new
      response.request = typhoeus_request
      response
    end

    before do
      allow_any_instance_of(Typhoeus::Request).to receive(:run) { typhoeus_response }
      allow(typhoeus_response).to receive(:response_code)
      allow(typhoeus_response).to receive(:success?) { true }
    end

    shared_examples 'a conditional construct for the response' do
      context 'when the response is successful' do
        it 'makes a RemoteResource::Response object with the Typhoeus::Response object and the connection_options' do
          expect(RemoteResource::Response).to receive(:new).with(typhoeus_response, expected_connection_options).and_call_original
          request.perform
        end

        it 'returns a RemoteResource::Response object' do
          expect(request.perform).to be_a RemoteResource::Response
        end
      end

      context 'when the response_code of the response is 422' do
        before { allow(typhoeus_response).to receive(:response_code) { 422 } }

        it 'makes a RemoteResource::Response object with the Typhoeus::Response object and the connection_options' do
          expect(RemoteResource::Response).to receive(:new).with(typhoeus_response, expected_connection_options).and_call_original
          request.perform
        end

        it 'returns a RemoteResource::Response object' do
          expect(request.perform).to be_a RemoteResource::Response
        end
      end

      context 'when the response is NOT successful' do
        before { allow(typhoeus_response).to receive(:success?) { false } }

        it 'calls #raise_http_errors to raise an error' do
          expect(request).to receive(:raise_http_errors).with typhoeus_response
          request.perform
        end
      end
    end

    context 'when the rest_action is :get' do
      let(:rest_action) { 'get' }

      it 'makes a GET request with the attributes as params' do
        expect(connection).to receive(:get).with(expected_request_url, params: expected_params, headers: expected_headers).and_call_original
        request.perform
      end

      it_behaves_like 'a conditional construct for the response'
    end

    context 'when the rest_action is :put' do
      let(:rest_action) { 'put' }

      it 'makes a PUT request with the attributes as body' do
        expect(connection).to receive(:put).with(expected_request_url, body: expected_body, headers: expected_headers.reverse_merge({ 'Content-Type' => 'application/json' })).and_call_original
        request.perform
      end

      it_behaves_like 'a conditional construct for the response'
    end

    context 'when the rest_action is :patch' do
      let(:rest_action) { 'patch' }

      it 'makes a PATCH request with the attributes as body' do
        expect(connection).to receive(:patch).with(expected_request_url, body: expected_body, headers: expected_headers.reverse_merge({ 'Content-Type' => 'application/json' })).and_call_original
        request.perform
      end

      it_behaves_like 'a conditional construct for the response'
    end

    context 'when the rest_action is :post' do
      let(:rest_action) { 'post' }

      it 'makes a POST request with the attributes as body' do
        expect(connection).to receive(:post).with(expected_request_url, body: expected_body, headers: expected_headers.reverse_merge({ 'Content-Type' => 'application/json' })).and_call_original
        request.perform
      end

      it_behaves_like 'a conditional construct for the response'
    end

    context 'when the rest_action is :delete' do
      let(:rest_action) { 'delete' }

      it 'makes a DELETE request with the attributes as body' do
        expect(connection).to receive(:delete).with(expected_request_url, params: expected_params, headers: expected_headers).and_call_original
        request.perform
      end

      it_behaves_like 'a conditional construct for the response'
    end

    context 'when the rest_action is unknown' do
      let(:rest_action) { 'foo' }

      it 'raises the RemoteResource::RESTActionUnknown error' do
        expect{ request.perform }.to raise_error RemoteResource::RESTActionUnknown, "for action: 'foo'"
      end
    end
  end

  describe '#request_url' do
    context 'the attributes contain an id' do
      let(:attributes) do
        { id: 12, name: 'Mies' }
      end

      it 'uses the id for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummy/12.json'
      end
    end

    context 'the connection_options contain an id' do
      let(:connection_options) do
        { id: 12 }
      end

      it 'uses the id for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummy/12.json'
      end
    end

    context 'the attributes or connection_options do NOT contain an id' do
      it 'does NOT use the id for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummy.json'
      end
    end

    context 'the connection_options contain a base_url' do
      let(:connection_options) do
        { base_url: 'http://www.foo.com/api' }
      end

      it 'uses the base_url for the request url' do
        expect(request.request_url).to eql 'http://www.foo.com/api.json'
      end
    end

    context 'the connection_options do NOT contain a base_url' do
      it 'does NOT use the base_url for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummy.json'
      end
    end

    context 'the connection_options contain a collection' do
      let(:connection_options) do
        { collection: true }
      end

      it 'uses the collection to determine the base_url for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummies.json'
      end
    end

    context 'the connection_options contain a extension' do
      let(:connection_options) do
        { extension: '.vnd+json' }
      end

      it 'uses the extension for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummy.vnd+json'
      end
    end

    context 'the connection_options contain a blank extension' do
      let(:connection_options) do
        { extension: '' }
      end

      it 'does NOT use a extension for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummy'
      end
    end

    context 'the connection_options do NOT contain a content_type' do
      it 'uses the DEFAULT_EXTENSION for the request url' do
        expect(request.request_url).to eql 'http://www.foobar.com/request_dummy.json'
      end
    end

    context 'collection_prefix' do
      let(:dummy_class) { RemoteResource::RequestDummyWithCollectionPrefix }

      context 'when connection_options does include collection_options' do
        let(:connection_options) do
          { collection_options: { parent_id: 23 } }
        end

        it { expect(request.request_url).to eql 'http://www.foobar.com/parent/23/request_dummy_with_collection_prefix.json' }
      end

      context 'when connection_options does NOT include collection_options' do
        it 'raises error' do
          expect{ request.request_url }.to raise_error(RemoteResource::CollectionOptionKeyError)
        end
      end
    end
  end

  describe '#params' do
    context 'the connection_options contain no_params' do
      let(:connection_options) do
        {
          params: { page: 5, limit: 15 },
          no_params: true
        }
      end

      it 'returns nil' do
        expect(request.params).to be_nil
      end
    end

    context 'the connection_options do NOT contain a no_params' do
      context 'and the connection_options contain no_attributes' do
        let(:connection_options) do
          {
            params: { page: 5, limit: 15 },
            no_params: false,
            no_attributes: true
          }
        end

        it 'returns the params' do
          expect(request.params).to eql({ page: 5, limit: 15 })
        end
      end

      context 'and the connection_options do NOT contain no_attributes' do
        let(:connection_options) do
          {
            params: { page: 5, limit: 15 },
            no_params: false,
            no_attributes: false
          }
        end

        it 'returns the params merge with the attributes' do
          expect(request.params).to eql({ name: 'Mies', page: 5, limit: 15 })
        end
      end
    end
  end

  describe '#attributes' do
    context 'the connection_options contain no_attributes' do
      let(:connection_options) do
        { no_attributes: true }
      end

      it 'returns an empty Hash' do
        expect(request.attributes).to eql({})
      end
    end

    context 'the connection_options do NOT contain a no_attributes' do
      it 'does NOT return an empty Hash' do
        expect(request.attributes).not_to eql({})
      end
    end

    context 'the connection_options contain a root_element' do
      let(:connection_options) do
        { root_element: :foobar }
      end

      it 'packs up the attributes with the root_element' do
        expect(request.attributes).to eql({ foobar: { name: 'Mies' } })
      end
    end

    context 'the connection_options do NOT contain a root_element' do
      it 'does NOT pack up the attributes with the root_element' do
        expect(request.attributes).to eql attributes
      end
    end
  end

  describe '#headers' do
    context 'default behaviour' do
      let(:expected_headers) do
        { 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}" }
      end

      it 'returns the default headers' do
        expect(request.headers).to eql expected_headers
      end
    end

    context 'when connection_options[:default_headers] are present' do
      let(:connection_options) do
        { default_headers: { 'User-Agent' => 'From connection_options[:default_headers]', 'X-Locale' => 'From connection_options[:default_headers]' } }
      end

      let(:expected_headers) do
        { 'User-Agent' => 'From connection_options[:default_headers]', 'X-Locale' => 'From connection_options[:default_headers]' }
      end

      it 'returns the default headers while overwriting the headers according to the correct precedence' do
        expect(request.headers).to eql expected_headers
      end
    end

    context 'when RemoteResource::Base.global_headers are present' do
      let(:expected_headers) do
        { 'Accept' => 'application/json', 'User-Agent' => 'From RemoteResource::Base.global_headers', 'X-Locale' => 'From RemoteResource::Base.global_headers' }
      end

      before { RemoteResource::Base.global_headers = { 'User-Agent' => 'From RemoteResource::Base.global_headers', 'X-Locale' => 'From RemoteResource::Base.global_headers' } }
      after  { RemoteResource::Base.global_headers = nil }

      it 'returns the default headers while overwriting the headers according to the correct precedence' do
        expect(request.headers).to eql expected_headers
      end
    end

    context 'when connection_options[:headers] are present' do
      let(:connection_options) do
        { headers: { 'User-Agent' => 'From connection_options[:headers]', 'X-Locale' => 'From connection_options[:headers]' } }
      end

      let(:expected_headers) do
        { 'Accept' => 'application/json', 'User-Agent' => 'From connection_options[:headers]', 'X-Locale' => 'From connection_options[:headers]' }
      end

      it 'returns the default headers while overwriting the headers according to the correct precedence' do
        expect(request.headers).to eql expected_headers
      end
    end
  end

  describe '#raise_http_errors' do
    let(:effective_url)     { 'http://www.foobar.com/request_dummy.json' }
    let(:response)          { instance_double Typhoeus::Response }
    let(:raise_http_errors) { request.send :raise_http_errors, response }

    before do
      allow(response).to receive(:response_code) { response_code }
      allow(response).to receive(:effective_url) { effective_url }
    end

    context 'when the response code is 301, 302, 303 or 307' do
      response_codes = [301, 302, 303, 307]
      response_codes.each do |response_code|

        it "raises a RemoteResource::HTTPRedirectionError with response code #{response_code}" do
          allow(response).to receive(:response_code) { response_code }

          expect{ raise_http_errors }.to raise_error RemoteResource::HTTPRedirectionError, "for url: #{effective_url} with HTTP response status: #{response_code} and response: #{response.inspect}"
        end
      end
    end

    context 'when the response code is in the 4xx range' do
      response_codes_with_error_class = {
        400 => RemoteResource::HTTPBadRequest,
        401 => RemoteResource::HTTPUnauthorized,
        403 => RemoteResource::HTTPForbidden,
        404 => RemoteResource::HTTPNotFound,
        405 => RemoteResource::HTTPMethodNotAllowed,
        406 => RemoteResource::HTTPNotAcceptable,
        408 => RemoteResource::HTTPRequestTimeout,
        409 => RemoteResource::HTTPConflict,
        410 => RemoteResource::HTTPGone,
        418 => RemoteResource::HTTPTeapot,
        444 => RemoteResource::HTTPNoResponse,
        494 => RemoteResource::HTTPRequestHeaderTooLarge,
        495 => RemoteResource::HTTPCertError,
        496 => RemoteResource::HTTPNoCert,
        497 => RemoteResource::HTTPToHTTPS,
        499 => RemoteResource::HTTPClientClosedRequest,
      }
      response_codes_with_error_class.each do |response_code, error_class|

        it "raises a #{error_class} with response code #{response_code}" do
          allow(response).to receive(:response_code) { response_code }

          expect{ raise_http_errors }.to raise_error error_class, "for url: #{effective_url} with HTTP response status: #{response_code} and response: #{response.inspect}"
        end
      end
    end

    context 'when the response code is in the 4xx range and no other error is raised' do
      let(:response_code) { 430 }

      it 'raises a RemoteResource::HTTPClientError' do
        expect{ raise_http_errors }.to raise_error RemoteResource::HTTPClientError, "for url: #{effective_url} with HTTP response status: #{response_code} and response: #{response.inspect}"
      end
    end

    context 'when the response code is in the 5xx range and no other error is raised' do
      let(:response_code) { 501 }

      it 'raises a RemoteResource::HTTPServerError' do
        expect{ raise_http_errors }.to raise_error RemoteResource::HTTPServerError, "for url: #{effective_url} with HTTP response status: #{response_code} and response: #{response.inspect}"
      end
    end

    context 'when the response code is nothing and no other error is raised' do
      let(:response_code) { nil }

      it 'raises a RemoteResource::HTTPError' do
        expect{ raise_http_errors }.to raise_error RemoteResource::HTTPError, "for url: #{effective_url} with HTTP response: #{response.inspect}"
      end
    end
  end

end
