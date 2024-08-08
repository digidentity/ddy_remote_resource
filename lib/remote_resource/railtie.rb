module RemoteResource
  class Railtie < Rails::Railtie
    initializer "remote_resource.deprecator" do |app|
      app.deprecators[:remote_resource] = RemoteResource.deprecator
    end
  end
end
