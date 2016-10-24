module RemoteResource
  module REST

    def get(attributes = {}, connection_options = {})
      RemoteResource::Request.new(self, __method__, attributes, connection_options).perform
    end

    def put(attributes = {}, connection_options = {})
      RemoteResource::Request.new(self, __method__, attributes, connection_options).perform
    end

    def patch(attributes = {}, connection_options = {})
      RemoteResource::Request.new(self, __method__, attributes, connection_options).perform
    end

    def post(attributes = {}, connection_options = {})
      RemoteResource::Request.new(self, __method__, attributes, connection_options).perform
    end

    def delete(attributes = {}, connection_options = {})
      RemoteResource::Request.new(self, __method__, attributes, connection_options).perform
    end

  end
end
