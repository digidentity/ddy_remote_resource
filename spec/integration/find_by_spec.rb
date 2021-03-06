require 'spec_helper'

RSpec.describe '.find_by' do

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

  let(:response_body) do
    {
      data: {
        id:         12,
        title:      'Lorem Ipsum',
        body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        featured:   true,
        created_at: Time.new(2015, 10, 4, 9, 30, 0),
      }
    }
  end

  let(:expected_default_headers) do
    { 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}" }
  end

  describe 'default behaviour' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/current.json')
      mock_request.with(query: { title: 'Lorem Ipsum', featured: true }, body: nil, headers: expected_default_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find_by({ title: 'Lorem Ipsum', featured: true }, path_postfix: '/current')
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct resource' do
      post = Post.find_by({ title: 'Lorem Ipsum', featured: true }, path_postfix: '/current')

      aggregate_failures do
        expect(post.id).to eql 12
        expect(post.title).to eql 'Lorem Ipsum'
        expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
        expect(post.featured).to eql true
        expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
      end
    end
  end

  describe 'with params[:id]' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(query: { title: 'Lorem Ipsum', featured: true }, body: nil, headers: expected_default_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find_by({ id: 12, title: 'Lorem Ipsum', featured: true })
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct resource' do
      post = Post.find_by({ id: 12, title: 'Lorem Ipsum', featured: true })

      aggregate_failures do
        expect(post.id).to eql 12
        expect(post.title).to eql 'Lorem Ipsum'
        expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
        expect(post.featured).to eql true
        expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
      end
    end
  end

  describe 'with connection_options[:params]' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/current.json')
      mock_request.with(query: { title: 'Lorem Ipsum', featured: true, pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find_by({ title: 'Lorem Ipsum', featured: true }, params: { pseudonym: 'pseudonym' }, path_postfix: '/current')
      expect(expected_request).to have_been_requested
    end
  end

  describe 'with connection_options[:headers]' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/current.json')
      mock_request.with(query: { title: 'Lorem Ipsum', featured: true }, body: nil, headers: { 'X-Pseudonym' => 'pseudonym' })
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find_by({ title: 'Lorem Ipsum', featured: true }, headers: { 'X-Pseudonym' => 'pseudonym' }, path_postfix: '/current')
      expect(expected_request).to have_been_requested
    end
  end

  describe 'with a 404 response' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/current.json')
      mock_request.with(query: { featured: false, pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 404)
      mock_request
    end

    it 'raises the not found error' do
      expect { Post.find_by({ featured: false }, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }, path_postfix: '/current') }.to raise_error RemoteResource::HTTPNotFound
    end

    it 'adds metadata to the raised error' do
      begin
        Post.find_by({ featured: false }, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }, path_postfix: '/current')
      rescue RemoteResource::HTTPNotFound => error
        aggregate_failures do
          expect(error.message).to eql 'HTTP request failed for Post with response_code=404 with http_action=get with request_url=https://www.example.com/posts/current.json'
          expect(error.request_url).to eql 'https://www.example.com/posts/current.json'
          expect(error.response_code).to eql 404
          expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym', featured: false }))
          expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        end
      end
    end
  end

  describe 'with a 500 response' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/current.json')
      mock_request.with(query: { featured: false, pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 500)
      mock_request
    end

    it 'raises the server error' do
      expect { Post.find_by({ featured: false }, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }, path_postfix: '/current') }.to raise_error RemoteResource::HTTPServerError
    end

    it 'adds metadata to the raised error' do
      begin
        Post.find_by({ featured: false }, params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }, path_postfix: '/current')
      rescue RemoteResource::HTTPServerError => error
        aggregate_failures do
          expect(error.message).to eql 'HTTP request failed for Post with response_code=500 with http_action=get with request_url=https://www.example.com/posts/current.json'
          expect(error.request_url).to eql 'https://www.example.com/posts/current.json'
          expect(error.response_code).to eql 500
          expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym', featured: false }))
          expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        end
      end
    end
  end

end
