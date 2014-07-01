require 'spec_helper'

describe RemoteResource::Base do

  module RemoteResource
    class Dummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::Dummy }
  let(:dummy)       { dummy_class.new }

  specify { expect(described_class.const_defined?('RemoteResource::UrlNaming')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::Connection')).to be_truthy }

  describe "OPTIONS" do
    let(:options) { [:site, :headers, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element] }

    specify { expect(described_class::OPTIONS).to eql options }
  end

  describe "attributes" do
    it "#id" do
      expect(dummy.attributes).to have_key :id
    end
  end

  describe ".connection_options" do
    it "instantiates as a RemoteResource::ConnectionOptions" do
      expect(dummy_class.connection_options).to be_a RemoteResource::ConnectionOptions
    end

    it "uses the implemented class as base_class" do
      expect(dummy_class.connection_options.base_class).to be RemoteResource::Dummy
    end
  end

  describe ".find" do
    let(:id)            { '12' }
    let(:request_url)   { 'https://foobar.com/dummy/12' }
    let(:headers)       { { "Accept"=>"application/json" } }
    let(:response_mock) { double('response', success?: false).as_null_object }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock } }

    it "uses the HTTP GET method" do
      expect(Typhoeus::Request).to receive(:get).and_call_original
      dummy_class.find id
    end

    it "uses the id in the request url" do
      expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy/12', headers: headers).and_call_original
      dummy_class.find id
    end

    it "uses the connection_options headers as request headers" do
      expect(Typhoeus::Request).to receive(:get).with(request_url, headers: { "Accept"=>"application/json" }).and_call_original
      dummy_class.find id
    end

    context "when custom connection_options are given" do
      it "uses the custom connection_options" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy/12.json', headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy_class.find(id, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the connection_options headers with custom connection_options default_headers" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy/12.json', headers: { "Baz" => "Bar" }).and_call_original
        dummy_class.find(id, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "when the response is a success" do
      let(:response_body)   { '{"id":"12"}' }
      let(:parsed_response) { JSON.parse response_body }
      let(:response_mock)   { double('response', success?: true, body: response_body) }

      it "instantiates the resource with the parsed response body" do
        expect(dummy_class).to receive(:new).with(parsed_response)
        dummy_class.find id
      end

      it "returns the instantiated resource" do
        expect(dummy_class.find(id).id).to eql '12'
      end
    end

    context "when the response is NOT a success" do
      let(:response_mock) { double('response', success?: false) }

      it "does NOT instantiate the resource" do
        expect(dummy_class).not_to receive(:new)
        dummy_class.find id
      end

      it "returns nil" do
        expect(dummy_class.find '15').to be_nil
      end
    end
  end

  describe ".find_by" do
    let(:params) { { id: '12' } }

    it "calls .get" do
      expect(dummy_class).to receive(:get).with(params, {})
      dummy_class.find_by params
    end

    context "when custom connection_options are given" do
      let(:custom_connection_options) do
        {
          content_type: '.xml',
          headers: { "Foo" => "Bar" }
        }
      end

      it "passes the custom connection_options as Hash to the .get" do
        expect(dummy_class).to receive(:get).with(params, custom_connection_options)
        dummy_class.find_by params, custom_connection_options
      end
    end

    context "when NO custom connection_options are given" do
      it "passes the connection_options as empty Hash to the .get" do
        expect(dummy_class).to receive(:get).with(params, {})
        dummy_class.find_by params
      end
    end

    context "root_element" do
      context "when the given custom connection_options contain a root_element" do
        let(:custom_connection_options) { { root_element: :foobar } }

        it "packs the params in the root_element and calls the .get" do
          expect(dummy_class).to receive(:get).with({ 'foobar' => { id: '12' } }, custom_connection_options)
          dummy_class.find_by params, custom_connection_options
        end
      end

      context "when the connection_options contain a root_element" do
        before { dummy_class.connection_options.merge root_element: :foobar  }

        it "packs the params in the root_element and calls the .get" do
          expect(dummy_class).to receive(:get).with({ 'foobar' => { id: '12' } }, {})
          dummy_class.find_by params
        end
      end

      context "when NO root_element is specified" do
        before { dummy_class.connection_options.merge root_element: nil  }

        it "does NOT pack the params in a root_element and calls the .get" do
          expect(dummy_class).to receive(:get).with({ id: '12' }, {})
          dummy_class.find_by params
        end
      end
    end

    context "when the response is a success" do
      let(:parsed_response) { { id: '12', foo: 'bar' } }

      before { allow(dummy_class).to receive(:get) { parsed_response } }

      it "instantiate the resource with the parsed response" do
        expect(dummy_class).to receive(:new).with parsed_response
        dummy_class.find_by params
      end

      it "returns the instantiated resource" do
        expect(dummy_class.find_by(params).id).to eql '12'
      end
    end

    context "when the response is NOT a success" do
      before { allow(dummy_class).to receive(:get) { nil } }

      it "instantiate with a empty Hash" do
        expect(dummy_class).to receive(:new).with({})
        dummy_class.find_by params
      end

      it "returns the instantiated resource" do
        expect(dummy_class.find_by(params).id).to be_nil
      end
    end
  end

  describe ".get" do
    let(:attributes)    { { foo: 'bar' } }
    let(:headers)       { { "Accept" => "application/json" } }
    let(:response_mock) { double('response', success?: false).as_null_object }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock } }

    it "uses the HTTP GET method" do
      expect(Typhoeus::Request).to receive(:get).and_call_original
      dummy_class.get attributes
    end

    it "uses the attributes as request body" do
      expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy', body: { foo: 'bar' }, headers: headers).and_call_original
      dummy_class.get attributes
    end

    it "uses the headers as request headers" do
      expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy', body: attributes, headers: { "Accept" => "application/json" }).and_call_original
      dummy_class.get attributes
    end

    context "when connection_options are given" do
      it "uses the connection_options" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy.json', body: attributes, headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy_class.get(attributes, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the headers with default_headers" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy.json', body: attributes, headers: { "Baz" => "Bar" }).and_call_original
        dummy_class.get(attributes, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "when response is a success" do
      let(:response_mock)   { double('response', success?: true, body: response_body) }

      context "and a root_element is defined" do
        let(:response_body) { '{"foobar":{"id":"12"}}' }
        let(:parsed_response) { JSON.parse(response_body)["foobar"] }

        before { dummy_class.root_element = :foobar }
        after  { dummy_class.root_element = nil }

        it "returns the unpacked and parsed response body from the root_element" do
          expect(dummy_class.get attributes).to eql({ "id" => "12" })
        end
      end

      context "and NO root_element is defined" do
        let(:response_body)   { '{"id":"12"}' }
        let(:parsed_response) { JSON.parse response_body }

        before { dummy_class.root_element = nil }

        it "returns the parsed response body from the root_element" do
          expect(dummy_class.get attributes).to eql({ "id" => "12" })
        end
      end
    end

    context "when a response is NOT a success" do
      let(:response_mock) { double('response', success?: false) }

      it "returns nil" do
        expect(dummy_class.get(attributes)).to be_nil
      end
    end
  end

  describe "#connection_options" do
    it "instanties as a RemoteResource::ConnectionOptions" do
      expect(dummy.connection_options).to be_a RemoteResource::ConnectionOptions
    end

    it "uses the implemented class as base_class" do
      expect(dummy.connection_options.base_class).to be RemoteResource::Dummy
    end
  end

  describe "#persisted?" do
    context "when id is present" do
      it "returns true" do
        dummy.id = 10
        expect(dummy.persisted?).to be_truthy
      end
    end

    context "when is is NOT present" do
      it "returns false" do
        expect(dummy.persisted?).to be_falsey
      end
    end
  end

  describe "#new_record?" do
    context "when instance persisted" do
      it "returns false" do
        allow(dummy).to receive(:persisted?) { true }

        expect(dummy.new_record?).to be_falsey
      end
    end

    context "when instance does NOT persist" do
      it "returns true" do
        allow(dummy).to receive(:persisted?) { false }

        expect(dummy.new_record?).to be_truthy
      end
    end
  end

  describe "#save" do
    let(:params) { dummy.params }

    before { allow(dummy).to receive(:post) }

    it "calls #create_or_update" do
      expect(dummy).to receive(:create_or_update).with({ foo: 'bar' }, {}).and_call_original
      dummy.save
    end

    context "when connection_options are given" do
      let(:custom_connection_options) do
        {
            content_type: '.xml',
            headers: { "Foo" => "Bar" }
        }
      end

      it "passes the connection_options to the #create_or_update" do
        expect(dummy).to receive(:create_or_update).with(params, custom_connection_options).and_call_original
        dummy.save custom_connection_options
      end
    end

    context "when NO connection_options are given" do
      it "passes the connection_options as empty Hash to the #create_or_update" do
        expect(dummy).to receive(:create_or_update).with(params, {}).and_call_original
        dummy.save
      end
    end
  end

  describe "#create_or_update" do
    context "when the attributes contain an id" do
      let(:attributes) { { id: 10, foo: 'bar' } }

      context "and a root_element is defined" do
        it "packs the attributes in the root_element and calls #patch" do
          dummy_class.root_element = :foobar

          expect(dummy).to receive(:patch).with({ 'foobar' => { id: 10, foo: 'bar' } }, {})
          dummy.create_or_update attributes

          dummy_class.root_element = nil
        end
      end

      context "and NO root_element is defined" do
        it "does NOT pack the attributes in the root_element and calls #patch" do
          dummy_class.root_element = nil

          expect(dummy).to receive(:patch).with({ id: 10, foo: 'bar' }, {})
          dummy.create_or_update attributes
        end
      end

      context "and connection_options are given" do
        let(:custom_connection_options) do
          {
              content_type: '.xml',
              headers: { "Foo" => "Bar" }
          }
        end

        it "passes the connection_options to the #patch" do
          expect(dummy).to receive(:patch).with(attributes, custom_connection_options)
          dummy.create_or_update attributes, custom_connection_options
        end
      end

      context "and NO connection_options are given" do
        it "passes the connection_options as empty Hash to the #patch" do
          expect(dummy).to receive(:patch).with(attributes, {})
          dummy.create_or_update attributes
        end
      end
    end

    context "when the attributes DON'T contain an id" do
      let(:attributes) { { foo: 'bar' } }

      context "and a root_element is defined" do
        it "packs the attributes in the root_element and calls #post" do
          dummy_class.root_element = :foobar

          expect(dummy).to receive(:post).with({ 'foobar' => { foo: 'bar' } }, {})
          dummy.create_or_update attributes

          dummy_class.root_element = nil
        end
      end

      context "and NO root_element is defined" do
        it "does NOT pack the attributes in the root_element and calls #post" do
          dummy_class.root_element = nil

          expect(dummy).to receive(:post).with({ foo: 'bar' }, {})
          dummy.create_or_update attributes
        end
      end

      context "and connection_options are given" do
        let(:custom_connection_options) do
          {
              content_type: '.xml',
              headers: { "Foo" => "Bar" }
          }
        end

        it "passes the connection_options to the #post" do
          expect(dummy).to receive(:post).with(attributes, custom_connection_options)
          dummy.create_or_update attributes, custom_connection_options
        end
      end

      context "and NO connection_options are given" do
        it "passes the connection_options as empty Hash to the #post" do
          expect(dummy).to receive(:post).with(attributes, {})
          dummy.create_or_update attributes
        end
      end
    end
  end

  describe "#post" do
    let(:attributes)    { { foo: 'bar' } }
    let(:headers)       { { "Accept"=>"application/json" } }
    let(:response_mock) { double('response').as_null_object }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock } }

    it "uses the HTTP POST method" do
      expect(Typhoeus::Request).to receive(:post).and_call_original
      dummy.post attributes
    end

    it "uses the attributes as request body" do
      expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/dummy', body: { foo: 'bar' }, headers: headers).and_call_original
      dummy.post attributes
    end

    it "uses the headers as request headers" do
      expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/dummy', body: attributes, headers: { "Accept"=>"application/json" }).and_call_original
      dummy.post attributes
    end

    context "when connection_options are given" do
      it "uses the connection_options" do
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/dummy.json', body: attributes, headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy.post(attributes, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the headers with default_headers" do
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/dummy.json', body: attributes, headers: { "Baz" => "Bar" }).and_call_original
        dummy.post(attributes, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "when response is a success" do
      let(:response_mock) { double('response', success?: true) }

      it "returns true" do
        expect(dummy.post attributes).to be_truthy
      end
    end

    context "when response is NOT a success" do
      context "and the response_code is 422" do
        let(:response_mock) { double('response', success?: false, response_code: 422, body: response_body) }

        context "and a root_element is defined" do
          let(:response_body) { '{"foobar":{"errors":{"foo":["is required"]}}}' }

          before { dummy_class.root_element = :foobar }
          after { dummy_class.root_element = nil }

          it "returns false" do
            expect(dummy.post attributes).to be_falsey
          end

          it "finds the errors in the response body and assigns the errors" do
            dummy.post attributes
            expect(dummy.errors.messages).to eql foo: ["is required"]
          end
        end

        context "and NO root_element is defined" do
          let(:response_body) { '{"errors":{"foo":["is required"]}}' }

          before { dummy_class.root_element = nil }

          it "returns false" do
            expect(dummy.post attributes).to be_falsey
          end

          it "finds the errors in the response body and assigns the errors" do
            dummy.post attributes
            expect(dummy.errors.messages).to eql foo: ["is required"]
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
    let(:request_url)   { 'https://foobar.com/dummies/10' }
    let(:attributes)    { { id: 10, foo: 'bar' } }
    let(:headers)       { { "Accept"=>"application/json" } }
    let(:response_mock) { double('response').as_null_object }

    before do
      dummy.id = 10
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

    it "uses the headers as request headers" do
      expect(Typhoeus::Request).to receive(:patch).with(request_url, body: attributes, headers: { "Accept"=>"application/json" }).and_call_original
      dummy.patch attributes
    end

    context "when connection_options are given" do
      it "uses the connection_options" do
        expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/dummies/10.json', body: attributes, headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy.patch(attributes, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the headers with default_headers" do
        expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/dummies/10.json', body: attributes, headers: { "Baz" => "Bar" }).and_call_original
        dummy.patch(attributes, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "when .collection is set truthy" do
      it "uses the id in the request url" do
        dummy_class.collection = true

        expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/dummies/10', body: attributes, headers: headers).and_call_original
        dummy.patch attributes

        dummy_class.collection = false
      end
    end

    context "when .collection is set falsely" do
      it "does NOT use the id in the request url" do
        dummy_class.collection = false

        expect(Typhoeus::Request).to receive(:patch).with('https://foobar.com/dummy', body: attributes, headers: headers).and_call_original
        dummy.patch attributes

        dummy_class.collection = true
      end
    end

    context "when response is a success" do
      let(:response_mock) { double('response', success?: true) }

      it "returns true" do
        expect(dummy.patch attributes).to be_truthy
      end
    end

    context "when response is NOT a success" do
      context "and the response_code is 422" do
        let(:response_mock) { double('response', success?: false, response_code: 422, body: response_body) }

        context "and a root_element is defined" do
          let(:response_body) { '{"foobar":{"errors":{"foo":["is required"]}}}' }

          before { dummy_class.root_element = :foobar }
          after { dummy_class.root_element = nil }

          it "returns false" do
            expect(dummy.patch attributes).to be_falsey
          end

          it "finds the errors in the response body and assigns the errors" do
            dummy.patch attributes
            expect(dummy.errors.messages).to eql foo: ["is required"]
          end
        end

        context "and NO root_element is defined" do
          let(:response_body) { '{"errors":{"foo":["is required"]}}' }

          before { dummy_class.root_element = nil }

          it "returns false" do
            expect(dummy.patch attributes).to be_falsey
          end

          it "finds the errors in the response body and assigns the errors" do
            dummy.patch attributes
            expect(dummy.errors.messages).to eql foo: ["is required"]
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

  describe "#assign_errors" do
    let(:error_data) { JSON.parse json_error_data }

    context "when a root_element is defined" do
      let(:json_error_data) { '{"foobar":{"errors":{"foo":["is required"]}}}' }

      it "assigns the errors within the root_element" do
        dummy_class.root_element = :foobar

        dummy.send :assign_errors, error_data
        expect(dummy.errors.messages).to eql foo: ["is required"]

        dummy_class.root_element = nil
      end
    end

    context "when NO root_element is defined" do
      let(:json_error_data) { '{"errors":{"foo":["is required"]}}' }

      it "assigns the errors without the root_element" do
        dummy.send :assign_errors, error_data
        expect(dummy.errors.messages).to eql foo: ["is required"]
      end
    end
  end

end

