require 'spec_helper'

RSpec.describe '#update_attributes' do

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

  let(:resource) { Post.new(id: 12, title: 'Aliquam lobortis', featured: false, created_at: Time.new(2015, 10, 4, 9, 30, 0)) }

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

  let(:expected_default_headers) do
    { 'Content-Type' => 'application/json', 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}" }
  end

  describe 'default behaviour' do
    let(:expected_request_body) do
      {
        data: {
          title:    'Aliquam lobortis',
          featured: false
        }
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
      mock_request.with(body: JSON.generate(expected_request_body), headers: expected_default_headers)
      mock_request.to_return(status: 201, body: JSON.generate(response_body))
      mock_request
    end

    it 'performs the correct HTTP PATCH request' do
      resource.update_attributes(title: 'Aliquam lobortis', featured: false)
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct resource' do
      resource.update_attributes(title: 'Aliquam lobortis', featured: false)

      post = resource

      aggregate_failures do
        expect(post.persisted?).to eql true
        expect(post.id).to eql 12
        expect(post.title).to eql 'Aliquam lobortis'
        expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
        expect(post.featured).to eql false
        expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
      end
    end
  end

  describe 'with connection_options[:headers]' do
    let(:expected_request_body) do
      {
        data: {
          title:    'Aliquam lobortis',
          featured: false
        }
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
      mock_request.with(body: JSON.generate(expected_request_body), headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 201, body: JSON.generate(response_body))
      mock_request
    end

    it 'performs the correct HTTP PATCH request' do
      resource.update_attributes({ title: 'Aliquam lobortis', featured: false }, { headers: { 'X-Pseudonym' => 'pseudonym' } })
      expect(expected_request).to have_been_requested
    end
  end

  describe 'with a 404 response' do
    let(:expected_request_body) do
      {
        data: {
          title:    'Aliquam lobortis',
          featured: false
        }
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
      mock_request.with(body: JSON.generate(expected_request_body), headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 404)
      mock_request
    end

    it 'raises the not found error' do
      expect { resource.update_attributes({ title: 'Aliquam lobortis', featured: false }, { headers: { 'X-Pseudonym' => 'pseudonym' } }) }.to raise_error RemoteResource::HTTPNotFound
    end

    xit 'adds metadata to the raised error' do
      begin
        resource.update_attributes({ title: 'Aliquam lobortis', featured: false }, { headers: { 'X-Pseudonym' => 'pseudonym' } })
      rescue RemoteResource::HTTPNotFound => error
        aggregate_failures do
          expect(error.message).to eql 'RemoteResource HTTP request failed, with status 404'
          expect(error.request_url).to eql 'https://www.example.com/posts/12.json'
          expect(error.response_code).to eql 404
          expect(error.request_params).to eql({ pseudonym: 'pseudonym' })
          expect(error.request_headers).to eql({ 'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus', 'Accept' => 'application/json', 'X-Pseudonym' => 'pseudonym' })
        end
      end
    end
  end

  describe 'with a 422 response' do
    let(:response_body) do
      {
        errors: {
          title:             ['Please use a title which is more than 5 characters'],
          body:              ['Please fill in a body'],
          virtual_attribute: ['You already posted today', 'Please refrain from using curse words']
        }
      }
    end

    let(:expected_request_body) do
      {
        data: {
          title:    'Lore',
          body:     '',
          featured: false
        }
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
      mock_request.with(body: JSON.generate(expected_request_body), headers: expected_default_headers)
      mock_request.to_return(status: 422, body: JSON.generate(response_body))
      mock_request
    end

    it 'performs the correct HTTP PATCH request' do
      resource.update_attributes(title: 'Lore', body: '', featured: false)
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct resource with validation errors' do
      resource.update_attributes(title: 'Lore', body: '', featured: false)

      post = resource

      aggregate_failures do
        expect(post.persisted?).to eql true
        expect(post.id).to eql 12
        expect(post.title).to eql 'Lore'
        expect(post.body).to eql ''
        expect(post.featured).to eql false
        expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
        expect(post.errors.messages[:title]).to eql ['Please use a title which is more than 5 characters']
        expect(post.errors.messages[:body]).to eql ['Please fill in a body']
        expect(post.errors.messages[:base]).to eql ['You already posted today', 'Please refrain from using curse words']
      end
    end
  end

  describe 'with a 500 response' do
    let(:expected_request_body) do
      {
        data: {
          title:    'Aliquam lobortis',
          featured: false
        }
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
      mock_request.with(body: JSON.generate(expected_request_body), headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
      mock_request.to_return(status: 500)
      mock_request
    end

    it 'raises the server error' do
      expect { resource.update_attributes({ title: 'Aliquam lobortis', featured: false }, { headers: { 'X-Pseudonym' => 'pseudonym' } }) }.to raise_error RemoteResource::HTTPServerError
    end

    xit 'adds metadata to the raised error' do
      begin
        resource.update_attributes({ title: 'Aliquam lobortis', featured: false }, { headers: { 'X-Pseudonym' => 'pseudonym' } })
      rescue RemoteResource::HTTPServerError => error
        aggregate_failures do
          expect(error.message).to eql 'foo'
          expect(error.request_url).to eql 'https://www.example.com/posts/12.json'
          expect(error.response_code).to eql 500
          expect(error.request_params).to eql({})
          expect(error.request_body).to eql(expected_request_body)
          expect(error.request_headers).to eql({ 'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus', 'Accept' => 'application/json', 'X-Pseudonym' => 'pseudonym' })
        end
      end
    end
  end

end
