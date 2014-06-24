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

  describe "attributes" do
    it "#id" do
      expect(dummy.attributes).to have_key :id
    end
  end

  describe ".app_host" do
    context "when the env is given as an argument" do
      it "uses the host specified in the application CONFIG for the given env" do
        stub_const("CONFIG", { development: { apps: { dummy: 'https://foobar.development.com' } } })

        expect(dummy_class.app_host 'dummy', 'development').to eql 'https://foobar.development.com'
      end
    end

    context "when the env is NOT given as an argument" do
      it "uses the host specified in the application CONFIG" do
        stub_const("CONFIG", { test: { apps: { dummy: 'https://foobar.test.com' } } })

        expect(dummy_class.app_host 'dummy').to eql 'https://foobar.test.com'
      end
    end
  end

  describe ".base_url" do
    context "without additional options" do
      it "returns the url" do
        expect(dummy_class.base_url).to eql 'https://foobar.com/dummy'
      end
    end

    context "with additional options" do
      context ".path_prefix" do
        it "returns the url with the path_prefix" do
          dummy_class.path_prefix = '/api/v2'

          expect(dummy_class.base_url).to eql 'https://foobar.com/api/v2/dummy'

          dummy_class.path_prefix = nil
        end
      end

      context ".path_postfix" do
        it "returns the url with the path_postfix" do
          dummy_class.path_postfix = '/refresh'

          expect(dummy_class.base_url).to eql 'https://foobar.com/dummy/refresh'

          dummy_class.path_postfix = nil
        end
      end
    end
  end

  describe ".url_safe_relative_name" do
    context "when .collection is set truthy" do
      it "returns the url for a plural resource" do
        dummy_class.collection = true

        expect(dummy_class.base_url).to eql 'https://foobar.com/dummies'

        dummy_class.collection = nil
      end
    end

    context "when .collection is set falsely" do
      it "returns the url for a singular resource" do
        dummy_class.collection = false

        expect(dummy_class.base_url).to eql 'https://foobar.com/dummy'

        dummy_class.collection = nil
      end
    end
  end

  describe ".relative_name" do
    context "when .collection_name is specified" do
      it "returns the relative name of the class without the module" do
        expect(dummy_class.relative_name).not_to eql 'RemoteResource::Dummy'
        expect(dummy_class.relative_name).to eql 'Dummy'
      end
    end

    context "when .collection_name is NOT specified" do
      it "returns the .collection_name" do
        dummy_class.collection_name = :crash_dummy

        expect(dummy_class.relative_name).to eql 'crash_dummy'

        dummy_class.collection_name = nil
      end
    end
  end

  describe ".use_relative_model_naming?" do
    it "returns true" do
      expect(dummy_class.use_relative_model_naming?).to be_true
    end
  end

  describe ".connection" do
    it "uses Typhoeus::Request" do
      expect(dummy_class.connection).to eql Typhoeus::Request
    end
  end

  describe ".find" do
    let(:id)            { '12' }
    let(:headers)       { { "Accept"=>"application/json" } }
    let(:response_mock) { double('response', success?: false).as_null_object }

    before { Typhoeus::Request.any_instance.stub(:run) { response_mock } }

    it "uses the HTTP GET method" do
      Typhoeus::Request.should_receive(:get).and_call_original
      dummy_class.find id
    end

    it "uses the id as request url" do
      Typhoeus::Request.should_receive(:get).with('https://foobar.com/dummy/12', headers: headers).and_call_original
      dummy_class.find id
    end

    it "uses the headers as request headers" do
      Typhoeus::Request.should_receive(:get).with('https://foobar.com/dummy/12', headers: { "Accept"=>"application/json" }).and_call_original
      dummy_class.find id
    end

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        Typhoeus::Request.should_receive(:get).with('https://foobar.com/dummy/12.json', headers: headers).and_call_original
        dummy_class.find id

        dummy_class.content_type = nil
      end
    end

    context "when response is a success" do
      let(:response_body)   { '{"id":"12"}' }
      let(:parsed_response) { JSON.parse response_body }
      let(:response_mock)   { double('response', success?: true, body: response_body) }

      it "instantiates the resource with the parsed response body" do
        dummy_class.should_receive(:new).with(parsed_response).and_call_original
        dummy_class.find id
      end

      it "returns the instantiated resource" do
        expect(dummy_class.find(id).id).to eql '12'
      end
    end

    context "when a response is NOT a success" do
      let(:response_mock) { double('response', success?: false) }

      it "does NOT instantiate the resource" do
        dummy_class.should_not_receive(:new)
        dummy_class.find id
      end

      it "returns nil" do
        expect(dummy_class.find '15').to be_nil
      end
    end
  end

  describe ".find_by" do
    let(:params) { { id: '12' } }

    context "when a root_element is defined" do
      it "packs the params in the root_element and calls the .get" do
        dummy_class.root_element = :foobar

        dummy_class.should_receive(:get).with({ 'foobar' => { id: '12' } })
        dummy_class.find_by params

        dummy_class.root_element = nil
      end
    end

    context "when NO root_element is defined" do
      it "does NOT pack the params in the root_element and calls the .get" do
        dummy_class.root_element = nil

        dummy_class.should_receive(:get).with({ id: '12' })
        dummy_class.find_by params
      end
    end
  end

  describe ".get" do
    let(:attributes)    { { foo: 'bar' } }
    let(:headers)       { { "Accept"=>"application/json" } }
    let(:response_mock) { double('response', success?: false).as_null_object }

    before { Typhoeus::Request.any_instance.stub(:run) { response_mock } }

    it "uses the HTTP GET method" do
      Typhoeus::Request.should_receive(:get).and_call_original
      dummy_class.get attributes
    end

    it "uses the attributes as request body" do
      Typhoeus::Request.should_receive(:get).with('https://foobar.com/dummy', body: { foo: 'bar' }, headers: headers).and_call_original
      dummy_class.get attributes
    end

    it "uses the headers as request headers" do
      Typhoeus::Request.should_receive(:get).with('https://foobar.com/dummy', body: attributes, headers: { "Accept"=>"application/json" }).and_call_original
      dummy_class.get attributes
    end

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        Typhoeus::Request.should_receive(:get).with('https://foobar.com/dummy.json', body: attributes, headers: headers).and_call_original
        dummy_class.get attributes

        dummy_class.content_type = nil
      end
    end

    context "when response is a success" do
      let(:response_mock)   { double('response', success?: true, body: response_body) }

      context "and a root_element is defined" do
        let(:response_body) { '{"foobar":{"id":"12"}}' }
        let(:parsed_response) { JSON.parse(response_body)["foobar"] }

        before { dummy_class.root_element = :foobar }
        after   { dummy_class.root_element = nil }

        it "unpacks the response body from the root_element and instantiates the resource with the parsed response body" do
          dummy_class.should_receive(:new).with(parsed_response).and_call_original
          dummy_class.get attributes
        end

        it "returns the instantiated resource" do
          expect(dummy_class.get(attributes).id).to eql '12'
        end
      end

      context "and NO root_element is defined" do
        let(:response_body)   { '{"id":"12"}' }
        let(:parsed_response) { JSON.parse response_body }

        before { dummy_class.root_element = nil }

        it "does NOT unpack the response body from the root_element and instantiates the resource with the parsed response body" do
          dummy_class.should_receive(:new).with(parsed_response).and_call_original
          dummy_class.get attributes
        end

        it "returns the instantiated resource" do
          expect(dummy_class.get(attributes).id).to eql '12'
        end
      end
    end

    context "when a response is NOT a success" do
      let(:response_mock) { double('response', success?: false) }

      it "does NOT instantiate the resource" do
        dummy_class.should_not_receive(:new)
        dummy_class.get attributes
      end

      it "returns nil" do
        expect(dummy_class.get(attributes)).to be_nil
      end
    end
  end

  describe "#persisted?" do
    context "when id is present" do
      it "returns true" do
        dummy.id = 10
        expect(dummy.persisted?).to be_true
      end
    end

    context "when is is NOT present" do
      it "returns false" do
        expect(dummy.persisted?).to be_false
      end
    end
  end

  describe "#new_record?" do
    context "when instance persisted" do
      it "returns false" do
        dummy.stub(:persisted?) { true }

        expect(dummy.new_record?).to be_false
      end
    end

    context "when instance does NOT persist" do
      it "returns true" do
        dummy.stub(:persisted?) { false }

        expect(dummy.new_record?).to be_true
      end
    end
  end

  describe "#save" do
    before { dummy.stub(:post) }

    it "calls #create_or_update" do
      dummy.should_receive(:create_or_update).with({ foo: 'bar' }).and_call_original
      dummy.save
    end
  end

  describe "#create_or_update" do
    context "when the attributes contain an id" do
      context "and a root_element is defined" do
        it "packs the attributes in the root_element and calls #patch" do
          dummy_class.root_element = :foobar

          dummy.should_receive(:patch).with({ 'foobar' => { id: 10, foo: 'bar' } })
          dummy.create_or_update id: 10, foo: 'bar'

          dummy_class.root_element = nil
        end
      end

      context "and NO root_element is defined" do
        it "does NOT pack the attributes in the root_element and calls #patch" do
          dummy_class.root_element = nil

          dummy.should_receive(:patch).with({ id: 10, foo: 'bar' })
          dummy.create_or_update id: 10, foo: 'bar'
        end
      end
    end

    context "when the attributes DON'T contain an id" do
      context "and a root_element is defined" do
        it "packs the attributes in the root_element and calls #post" do
          dummy_class.root_element = :foobar

          dummy.should_receive(:post).with({ 'foobar' => { foo: 'bar' } })
          dummy.create_or_update foo: 'bar'

          dummy_class.root_element = nil
        end
      end

      context "and NO root_element is defined" do
        it "does NOT pack the attributes in the root_element and calls #post" do
          dummy_class.root_element = nil

          dummy.should_receive(:post).with({ foo: 'bar' })
          dummy.create_or_update foo: 'bar'
        end
      end
    end
  end

  describe "#post" do
    let(:attributes)    { { foo: 'bar' } }
    let(:headers)       { { "Accept"=>"application/json" } }
    let(:response_mock) { double('response').as_null_object }

    before { Typhoeus::Request.any_instance.stub(:run) { response_mock } }

    it "uses the HTTP POST method" do
      Typhoeus::Request.should_receive(:post).and_call_original
      dummy.post attributes
    end

    it "uses the attributes as request body" do
      Typhoeus::Request.should_receive(:post).with('https://foobar.com/dummy', body: { foo: 'bar' }, headers: headers).and_call_original
      dummy.post attributes
    end

    it "uses the headers as request headers" do
      Typhoeus::Request.should_receive(:post).with('https://foobar.com/dummy', body: attributes, headers: { "Accept"=>"application/json" }).and_call_original
      dummy.post attributes
    end

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        Typhoeus::Request.should_receive(:post).with('https://foobar.com/dummy.json', body: attributes, headers: headers).and_call_original
        dummy.post attributes

        dummy_class.content_type = nil
      end
    end

    context "when response is a success" do
      let(:response_mock) { double('response', success?: true) }

      it "returns true" do
        expect(dummy.post attributes).to be_true
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
            expect(dummy.post attributes).to be_false
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
            expect(dummy.post attributes).to be_false
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
          expect(dummy.post attributes).to be_false
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
      Typhoeus::Request.any_instance.stub(:run) { response_mock }
    end

    before { dummy_class.collection = true }
    after { dummy_class.collection = false }

    it "uses the HTTP PATCH method" do
      Typhoeus::Request.should_receive(:patch).and_call_original
      dummy.patch attributes
    end

    it "uses the attributes as request body" do
      Typhoeus::Request.should_receive(:patch).with(request_url, body: { id: 10, foo: 'bar' }, headers: headers).and_call_original
      dummy.patch attributes
    end

    it "uses the headers as request headers" do
      Typhoeus::Request.should_receive(:patch).with(request_url, body: attributes, headers: { "Accept"=>"application/json" }).and_call_original
      dummy.patch attributes
    end

    context "when .collection is set truthy" do
      it "uses the id in the request url" do
        dummy_class.collection = true

        Typhoeus::Request.should_receive(:patch).with('https://foobar.com/dummies/10', body: attributes, headers: headers).and_call_original
        dummy.patch attributes

        dummy_class.collection = false
      end
    end

    context "when .collection is set falsely" do
      it "does NOT use the id in the request url" do
        dummy_class.collection = false

        Typhoeus::Request.should_receive(:patch).with('https://foobar.com/dummy', body: attributes, headers: headers).and_call_original
        dummy.patch attributes

        dummy_class.collection = true
      end
    end

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        Typhoeus::Request.should_receive(:patch).with("#{request_url}.json", body: attributes, headers: headers).and_call_original
        dummy.patch attributes

        dummy_class.content_type = nil
      end
    end

    context "when response is a success" do
      let(:response_mock) { double('response', success?: true) }

      it "returns true" do
        expect(dummy.patch attributes).to be_true
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
            expect(dummy.patch attributes).to be_false
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
            expect(dummy.patch attributes).to be_false
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
          expect(dummy.patch attributes).to be_false
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

