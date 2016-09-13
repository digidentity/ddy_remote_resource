module RemoteResource
  class Request
    include RemoteResource::HTTPErrors

    DEFAULT_HEADERS = {
      'Accept'     => 'application/json',
      'User-Agent' => "RemoteResource #{RemoteResource::VERSION}"
    }.freeze

    DEFAULT_CONTENT_TYPE = {
      'Content-Type' => 'application/json'
    }.freeze

    DEFAULT_EXTENSION = '.json'.freeze

    attr_reader :resource, :resource_klass, :rest_action, :attributes

    def initialize(resource, rest_action, attributes = {}, connection_options = {})
      @resource                    = resource
      @resource_klass              = resource.is_a?(Class) ? resource : resource.class
      @rest_action                 = rest_action.to_sym
      @attributes                  = attributes
      @connection_options          = connection_options
      @original_connection_options = connection_options.dup
    end

    def connection
      resource_klass.connection
    end

    def connection_options
      @connection_options.reverse_merge(threaded_connection_options).reverse_merge(resource.connection_options.to_hash)
    end

    def original_connection_options
      @original_connection_options.reverse_merge(threaded_connection_options)
    end

    def threaded_connection_options
      resource.try(:threaded_connection_options) || {}
    end
    private :threaded_connection_options

    def perform
      case rest_action
      when :get
        response = connection.public_send(rest_action, determined_request_url, params: determined_params, headers: determined_headers.reverse_merge(DEFAULT_HEADERS))
      when :put, :patch, :post
        response = connection.public_send(rest_action, determined_request_url, body: JSON.generate(determined_attributes), headers: determined_headers.reverse_merge(DEFAULT_HEADERS).reverse_merge(DEFAULT_CONTENT_TYPE))
      when :delete
        response = connection.public_send(rest_action, determined_request_url, params: determined_params, headers: determined_headers.reverse_merge(DEFAULT_HEADERS))
      else
        raise RemoteResource::RESTActionUnknown, "for action: '#{rest_action}'"
      end

      if response.success? || response.response_code == 422
        RemoteResource::Response.new response, connection_options
      else
        raise_http_errors response
      end
    end

    def determined_request_url
      id        = attributes[:id].presence || connection_options[:id]
      base_url  = original_connection_options[:base_url].presence || RemoteResource::UrlNamingDetermination.new(resource_klass, original_connection_options).base_url(id, check_collection_options: true)
      extension = connection_options[:extension] || DEFAULT_EXTENSION

      "#{base_url}#{extension}"
    end

    def determined_params
      no_params     = connection_options[:no_params].eql? true
      no_attributes = connection_options[:no_attributes].eql? true
      params        = connection_options[:params].presence || {}

      if no_params
        nil
      elsif no_attributes
        params
      else
        attributes.merge! params
      end
    end

    def determined_attributes
      no_attributes = connection_options[:no_attributes].eql? true
      root_element  = connection_options[:root_element].presence

      if no_attributes
        {}
      elsif root_element
        { root_element => attributes }
      else
        attributes
      end
    end

    def determined_headers
      headers = original_connection_options[:headers].presence || {}

      (connection_options[:default_headers].presence || resource.connection_options.headers.merge(headers)).reverse_merge(RemoteResource::Base.global_headers)
    end

  end
end
