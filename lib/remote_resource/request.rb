module RemoteResource
  class Request

    RESTActionUnknown = Class.new(StandardError)

    attr_reader :resource, :rest_action, :attributes, :connection_options

    def initialize(resource, rest_action, attributes = {}, connection_options = {})
      @resource           = resource
      @rest_action        = rest_action.to_sym
      @attributes         = attributes
      @connection_options = connection_options
    end

    def perform
      case rest_action
      when :get
        response = connection.public_send rest_action, determined_request_url, params: determined_attributes, headers: determined_headers
      when :put, :patch, :post
        response = connection.public_send rest_action, determined_request_url, body: determined_attributes, headers: determined_headers
      else
        raise RESTActionUnknown, "for action: '#{rest_action}'"
      end

      RemoteResource::Response.new response, connection_options
    end

    def connection
      Typhoeus::Request
    end

    def determined_request_url
      id           = attributes[:id].presence
      base_url     = connection_options[:base_url].presence || resource.connection_options.base_url.presence
      content_type = connection_options[:content_type]      || resource.connection_options.content_type.presence

      if id
        "#{base_url}/#{id}#{content_type}"
      else
        "#{base_url}#{content_type}"
      end
    end

    def determined_attributes
      no_params    = connection_options[:no_params].eql? true
      root_element = connection_options[:root_element].presence || resource.connection_options.root_element.presence

      if no_params
        {}
      elsif root_element
        pack_up_attributes attributes, root_element
      else
        attributes
      end
    end

    def determined_headers
      headers = connection_options[:headers].presence || {}

      connection_options[:default_headers].presence || resource.connection_options.headers.merge(headers)
    end

    private

    def pack_up_attributes(attributes, root_element)
      Hash[root_element.to_s, attributes]
    end

  end
end