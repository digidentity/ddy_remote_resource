module RemoteResource
  RemoteResourceError = Class.new(StandardError)

  IdMissingError = Class.new(RemoteResourceError)

  CollectionOptionKeyError = Class.new(RemoteResourceError)

  HTTPMethodUnsupported = Class.new(RemoteResourceError) # REST action

  class HTTPError < RemoteResourceError # HTTP errors

    def initialize(request, response)
      @request  = request
      @response = response
    end

    def resource_klass
      @request.resource_klass
    end

    def http_action
      @request.http_action
    end

    def request_url
      @request.request_url
    end

    def request_query
      @request.query
    end

    def request_body
      @request.body # TODO: Filter sensitive information using: RemoteResource::Util.filter_params
    end

    def request_headers
      @request.headers
    end

    def response_code
      @response.code
    end

    # The return code can contain additional information when response_code=0
    # see https://curl.se/libcurl/c/libcurl-errors.html for the full list
    def return_code
      @response.return_code
    end

    def response_body
      @response.body # TODO: Filter sensitive information using: RemoteResource::Util.filter_params
    end

    def response_headers
      @response.headers
    end

    def to_s
      message = "HTTP request failed for #{resource_klass}"
      message << " with response_code=#{response_code}" if response_code.present?
      message << " with return_code=#{return_code}" if return_code.present? && response_code.zero?
      message << " with http_action=#{http_action}"
      message << " with request_url=#{request_url}"
      message
    end

  end

  HTTPRedirectionError = Class.new(HTTPError) # HTTP 3xx
  HTTPClientError      = Class.new(HTTPError) # HTTP 4xx
  HTTPServerError      = Class.new(HTTPError) # HTTP 5xx

  HTTPBadRequest       = Class.new(HTTPClientError) # HTTP 400
  HTTPUnauthorized     = Class.new(HTTPClientError) # HTTP 401
  HTTPForbidden        = Class.new(HTTPClientError) # HTTP 403
  HTTPNotFound         = Class.new(HTTPClientError) # HTTP 404
  HTTPMethodNotAllowed = Class.new(HTTPClientError) # HTTP 405
  HTTPNotAcceptable    = Class.new(HTTPClientError) # HTTP 406
  HTTPRequestTimeout   = Class.new(HTTPClientError) # HTTP 408
  HTTPConflict         = Class.new(HTTPClientError) # HTTP 409
  HTTPGone             = Class.new(HTTPClientError) # HTTP 410
  HTTPTeapot           = Class.new(HTTPClientError) # HTTP 418

  NginxClientError = Class.new(HTTPClientError) # HTTP errors used in Nginx

  HTTPNoResponse            = Class.new(NginxClientError) # HTTP 444
  HTTPRequestHeaderTooLarge = Class.new(NginxClientError) # HTTP 494
  HTTPCertError             = Class.new(NginxClientError) # HTTP 495
  HTTPNoCert                = Class.new(NginxClientError) # HTTP 496
  HTTPToHTTPS               = Class.new(NginxClientError) # HTTP 497
  HTTPClientClosedRequest   = Class.new(NginxClientError) # HTTP 499
end
