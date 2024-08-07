require 'spec_helper'

RSpec.describe RemoteResource::Request do

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
  let(:dummy) { dummy_class.new id: '12' }

  let(:resource) { dummy_class }
  let(:http_action) { :get }
  let(:connection_options) { {} }
  let(:attributes) do
    { name: 'Mies' }
  end

  let(:request) { described_class.new(resource, http_action, attributes, connection_options) }

  describe '#resource_klass' do
    context 'when the resource is a RemoteResource class' do
      let(:resource) { dummy_class }

      it 'returns the resource' do
        expect(request.resource_klass).to eql RemoteResource::RequestDummy
      end
    end

    context 'when the resource is a RemoteResource object' do
      let(:resource) { dummy }

      it 'returns the Class of the resource' do
        expect(request.resource_klass).to eql RemoteResource::RequestDummy
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
        json_spec:    'From .with_connection_options',
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
        json_spec:         'From .with_connection_options',
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
    let(:connection_request) { Typhoeus::Request.new(expected_request_url) }
    let(:connection_response) do
      response         = Typhoeus::Response.new({ mock: true, body: 'response_body', code: response_code, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' } })
      response.request = connection_request
      response
    end

    let(:response_code) { 200 }
    let(:expected_response) { RemoteResource::Response.new(connection_response, connection_options) }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { connection_response } }

    shared_examples 'a conditional construct for the response' do
      context 'when the response is #success?' do
        it 'returns a RemoteResource::Response object with the request' do
          aggregate_failures do
            result = request.perform

            expect(result).to be_a RemoteResource::Response
            expect(result.request).to eql request
          end
        end
      end

      context 'when the response is #unprocessable_entity? (response_code=422)' do
        let(:response_code) { 422 }

        it 'returns a RemoteResource::Response object with the request' do
          aggregate_failures do
            result = request.perform

            expect(result).to be_a RemoteResource::Response
            expect(result.request).to eql request
          end
        end
      end

      context 'when the response is NOT successful' do
        let(:response_code) { 500 }

        it 'raises a RemoteResource::HTTPError' do
          expect { request.perform }.to raise_error RemoteResource::HTTPError
        end
      end
    end

    context 'when the http_action is :get' do
      let(:http_action) { 'get' }
      let(:attributes) do
        {}
      end
      let(:connection_options) do
        { params: { pseudonym: 'pseudonym' } }
      end

      let(:expected_request_url) { 'http://www.foobar.com/request_dummy.json' }
      let(:expected_params) { RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }) }
      let(:expected_headers) { described_class::DEFAULT_HEADERS }
      let(:expected_body) { nil }
      let(:expected_connection_options) { request.connection_options }

      it 'makes a GET request with the connection_options[:params] as query' do
        expect(connection).to receive(:get).with(expected_request_url, params: expected_params,
                                                 body: expected_body, headers: expected_headers,
                                                 connecttimeout: 30, timeout: 120).and_call_original
        request.perform
      end

      include_examples 'a conditional construct for the response'
    end

    context 'when the http_action is :put' do
      let(:http_action) { 'put' }
      let(:attributes) do
        { id: 15, name: 'Mies', famous: true }
      end
      let(:connection_options) do
        {}
      end

      let(:expected_request_url) { 'http://www.foobar.com/request_dummy/15.json' }
      let(:expected_params) { nil }
      let(:expected_headers) { described_class::DEFAULT_HEADERS.merge(described_class::DEFAULT_CONTENT_TYPE) }
      let(:expected_body) { JSON.generate(attributes) }
      let(:expected_connection_options) { request.connection_options }

      it 'makes a PUT request with the attributes as body' do
        expect(connection).to receive(:put).with(expected_request_url, params: expected_params,
                                                 body: expected_body, headers: expected_headers,
                                                 connecttimeout: 30, timeout: 120).and_call_original
        request.perform
      end

      include_examples 'a conditional construct for the response'
    end

    context 'when the http_action is :patch' do
      let(:http_action) { 'patch' }
      let(:attributes) do
        { id: 15, name: 'Mies', famous: true }
      end
      let(:connection_options) do
        {}
      end

      let(:expected_request_url) { 'http://www.foobar.com/request_dummy/15.json' }
      let(:expected_params) { nil }
      let(:expected_headers) { described_class::DEFAULT_HEADERS.merge(described_class::DEFAULT_CONTENT_TYPE) }
      let(:expected_body) { JSON.generate(attributes) }
      let(:expected_connection_options) { request.connection_options }

      it 'makes a PATCH request with the attributes as body' do
        expect(connection).to receive(:patch).with(expected_request_url, params: expected_params,
                                                   body: expected_body, headers: expected_headers,
                                                   connecttimeout: 30, timeout: 120).and_call_original
        request.perform
      end

      include_examples 'a conditional construct for the response'
    end

    context 'when the http_action is :post' do
      let(:http_action) { 'post' }
      let(:attributes) do
        { name: 'Mies', famous: true }
      end
      let(:connection_options) do
        {}
      end

      let(:expected_request_url) { 'http://www.foobar.com/request_dummy.json' }
      let(:expected_params) { nil }
      let(:expected_headers) { described_class::DEFAULT_HEADERS.merge(described_class::DEFAULT_CONTENT_TYPE) }
      let(:expected_body) { JSON.generate(attributes) }
      let(:expected_connection_options) { request.connection_options }

      it 'makes a POST request with the attributes as body' do
        expect(connection).to receive(:post).with(expected_request_url, params: expected_params,
                                                  body: expected_body, headers: expected_headers,
                                                  connecttimeout: 30, timeout: 120).and_call_original
        request.perform
      end

      include_examples 'a conditional construct for the response'
    end

    context 'when the http_action is :delete' do
      let(:http_action) { 'delete' }
      let(:attributes) do
        { id: 15 }
      end
      let(:connection_options) do
        { params: { pseudonym: 'pseudonym' } }
      end

      let(:expected_request_url) { 'http://www.foobar.com/request_dummy/15.json' }
      let(:expected_params) { RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }) }
      let(:expected_headers) { described_class::DEFAULT_HEADERS }
      let(:expected_body) { nil }
      let(:expected_connection_options) { request.connection_options }

      it 'makes a DELETE request with the connection_options[:params] as query' do
        expect(connection).to receive(:delete).with(expected_request_url, params: expected_params,
                                                    body: expected_body, headers: expected_headers,
                                                    connecttimeout: 30, timeout: 120).and_call_original
        request.perform
      end

      include_examples 'a conditional construct for the response'
    end

    context 'when the http_action is unknown' do
      let(:http_action) { 'foo' }
      let(:expected_request_url) { '' }

      it 'raises the RemoteResource::HTTPMethodUnsupported error' do
        expect { request.perform }.to raise_error RemoteResource::HTTPMethodUnsupported, 'Requested HTTP method=foo is NOT supported, the HTTP action MUST be a supported HTTP action=get, put, patch, post, delete'
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
          expect { request.request_url }.to raise_error(RemoteResource::CollectionOptionKeyError)
        end
      end
    end
  end

  describe '#query' do
    context 'when connection_options[:params] are present' do
      let(:connection_options) do
        { root_element: :data, params: { pseudonym: 'pseudonym', labels: [1, '2', 'three'], pagination: { page: 5, limit: 15, ordered: true } } }
      end

      let(:expected_query) do
        'pseudonym=pseudonym&labels[]=1&labels[]=2&labels[]=three&pagination[page]=5&pagination[limit]=15&pagination[ordered]=true'
      end

      it 'returns the URL-encoded params' do
        expect(CGI.unescape(request.query)).to eql expected_query
      end

      context "when connection_options[:force_get_params_in_body] is present" do
        let(:connection_options) do
          { root_element: :data, force_get_params_in_body: true, params: { pseudonym: 'pseudonym', labels: [1, '2', 'three'], pagination: { page: 5, limit: 15, ordered: true } } }
        end

        it 'returns nil' do
          expect(request.query).to be_nil
        end
      end
    end

    context 'when connection_options[:params] are NOT present' do
      let(:connection_options) do
        { root_element: :data }
      end

      it 'returns nil' do
        expect(request.query).to be_nil
      end
    end
  end

  describe '#body' do
    let(:attributes) do
      { name: 'Mies', featured: true, labels: [1, '2', 'three'] }
    end

    context 'when the http_action is :put, :patch or :post' do
      let(:http_action) { :post }

      let(:expected_body) do
        '{"name":"Mies","featured":true,"labels":[1,"2","three"]}'
      end

      it 'returns the JSON-encoded attributes' do
        expect(request.body).to eql expected_body
      end
    end

    context 'when the http_action is :get and connection_options[:force_get_params_in_body] is present' do
      let(:http_action) { :get }
      let(:connection_options) do
        { force_get_params_in_body: true, params: { pseudonym: 'pseudonym', labels: [1, '2', 'three'] } }
      end

      let(:expected_body) do
        '{"pseudonym":"pseudonym","labels":[1,"2","three"]}'
      end

      it 'returns the JSON-encoded connection_options[:params]' do
        expect(request.body).to eql expected_body
      end
    end

    context "when the http_action is :get and connection_options[:params][:force_get_params_in_body] is not present" do
      let(:http_action) { :get }

      it 'returns nil' do
        expect(request.body).to be_nil
      end
    end
  end

  describe '#attributes' do
    context 'default behaviour' do
      let(:attributes) do
        { name: 'Mies', featured: true, labels: [1, '2', 'three'] }
      end

      let(:expected_attributes) do
        { name: 'Mies', featured: true, labels: [1, '2', 'three'] }
      end

      it 'returns the given attributes' do
        expect(request.attributes).to eql expected_attributes
      end

      context 'and there are NO given attributes' do
        let(:attributes) do
          nil
        end

        it 'returns an empty Hash' do
          expect(request.attributes).to eql({})
        end
      end
    end

    context 'when connection_options[:root_element] is present' do
      let(:connection_options) do
        { root_element: :data }
      end

      let(:attributes) do
        { name: 'Mies', featured: true, labels: [1, '2', 'three'] }
      end

      it 'returns the given attributes wrapped in the connection_options[:root_element]' do
        expect(request.attributes).to eql({ data: { name: 'Mies', featured: true, labels: [1, '2', 'three'] } })
      end

      context 'and there are NO given attributes' do
        let(:attributes) do
          nil
        end

        it 'returns nil wrapped in the connection_options[:root_element]' do
          expect(request.attributes).to eql({ data: nil })
        end
      end
    end

    context 'when connection_options[:json_spec] == :json_api' do
      let(:connection_options) do
        { json_spec: :json_api }
      end

      let(:attributes) do
        { id: 1, name: 'Mies', featured: true, labels: [1, '2', 'three'] }
      end

      it 'returns the given attributes wrapped in the json api spec' do
        expect(request.attributes).to eql({ data: { id: 1, type: "RequestDummy", attributes: { name: 'Mies', featured: true, labels: [1, '2', 'three'] } } })
      end

      context 'and there are NO given attributes' do
        let(:attributes) do
          nil
        end

        it 'returns nil wrapped in the connection_options[:root_element]' do
          expect(request.attributes).to eql({ data: {} })
        end
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
      after { RemoteResource::Base.global_headers = nil }

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

    context 'when conditional_headers are present' do
      let(:http_action) { 'post' }

      context 'when a body is present' do
        let(:expected_headers) do
          { 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}", 'Content-Type' => 'application/json' }
        end

        it 'returns the default headers with the conditional_headers' do
          expect(request.headers).to eql expected_headers
        end
      end

      context 'when RequestStore.store[:request_id] is present' do
        before do
          RequestStore.store[:request_id] = 'CASCADING-REQUEST-ID'
        end

        after do
          RequestStore.store[:request_id] = nil
        end

        let(:expected_headers) do
          { 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}", 'Content-Type' => 'application/json', 'X-Request-Id' => 'CASCADING-REQUEST-ID' }
        end

        it 'returns the default headers with the X-Request-Id header' do
          expect(request.headers).to eql expected_headers
        end
      end
    end
  end

  describe '#timeout_options' do
    it 'is not given by default' do
      expect(request.connection_options).not_to include :connecttimeout, :timeout
    end

    context 'with custom timeouts' do
      let(:connection_options) do
        { connecttimeout: 1, timeout: 2 }
      end

      it 'sets the timeouts from connection_options' do
        aggregate_failures do
          expect(request.connection_options[:connecttimeout]).to eq 1
          expect(request.connection_options[:timeout]).to eq 2
        end
      end
    end
  end

  describe '#raise_http_error' do
    let(:connection_response) { instance_double(Typhoeus::Response, request: instance_double(Typhoeus::Request), timed_out?: false) }
    let(:response) { RemoteResource::Response.new(connection_response, connection_options) }

    context 'when the response has timed out' do
      let(:connection_response) { instance_double(Typhoeus::Response, request: instance_double(Typhoeus::Request), timed_out?: true) }

      it 'raises a RemoteResource::HTTPRequestTimeout' do
        expect { request.send(:raise_http_error, request, response) }.to raise_error RemoteResource::HTTPRequestTimeout
      end
    end

    context 'when the response code is 301, 302, 303 or 307' do
      response_codes = [301, 302, 303, 307]
      response_codes.each do |response_code|
        it "raises a RemoteResource::HTTPRedirectionError with response code #{response_code}" do
          allow(response).to receive(:response_code) { response_code }

          expect { request.send(:raise_http_error, request, response) }.to raise_error RemoteResource::HTTPRedirectionError
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

          expect { request.send(:raise_http_error, request, response) }.to raise_error error_class
        end
      end
    end

    context 'when the response code is in the 4xx range and no other error is raised' do
      it 'raises a RemoteResource::HTTPClientError' do
        allow(response).to receive(:response_code) { 430 }

        expect { request.send(:raise_http_error, request, response) }.to raise_error RemoteResource::HTTPClientError
      end
    end

    context 'when the response code is in the 5xx range and no other error is raised' do
      it 'raises a RemoteResource::HTTPServerError' do
        allow(response).to receive(:response_code) { 501 }

        expect { request.send(:raise_http_error, request, response) }.to raise_error RemoteResource::HTTPServerError
      end
    end

    context 'when the response code is 0 and no other error is raised' do
      it 'raises a RemoteResource::HTTPError with correct error message' do
        allow(response).to receive(:response_code) { 0 }
        allow(connection_response).to receive(:return_code) { :ssl_connect }
        allow(connection_response).to receive(:response_code) { 0 }

        error_message = 'HTTP request failed for RemoteResource::RequestDummy with response_code=0 with return_code=ssl_connect with http_action=get with request_url=http://www.foobar.com/request_dummy.json'
        expect { request.send(:raise_http_error, request, response) }.to raise_error RemoteResource::HTTPError, error_message
      end
    end

    context 'when the response code is nothing and no other error is raised' do
      it 'raises a RemoteResource::HTTPError' do
        allow(response).to receive(:response_code) { nil }

        expect { request.send(:raise_http_error, request, response) }.to raise_error RemoteResource::HTTPError
      end
    end
  end

end
