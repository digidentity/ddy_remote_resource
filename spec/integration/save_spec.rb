require 'spec_helper'

RSpec.describe '#save' do

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
        featured:   false,
        created_at: Time.new(2015, 10, 4, 9, 30, 0),
      }
    }
  end

  let(:expected_default_headers) do
    { 'Content-Type' => 'application/json', 'Accept' => 'application/json', 'User-Agent' => "RemoteResource #{RemoteResource::VERSION}" }
  end

  describe 'when resource is persisted' do
    let(:resource) { Post.new(id: 12, title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: false, created_at: Time.new(2015, 10, 4, 9, 30, 0)) }

    let(:expected_request_body) do
      {
        data: {
          title:      'Lorem Ipsum',
          body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          featured:   false,
          created_at: Time.new(2015, 10, 4, 9, 30, 0),
        }
      }
    end

    describe 'default behaviour' do
      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: expected_request_body.to_json, headers: expected_default_headers)
        mock_request.to_return(status: 200, body: JSON.generate(response_body))
        mock_request
      end

      it 'performs the correct HTTP PATCH request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource' do
        resource.save

        post = resource

        aggregate_failures do
          expect(post.persisted?).to eql true
          expect(post.id).to eql 12
          expect(post.title).to eql 'Lorem Ipsum'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql false
          expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
        end
      end
    end

    describe 'with connection_options[:headers]' do
      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: expected_request_body.to_json, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 200, body: JSON.generate(response_body))
        mock_request
      end

      it 'performs the correct HTTP PATCH request' do
        resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } })
        expect(expected_request).to have_been_requested
      end
    end

    describe 'with a 422 response' do
      let(:response_body) do
        {
          errors: {
            title: ['Please use a title which is more than 5 characters'],
            body:  ['Please fill in a body']
          }
        }
      end

      let(:expected_request_body) do
        {
          data: {
            title:      'Lore',
            body:       '',
            featured:   true,
            created_at: Time.new(2015, 10, 4, 9, 30, 0),
          }
        }
      end

      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: expected_request_body.to_json, headers: expected_default_headers)
        mock_request.to_return(status: 422, body: JSON.generate(response_body))
        mock_request
      end

      before do
        resource.title    = 'Lore'
        resource.body     = ''
        resource.featured = true
      end

      it 'performs the correct HTTP PATCH request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource with validation errors' do
        resource.save

        post = resource

        aggregate_failures do
          expect(post.persisted?).to eql true
          expect(post.id).to eql 12
          expect(post.title).to eql 'Lore'
          expect(post.body).to eql ''
          expect(post.featured).to eql true
          expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
          expect(post.errors.messages[:title]).to eql ['Please use a title which is more than 5 characters']
          expect(post.errors.messages[:body]).to eql ['Please fill in a body']
        end
      end
    end

    describe 'with a 500 response' do
      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.with(query: nil, body: expected_request_body.to_json, headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 500)
        mock_request
      end

      it 'raises the server error' do
        expect { resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } }) }.to raise_error RemoteResource::HTTPServerError
      end

      it 'adds metadata to the raised error' do
        begin
          resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } })
        rescue RemoteResource::HTTPServerError => error
          aggregate_failures do
            expect(error.message).to eql 'HTTP request failed for Post with response_code=500 with http_action=patch with request_url=https://www.example.com/posts/12.json'
            expect(error.request_url).to eql 'https://www.example.com/posts/12.json'
            expect(error.response_code).to eql 500
            expect(error.request_query).to be_nil
            expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
          end
        end
      end
    end
  end

  describe 'when resource is NOT persisted' do
    let(:resource) { Post.new(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: false) }

    let(:expected_request_body) do
      {
        data: {
          title:      'Lorem Ipsum',
          body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          featured:   false,
          created_at: nil,
        }
      }
    end

    describe 'default behaviour' do
      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.with(query: nil, body: JSON.generate(expected_request_body), headers: expected_default_headers)
        mock_request.to_return(status: 201, body: JSON.generate(response_body))
        mock_request
      end

      it 'performs the correct HTTP POST request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource' do
        resource.save

        post = resource

        aggregate_failures do
          expect(post.persisted?).to eql true
          expect(post.id).to eql 12
          expect(post.title).to eql 'Lorem Ipsum'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql false
          expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
        end
      end
    end

    describe 'with connection_options[:headers]' do
      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.with(query: nil, body: JSON.generate(expected_request_body), headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 201, body: JSON.generate(response_body))
        mock_request
      end

      it 'performs the correct HTTP POST request' do
        resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } })
        expect(expected_request).to have_been_requested
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
            title:      'Lore',
            body:       '',
            featured:   true,
            created_at: nil
          }
        }
      end

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.with(query: nil, body: JSON.generate(expected_request_body), headers: expected_default_headers)
        mock_request.to_return(status: 422, body: JSON.generate(response_body))
        mock_request
      end

      before do
        resource.title    = 'Lore'
        resource.body     = ''
        resource.featured = true
      end

      it 'performs the correct HTTP POST request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource with validation errors' do
        resource.save

        post = resource

        aggregate_failures do
          expect(post.persisted?).to eql false
          expect(post.id).to be_nil
          expect(post.title).to eql 'Lore'
          expect(post.body).to eql ''
          expect(post.featured).to eql true
          expect(post.created_at).to be_blank
          expect(post.errors.messages[:title]).to eql ['Please use a title which is more than 5 characters']
          expect(post.errors.messages[:body]).to eql ['Please fill in a body']
          expect(post.errors.messages[:base]).to eql ['You already posted today', 'Please refrain from using curse words']
        end
      end
    end

    describe 'with a 500 response' do
      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.with(query: nil, body: JSON.generate(expected_request_body), headers: expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
        mock_request.to_return(status: 500)
        mock_request
      end

      it 'raises the server error' do
        expect { resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } }) }.to raise_error RemoteResource::HTTPServerError
      end

      it 'adds metadata to the raised error' do
        begin
          resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } })
        rescue RemoteResource::HTTPServerError => error
          aggregate_failures do
            expect(error.message).to eql 'HTTP request failed for Post with response_code=500 with http_action=post with request_url=https://www.example.com/posts.json'
            expect(error.request_url).to eql 'https://www.example.com/posts.json'
            expect(error.response_code).to eql 500
            expect(error.request_query).to be_nil
            expect(error.request_headers).to eql(expected_default_headers.merge({ 'X-Pseudonym' => 'pseudonym' }))
          end
        end
      end
    end
  end

end
