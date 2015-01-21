require 'active_support/all'
require 'active_model'
require 'virtus'
require 'typhoeus'

require_relative 'extensions/ethon/easy/queryable'

require 'remote_resource/version'
require 'remote_resource/base'
require 'remote_resource/collection'
require 'remote_resource/url_naming_determination'
require 'remote_resource/url_naming'
require 'remote_resource/connection'
require 'remote_resource/builder'
require 'remote_resource/connection_options'
require 'remote_resource/rest'
require 'remote_resource/response'
require 'remote_resource/querying/finder_methods'
require 'remote_resource/querying/persistence_methods'
require 'remote_resource/http_errors'
require 'remote_resource/request'


module RemoteResource
  RemoteResourceError = Class.new StandardError

  RESTActionUnknown = Class.new RemoteResourceError # REST action

  class HTTPError < RemoteResourceError # HTTP errors

    def initialize(response)
      if response.try(:response_code)
        super "for url: #{response.try(:effective_url)} with HTTP response status: #{response.response_code} and response: #{response.inspect}"
      else
        super "for url: #{response.try(:effective_url)} with HTTP response: #{response.inspect}"
      end
    end
  end

  HTTPRedirectionError = Class.new HTTPError # HTTP 3xx
  HTTPClientError      = Class.new HTTPError # HTTP 4xx
  HTTPServerError      = Class.new HTTPError # HTTP 5xx

  HTTPBadRequest        = Class.new HTTPClientError # HTTP 400
  HTTPUnauthorized      = Class.new HTTPClientError # HTTP 401
  HTTPForbidden         = Class.new HTTPClientError # HTTP 403
  HTTPNotFound          = Class.new HTTPClientError # HTTP 404
  HTTPMethodNotAllowed  = Class.new HTTPClientError # HTTP 405
  HTTPNotAcceptable     = Class.new HTTPClientError # HTTP 406
  HTTPRequestTimeout    = Class.new HTTPClientError # HTTP 408
  HTTPConflict          = Class.new HTTPClientError # HTTP 409
  HTTPGone              = Class.new HTTPClientError # HTTP 410
  HTTPTeapot            = Class.new HTTPClientError # HTTP 418

  NginxClientError = Class.new HTTPClientError # HTTP errors used in Nginx

  HTTPNoResponse            = Class.new NginxClientError # HTTP 444
  HTTPRequestHeaderTooLarge = Class.new NginxClientError # HTTP 494
  HTTPCertError             = Class.new NginxClientError # HTTP 495
  HTTPNoCert                = Class.new NginxClientError # HTTP 496
  HTTPToHTTPS               = Class.new NginxClientError # HTTP 497
  HTTPClientClosedRequest   = Class.new NginxClientError # HTTP 499

end
