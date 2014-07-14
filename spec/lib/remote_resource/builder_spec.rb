require 'spec_helper'

describe RemoteResource::Builder do

  module RemoteResource
    class BuilderDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::BuilderDummy }
  let(:dummy)       { dummy_class.new }

  describe ".build_resource_from_response" do
    let(:response)                { RemoteResource::Response.new double.as_null_object }
    let(:sanitized_response_body) { { "id" => "12", "username" => "foobar" } }

    before { allow(response).to receive(:sanitized_response_body) { sanitized_response_body } }

    it "calls the .build_resource" do
      expect(dummy_class).to receive(:build_resource).with sanitized_response_body, { _response: an_instance_of(RemoteResource::Response) }
      dummy_class.build_resource_from_response response
    end
  end

  describe ".build_resource" do
    let(:response)      { RemoteResource::Response.new double.as_null_object }
    let(:response_hash) { dummy_class.send :response_hash, response }

    context "when the collection is a Hash" do
      let(:collection)  { { "id" => "12", "username" => "foobar" } }

      context "and response_hash is given" do
        it "instantiates the resource with the collection AND with response_hash" do
          expect(dummy_class).to receive(:new).with(collection.merge(response_hash)).and_call_original
          dummy_class.build_resource collection, response_hash
        end
      end

      context "and NO response_hash is given" do
        it "instantiates the resource with the collection" do
          expect(dummy_class).to receive(:new).with(collection).and_call_original
          dummy_class.build_resource collection
        end
      end
    end

    context "when the collection is an Array" do
      let(:collection) do
        [
          { "id" => "10", "username" => "foobar" },
          { "id" => "11", "username" => "bazbar" },
          { "id" => "12", "username" => "aapmies" }
        ]
      end

      context "and response_hash is given" do
        it "instantiates each element in the collection as resource AND with response_hash" do
          expect(dummy_class).to receive(:new).with(collection[0].merge(response_hash)).and_call_original
          expect(dummy_class).to receive(:new).with(collection[1].merge(response_hash)).and_call_original
          expect(dummy_class).to receive(:new).with(collection[2].merge(response_hash)).and_call_original
          dummy_class.build_resource collection, response_hash
        end

        it "returns the resources" do
          resources = dummy_class.build_resource collection, response_hash
          resources.each { |resource| expect(resource).to be_a dummy_class }
        end
      end

      context "and NO response_hash is given" do
        it "instantiates each element in the collection as resource" do
          expect(dummy_class).to receive(:new).with(collection[0]).and_call_original
          expect(dummy_class).to receive(:new).with(collection[1]).and_call_original
          expect(dummy_class).to receive(:new).with(collection[2]).and_call_original
          dummy_class.build_resource collection
        end
      end
    end

    context "when the collection is something else" do
      let(:collection)  { 'foobar' }

      context "and response_hash is given" do
        it "instantiates the resource with the response_hash" do
          expect(dummy_class).to receive(:new).with(response_hash).and_call_original
          dummy_class.build_resource collection, response_hash
        end
      end

      context "and NO response_hash is given" do
        it "instantiates the resource with an empty Hash" do
          expect(dummy_class).to receive(:new).with({}).and_call_original
          dummy_class.build_resource collection
        end
      end
    end
  end

end