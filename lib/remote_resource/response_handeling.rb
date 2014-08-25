module RemoteResource
  class ResponseHandeling

    attr_reader :resource, :response, :connection_options

    def initialize(resource, response, connection_options = {})
      @resource           = resource
      @response           = response
      @connection_options = connection_options
    end

    def perform
      if response.success?
        if resource.respond_to? :new
          resource.build_resource_from_response response
        else
          resource
        end
      elsif errors?
        if resource.respond_to? :new
          #
        else
          # assign response
          resource.assign_errors response.parsed_response_body, root_element
        end
      else
        # nil
      end
    end

    def errors?
      parsed_response_body = response.parsed_response_body

      if parsed_response_body
        parsed_response_body.has_key?("errors") || parsed_response_body.fetch(root_element.to_s, nil).has_key?("errors")
      else
        false
      end
    end

    private

    def root_element
      connection_options[:root_element].presence || resource.connection_options.root_element.presence
    end

  end
end