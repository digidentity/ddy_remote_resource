require 'spec_helper'

describe RemoteResource::REST do

  module RemoteResource
    class RESTDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::RESTDummy }
  let(:dummy)       { dummy_class.new }

  describe ".get" do
    let(:attributes)    { { foo: 'bar' } }
    let(:request_url)   { 'https://foobar.com/rest_dummy' }
    let(:headers)       { { "Accept" => "application/json" } }
    let(:response_mock) { double('response', success?: false).as_null_object }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock } }

    it "uses the HTTP GET method" do
      expect(Typhoeus::Request).to receive(:get).and_call_original
      dummy_class.get attributes
    end

    it "uses the attributes as request params" do
      expect(Typhoeus::Request).to receive(:get).with(request_url, params: { foo: 'bar' }, headers: headers).and_call_original
      dummy_class.get attributes
    end

    it "uses the connection_options headers as request headers" do
      expect(Typhoeus::Request).to receive(:get).with(request_url, params: attributes, headers: { "Accept" => "application/json" }).and_call_original
      dummy_class.get attributes
    end

    context "when custom connection_options are given" do
      it "uses the custom connection_options" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/rest_dummy.json', params: attributes, headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy_class.get(attributes, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the connection_options headers with custom connection_options default_headers" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/rest_dummy.json', params: attributes, headers: { "Baz" => "Bar" }).and_call_original
        dummy_class.get(attributes, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "response" do
      let(:connection_options)  { dummy_class.connection_options.to_hash }

      it "instantiates the RemoteResource::Response with the response AND connection_options" do
        expect(RemoteResource::Response).to receive(:new).with(response_mock, connection_options).and_call_original
        dummy_class.get attributes
      end

      it "returns the RemoteResource::Response" do
        expect(dummy_class.get(attributes)).to be_an_instance_of RemoteResource::Response
      end
    end
  end

  describe ".post" do
    let(:attributes)    { { foo: 'bar' } }
    let(:request_url)   { 'https://foobar.com/rest_dummy' }
    let(:headers)       { { "Accept" => "application/json" } }
    let(:response_mock) { double('response', success?: false).as_null_object }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock } }

    it "uses the HTTP POST method" do
      expect(Typhoeus::Request).to receive(:post).and_call_original
      dummy_class.post attributes
    end

    it "uses the attributes as request body" do
      expect(Typhoeus::Request).to receive(:post).with(request_url, body: { foo: 'bar' }, headers: headers).and_call_original
      dummy_class.post attributes
    end

    it "uses the connection_options headers as request headers" do
      expect(Typhoeus::Request).to receive(:post).with(request_url, body: attributes, headers: { "Accept" => "application/json" }).and_call_original
      dummy_class.post attributes
    end

    context "when custom connection_options are given" do
      it "uses the custom connection_options" do
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/rest_dummy.json', body: attributes, headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy_class.post(attributes, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the connection_options headers with custom connection_options default_headers" do
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/rest_dummy.json', body: attributes, headers: { "Baz" => "Bar" }).and_call_original
        dummy_class.post(attributes, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "response" do
      let(:connection_options)  { dummy_class.connection_options.to_hash }

      it "instantiates the RemoteResource::Response with the response AND connection_options" do
        expect(RemoteResource::Response).to receive(:new).with(response_mock, connection_options).and_call_original
        dummy_class.post attributes
      end

      it "returns the RemoteResource::Response" do
        expect(dummy_class.post(attributes)).to be_an_instance_of RemoteResource::Response
      end
    end
  end

  describe ".determined_request_url" do
    context "base_url" do
      context "when the given custom connection_options contain a base_url" do
        let(:custom_connection_options) { { base_url: 'https://api.baz.eu/' } }

        it "uses the base_url for the request_url" do
          expect(dummy_class.send :determined_request_url, custom_connection_options).to eql 'https://api.baz.eu/'
        end
      end

      context "when the connection_options contain a base_url" do
        before { dummy_class.connection_options.merge base_url: 'https://api.baz.eu/' }
        after  { dummy_class.connection_options.reload }

        it "uses the base_url for the request_url" do
          expect(dummy_class.send :determined_request_url).to eql 'https://api.baz.eu/'
        end
      end
    end

    context "id" do
      context "when the id is given" do
        it "uses the id for the request_url" do
          expect(dummy_class.send :determined_request_url, {}, 12).to eql 'https://foobar.com/rest_dummy/12'
        end
      end

      context "when the id is NOT given" do
        it "does NOT use the id for the request_url" do
          expect(dummy_class.send :determined_request_url).to eql 'https://foobar.com/rest_dummy'
        end
      end
    end

    context "content_type" do
      context "when the given custom connection_options contain a content_type" do
        let(:custom_connection_options) { { content_type: '.xml' } }

        it "uses the content_type for the request_url" do
          expect(dummy_class.send :determined_request_url, custom_connection_options).to eql 'https://foobar.com/rest_dummy.xml'
        end
      end

      context "when the connection_options contain a content_type" do
        before { dummy_class.connection_options.merge content_type: '.xml' }
        after  { dummy_class.connection_options.reload }

        it "uses the content_type for the request_url" do
          expect(dummy_class.send :determined_request_url).to eql 'https://foobar.com/rest_dummy.xml'
        end
      end
    end
  end

  describe "#post" do
    let(:attributes)    { { foo: 'bar' } }
    let(:request_url)   { 'https://foobar.com/rest_dummy' }
    let(:headers)       { { "Accept" => "application/json" } }
    let(:response_mock) { double('response').as_null_object }

    before do
      allow(response_mock).to receive(:request)
      allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock }
    end

    it "uses the HTTP POST method" do
      expect(Typhoeus::Request).to receive(:post).and_call_original
      dummy.post attributes
    end

    it "uses the attributes as request body" do
      expect(Typhoeus::Request).to receive(:post).with(request_url, body: { foo: 'bar' }, headers: headers).and_call_original
      dummy.post attributes
    end

    it "uses the connection_options headers as request headers" do
      expect(Typhoeus::Request).to receive(:post).with(request_url, body: attributes, headers: { "Accept" => "application/json" }).and_call_original
      dummy.post attributes
    end

    it "assigns the _response" do
      expect(dummy._response).to be_nil

      dummy.post attributes

      expect(dummy._response).to be_a RemoteResource::Response
    end

    context "when custom connection_options are given" do
      it "uses the custom connection_options" do
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/rest_dummy.json', body: attributes, headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy.post(attributes, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the connection_options headers with custom connection_options default_headers" do
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/rest_dummy.json', body: attributes, headers: { "Baz" => "Bar" }).and_call_original
        dummy.post(attributes, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "when the response is a success" do
      let(:response_mock) { double('response', success?: true) }

      it "returns true" do
        expect(dummy.post attributes).to be_truthy
      end
    end

    context "when the response is NOT a success" do
      context "and the response_code is 422" do
        let(:response_mock) { double('response', success?: false, response_code: 422, body: response_body) }

        context "root_element" do
          context "and the given custom connection_options contain a root_element" do
            let(:custom_connection_options) { { root_element: :foobar } }
            let(:response_body)             { '{"foobar":{"errors":{"foo":["is required"]}}}' }

            it "returns false" do
              expect(dummy.post attributes, custom_connection_options).to be_falsey
            end

            it "finds the errors in the parsed response body from the root_element and assigns the errors" do
              dummy.post attributes, custom_connection_options
              expect(dummy.errors.messages).to eql foo: ["is required"]
            end
          end

          context "and the connection_options contain a root_element" do
            let(:response_body) { '{"foobar":{"errors":{"foo":["is required"]}}}' }

            before { dummy.connection_options.merge root_element: :foobar  }

            it "returns false" do
              expect(dummy.post attributes).to be_falsey
            end

            it "finds the errors in the parsed response body from the root_element and assigns the errors" do
              dummy.post attributes
              expect(dummy.errors.messages).to eql foo: ["is required"]
            end
          end

          context "and NO root_element is specified" do
            let(:response_body) { '{"errors":{"foo":["is required"]}}' }

            before { dummy.connection_options.merge root_element: nil  }

            it "returns false" do
              expect(dummy.post attributes).to be_falsey
            end

            it "finds the errors in the parsed response body and assigns the errors" do
              dummy.post attributes
              expect(dummy.errors.messages).to eql foo: ["is required"]
            end
          end
        end
      end

      context "and the response_code is NOT 422" do
        let(:response_mock) { double('response', success?: false, response_code: 400) }

        it "returns false" do
          expect(dummy.post attributes).to be_falsey
        end

        it "does NOT assign the errors" do
          dummy.post attributes
          expect(dummy.errors).to be_empty
        end
      end
    end
  end

  describe "#patch" do
    let(:request_url)   { 'https://foobar.com/rest_dummies/10' }
    let(:attributes)    { { id: 10, foo: 'bar' } }
    let(:headers)       { { "Accept" => "application/json" } }
    let(:response_mock) { double('response').as_null_object }

    before do
      dummy.id = 10
      allow(response_mock).to receive(:request)
      allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock }
    end

    before { dummy_class.collection = true }
    after { dummy_class.collection = false }

    it "uses the HTTP PATCH method" do
      expect(Typhoeus::Request).to receive(:patch).and_call_original
      dummy.patch attributes
    end

    it "uses the attributes as request body" do
      expect(Typhoeus::Request).to receive(:patch).with(request_url, body: { id: 10, foo: 'bar' }, headers: headers).and_call_original
      dummy.patch attributes
    end

    it "uses the connection_options headers as request headers" do
      expect(Typhoeus::Request).to receive(:patch).with(request_url, body: attributes, headers: { "Accept"=>"application/json" }).and_call_original
      dummy.patch attributes
    end

    it "assigns the _response" do
      expect(dummy._response).to be_nil

      dummy.patch attributes

      expect(dummy._response).to be_a RemoteResource::Response
    end

    context "when custom connection_options are given" do
      it "uses the custom connection_options" do
        expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/rest_dummies/10.json', body: attributes, headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy.patch(attributes, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the connection_options headers with custom connection_options default_headers" do
        expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/rest_dummies/10.json', body: attributes, headers: { "Baz" => "Bar" }).and_call_original
        dummy.patch(attributes, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "collection" do
      context "when the given custom connection_options collection option is truthy" do
        let(:custom_connection_options) { { collection: true } }

        it "uses the id in the request url" do
          expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/rest_dummies/10', body: attributes, headers: headers).and_call_original
          dummy.patch attributes, custom_connection_options
        end
      end

      context "when the connection_options collection option is truthy" do
        before { dummy.connection_options.merge collection: true  }

        it "uses the id in the request url" do
          expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/rest_dummies/10', body: attributes, headers: headers).and_call_original
          dummy.patch attributes
        end
      end

      context "when NO collection option is set OR falsely" do
        before { dummy.connection_options.merge collection: false  }

        it "does NOT use the id in the request url" do
          expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/rest_dummies', body: attributes, headers: headers).and_call_original
          dummy.patch attributes
        end
      end
    end

    context "when the response is a success" do
      let(:response_mock) { double('response', success?: true) }

      it "returns true" do
        expect(dummy.patch attributes).to be_truthy
      end
    end

    context "when the response is NOT a success" do
      context "and the response_code is 422" do
        let(:response_mock) { double('response', success?: false, response_code: 422, body: response_body) }

        context "root_element" do
          context "and the given custom connection_options contain a root_element" do
            let(:custom_connection_options) { { root_element: :foobar } }
            let(:response_body)             { '{"foobar":{"errors":{"foo":["is required"]}}}' }

            it "returns false" do
              expect(dummy.patch attributes, custom_connection_options).to be_falsey
            end

            it "finds the errors in the parsed response body from the root_element and assigns the errors" do
              dummy.patch attributes, custom_connection_options
              expect(dummy.errors.messages).to eql foo: ["is required"]
            end
          end

          context "and the connection_options contain a root_element" do
            let(:response_body) { '{"foobar":{"errors":{"foo":["is required"]}}}' }

            before { dummy.connection_options.merge root_element: :foobar  }

            it "returns false" do
              expect(dummy.patch attributes).to be_falsey
            end

            it "finds the errors in the parsed response body from the root_element and assigns the errors" do
              dummy.patch attributes
              expect(dummy.errors.messages).to eql foo: ["is required"]
            end
          end

          context "and NO root_element is specified" do
            let(:response_body) { '{"errors":{"foo":["is required"]}}' }

            before { dummy.connection_options.merge root_element: nil  }

            it "returns false" do
              expect(dummy.patch attributes).to be_falsey
            end

            it "finds the errors in the parsed response body and assigns the errors" do
              dummy.patch attributes
              expect(dummy.errors.messages).to eql foo: ["is required"]
            end
          end
        end
      end

      context "and the response_code is NOT 422" do
        let(:response_mock) { double('response', success?: false, response_code: 400) }

        it "returns false" do
          expect(dummy.patch attributes).to be_falsey
        end

        it "does NOT assign the errors" do
          dummy.patch attributes
          expect(dummy.errors).to be_empty
        end
      end
    end
  end

  describe "#determined_request_url" do
    context "collection" do
      context "when the connection_options collection option is truthy" do
        let(:connection_options)  { { collection: true } }

        context "and the id is present" do
          let(:id)    { 12 }
          let(:dummy) { dummy_class.new id: id }

          it "calls .determined_request_url" do
            expect(dummy_class).to receive(:determined_request_url).with(connection_options, id)
            dummy.send :determined_request_url, connection_options
          end

          it "uses the id for the request_url" do
            expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/rest_dummy/12'
          end
        end

        context "and the id is NOT present" do
          it "calls .determined_request_url" do
            expect(dummy_class).to receive(:determined_request_url).with(connection_options)
            dummy.send :determined_request_url, connection_options
          end

          it "does NOT use the id for the request_url" do
            expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/rest_dummy'
          end
        end
      end

      context "when NO connection_options collection option is set OR falsely" do
        let(:connection_options)  { { collection: false } }

        it "calls .determined_request_url" do
          expect(dummy_class).to receive(:determined_request_url).with(connection_options)
          dummy.send :determined_request_url, connection_options
        end

        it "does NOT use the id for the request_url" do
          expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/rest_dummy'
        end
      end
    end
  end

end
