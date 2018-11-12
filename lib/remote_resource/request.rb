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

      connection_response = connection.public_send(http_action, request_url, params: query, body: body, headers: headers)
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

        if params.present?
          RemoteResource::Util.encode_params_to_query(params)
        else
          nil
        end
      end
    end

    def body
      @body ||= begin
        if [:put, :patch, :post].include?(http_action)
          JSON.generate(attributes)
        else
          nil
        end
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

    private

    def raise_http_error(request, response)
      case response.try(:response_code)
      when 301, 302, 303, 307 then raise RemoteResource::HTTPRedirectionError.new(request, response)
      when 400 then raise RemoteResource::HTTPBadRequest.new(request, response)
      when 401 then raise RemoteResource::HTTPUnauthorized.new(request, response)
      when 403 then raise RemoteResource::HTTPForbidden.new(request, response)
      when 404 then raise RemoteResource::HTTPNotFound.new(request, response)
      when 405 then raise RemoteResource::HTTPMethodNotAllowed.new(request, response)
      when 406 then raise RemoteResource::HTTPNotAcceptable.new(request, response)
      when 408 then raise RemoteResource::HTTPRequestTimeout.new(request, response)
      when 409 then raise RemoteResource::HTTPConflict.new(request, response)
      when 410 then raise RemoteResource::HTTPGone.new(request, response)
      when 418 then raise RemoteResource::HTTPTeapot.new(request, response)
      when 444 then raise RemoteResource::HTTPNoResponse.new(request, response)
      when 494 then raise RemoteResource::HTTPRequestHeaderTooLarge.new(request, response)
      when 495 then raise RemoteResource::HTTPCertError.new(request, response)
      when 496 then raise RemoteResource::HTTPNoCert.new(request, response)
      when 497 then raise RemoteResource::HTTPToHTTPS.new(request, response)
      when 499 then raise RemoteResource::HTTPClientClosedRequest.new(request, response)
      when 400..499 then raise RemoteResource::HTTPClientError.new(request, response)
      when 500..599 then raise RemoteResource::HTTPServerError.new(request, response)
      else
        raise RemoteResource::HTTPError.new(request, response)
      end
    end

  end
end
