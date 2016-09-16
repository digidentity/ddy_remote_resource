require 'spec_helper'

RSpec.describe RemoteResource::Querying::FinderMethods do

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

  describe '.find' do
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
      mock_request = stub_request(:get, 'https://www.example.com/posts/12.json')
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the HTTP request' do
      Post.find(12)
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct resource' do
      post = Post.find(12)

      aggregate_failures do
        expect(post.id).to eql 12
        expect(post.title).to eql 'Lorem Ipsum'
        expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
        expect(post.featured).to eql true
        expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
      end
    end

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { Post.find(12, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
    end

    xcontext 'return value #success? and NOT #success?' do
    end
  end

  describe '.find_by' do
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
      mock_request = stub_request(:get, 'https://www.example.com/posts/current.json')
      mock_request.with(query: { title: 'Lorem Ipsum', featured: true })
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the HTTP request' do
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

    it 'does NOT change the given params' do
      params = { title: 'Lorem Ipsum', featured: true }

      expect { Post.find_by(params, path_postfix: '/current') }.not_to change { params }.from(params.dup)
    end

    it 'does NOT change the given connection_options' do
      params             = { title: 'Lorem Ipsum', featured: true }
      connection_options = { path_postfix: '/current', headers: { 'Foo' => 'Bar' } }

      expect { Post.find_by(params, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
    end

    xcontext 'return value #success? and NOT #success?' do
    end
  end

  describe '.all' do
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

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts.json')
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the HTTP request' do
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

    it 'does NOT change the given connection_options' do
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { Post.all(connection_options) }.not_to change { connection_options }.from(connection_options.dup)
    end

    xcontext 'return value #success? and NOT #success?' do
    end
  end

  describe '.where' do
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

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts.json')
      mock_request.with(query: { pseudonym: 'pseudonym' })
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the HTTP request' do
      Post.where({ pseudonym: 'pseudonym' })
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct collection of resources' do
      posts = Post.where({ pseudonym: 'pseudonym' })

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

    it 'does NOT change the given params' do
      params = { pseudonym: 'pseudonym' }

      expect { Post.where(params) }.not_to change { params }.from(params.dup)
    end

    it 'does NOT change the given connection_options' do
      params             = { pseudonym: 'pseudonym' }
      connection_options = { headers: { 'Foo' => 'Bar' } }

      expect { Post.where(params, connection_options) }.not_to change { connection_options }.from(connection_options.dup)
    end

    xcontext 'return value #success? and NOT #success?' do
    end
  end

end
