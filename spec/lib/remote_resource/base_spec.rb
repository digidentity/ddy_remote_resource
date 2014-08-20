require 'spec_helper'

describe RemoteResource::Base do

  module RemoteResource
    class Dummy
      include RemoteResource::Base

      self.site         = 'https://foobar.com'
      self.content_type = ''

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::Dummy }
  let(:dummy)       { dummy_class.new }

  specify { expect(described_class.const_defined?('RemoteResource::Builder')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::UrlNaming')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::Connection')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::REST')).to be_truthy }

  describe "OPTIONS" do
    let(:options) { [:base_url, :site, :headers, :version, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element] }

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

