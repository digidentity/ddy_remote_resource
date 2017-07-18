require 'spec_helper'

RSpec.describe 'connection_options for naming' do

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

  describe 'connection_options[:site]' do
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

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://api.example.com/posts/12.json')
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find(12, { site: 'https://api.example.com' })
      Post.find(12, { site: 'https://api.example.com/' })
      expect(expected_request).to have_been_requested.times(2)
    end
  end

  describe 'connection_options[:version]' do
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

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/api/v2/posts/12.json')
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find(12, { version: '/api/v2' })
      Post.find(12, { version: 'api/v2' })
      Post.find(12, { version: '/api/v2/' })
      expect(expected_request).to have_been_requested.times(3)
    end
  end

  describe 'connection_options[:version] and connection_options[:path_prefix]' do
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

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/api/v2/archive/posts/12.json')
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find(12, { version: '/api/v2', path_prefix: '/archive' })
      Post.find(12, { version: 'api/v2', path_prefix: 'archive' })
      Post.find(12, { version: '/api/v2/', path_prefix: '/archive/' })
      expect(expected_request).to have_been_requested.times(3)
    end
  end

  describe 'connection_options[:path_postfix]' do
    let(:response_body_singular) do
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

    let(:response_body_collection) do
      {
        data: [
                {
                  id:         12,
                  title:      'Aliquam lobortis',
                  body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                  featured:   false,
                  created_at: Time.new(2015, 10, 4, 9, 30, 0),
                }
              ]
      }
    end

    let!(:expected_request_singular) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12/featured.json')
      mock_request.to_return(status: 200, body: response_body_singular.to_json)
      mock_request
    end

    let!(:expected_request_collection) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/featured.json')
      mock_request.to_return(status: 200, body: response_body_collection.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request for a singular resource' do
      Post.find(12, { path_postfix: '/featured' })
      Post.find(12, { path_postfix: 'featured' })
      Post.find(12, { path_postfix: '/featured/' })
      expect(expected_request_singular).to have_been_requested.times(3)
    end

    it 'performs the correct HTTP GET request for a collection resource' do
      Post.all({ path_postfix: '/featured' })
      Post.all({ path_postfix: 'featured' })
      Post.all({ path_postfix: '/featured/' })
      expect(expected_request_collection).to have_been_requested.times(3)
    end
  end

end
