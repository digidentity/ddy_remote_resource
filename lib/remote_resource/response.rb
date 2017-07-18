module RemoteResource
  class Response

    def initialize(connection_response, connection_options = {})
      @connection_response = connection_response
      @connection_request  = connection_options[:connection_request]
      @request             = connection_options[:request]
      @connection_options  = connection_options
    end

    def request
      @request
    end

    def success?
      @connection_response.success?
    end

    def unprocessable_entity?
      response_code == 422
    end

    def response_code
      @response_code ||= @connection_response.response_code
    end

    alias_method :code, :response_code

    def headers
      @headers ||= @connection_response.headers
    end

    def body
      @body ||= @connection_response.body
    end

    def parsed_body
      @parsed_body ||= begin
        JSON.parse(body.to_s)
      rescue JSON::ParserError
        {}
      end
    end

    def attributes
      @attributes ||= begin
        root_element = @connection_options[:root_element].to_s
        data         = nil

        if root_element.present?
          data = parsed_body.try(:key?, root_element) && parsed_body[root_element]
        else
          data = parsed_body
        end

        if data.is_a?(Array)
          data
        else
          data.presence || {}
        end
      end
    end

    def errors
      @errors ||= parsed_body.try(:key?, 'errors') && parsed_body['errors'].presence || attributes.try(:key?, 'errors') && attributes['errors'].presence || {}
    end

    def meta
      @meta ||= parsed_body.try(:key?, 'meta') && parsed_body['meta'].presence || {}
    end

  end
end
