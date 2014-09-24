module RemoteResource
  module HTTPErrors

    private

    def raise_http_errors(response)
      case response.response_code
      when 301, 302, 303, 307 then raise RemoteResource::HTTPRedirectionError, response
      when 400 then raise RemoteResource::HTTPBadRequest, response
      when 401 then raise RemoteResource::HTTPUnauthorized, response
      when 403 then raise RemoteResource::HTTPForbidden, response
      when 404 then raise RemoteResource::HTTPNotFound, response
      when 405 then raise RemoteResource::HTTPMethodNotAllowed, response
      when 406 then raise RemoteResource::HTTPNotAcceptable, response
      when 408 then raise RemoteResource::HTTPRequestTimeout, response
      when 409 then raise RemoteResource::HTTPConflict, response
      when 410 then raise RemoteResource::HTTPGone, response
      when 418 then raise RemoteResource::HTTPTeapot, response
      when 444 then raise RemoteResource::HTTPNoResponse, response
      when 494 then raise RemoteResource::HTTPRequestHeaderTooLarge, response
      when 495 then raise RemoteResource::HTTPCertError, response
      when 496 then raise RemoteResource::HTTPNoCert, response
      when 497 then raise RemoteResource::HTTPToHTTPS, response
      when 499 then raise RemoteResource::HTTPClientClosedRequest, response
      when 400..499 then raise RemoteResource::HTTPClientError, response
      when 500..599 then raise RemoteResource::HTTPServerError, response
      else
        raise RemoteResource::HTTPError, response
      end
    end

  end
end
