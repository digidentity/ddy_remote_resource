require 'spec_helper'

describe RemoteResource::Connection do

  module RemoteResource
    class ConnectionDummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      def params
        { foo: 'bar' }
      end
    end
  end

  let(:dummy_class) { RemoteResource::ConnectionDummy }
  let(:dummy)       { dummy_class.new }

  describe ".connection" do
    it "uses Typhoeus::Request" do
      expect(dummy_class.connection).to eql Typhoeus::Request
    end
  end

  describe ".content_type" do
    context "when content_type is set" do
      it "returns the given content_type" do
        dummy_class.content_type = '.html'

        expect(dummy_class.content_type).to eql '.html'

        dummy_class.content_type = ''
      end
    end

    context "when NO content_type is set" do
      it "returns the default content_type" do
        dummy_class.content_type = nil

        expect(dummy_class.content_type).to eql '.json'

        dummy_class.content_type = ''
      end
    end
  end

  describe ".headers" do
    context "when headers are set" do
      it "returns the default headers merged with the set headers" do
        dummy_class.headers = { "Foo" => "Bar" }

        expect(dummy_class.headers).to eql({ "Accept"=>"application/json", "Foo" => "Bar" })

        dummy_class.headers = nil
      end
    end

    context "when NO headers are set" do
      it "returns the default headers" do
        expect(dummy_class.headers).to eql({ "Accept"=>"application/json" })
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
          expect(dummy_class.send :determined_request_url, {}, 12).to eql 'https://foobar.com/connection_dummy/12'
        end
      end

      context "when the id is NOT given" do
        it "does NOT use the id for the request_url" do
          expect(dummy_class.send :determined_request_url).to eql 'https://foobar.com/connection_dummy'
        end
      end
    end

    context "content_type" do
      context "when the given custom connection_options contain a content_type" do
        let(:custom_connection_options) { { content_type: '.xml' } }

        it "uses the content_type for the request_url" do
          expect(dummy_class.send :determined_request_url, custom_connection_options).to eql 'https://foobar.com/connection_dummy.xml'
        end
      end

      context "when the connection_options contain a content_type" do
        before { dummy_class.connection_options.merge content_type: '.xml' }
        after  { dummy_class.connection_options.reload }

        it "uses the content_type for the request_url" do
          expect(dummy_class.send :determined_request_url).to eql 'https://foobar.com/connection_dummy.xml'
        end
      end
    end
  end

  describe ".determined_headers" do
    context "when given custom connection_options contain a default_headers" do
      let(:connection_options) { { default_headers: { "Baz" => "Bar" } } }

      it "uses the default_headers" do
        expect(dummy_class.send :determined_headers, connection_options).to eql({ "Baz" => "Bar" })
      end
    end

    context "when given custom connection_options contain a headers" do
      let(:connection_options) { { headers: { "Baz" => "Bar" } } }

      it "uses the merged the headers with the connection_options headers" do
        expect(dummy_class.send :determined_headers, connection_options).to eql({ "Accept" => "application/json", "Baz" => "Bar" })
      end
    end

    context "when NO custom connection_options headers option is given" do
      it "uses the headers" do
        expect(dummy_class.send :determined_headers).to eql({ "Accept" => "application/json" })
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
            expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/connection_dummy/12'
          end
        end

        context "and the id is NOT present" do
          it "calls .determined_request_url" do
            expect(dummy_class).to receive(:determined_request_url).with(connection_options)
            dummy.send :determined_request_url, connection_options
          end

          it "does NOT use the id for the request_url" do
            expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/connection_dummy'
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
          expect(dummy.send :determined_request_url, connection_options).to eql 'https://foobar.com/connection_dummy'
        end
      end
    end
  end

  describe "#determined_headers" do
    let(:connection_options) { { headers: { "Baz" => "Bar" } } }

    it "calls the .determined_headers" do
      expect(dummy_class).to receive(:determined_headers).with(connection_options).and_call_original
      dummy.send :determined_headers, connection_options
    end
  end

end