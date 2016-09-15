module RemoteResource
  class Request
    include RemoteResource::HTTPErrors

    SUPPORTED_HTTP_METHODS = [:get, :put, :patch, :post, :delete].freeze

    DEFAULT_HEADERS = {
      'Accept'     => 'application/json',
      'User-Agent' => "RemoteResource #{RemoteResource::VERSION}"
    }.freeze

    DEFAULT_CONTENT_TYPE = {
      'Content-Type' => 'application/json'
    }.freeze

    DEFAULT_EXTENSION = '.json'.freeze

    attr_reader :resource, :resource_klass, :http_action, :attributes

    def initialize(resource, http_action, attributes = {}, connection_options = {})
      @resource           = resource
      @resource_klass     = resource.is_a?(Class) ? resource : resource.class
      @http_action        = http_action.to_sym
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
      SUPPORTED_HTTP_METHODS.include?(http_action) || raise(RemoteResource::HTTPMethodUnsupported, "Requested HTTP method=#{http_action.to_s} is NOT supported, the HTTP action MUST be a supported HTTP action=#{SUPPORTED_HTTP_METHODS.join(', ')}")

      response = connection.public_send(http_action, request_url, params: query, body: body, headers: headers)

      if response.success? || response.response_code == 422
        RemoteResource::Response.new(response, connection_options)
      else
        raise_http_errors(response)
      end
    end

    def request_url
      id        = @attributes[:id].presence || connection_options[:id]
      base_url  = connection_options[:base_url].presence || RemoteResource::UrlNamingDetermination.new(resource_klass, connection_options).base_url(id, check_collection_options: true)
      extension = connection_options[:extension] || DEFAULT_EXTENSION

      "#{base_url}#{extension}"
    end

    def query
      params = connection_options[:params]

      if params.present?
        RemoteResource::Util.encode_params_to_query(params)
      else
        nil
      end
    end

    def body
      if [:put, :patch, :post].include?(http_action)
        JSON.generate(attributes)
      else
        nil
      end
    end

    def attributes
      root_element = connection_options[:root_element]

      if root_element.present?
        { root_element => @attributes }
      else
        @attributes || {}
      end
    end

    def headers
      default_headers = connection_options[:default_headers].presence || DEFAULT_HEADERS
      global_headers  = RemoteResource::Base.global_headers.presence || {}
      headers         = connection_options[:headers].presence || {}

      default_headers.merge(global_headers).merge(headers).merge(conditional_headers)
    end

    def conditional_headers
      headers = {}
      headers = headers.merge(DEFAULT_CONTENT_TYPE) if body.present?
      headers
    end

  end
end
