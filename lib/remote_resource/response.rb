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
      return empty_hash if response_body.blank?
      return empty_hash if parsed_response_body.blank?

      unpacked_parsed_response_body
    end

    def error_messages_response_body
      return empty_hash if response_body.blank?
      return empty_hash if parsed_response_body.blank?

      return parsed_response_body["errors"]          if parsed_response_body.try :has_key?, "errors"
      return unpacked_parsed_response_body["errors"] if unpacked_parsed_response_body.try :has_key?, "errors"

      empty_hash
    end

    def parsed_response_body
      @parsed_response_body ||= JSON.parse response_body
    rescue JSON::ParserError
      nil
    end

    private

    def empty_hash
      {}
    end

    def unpacked_parsed_response_body
      root_element = @connection_options[:root_element].presence

      if root_element
        parsed_response_body[root_element.to_s]
      else
        parsed_response_body
      end
    end

  end
end