require 'spec_helper'

RSpec.describe RemoteResource::Querying::PersistenceMethods do

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

  describe '.create' do
    context 'when resource is persisted' do
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

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.to_return(status: 201, body: JSON.generate(response_body))
        mock_request
      end

      it 'performs the HTTP request' do
        Post.create(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true)
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource' do
        post = Post.create(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true)

        aggregate_failures do
          expect(post.persisted?).to eql true
          expect(post.id).to eql 12
          expect(post.title).to eql 'Lorem Ipsum'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql true
          expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
        end
      end

      it 'does NOT change the given attributes' do
        attributes = { title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true }

        expect { Post.create(attributes) }.not_to change { attributes }.from(attributes.dup)
      end

      it 'does NOT change the given connection_options' do
        attributes         = { title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true }
        connection_options = { headers: { 'Foo' => 'Bar' } }

        expect { Post.create(attributes, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
      end
    end

    context 'when resource is NOT persisted' do
      let(:response_body) do
        {
          errors: {
            title:             ['Please use a title which is more than 5 characters'],
            body:              ['Please fill in a body'],
            virtual_attribute: ['You already posted today', 'Please refrain from using curse words']
          }
        }
      end

      let(:resource) { Post.new(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true) }

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.to_return(status: 422, body: JSON.generate(response_body))
        mock_request
      end

      it 'returns the resource' do
        expect(Post.create(title: 'Aliquam lobortis', featured: true)).to be_a(Post)
      end

      it 'performs the HTTP request' do
        Post.create(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true)
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource' do
        post = Post.create(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true)

        aggregate_failures do
          expect(post.persisted?).to eql false
          expect(post.id).to eql nil
          expect(post.title).to eql 'Lorem Ipsum'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql true
          expect(post.created_at).to eql nil
          expect(post.errors.messages[:title]).to eql ['Please use a title which is more than 5 characters']
          expect(post.errors.messages[:body]).to eql ['Please fill in a body']
          expect(post.errors.messages[:base]).to eql ['You already posted today', 'Please refrain from using curse words']
        end
      end

      it 'does NOT change the given attributes' do
        attributes = { title: 'Aliquam lobortis', featured: true }

        expect { Post.create(attributes) }.not_to change { attributes }.from(attributes.dup)
      end

      it 'does NOT change the given connection_options' do
        attributes         = { title: 'Aliquam lobortis', featured: true }
        connection_options = { headers: { 'Foo' => 'Bar' } }

        expect { Post.create(attributes, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
      end
    end
  end

  describe '.create!' do
    context 'when resource is persisted' do
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

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.to_return(status: 201, body: JSON.generate(response_body))
        mock_request
      end

      it 'performs the HTTP request' do
        Post.create!(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true)
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource' do
        post = Post.create!(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true)

        aggregate_failures do
          expect(post.persisted?).to eql true
          expect(post.id).to eql 12
          expect(post.title).to eql 'Lorem Ipsum'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql true
          expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
        end
      end

      it 'does NOT change the given attributes' do
        attributes = { title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true }

        expect { Post.create!(attributes) }.not_to change { attributes }.from(attributes.dup)
      end

      it 'does NOT change the given connection_options' do
        attributes         = { title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true }
        connection_options = { headers: { 'Foo' => 'Bar' } }

        expect { Post.create!(attributes, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
      end
    end

    context 'when resource is NOT persisted' do
      let(:response_body) do
        {
          errors: {
            title:             ['Please use a title which is more than 5 characters'],
            body:              ['Please fill in a body'],
            virtual_attribute: ['You already posted today', 'Please refrain from using curse words']
          }
        }
      end

      let(:resource) { Post.new(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true) }

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.to_return(status: 422, body: JSON.generate(response_body))
        mock_request
      end

      it 'raise the resource invalid error' do
        expect do
          Post.create!(title: 'Aliquam lobortis', featured: true)
        end.to raise_error(RemoteResource::ResourceInvalid, /Validation failed: Title Please use a title/)
      end
    end
  end

  describe '.destroy' do
    let(:response_body) do
      {}
    end

    let!(:expected_request) do
      mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
      mock_request.to_return(status: 204, body: response_body.to_json)
      mock_request
    end

    it 'performs the HTTP request' do
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

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { Post.destroy(12, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
    end
  end

  describe '#update_attributes' do
    context 'when resource is persisted' do
      let(:response_body) do
        {
          data: {
            id:         12,
            title:      'Aliquam lobortis',
            body:       'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            featured:   true,
            created_at: Time.new(2015, 10, 4, 9, 30, 0),
          }
        }
      end

      let(:resource) { Post.new(id: 12, title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true, created_at: Time.new(2015, 10, 4, 9, 30, 0)) }

      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.to_return(status: 201, body: JSON.generate(response_body))
        mock_request
      end

      it 'returns the resource' do
        expect(resource.update_attributes(title: 'Aliquam lobortis', featured: true)).to eql resource
      end

      it 'performs the HTTP request' do
        resource.update_attributes(title: 'Aliquam lobortis', featured: true)
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource' do
        resource.update_attributes(title: 'Aliquam lobortis', featured: true)

        post = resource

        aggregate_failures do
          expect(post.persisted?).to eql true
          expect(post.id).to eql 12
          expect(post.title).to eql 'Aliquam lobortis'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql true
          expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
        end
      end

      it 'does NOT change the given attributes' do
        attributes = { title: 'Aliquam lobortis', featured: true }

        expect { resource.update_attributes(attributes) }.not_to change { attributes }.from(attributes.dup)
      end

      it 'does NOT change the given connection_options' do
        attributes         = { title: 'Aliquam lobortis', featured: true }
        connection_options = { headers: { 'Foo' => 'Bar' } }

        expect { resource.update_attributes(attributes, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
      end
    end

    context 'when resource is NOT persisted' do
      let(:response_body) do
        {
          errors: {
            title:             ['Please use a title which is more than 5 characters'],
            body:              ['Please fill in a body'],
            virtual_attribute: ['You already posted today', 'Please refrain from using curse words']
          }
        }
      end

      let(:resource) { Post.new(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: true) }

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.to_return(status: 422, body: JSON.generate(response_body))
        mock_request
      end

      it 'returns false' do
        expect(resource.update_attributes(title: 'Aliquam lobortis', featured: true)).to eql false
      end

      it 'performs the HTTP request' do
        resource.update_attributes(title: 'Aliquam lobortis', featured: true)
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource' do
        resource.update_attributes(title: 'Aliquam lobortis', featured: true)

        post = resource

        aggregate_failures do
          expect(post.persisted?).to eql false
          expect(post.id).to eql nil
          expect(post.title).to eql 'Aliquam lobortis'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql true
          expect(post.created_at).to eql nil
          expect(post.errors.messages[:title]).to eql ['Please use a title which is more than 5 characters']
          expect(post.errors.messages[:body]).to eql ['Please fill in a body']
          expect(post.errors.messages[:base]).to eql ['You already posted today', 'Please refrain from using curse words']
        end
      end

      it 'does NOT change the given attributes' do
        attributes = { title: 'Aliquam lobortis', featured: true }

        expect { resource.update_attributes(attributes) }.not_to change { attributes }.from(attributes.dup)
      end

      it 'does NOT change the given connection_options' do
        attributes         = { title: 'Aliquam lobortis', featured: true }
        connection_options = { headers: { 'Foo' => 'Bar' } }

        expect { resource.update_attributes(attributes, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
      end
    end
  end

  describe '#save' do
    context 'when resource is persisted' do
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

      let(:resource) { Post.new(id: 12, title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: false, created_at: Time.new(2015, 10, 4, 9, 30, 0)) }

      let!(:expected_request) do
        mock_request = stub_request(:patch, 'https://www.example.com/posts/12.json')
        mock_request.to_return(status: 200, body: JSON.generate(response_body))
        mock_request
      end

      it 'returns the resource' do
        expect(resource.save).to eql resource
      end

      it 'performs the HTTP request' do
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

      it 'does NOT change the given connection_options' do
        connection_options = { headers: { 'Foo' => 'Bar' } }

        expect { resource.save(connection_options) }.not_to change { connection_options }.from(connection_options.dup)
      end
    end

    context 'when resource is NOT persisted' do
      let(:response_body) do
        {
          errors: {
            title:             ['Please use a title which is more than 5 characters'],
            body:              ['Please fill in a body'],
            virtual_attribute: ['You already posted today', 'Please refrain from using curse words']
          }
        }
      end

      let(:resource) { Post.new(title: 'Lorem Ipsum', body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', featured: false) }

      let!(:expected_request) do
        mock_request = stub_request(:post, 'https://www.example.com/posts.json')
        mock_request.to_return(status: 422, body: JSON.generate(response_body))
        mock_request
      end

      it 'returns false' do
        expect(resource.save).to eql false
      end

      it 'performs the HTTP request' do
        resource.save
        expect(expected_request).to have_been_requested
      end

      it 'builds the correct resource  with validation errors' do
        resource.save

        post = resource

        aggregate_failures do
          expect(post.persisted?).to eql false
          expect(post.id).to eql nil
          expect(post.title).to eql 'Lorem Ipsum'
          expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
          expect(post.featured).to eql false
          expect(post.created_at).to eql nil
          expect(post.errors.messages[:title]).to eql ['Please use a title which is more than 5 characters']
          expect(post.errors.messages[:body]).to eql ['Please fill in a body']
          expect(post.errors.messages[:base]).to eql ['You already posted today', 'Please refrain from using curse words']
        end
      end

      it 'does NOT change the given connection_options' do
        connection_options = { headers: { 'Foo' => 'Bar' } }

        expect { resource.save(connection_options) }.not_to change { connection_options }.from(connection_options.dup)
      end
    end
  end

  describe '#destroy' do
    let(:resource) { Post.new(id: 12) }

    let(:response_body) do
      {}
    end

    let!(:expected_request) do
      mock_request = stub_request(:delete, 'https://www.example.com/posts/12.json')
      mock_request.to_return(status: 204, body: response_body.to_json)
      mock_request
    end

    it 'performs the HTTP request' do
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

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { resource.destroy(connection_options) }.not_to change { connection_options }.from(connection_options.dup)
    end

    context 'when the id is NOT present' do
      let(:resource) { Post.new }

      it 'raises the RemoteResource::IdMissingError error' do
        expect { resource.destroy }.to raise_error(RemoteResource::IdMissingError, "`id` is missing from resource")
      end
    end
  end

end
