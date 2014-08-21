module RemoteResource
  class Response

    attr_reader :original_response, :original_request
    private :original_response, :original_request

    def initialize(response, connection_options = {})
      @original_response  = response
      @original_request   = response.request
      @connection_options = connection_options
    end

    def success?
      original_response.success?
    end

    def unprocessable_entity?
      response_code == 422
    end

    def response_body
      original_response.body
    end

    def response_code
      original_response.response_code
    end

    def sanitized_response_body
      return {} if response_body.blank?
      return {} if parsed_response_body.blank?

      unpack_response_body parsed_response_body
    end

    def parsed_response_body
      @parsed_response_body ||= JSON.parse response_body
    rescue JSON::ParserError
      nil
    end

    private

    def unpack_response_body(body)
      root_element = @connection_options[:root_element]
      root_element ? body[root_element.to_s] : body
    end

  end
end