module RemoteResource
  class Response

    def initialize(response)
      @original_response = response
    end

    def response_body
      original_response.body
    end

    def response_code
      original_response.response_code
    end

    private

    def original_response
      @original_response
    end

    def original_request
      @original_response.request
    end

  end
end