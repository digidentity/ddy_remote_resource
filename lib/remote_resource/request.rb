module RemoteResource
  class Request
    include RemoteResource::HTTPErrors

    attr_reader :resource, :rest_action, :attributes

    def initialize(resource, rest_action, attributes = {}, connection_options = {})
      @resource           = resource
      @rest_action        = rest_action.to_sym
      @attributes         = attributes
      @connection_options = connection_options
      @original_connection_options = connection_options.dup
    end

    def connection
      resource_klass.connection
    end

    def connection_options
      @connection_options.reverse_merge! threaded_connection_options
      @connection_options.reverse_merge! resource.connection_options.to_hash
    end

    def original_connection_options
      @original_connection_options.reverse_merge! threaded_connection_options
    end

    def perform
      case rest_action
      when :get
        response = connection.public_send rest_action, determined_request_url, params: determined_params, headers: determined_headers
      when :put, :patch, :post
        response = connection.public_send rest_action, determined_request_url, body: determined_attributes, headers: determined_headers
      else
        raise RemoteResource::RESTActionUnknown, "for action: '#{rest_action}'"
      end

      if response.success?
        RemoteResource::Response.new response, connection_options
      else
        raise_http_errors response
      end
    end

    def determined_request_url
      id           = attributes[:id].presence
      base_url     = original_connection_options[:base_url].presence || determined_url_naming.base_url(id)
      content_type = connection_options[:content_type]

      "#{base_url}#{content_type}"
    end

    def determined_params
      no_params     = connection_options[:no_params].eql? true
      no_attributes = connection_options[:no_attributes].eql? true
      params        = connection_options[:params].presence || {}

      if no_params
        nil
      elsif no_attributes
        params
      else
        attributes.merge! params
      end
    end

    def determined_attributes
      no_attributes = connection_options[:no_attributes].eql? true
      root_element  = connection_options[:root_element].presence

      if no_attributes
        {}
      elsif root_element
        pack_up_attributes attributes, root_element
      else
        attributes
      end
    end

    def determined_headers
      headers = original_connection_options[:headers].presence || {}

      connection_options[:default_headers].presence || resource.connection_options.headers.merge(headers)
    end

    private

    def threaded_connection_options
      resource.try(:threaded_connection_options) || {}
    end

    def determined_url_naming
      RemoteResource::UrlNamingDetermination.new resource_klass, original_connection_options
    end

    def resource_klass
      resource.is_a?(Class) ? resource : resource.class
    end

    def pack_up_attributes(attributes, root_element)
      Hash[root_element.to_s, attributes]
    end

  end
end
