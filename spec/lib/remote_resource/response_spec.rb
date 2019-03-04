require 'spec_helper'

RSpec.describe RemoteResource::Response do

  module RemoteResource
    class ResponseDummy
      include RemoteResource::Base

      self.site = 'http://www.foobar.com'

      attr_accessor :name

    end
  end

  let(:dummy_class) { RemoteResource::ResponseDummy }
  let(:dummy) { dummy_class.new(id: '12') }

  let(:connection_options) do
    { collection: true }
  end
  let(:request) { RemoteResource::Request.new(dummy_class, :post, { name: 'Mies' }, connection_options) }
  let(:connection_response) { Typhoeus::Response.new(mock: true, code: 201, body: { id: 12, name: 'Mies' }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }
  let(:connection_request) { Typhoeus::Request.new('http://www.foobar.com/response_dummies.json', method: :post, body: { name: 'Mies' }.to_json, headers: { 'Content-Type' => 'application/json' }) }

  let(:response) { described_class.new(connection_response, connection_options.merge(request: request, connection_request: connection_request)) }

  describe '#request' do
    it 'returns the RemoteResource::Request' do
      aggregate_failures do
        expect(response.request).to be_a RemoteResource::Request
        expect(response.request).to eql request
      end
    end
  end

  describe '#success?' do
    context 'when the response is successful' do
      it 'returns true' do
        expect(response.success?).to eql true
      end
    end

    context 'when the response is NOT successful' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 422, body: { errors: { name: ['is invalid'] } }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns false' do
        expect(response.success?).to eql false
      end
    end
  end

  describe '#unprocessable_entity?' do
    context 'when the response code is 422' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 422, body: { errors: { name: ['is invalid'] } }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns true' do
        expect(response.unprocessable_entity?).to eql true
      end
    end

    context 'when the response code is NOT 422' do
      it 'returns false' do
        expect(response.unprocessable_entity?).to eql false
      end
    end
  end

  describe '#response_code' do
    it 'returns the response code' do
      expect(response.response_code).to eql 201
    end
  end

  describe '#headers' do
    it 'returns the response headers' do
      expect(response.headers).to eql({ 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' })
    end
  end

  describe '#body' do
    it 'returns the response body' do
      expect(response.body).to eql '{"id":12,"name":"Mies"}'
    end
  end

  describe '#parsed_body' do
    it 'returns the parsed JSON of the response body' do
      expect(response.parsed_body).to eql({ 'id' => 12, 'name' => 'Mies' })
    end

    context 'when the response body is nil' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 500, body: nil, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.parsed_body).to eql({})
      end
    end

    context 'when the response body is empty' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 500, body: '', headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.parsed_body).to eql({})
      end
    end

    context 'when the response body is NOT JSON' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 500, body: 'foo', headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.parsed_body).to eql({})
      end
    end
  end

  describe '#attributes' do
    it 'returns the attributes from the parsed response body' do
      expect(response.attributes).to eql({ 'id' => 12, 'name' => 'Mies' })
    end

    context 'when connection_options[:root_element] is present' do
      let(:connection_options) do
        { root_element: :data, collection: true }
      end
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 201, body: { data: { id: 12, name: 'Mies' } }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns the attributes wrapped in the connection_options[:root_element] from the parsed response body' do
        expect(response.attributes).to eql({ 'id' => 12, 'name' => 'Mies' })
      end
    end

    context 'when connection_options[:root_element] is present and the parsed response body has NO keys' do
      let(:connection_options) do
        { root_element: :data, collection: true }
      end
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 200, body: [{ id: 12, name: 'Mies' }].to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.attributes).to eql({})
      end
    end

    context 'when the parsed response body is an empty Array' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Array' do
        expect(response.attributes).to eql([])
      end
    end

    context 'when the parsed response body is NOT present' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 500, body: '', headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.attributes).to eql({})
      end
    end

    context 'with the json_api spec' do
      let(:connection_options) do
        { root_element: :data, json_spec: :json_api }
      end

      context "single response" do
        let(:connection_response) { Typhoeus::Response.new(mock: true, code: 201, body: { data: { id: 12, attributes: { name: 'Mies' } } }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

        it 'parses the attributes from the nested hash' do
          expect(response.attributes).to eql({ 'id' => 12, 'name' => 'Mies' })
        end
      end

      context "empty response" do
        let(:connection_response) { Typhoeus::Response.new(mock: true, code: 204, body: {}.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

        it 'parses the attributes from the nested hash' do
          expect(response.attributes).to eql({})
        end
      end

      context "collection response" do
        let(:connection_response) { Typhoeus::Response.new(mock: true, code: 201, body: { data: [{ id: 12, attributes: { name: 'Mies' } }] }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

        it 'parses the attributes from the nested hash' do
          expect(response.attributes).to eql(['id' => 12, 'name' => 'Mies'])
        end
      end
    end
  end

  describe '#errors' do
    context 'when the parsed response body contains "errors"' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 422, body: { errors: { name: ['is invalid'] } }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns the errors from the parsed response body' do
        expect(response.errors).to eql({ 'name' => ['is invalid'] })
      end
    end

    context 'when the attributes contains "errors", e.g. when connection_options[:root_element] is present' do
      let(:connection_options) do
        { root_element: :data, collection: true }
      end
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 422, body: { data: { errors: { name: ['is invalid'] } } }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns the errors from the attributes' do
        expect(response.errors).to eql({ 'name' => ['is invalid'] })
      end
    end

    context 'when the "errors" are NOT present' do
      it 'returns an empty Hash' do
        expect(response.errors).to eql({})
      end
    end

    context 'when the parsed response body does NOT contain keys' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 200, body: [{ id: 12, name: 'Mies' }].to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.errors).to eql({})
      end
    end

    context 'when the attributes do NOT contain keys, e.g. when connection_options[:root_element] is present' do
      let(:connection_options) do
        { root_element: :data, collection: true }
      end
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 200, body: { data: [{ id: 12, name: 'Mies' }] }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.errors).to eql({})
      end
    end
  end

  describe '#meta' do
    context 'when the parsed response body contains "meta"' do
      let(:connection_options) do
        { root_element: :data, collection: true }
      end
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 201, body: { data: { id: 12, name: 'Mies' }, meta: { total: 10 } }.to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns the meta information from the parsed response body' do
        expect(response.meta).to eql({ 'total' => 10 })
      end
    end

    context 'when the parsed response body does NOT contain "meta"' do
      it 'returns an empty Hash' do
        expect(response.meta).to eql({})
      end
    end

    context 'when the parsed response body does NOT contain keys' do
      let(:connection_response) { Typhoeus::Response.new(mock: true, code: 200, body: [{ id: 12, name: 'Mies' }].to_json, headers: { 'Content-Type' => 'application/json', 'Server' => 'nginx/1.4.6 (Ubuntu)' }) }

      it 'returns an empty Hash' do
        expect(response.meta).to eql({})
      end
    end
  end

end
