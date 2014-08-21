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

  describe '.find_by' do
    let(:response) { instance_double(RemoteResource::Response) }
    let(:params) do
      { id: '12' }
    end

    before do
      allow(dummy_class).to receive(:handle_response)                     { dummy }
      allow_any_instance_of(RemoteResource::Request).to receive(:perform) { response }
    end

    it 'performs a RemoteResource::Request' do
      expect(RemoteResource::Request).to receive(:new).with(dummy_class, :get, params, {}).and_call_original
      expect_any_instance_of(RemoteResource::Request).to receive(:perform)
      dummy_class.find_by params
    end

    it 'handles the RemoteResource::Response' do
      expect(dummy_class).to receive(:handle_response).with response
      dummy_class.find_by params
    end
  end

end