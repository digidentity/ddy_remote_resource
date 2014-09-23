module RemoteResource
  module HTTPErrors

    private

    def raise_http_errors(response)
      case response.status
      when 301, 302, 303, 307
        raise RemoteResource::HTTPRedirectionError, "with HTTP response status: #{response.status} and response: #{response}"
      when 400
        raise RemoteResource::HTTPBadRequest, "with HTTP response status: #{response.status} and response: #{response}"
      when 401
        raise RemoteResource::HTTPUnauthorized, "with HTTP response status: #{response.status} and response: #{response}"
      when 403
        raise RemoteResource::HTTPForbidden, "with HTTP response status: #{response.status} and response: #{response}"
      when 404
        raise RemoteResource::HTTPNotFound, "with HTTP response status: #{response.status} and response: #{response}"
      when 405
        raise RemoteResource::HTTPMethodNotAllowed, "with HTTP response status: #{response.status} and response: #{response}"
      when 406
        raise RemoteResource::HTTPNotAcceptable, "with HTTP response status: #{response.status} and response: #{response}"
      when 408
        raise RemoteResource::HTTPRequestTimeout, "with HTTP response status: #{response.status} and response: #{response}"
      when 409
        raise RemoteResource::HTTPConflict, "with HTTP response status: #{response.status} and response: #{response}"
      when 410
        raise RemoteResource::HTTPGone, "with HTTP response status: #{response.status} and response: #{response}"
      when 418
        raise RemoteResource::HTTPTeapot, "with HTTP response status: #{response.status} and response: #{response}"
      when 444
        raise RemoteResource::HTTPNoResponse, "with HTTP response status: #{response.status} and response: #{response}"
      when 494
        raise RemoteResource::HTTPRequestHeaderTooLarge, "with HTTP response status: #{response.status} and response: #{response}"
      when 495
        raise RemoteResource::HTTPCertError, "with HTTP response status: #{response.status} and response: #{response}"
      when 496
        raise RemoteResource::HTTPNoCert, "with HTTP response status: #{response.status} and response: #{response}"
      when 497
        raise RemoteResource::HTTPToHTTPS, "with HTTP response status: #{response.status} and response: #{response}"
      when 499
        raise RemoteResource::HTTPClientClosedRequest, "with HTTP response status: #{response.status} and response: #{response}"
      when 400..499
        raise RemoteResource::HTTPClientError, "with HTTP response status: #{response.status} and response: #{response}"
      when 500..599
        raise RemoteResource::HTTPServerError, "with HTTP response status: #{response.status} and response: #{response}"
      else
        raise RemoteResource::HTTPError, "with HTTP response: #{response}"
      end
    end

  end
end
