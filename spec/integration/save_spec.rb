require 'spec_helper'

RSpec.describe '#save' do

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
        title:      'Lorem Ipsum',
        body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        featured:   false,
        created_at: Time.new(2015, 10, 4, 9, 30, 0),
      }
    }
  end

  describe 'when resource is persisted' do
    let(:resource) { Post.new(id: 12, title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: false, created_at: Time.new(2015, 10, 4, 9, 30, 0)) }

    let(:expected_request_body) do
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

    describe 'default behaviour' do
      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.with(body: expected_request_body.to_json)
        mock_request.to_return(status: 200, body: response_body.to_json)
        mock_request
      end

      xit 'performs the correct HTTP PATCH request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      xit 'builds the correct resource' do
        post = resource.save

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
        mock_request.with(body: expected_request_body.to_json)
        mock_request.with(headers: { 'X-Pseudonym' => 'pseudonym' })
        mock_request.to_return(status: 200, body: response_body.to_json)
        mock_request
      end

      xit 'performs the correct HTTP PATCH request' do
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
            id:         12,
            title:      'Lore',
            body:       '',
            featured:   true,
            created_at: Time.new(2015, 10, 4, 9, 30, 0),
          }
        }
      end

      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.with(body: expected_request_body.to_json)
        mock_request.to_return(status: 422, body: response_body.to_json)
        mock_request
      end

      before do
        resource.title    = 'Lore'
        resource.body     = ''
        resource.featured = true
      end

      xit 'performs the correct HTTP PATCH request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      xit 'builds the correct resource with validation errors' do
        post = resource.save

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
        mock_request.with(body: expected_request_body.to_json)
        mock_request.with(headers: { 'X-Pseudonym' => 'pseudonym' })
        mock_request.to_return(status: 500)
        mock_request
      end

      xit 'raises the server error' do
        expect { resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } }) }.to raise_error RemoteResource::HTTPServerError
      end

      xit 'adds metadata to the raised error' do
        begin
          resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } })
        rescue RemoteResource::HTTPServerError => error
          aggregate_failures do
            expect(error.message).to eql 'foo'
            expect(error.request_url).to eql 'https://www.example.com/posts.json'
            expect(error.response_code).to eql 500
            expect(error.request_params).to eql({})
            expect(error.request_body).to eql(expected_request_body)
            expect(error.request_headers).to eql({ 'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus', 'Accept' => 'application/json', 'X-Pseudonym' => 'pseudonym' })
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
        }
      }
    end

    describe 'default behaviour' do
      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.with(body: expected_request_body.to_json)
        mock_request.to_return(status: 201, body: response_body.to_json)
        mock_request
      end

      xit 'performs the correct HTTP POST request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      xit 'builds the correct resource' do
        post = resource.save

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
        mock_request.with(body: expected_request_body.to_json)
        mock_request.with(headers: { 'X-Pseudonym' => 'pseudonym' })
        mock_request.to_return(status: 201, body: response_body.to_json)
        mock_request
      end

      xit 'performs the correct HTTP POST request' do
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
            title:    'Lore',
            body:     '',
            featured: true
          }
        }
      end

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.with(body: expected_request_body.to_json)
        mock_request.to_return(status: 422, body: response_body.to_json)
        mock_request
      end

      before do
        resource.title    = 'Lore'
        resource.body     = ''
        resource.featured = true
      end

      xit 'performs the correct HTTP POST request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      xit 'builds the correct resource with validation errors' do
        post = resource.save

        aggregate_failures do
          expect(post.persisted?).to eql false
          expect(post.id).to be_nil
          expect(post.title).to eql 'Lore'
          expect(post.body).to eql ''
          expect(post.featured).to eql true
          expect(post.created_at).to be_blank
          expect(post.errors.messages[:title]).to eql ['Please use a title which is more than 5 characters']
          expect(post.errors.messages[:body]).to eql ['Please fill in a body']
        end
      end
    end

    describe 'with a 500 response' do
      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.with(body: expected_request_body.to_json)
        mock_request.with(headers: { 'X-Pseudonym' => 'pseudonym' })
        mock_request.to_return(status: 500)
        mock_request
      end

      xit 'raises the server error' do
        expect { resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } }) }.to raise_error RemoteResource::HTTPServerError
      end

      xit 'adds metadata to the raised error' do
        begin
          resource.save({ headers: { 'X-Pseudonym' => 'pseudonym' } })
        rescue RemoteResource::HTTPServerError => error
          aggregate_failures do
            expect(error.message).to eql 'foo'
            expect(error.request_url).to eql 'https://www.example.com/posts.json'
            expect(error.response_code).to eql 500
            expect(error.request_params).to eql({})
            expect(error.request_body).to eql(expected_request_body)
            expect(error.request_headers).to eql({ 'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus', 'Accept' => 'application/json', 'X-Pseudonym' => 'pseudonym' })
          end
        end
      end
    end
  end

end
