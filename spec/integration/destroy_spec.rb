require 'spec_helper'

RSpec.describe '.destroy and #destroy' do

  class Post
    include RemoteResource::Base

    self.site         = 'https://www.example.com'
    self.collection   = true
    self.root_element = :data

    attribute :title, String
    attribute :body, String
    attribute :featured, Boolean
    attribute :created_at, Time
  end

  describe '.destroy' do
    let(:response_body) do
      {}
    end

    let(:expected_default_headers) do
      { 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}" }
    end

    describe 'default behaviour' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: nil, headers: expected_default_headers)
        mock_request.to_return(status: 204, body: response_body.to_json)
        mock_request
      end

      it 'performs the correct HTTP DELETE request' do
        Post.destroy(12)
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct non-persistent resource' do
        post = Post.destroy(12)

        aggregate_failures do
          expect(post.id).to eql 12
          expect(post.persisted?).to eql false
        end
      end
    end

    describe 'with connection_options[:params]' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers)
        mock_request.to_return(status: 204, body: response_body.to_json)
        mock_request
      end

      it 'performs the correct HTTP DELETE request' do
        Post.destroy(12, params: { pseudonym: 'pseudonym' })
        expect(expected_request).to have_been_requested
      end
    end

    describe 'with connection_options[:headers]' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 204, body: response_body.to_json)
        mock_request
      end

      it 'performs the correct HTTP DELETE request' do
        Post.destroy(12, headers: { 'X-Pseudonym' => 'pseudonym' })
        expect(expected_request).to have_been_requested
      end
    end

    describe 'with a 404 response' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 404)
        mock_request
      end

      it 'raises the not found error' do
        expect { Post.destroy(12, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }) }.to raise_error RemoteResource::HTTPNotFound
      end

      it 'adds metadata to the raised error' do
        begin
          Post.destroy(12, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' })
        rescue RemoteResource::HTTPNotFound => error
          aggregate_failures do
            expect(error.message).to eql 'HTTP request failed for Post with response_code=404 with http_action=delete with request_url=https://www.example.com/posts/12.json'
            expect(error.request_url).to eql 'https://www.example.com/posts/12.json'
            expect(error.response_code).to eql 404
            expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }))
            expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
          end
        end
      end
    end

    describe 'with a 500 response' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 500)
        mock_request
      end

      it 'raises the server error' do
        expect { Post.destroy(12, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }) }.to raise_error RemoteResource::HTTPServerError
      end

      it 'adds metadata to the raised error' do
        begin
          Post.destroy(12, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' })
        rescue RemoteResource::HTTPServerError => error
          aggregate_failures do
            expect(error.message).to eql 'HTTP request failed for Post with response_code=500 with http_action=delete with request_url=https://www.example.com/posts/12.json'
            expect(error.request_url).to eql 'https://www.example.com/posts/12.json'
            expect(error.response_code).to eql 500
            expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }))
            expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
          end
        end
      end
    end
  end

  describe '#destroy' do
    let(:resource) { Post.new(id: 12) }

    let(:response_body) do
      {}
    end

    let(:expected_default_headers) do
      { 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}" }
    end

    describe 'default behaviour' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: nil, headers: expected_default_headers)
        mock_request.to_return(status: 204, body: response_body.to_json)
        mock_request
      end

      it 'performs the correct HTTP DELETE request' do
        resource.destroy
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct non-persistent resource' do
        resource.destroy

        post = resource

        aggregate_failures do
          expect(post.id).to eql 12
          expect(post.persisted?).to eql false
        end
      end
    end

    describe 'with connection_options[:params]' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers)
        mock_request.to_return(status: 204, body: response_body.to_json)
        mock_request
      end

      it 'performs the correct HTTP DELETE request' do
        resource.destroy(params: { pseudonym: 'pseudonym' })
        expect(expected_request).to have_been_requested
      end
    end

    describe 'with connection_options[:body]' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(body: { pseudonym: 'pseudonym' }.to_json, headers: expected_default_headers.merge('Content-Type' => 'application/json'))
        mock_request.to_return(status: 204, body: response_body.to_json)
        mock_request
      end

      it 'performs the correct HTTP DELETE request' do
        resource.destroy(body: { pseudonym: 'pseudonym' })
        expect(expected_request).to have_been_requested
      end
    end

    describe 'with connection_options[:headers]' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 204, body: response_body.to_json)
        mock_request
      end

      it 'performs the correct HTTP DELETE request' do
        resource.destroy(headers: { 'X-Pseudonym' => 'pseudonym' })
        expect(expected_request).to have_been_requested
      end
    end

    describe 'with a 404 response' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 404)
        mock_request
      end

      it 'raises the not found error' do
        expect { resource.destroy(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }) }.to raise_error RemoteResource::HTTPNotFound
      end

      it 'adds metadata to the raised error' do
        begin
          resource.destroy(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' })
        rescue RemoteResource::HTTPNotFound => error
          aggregate_failures do
            expect(error.message).to eql 'HTTP request failed for Post with response_code=404 with http_action=delete with request_url=https://www.example.com/posts/12.json'
            expect(error.request_url).to eql 'https://www.example.com/posts/12.json'
            expect(error.response_code).to eql 404
            expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }))
            expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
          end
        end
      end
    end

    describe 'with a 500 response' do
      let!(:expected_request) do
        mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
        mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 500)
        mock_request
      end

      it 'raises the server error' do
        expect { resource.destroy(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }) }.to raise_error RemoteResource::HTTPServerError
      end

      it 'adds metadata to the raised error' do
        begin
          resource.destroy(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' })
        rescue RemoteResource::HTTPServerError => error
          aggregate_failures do
            expect(error.message).to eql 'HTTP request failed for Post with response_code=500 with http_action=delete with request_url=https://www.example.com/posts/12.json'
            expect(error.request_url).to eql 'https://www.example.com/posts/12.json'
            expect(error.response_code).to eql 500
            expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }))
            expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
          end
        end
      end
    end
  end

end
