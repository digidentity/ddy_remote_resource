module RemoteResource
  class Request

    SUPPORTED_HTTP_METHODS = [:get, :put, :patch, :post, :delete].freeze

    DEFAULT_HEADERS = {
      'Accept'     => 'application/json',
      'User-Agent' => "RemoteResource #{RemoteResource::VERSION}"
    }.freeze

    DEFAULT_CONTENT_TYPE = {
      'Content-Type' => 'application/json'
    }.freeze

    DEFAULT_EXTENSION = '.json'.freeze

    DEFAULT_CONNECT_TIMEOUT = 30
    DEFAULT_READ_TIMEOUT = 120

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

      connection_response = connection.public_send(http_action, request_url, params: query, body: body, headers: headers, **timeout_options)
      response            = RemoteResource::Response.new(connection_response, connection_options.merge(request: self, connection_request: connection_response.request))

      if response.success? || response.unprocessable_entity?
        response
      else
        raise_http_error(self, response)
      end
    end

    def request_url
      @request_url ||= begin
        id        = @attributes[:id].presence || connection_options[:id]
        base_url  = connection_options[:base_url].presence || RemoteResource::UrlNamingDetermination.new(resource_klass, connection_options).base_url(id, check_collection_options: true)
        extension = connection_options[:extension] || DEFAULT_EXTENSION

        "#{base_url}#{extension}"
      end
    end

    def query
      @query ||= begin
        params = connection_options[:params]

        if params.present? && !connection_options[:force_get_params_in_body]
          RemoteResource::Util.encode_params_to_query(params)
        else
          nil
        end
      end
    end

    def body
      @body ||= begin
        case http_action
        when :put, :patch, :post
          attributes.to_json
        when :get
          connection_options[:params].to_json if connection_options[:force_get_params_in_body]
        else
          nil
        end
      end
    end

    def attributes
      if connection_options[:json_spec] == :json_api
        if @attributes
          { data: { id: @attributes[:id], type: resource_klass.name.demodulize, attributes: @attributes.except(:id) } }
        else
          { data: {} }
        end
      else
        root_element = connection_options[:root_element]

        if root_element.present?
          { root_element => @attributes }
        else
          @attributes || {}
        end
      end
    end

    def headers
      @headers ||= begin
        default_headers = connection_options[:default_headers].presence || DEFAULT_HEADERS
        global_headers  = RemoteResource::Base.global_headers.presence || {}
        headers         = connection_options[:headers].presence || {}

        default_headers.merge(global_headers).merge(headers).merge(conditional_headers)
      end
    end

    def conditional_headers
      headers = {}
      headers = headers.merge(DEFAULT_CONTENT_TYPE) if body.present?
      headers = headers.merge({ 'X-Request-Id' => RequestStore.store[:request_id] }) if RequestStore.store[:request_id].present?
      headers
    end

    def timeout_options
      connecttimeout = connection_options[:connecttimeout].presence || DEFAULT_CONNECT_TIMEOUT
      timeout = connection_options[:timeout].presence || DEFAULT_READ_TIMEOUT

      { connecttimeout: connecttimeout, timeout: timeout }
    end

    private

    def raise_http_error(request, response)
      # Special case if a request has a time out, as Typhoeus does not set a 408 response_code
      raise RemoteResource::HTTPRequestTimeout.new(request, response) if response.timed_out?

      case response.try(:response_code)
      when 301, 302, 303, 307 then
        raise RemoteResource::HTTPRedirectionError.new(request, response)
      when 400
        raise RemoteResource::HTTPBadRequest.new(request, response)
      when 401
        raise RemoteResource::HTTPUnauthorized.new(request, response)
      when 403
        raise RemoteResource::HTTPForbidden.new(request, response)
      when 404
        raise RemoteResource::HTTPNotFound.new(request, response)
      when 405
        raise RemoteResource::HTTPMethodNotAllowed.new(request, response)
      when 406
        raise RemoteResource::HTTPNotAcceptable.new(request, response)
      when 408
        raise RemoteResource::HTTPRequestTimeout.new(request, response)
      when 409
        raise RemoteResource::HTTPConflict.new(request, response)
      when 410
        raise RemoteResource::HTTPGone.new(request, response)
      when 418
        raise RemoteResource::HTTPTeapot.new(request, response)
      when 444
        raise RemoteResource::HTTPNoResponse.new(request, response)
      when 494
        raise RemoteResource::HTTPRequestHeaderTooLarge.new(request, response)
      when 495
        raise RemoteResource::HTTPCertError.new(request, response)
      when 496
        raise RemoteResource::HTTPNoCert.new(request, response)
      when 497
        raise RemoteResource::HTTPToHTTPS.new(request, response)
      when 499
        raise RemoteResource::HTTPClientClosedRequest.new(request, response)
      when 400..499
        raise RemoteResource::HTTPClientError.new(request, response)
      when 500..599
        raise RemoteResource::HTTPServerError.new(request, response)
      else
        raise RemoteResource::HTTPError.new(request, response)
      end
    end

  end
end
