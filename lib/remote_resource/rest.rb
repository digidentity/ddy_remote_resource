module RemoteResource
  module REST
    extend ActiveSupport::Concern

    ACTIONS = [:get, :put, :patch, :post]

    module ClassMethods

      RemoteResource::REST::ACTIONS.each do |action|
        define_method action do |*args|
          attributes         = args[0] || {}
          connection_options = args[1] || {}

          RemoteResource::Request.new(self, action, attributes, connection_options).perform
        end
      end
    end

    RemoteResource::REST::ACTIONS.each do |action|
      define_method action do |*args|
        attributes         = args[0] || {}
        connection_options = args[1] || {}

        RemoteResource::Request.new(self, action, attributes, connection_options).perform
      end
    end

  end
end