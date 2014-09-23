module RemoteResource
  module HTTPErrors

    private

    def raise_http_errors(response)
      case response.response_code
      when 301, 302, 303, 307
        raise RemoteResource::HTTPRedirectionError, response
      when 400
        raise RemoteResource::HTTPBadRequest, response
      when 401
        raise RemoteResource::HTTPUnauthorized, response
      when 403
        raise RemoteResource::HTTPForbidden, response
      when 404
        raise RemoteResource::HTTPNotFound, response
      when 405
        raise RemoteResource::HTTPMethodNotAllowed, response
      when 406
        raise RemoteResource::HTTPNotAcceptable, response
      when 408
        raise RemoteResource::HTTPRequestTimeout, response
      when 409
        raise RemoteResource::HTTPConflict, response
      when 410
        raise RemoteResource::HTTPGone, response
      when 418
        raise RemoteResource::HTTPTeapot, response
      when 444
        raise RemoteResource::HTTPNoResponse, response
      when 494
        raise RemoteResource::HTTPRequestHeaderTooLarge, response
      when 495
        raise RemoteResource::HTTPCertError, response
      when 496
        raise RemoteResource::HTTPNoCert, response
      when 497
        raise RemoteResource::HTTPToHTTPS, response
      when 499
        raise RemoteResource::HTTPClientClosedRequest, response
      when 400..499
        raise RemoteResource::HTTPClientError, response
      when 500..599
        raise RemoteResource::HTTPServerError, response
      else
        raise RemoteResource::HTTPError, response
      end
    end

  end
end
