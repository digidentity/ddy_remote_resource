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
    let(:options) { [:base_url, :site, :headers, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element] }

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

    it "sets the name of Thread variable with the implemented class" do
      expect(dummy_class.connection_options).to eql Thread.current['remote_resource.dummy.connection_options']
    end
  end

  describe ".with_connection_options" do
    let(:connection_options) { {} }

    let(:block_with_connection_options) do
      dummy_class.with_connection_options(connection_options) do
        dummy_class.find_by({ username: 'foobar' }, { content_type: '.json' })
        dummy_class.find_by({ username: 'bazbar' }, { content_type: '.xml' })
      end
    end

    let(:response_mock) { double('response', success?: false).as_null_object }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock } }

    it "yields the block" do
      expect(dummy_class).to receive(:find_by).with({ username: 'foobar' }, { content_type: '.json' }).and_call_original
      expect(dummy_class).to receive(:find_by).with({ username: 'bazbar' }, { content_type: '.xml' }).and_call_original
      block_with_connection_options
    end

    it "ensures to set the connection_options Thread variable to nil" do
      dummy_class.connection_options

      expect{ block_with_connection_options }.to change{ Thread.current['remote_resource.dummy.connection_options'] }.from(an_instance_of(RemoteResource::ConnectionOptions)).to nil
    end

    context "when the connection_options contain the headers" do
      let(:connection_options) do
        {
          headers: { "Foo" => "Bar" }
        }
      end

      it "uses the connection_options which are set in the block AND on the class method" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy.json', params: { username: 'foobar' }, headers: { "Accept" => "application/json", "Foo" => "Bar" }).and_call_original
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy.xml', params: { username: 'bazbar' }, headers: { "Accept" => "application/json", "Foo" => "Bar" }).and_call_original
        block_with_connection_options
      end
    end

    context "when NO headers are specified in the connection_options" do
      let(:connection_options) do
        {
          base_url: 'https://api.foobar.eu/dummy'
        }
      end

      it "uses the connection_options which are set in the block AND on the class method" do
        expect(Typhoeus::Request).to receive(:get).with('https://api.foobar.eu/dummy.json', params: { username: 'foobar' }, headers: { "Accept" => "application/json" }).and_call_original
        expect(Typhoeus::Request).to receive(:get).with('https://api.foobar.eu/dummy.xml', params: { username: 'bazbar' }, headers: { "Accept" => "application/json" }).and_call_original
        block_with_connection_options
      end
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

    it "assigns the _response" do
      allow(dummy_class).to receive(:get) { { _response: RemoteResource::Response.new(double('response')) } }

      expect(dummy_class.find_by(params)._response).to be_a RemoteResource::Response
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
          expect(dummy_class.send :determined_request_url, {}, 12).to eql 'https://foobar.com/dummy/12'
        end
      end

      context "when the id is NOT given" do
        it "does NOT use the id for the request_url" do
          expect(dummy_class.send :determined_request_url).to eql 'https://foobar.com/dummy'
        end
      end
    end

    context "content_type" do
      context "when the given custom connection_options contain a content_type" do
        let(:custom_connection_options) { { content_type: '.xml' } }

        it "uses the content_type for the request_url" do
          expect(dummy_class.send :determined_request_url, custom_connection_options).to eql 'https://foobar.com/dummy.xml'
        end
      end

      context "when the connection_options contain a content_type" do
        before { dummy_class.connection_options.merge content_type: '.xml' }
        after  { dummy_class.connection_options.reload }

        it "uses the content_type for the request_url" do
          expect(dummy_class.send :determined_request_url).to eql 'https://foobar.com/dummy.xml'
        end
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

    before { allow(dummy).to receive(:create_or_update) }

    it "calls #create_or_update" do
      expect(dummy).to receive(:create_or_update).with(params, {})
      dummy.save
    end

    context "when custom connection_options are given" do
      let(:custom_connection_options) do
        {
          content_type: '.xml',
          headers: { "Foo" => "Bar" }
        }
      end

      it "passes the custom connection_options as Hash to the #create_or_update" do
        expect(dummy).to receive(:create_or_update).with(params, custom_connection_options)
        dummy.save custom_connection_options
      end
    end

    context "when NO custom connection_options are given" do
      it "passes the connection_options as empty Hash to the #create_or_update" do
        expect(dummy).to receive(:create_or_update).with(params, {})
        dummy.save
      end
    end
  end

  describe "#create_or_update" do
    context "when the attributes contain an id" do
      let(:attributes) { { id: 10, foo: 'bar' } }

      context "and custom connection_options are given" do
        let(:custom_connection_options) do
          {
            content_type: '.xml',
            headers: { "Foo" => "Bar" }
          }
        end

        it "passes the custom connection_options as Hash to the #patch" do
          expect(dummy).to receive(:patch).with(attributes, custom_connection_options)
          dummy.create_or_update attributes, custom_connection_options
        end
      end

      context "and NO custom connection_options are given" do
        it "passes the connection_options as empty Hash to the #patch" do
          expect(dummy).to receive(:patch).with(attributes, {})
          dummy.create_or_update attributes
        end
      end

      context "root_element" do
        context "and the given custom connection_options contain a root_element" do
          let(:custom_connection_options) { { root_element: :foobar } }

          it "packs the attributes in the root_element and calls the #patch" do
            expect(dummy).to receive(:patch).with({ 'foobar' => { id: 10, foo: 'bar' } }, custom_connection_options)
            dummy.create_or_update attributes, custom_connection_options
          end
        end

        context "and the connection_options contain a root_element" do
          before { dummy.connection_options.merge root_element: :foobar  }

          it "packs the attributes in the root_element and calls the #patch" do
            expect(dummy).to receive(:patch).with({ 'foobar' => { id: 10, foo: 'bar' } }, {})
            dummy.create_or_update attributes
          end
        end

        context "and NO root_element is specified" do
          before { dummy_class.connection_options.merge root_element: nil  }

          it "does NOT pack the attributes in a root_element and calls the #patch" do
            expect(dummy).to receive(:patch).with({ id: 10, foo: 'bar' }, {})
            dummy.create_or_update attributes
          end
        end
      end
    end

    context "when the attributes DON'T contain an id" do
      let(:attributes) { { foo: 'bar' } }

      context "and custom connection_options are given" do
        let(:custom_connection_options) do
          {
              content_type: '.xml',
              headers: { "Foo" => "Bar" }
          }
        end

        it "passes the custom connection_options as Hash to the #post" do
          expect(dummy).to receive(:post).with(attributes, custom_connection_options)
          dummy.create_or_update attributes, custom_connection_options
        end
      end

      context "and NO custom connection_options are given" do
        it "passes the connection_options as empty Hash to the #post" do
          expect(dummy).to receive(:post).with(attributes, {})
          dummy.create_or_update attributes
        end
      end

      context "root_element" do
        context "and the given custom connection_options contain a root_element" do
          let(:custom_connection_options) { { root_element: :foobar } }

          it "packs the attributes in the root_element and calls the #post" do
            expect(dummy).to receive(:post).with({ 'foobar' => { foo: 'bar' } }, custom_connection_options)
            dummy.create_or_update attributes, custom_connection_options
          end
        end

        context "and the connection_options contain a root_element" do
          before { dummy.connection_options.merge root_element: :foobar  }

          it "packs the attributes in the root_element and calls the #post" do
            expect(dummy).to receive(:post).with({ 'foobar' => { foo: 'bar' } }, {})
            dummy.create_or_update attributes
          end
        end

        context "and NO root_element is specified" do
          before { dummy_class.connection_options.merge root_element: nil  }

          it "does NOT pack the attributes in a root_element and calls the #post" do
            expect(dummy).to receive(:post).with({ foo: 'bar' }, {})
            dummy.create_or_update attributes
          end
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
            expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/dummy/12'
          end
        end

        context "and the id is NOT present" do
          it "calls .determined_request_url" do
            expect(dummy_class).to receive(:determined_request_url).with(connection_options)
            dummy.send :determined_request_url, connection_options
          end

          it "does NOT use the id for the request_url" do
            expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/dummy'
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
          expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/dummy'
        end
      end
    end
  end

  describe "#assign_errors" do
    let(:error_data) { JSON.parse json_error_data }

    context "when a root_element is given" do
      let(:json_error_data) { '{"foobar":{"errors":{"foo":["is required"]}}}' }

      it "assigns the errors within the root_element" do
        dummy.send :assign_errors, error_data, :foobar
        expect(dummy.errors.messages).to eql foo: ["is required"]
      end
    end

    context "when NO root_element is given" do
      let(:json_error_data) { '{"errors":{"foo":["is required"]}}' }

      it "assigns the errors without the root_element" do
        dummy.send :assign_errors, error_data
        expect(dummy.errors.messages).to eql foo: ["is required"]
      end
    end
  end

end

