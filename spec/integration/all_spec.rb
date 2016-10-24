require 'spec_helper'

RSpec.describe '.all' do

  class Post
    include RemoteResource::Base

    self.site         = 'https://www.example.com'
    self.collection   = true
    self.root_element = :data

    attribute :title, String
    attribute :body, String
    attribute :created_at, Time
  end

  let(:response_body) do
    {
      data: [
              {
                id:         12,
                title:      'Lorem Ipsum',
                body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                created_at: Time.new(2015, 10, 4, 9, 30, 0),
              },
              {
                id:         14,
                title:      'Mauris Purus',
                body:       'Mauris purus urna, ultrices et suscipit ut, faucibus eget mauris.',
                created_at: Time.new(2015, 12, 11, 11, 32, 0),
              },
              {
                id:         16,
                title:      'Vestibulum Commodo',
                body:       'Vestibulum commodo fringilla suscipit.',
                created_at: Time.new(2016, 2, 6, 18, 45, 0),
              },
            ]
    }
  end

  let(:expected_default_headers) do
    { 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}" }
  end

  describe 'default behaviour' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts.json')
      mock_request.with(query: nil, body: nil, headers: expected_default_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.all
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct collection of resources' do
      posts = Post.all

      aggregate_failures do
        expect(posts).to respond_to :each
        expect(posts).to all(be_a(Post))
        expect(posts.size).to eql 3

        expect(posts[0].id).to eql 12
        expect(posts[0].title).to eql 'Lorem Ipsum'
        expect(posts[0].body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
        expect(posts[0].created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
        expect(posts[1].id).to eql 14
        expect(posts[1].title).to eql 'Mauris Purus'
        expect(posts[1].body).to eql 'Mauris purus urna, ultrices et suscipit ut, faucibus eget mauris.'
        expect(posts[1].created_at).to eql Time.new(2015, 12, 11, 11, 32, 0)
        expect(posts[2].id).to eql 16
        expect(posts[2].title).to eql 'Vestibulum Commodo'
        expect(posts[2].body).to eql 'Vestibulum commodo fringilla suscipit.'
        expect(posts[2].created_at).to eql Time.new(2016, 2, 6, 18, 45, 0)
      end
    end
  end

  describe 'with connection_options[:params]' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts.json')
      mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.all(params: { pseudonym: 'pseudonym' })
      expect(expected_request).to have_been_requested
    end
  end

  describe 'with connection_options[:headers]' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts.json')
      mock_request.with(query: nil, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.all(headers: { 'X-Pseudonym' => 'pseudonym' })
      expect(expected_request).to have_been_requested
    end
  end

  describe 'with a 404 response' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts.json')
      mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 404)
      mock_request
    end

    it 'raises the not found error' do
      expect { Post.all(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }) }.to raise_error RemoteResource::HTTPNotFound
    end

    it 'adds metadata to the raised error' do
      begin
        Post.all(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' })
      rescue RemoteResource::HTTPNotFound => error
        aggregate_failures do
          expect(error.message).to eql 'HTTP request failed for Post with response_code=404 with http_action=get with request_url=https://www.example.com/posts.json'
          expect(error.request_url).to eql 'https://www.example.com/posts.json'
          expect(error.response_code).to eql 404
          expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }))
          expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        end
      end
    end
  end

  describe 'with a 500 response' do
    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts.json')
      mock_request.with(query: { pseudonym: 'pseudonym' }, body: nil, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 500)
      mock_request
    end

    it 'raises the server error' do
      expect { Post.all(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' }) }.to raise_error RemoteResource::HTTPServerError
    end

    it 'adds metadata to the raised error' do
      begin
        Post.all(params: { pseudonym: 'pseudonym' }, headers: { 'X-Pseudonym' => 'pseudonym' })
      rescue RemoteResource::HTTPServerError => error
        aggregate_failures do
          expect(error.message).to eql 'HTTP request failed for Post with response_code=500 with http_action=get with request_url=https://www.example.com/posts.json'
          expect(error.request_url).to eql 'https://www.example.com/posts.json'
          expect(error.response_code).to eql 500
          expect(error.request_query).to eql(RemoteResource::Util.encode_params_to_query({ pseudonym: 'pseudonym' }))
          expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        end
      end
    end
  end


end
