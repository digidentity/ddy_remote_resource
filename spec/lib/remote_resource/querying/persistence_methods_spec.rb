require 'spec_helper'

describe RemoteResource::Querying::PersistenceMethods do

  module RemoteResource
    module Querying
      class PersistenceMethodsDummy
        include RemoteResource::Base

        self.site         = 'https://foobar.com'
        self.content_type = ''

        def params
          { foo: 'bar' }
        end
      end
    end
  end

  let(:dummy_class) { RemoteResource::Querying::PersistenceMethodsDummy }
  let(:dummy)       { dummy_class.new }

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

end