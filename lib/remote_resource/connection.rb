module RemoteResource
  module Connection

    attr_writer :headers

    def connection
      Typhoeus::Request
    end

    def headers
      @headers ||= {}
      @headers.merge("Accept" => "application/json")
    end

  end
end