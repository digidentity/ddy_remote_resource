require 'spec_helper'

RSpec.describe 'headers in connection_options' do

  after(:all) { remove_const(:Post) }

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
        title:      'Aliquam lobortis',
        body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        featured:   false,
        created_at: Time.new(2015, 10, 4, 9, 30, 0),
      }
    }
  end

  describe 'default behaviour' do
    let(:expected_headers) do
      {
        'Accept'     => 'application/json',
        'User-Agent' => "RemoteResource #{RemoteResource::VERSION}"
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request with the default headers' do
      Post.find(12)
      expect(expected_request).to have_been_requested
    end
  end

  describe 'connection_options[:headers]' do
    let(:expected_headers) do
      {
        'Accept'     => 'application/json',
        'User-Agent' => "RemoteResource #{RemoteResource::VERSION}",
        'X-Locale'   => 'From connection_options[:headers]'
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request with the default headers and connection_options[:headers]' do
      Post.find(12, { headers: { 'X-Locale' => 'From connection_options[:headers]' } })
      expect(expected_request).to have_been_requested
    end
  end

  describe 'connection_options[:default_headers]' do
    let(:expected_headers) do
      {
        'User-Agent' => 'From connection_options[:default_headers]',
        'X-Locale' => 'From connection_options[:headers]'
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request overriding the default headers with the connection_options[:default_headers]' do
      Post.find(12, { headers: { 'X-Locale' => 'From connection_options[:headers]' }, default_headers: { 'User-Agent' => 'From connection_options[:default_headers]' } })
      expect(expected_request).to have_been_requested
    end
  end

  describe '.default_headers' do
    let(:expected_headers) do
      {
        'User-Agent' => 'From .default_headers',
        'X-Locale' => 'From connection_options[:headers]'
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    before { Post.default_headers = { 'User-Agent' => 'From .default_headers' } }
    after { Post.default_headers = {} }

    it 'performs the correct HTTP GET request overriding the default headers with the .default_headers headers' do
      Post.find(12, { headers: { 'X-Locale' => 'From connection_options[:headers]' } })
      expect(expected_request).to have_been_requested
    end
  end

  describe 'connection_options[:default_headers] and .default_headers' do
    let(:expected_headers) do
      {
        'User-Agent' => 'From connection_options[:default_headers]',
        'X-Locale' => 'From connection_options[:headers]'
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    before { Post.default_headers = { 'User-Agent' => 'From .default_headers' } }
    after { Post.default_headers = {} }

    it 'performs the correct HTTP GET request overriding the default headers with the connection_options[:default_headers]' do
      Post.find(12, { headers: { 'X-Locale' => 'From connection_options[:headers]' }, default_headers: { 'User-Agent' => 'From connection_options[:default_headers]' } })
      expect(expected_request).to have_been_requested
    end
  end

  describe 'RemoteResource::Base.global_headers' do
    let(:expected_headers) do
      {
        'Accept'        => 'application/json',
        'User-Agent'    => 'From RemoteResource::Base.global_headers',
        'Authorization' => 'From RemoteResource::Base.global_headers',
        'X-Locale'      => 'From connection_options[:headers]',
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    before { RemoteResource::Base.global_headers = { 'User-Agent' => 'From RemoteResource::Base.global_headers', 'X-Locale' => 'From RemoteResource::Base.global_headers', 'Authorization' => 'From RemoteResource::Base.global_headers' } }
    after { RemoteResource::Base.global_headers = nil }

    it 'performs the correct HTTP GET request with the default headers and the .global_headers headers' do
      Post.find(12, { headers: { 'X-Locale' => 'From connection_options[:headers]' } })
      expect(expected_request).to have_been_requested
    end
  end

  describe '.with_connection_options' do
    let(:expected_headers) do
      {
        'Accept'        => 'application/json',
        'User-Agent'    => 'From .with_connection_options',
        'Authorization' => 'From .with_connection_options',
        'X-Locale'      => 'From connection_options[:headers]',
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request with the default headers and the .with_connection_options headers' do
      Post.with_connection_options({ headers: { 'User-Agent' => 'From .with_connection_options', 'X-Locale' => 'From .with_connection_options', 'Authorization' => 'From .with_connection_options' } }) do
        Post.find(12, { headers: { 'X-Locale' => 'From connection_options[:headers]' } })
      end
      expect(expected_request).to have_been_requested
    end
  end

  describe 'RemoteResource::Base.global_headers and .with_connection_options' do
    let(:expected_headers) do
      {
        'Accept'        => 'application/json',
        'User-Agent'    => 'From RemoteResource::Base.global_headers',
        'Authorization' => 'From .with_connection_options',
        'X-Locale'      => 'From connection_options[:headers]',
        'X-Country'     => 'From connection_options[:headers]',
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.with(headers: expected_headers)
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    before { RemoteResource::Base.global_headers = { 'User-Agent' => 'From RemoteResource::Base.global_headers', 'X-Locale' => 'From RemoteResource::Base.global_headers', 'Authorization' => 'From RemoteResource::Base.global_headers' } }
    after { RemoteResource::Base.global_headers = nil }

    it 'performs the correct HTTP GET request with the default headers and the .global_headers headers and the and .with_connection_options headers' do
      Post.with_connection_options({ headers: { 'Authorization' => 'From .with_connection_options' } }) do
        Post.find(12, { headers: { 'X-Locale' => 'From connection_options[:headers]', 'X-Country' => 'From connection_options[:headers]' } })
      end
      expect(expected_request).to have_been_requested
    end
  end

end
