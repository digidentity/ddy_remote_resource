module RemoteResource
  module Connection

    def connection
      Typhoeus::Request
    end

    def headers=(headers)
      Thread.current['remote_resource.headers'] = headers
    end

    def headers
      Thread.current['remote_resource.headers'] ||= {}
      Thread.current['remote_resource.headers'].merge({"Accept" => "application/json"})
    end

  end
end