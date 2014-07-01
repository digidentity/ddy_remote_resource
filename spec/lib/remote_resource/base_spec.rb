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

  describe ".find" do
    let(:id)            { '12' }
    let(:headers)       { { "Accept"=>"application/json" } }
    let(:response_mock) { double('response', success?: false).as_null_object }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock } }

    it "uses the HTTP GET method" do
      expect(Typhoeus::Request).to receive(:get).and_call_original
      dummy_class.find id
    end

    it "uses the id as request url" do
      expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy/12', headers: headers).and_call_original
      dummy_class.find id
    end

    it "uses the headers as request headers" do
      expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy/12', headers: { "Accept"=>"application/json" }).and_call_original
      dummy_class.find id
    end

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy/12.json', headers: headers).and_call_original
        dummy_class.find id

        dummy_class.content_type = nil
      end
    end

    context "when response is a success" do
      let(:response_body)   { '{"id":"12"}' }
      let(:parsed_response) { JSON.parse response_body }
      let(:response_mock)   { double('response', success?: true, body: response_body) }

      it "instantiates the resource with the parsed response body" do
        expect(dummy_class).to receive(:new).with(parsed_response).and_call_original
        dummy_class.find id
      end

      it "returns the instantiated resource" do
        expect(dummy_class.find(id).id).to eql '12'
      end
    end

    context "when a response is NOT a success" do
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

    context "when a root_element is defined" do
      before { dummy_class.root_element = :foobar }
      after  { dummy_class.root_element = nil }

      it "packs the params in the root_element and calls the .get" do
        expect(dummy_class).to receive(:get).with({ 'foobar' => { id: '12' } })
        dummy_class.find_by params
      end

      it "instanties the resource with the response" do
        allow(dummy_class).to receive(:get) { { id: '12' } }

        expect(dummy_class).to receive(:new).with({ id: '12' })
        dummy_class.find_by params
      end
    end

    context "when NO root_element is defined" do
      before { dummy_class.root_element = nil }

      it "does NOT pack the params in the root_element and calls the .get" do
        expect(dummy_class).to receive(:get).with({ id: '12' })
        dummy_class.find_by params
      end

      it "instanties the resource with the response" do
        allow(dummy_class).to receive(:get) { { id: '12' } }

        expect(dummy_class).to receive(:new).with({ id: '12' })
        dummy_class.find_by params
      end
    end

    context "when the response returns nil" do
      it "instanties with a empty Hash" do
        allow(dummy_class).to receive(:get) { nil }

        expect(dummy_class).to receive(:new).with({})
        dummy_class.find_by params
      end
    end
  end

  describe ".get" do
    let(:attributes)    { { foo: 'bar' } }
    let(:headers)       { { "Accept"=>"application/json" } }
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
      expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy', body: attributes, headers: { "Accept"=>"application/json" }).and_call_original
      dummy_class.get attributes
    end

    it "uses the options when given" do
      expect(Typhoeus::Request).to receive(:get).with('https://hello.com/', body: attributes, headers: headers).and_call_original
      dummy_class.get(attributes) do |options|
        options.url = 'https://hello.com/'
      end
    end

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy.json', body: attributes, headers: headers).and_call_original
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

  describe "#initialize" do
    it "instanties the resource" do
      expect(dummy_class.new(id: 12).id).to eql 12
    end

    it "calls #thread_safe! on the resource" do
      expect_any_instance_of(dummy_class).to receive(:thread_safe!).and_call_original
      dummy_class.new id: 12
    end
  end

  describe "#thread_safe!" do
    it "defines the getter and setter methods for the THREADED_OPTIONS" do
      dummy.thread_safe!

      dummy_class::THREADED_OPTIONS.each do |option|
        expect(dummy).to respond_to "#{option}"
        expect(dummy).to respond_to "#{option}="
      end
    end

    it "assigns the instace_variable of the option in the THREADED_OPTIONS" do
      dummy.thread_safe!

      dummy_class::THREADED_OPTIONS.each do |option|
        expect(dummy.public_send(option)).to eql dummy_class.public_send(option)
      end
    end

    it "allows to set option different to the class method of the option" do
      dummy_class.root_element = :foobar
      dummy.thread_safe!

      expect(dummy_class.root_element).to eql :foobar
      expect(dummy.root_element).to eql :foobar

      dummy.root_element = :bazbar

      expect(dummy_class.root_element).to eql :foobar
      expect(dummy.root_element).to eql :bazbar

      dummy_class.root_element = nil
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
    before { allow(dummy).to receive(:post) }

    it "calls #create_or_update" do
      expect(dummy).to receive(:create_or_update).with({ foo: 'bar' }).and_call_original
      dummy.save
    end
  end

  describe "#create_or_update" do
    context "when the attributes contain an id" do
      context "and a root_element is defined" do
        it "packs the attributes in the root_element and calls #patch" do
          dummy_class.root_element = :foobar

          expect(dummy).to receive(:patch).with({ 'foobar' => { id: 10, foo: 'bar' } })
          dummy.create_or_update id: 10, foo: 'bar'

          dummy_class.root_element = nil
        end
      end

      context "and NO root_element is defined" do
        it "does NOT pack the attributes in the root_element and calls #patch" do
          dummy_class.root_element = nil

          expect(dummy).to receive(:patch).with({ id: 10, foo: 'bar' })
          dummy.create_or_update id: 10, foo: 'bar'
        end
      end
    end

    context "when the attributes DON'T contain an id" do
      context "and a root_element is defined" do
        it "packs the attributes in the root_element and calls #post" do
          dummy_class.root_element = :foobar

          expect(dummy).to receive(:post).with({ 'foobar' => { foo: 'bar' } })
          dummy.create_or_update foo: 'bar'

          dummy_class.root_element = nil
        end
      end

      context "and NO root_element is defined" do
        it "does NOT pack the attributes in the root_element and calls #post" do
          dummy_class.root_element = nil

          expect(dummy).to receive(:post).with({ foo: 'bar' })
          dummy.create_or_update foo: 'bar'
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

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/dummy.json', body: attributes, headers: headers).and_call_original
        dummy.post attributes

        dummy_class.content_type = nil
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

    context "when a .content_type is specified" do
      it "uses the content_type as request url" do
        dummy_class.content_type = '.json'

        expect(Typhoeus::Request).to receive(:patch).with("#{request_url}.json", body: attributes, headers: headers).and_call_original
        dummy.patch attributes

        dummy_class.content_type = nil
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

