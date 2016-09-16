require 'spec_helper'

RSpec.describe 'connection_options[:collection_prefix] and connection_options[:collection_options]' do

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

  class Comment
    include RemoteResource::Base

    self.site              = 'https://www.example.com'
    self.collection        = true
    self.collection_prefix = '/posts/:post_id'
    self.root_element      = :data

    attribute :body, String
    attribute :commented_at, Time
  end

  describe 'connection_options[:collection_prefix] defined on class' do
    let(:response_body) do
      {
        data: {
          id:           18,
          body:         'Very interesting comment',
          commented_at: Time.new(2016, 12, 8, 11, 38, 0)
        }
      }
    end

    let!(:expected_request) do
      mock_request = stub_request(:get, 'https://www.example.com/posts/12/comments/18.json')
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Comment.find(18, collection_options: { post_id: 12 })
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct resource' do
      comment = Comment.find(18, collection_options: { post_id: 12 })

      aggregate_failures do
        expect(comment.id).to eql 18
        expect(comment.body).to eql 'Very interesting comment'
        expect(comment.commented_at).to eql Time.new(2016, 12, 8, 11, 38, 0)
      end
    end
  end

  describe 'connection_options[:collection_prefix] given as argument' do
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
      mock_request = stub_request(:get, 'https://www.example.com/users/450/posts/12.json')
      mock_request.to_return(status: 200, body: response_body.to_json)
      mock_request
    end

    it 'performs the correct HTTP GET request' do
      Post.find(12, collection_prefix: '/users/:user_id', collection_options: { user_id: 450 })
      expect(expected_request).to have_been_requested
    end

    it 'builds the correct resource' do
      post = Post.find(12, collection_prefix: '/users/:user_id', collection_options: { user_id: 450 })

      aggregate_failures do
        expect(post.id).to eql 12
        expect(post.title).to eql 'Lorem Ipsum'
        expect(post.body).to eql 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
        expect(post.created_at).to eql Time.new(2015, 10, 4, 9, 30, 0)
      end
    end
  end

end
