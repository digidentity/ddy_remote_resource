require 'spec_helper'

describe RemoteResource::Querying::FinderMethods do

  module RemoteResource
    module Querying
      class FinderMethodsDummy
        include RemoteResource::Base

        self.site         = 'https://foobar.com'
        self.content_type = ''

        def params
          { foo: 'bar' }
        end
      end
    end
  end

  let(:dummy_class) { RemoteResource::Querying::FinderMethodsDummy }
  let(:dummy)       { dummy_class.new }

  describe ".find" do
    let(:id)            { '12' }
    let(:request_url)   { 'https://foobar.com/finder_methods_dummy/12' }
    let(:headers)       { { "Accept"=>"application/json" } }

    let(:response_mock)           { double('response', success?: false).as_null_object }
    let(:sanitized_response_body) { nil }

    before do
      allow_any_instance_of(Typhoeus::Request).to receive(:run) { response_mock }
      allow_any_instance_of(RemoteResource::Response).to receive(:sanitized_response_body) { sanitized_response_body }
    end

    it "uses the HTTP GET method" do
      expect(Typhoeus::Request).to receive(:get).and_call_original
      dummy_class.find id
    end

    it "uses the id in the request url" do
      expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/finder_methods_dummy/12', headers: headers).and_call_original
      dummy_class.find id
    end

    it "uses the connection_options headers as request headers" do
      expect(Typhoeus::Request).to receive(:get).with(request_url, headers: { "Accept"=>"application/json" }).and_call_original
      dummy_class.find id
    end

    context "when custom connection_options are given" do
      it "uses the custom connection_options" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/finder_methods_dummy/12.json', headers: { "Accept" => "application/json", "Baz" => "Bar" }).and_call_original
        dummy_class.find(id, { content_type: '.json', headers: { "Baz" => "Bar" } })
      end

      it "overrides the connection_options headers with custom connection_options default_headers" do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/finder_methods_dummy/12.json', headers: { "Baz" => "Bar" }).and_call_original
        dummy_class.find(id, { content_type: '.json', default_headers: { "Baz" => "Bar" } })
      end
    end

    context "response" do
      let(:connection_options)      { dummy_class.connection_options.to_hash }
      let(:sanitized_response_body) { { id: '12', foo: 'bar' } }

      it "instantiates the RemoteResource::Response with the response AND connection_options" do
        expect(RemoteResource::Response).to receive(:new).with(response_mock, connection_options).and_call_original
        dummy_class.find id
      end

      it "builds the resource from the response" do
        expect(dummy_class).to receive(:build_resource_from_response).with(an_instance_of RemoteResource::Response).and_call_original
        dummy_class.find id
      end

      it "assigns the _response" do
        expect(dummy_class.find(id)._response).to be_a RemoteResource::Response
      end

      it "returns the build resource" do
        expect(dummy_class.find(id).id).to eql '12'
      end
    end
  end

  describe ".find_by" do
    let(:params)                  { { id: '12' } }
    let(:response_object_mock)    { RemoteResource::Response.new(double('response').as_null_object) }
    let(:sanitized_response_body) { nil }

    before do
      allow(dummy_class).to receive(:get) { response_object_mock }
      allow(response_object_mock).to receive(:sanitized_response_body) { sanitized_response_body }
    end

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

    context "response" do
      let(:sanitized_response_body) { { id: '12', foo: 'bar' } }

      it "builds the resource from the response" do
        expect(dummy_class).to receive(:build_resource_from_response).with(response_object_mock).and_call_original
        dummy_class.find_by params
      end

      it "assigns the _response" do
        dummy = dummy_class.find_by(params)._response

        expect(dummy).to be_a RemoteResource::Response
        expect(dummy).to eql response_object_mock
      end

      it "returns the build resource" do
        expect(dummy_class.find_by(params).id).to eql '12'
      end
    end
  end

end