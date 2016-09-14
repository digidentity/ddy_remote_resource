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
      @resource           = resource
      @resource_klass     = resource.is_a?(Class) ? resource : resource.class
      @rest_action        = rest_action.to_sym
      @attributes         = attributes
      @connection_options = connection_options.dup
    end

    def connection
      resource_klass.connection
    end

    def connection_options
      @combined_connection_options ||= begin
        default = resource.connection_options.to_hash # Defined on the resource (klass).
        block   = resource.try(:threaded_connection_options) || {} # Given as arguments in the .with_connection_options block.
        local   = @connection_options # Given as arguments directly.

        default.deep_merge(block).deep_merge(local)
      end
    end

    def perform
      case rest_action
      when :get
        response = connection.public_send(rest_action, request_url, params: params, headers: headers)
      when :put, :patch, :post
        response = connection.public_send(rest_action, request_url, body: JSON.generate(attributes), headers: headers.reverse_merge(DEFAULT_CONTENT_TYPE))
      when :delete
        response = connection.public_send(rest_action, request_url, params: params, headers: headers)
      else
        raise RemoteResource::RESTActionUnknown, "for action: '#{rest_action}'"
      end

      if response.success? || response.response_code == 422
        RemoteResource::Response.new response, connection_options
      else
        raise_http_errors response
      end
    end

    def request_url
      id        = @attributes[:id].presence || connection_options[:id]
      base_url  = connection_options[:base_url].presence || RemoteResource::UrlNamingDetermination.new(resource_klass, connection_options).base_url(id, check_collection_options: true)
      extension = connection_options[:extension] || DEFAULT_EXTENSION

      "#{base_url}#{extension}"
    end

    def params
      no_params     = connection_options[:no_params].eql? true
      no_attributes = connection_options[:no_attributes].eql? true
      params        = connection_options[:params].presence || {}

      if no_params
        nil
      elsif no_attributes
        params
      else
        @attributes.merge(params)
      end
    end

    def attributes
      no_attributes = connection_options[:no_attributes].eql? true
      root_element  = connection_options[:root_element].presence

      if no_attributes
        {}
      elsif root_element
        { root_element => @attributes }
      else
        @attributes
      end
    end

    def headers
      default_headers = connection_options[:default_headers].presence || DEFAULT_HEADERS
      global_headers  = RemoteResource::Base.global_headers.presence || {}
      headers         = connection_options[:headers].presence || {}

      default_headers.merge(global_headers).merge(headers)
    end

  end
end
