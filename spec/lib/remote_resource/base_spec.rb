require 'spec_helper'

describe RemoteResource::Base do

  module RemoteResource
    class Dummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

    end
  end

  let(:dummy_class) { RemoteResource::Dummy }
  let(:dummy)       { dummy_class.new }

  specify { expect(described_class.const_defined?('RemoteResource::Builder')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::UrlNaming')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::Connection')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::REST')).to be_truthy }

  specify { expect(described_class.const_defined?('RemoteResource::Querying::FinderMethods')).to be_truthy }
  specify { expect(described_class.const_defined?('RemoteResource::Querying::PersistenceMethods')).to be_truthy }

  describe 'OPTIONS' do
    let(:options) { [:base_url, :site, :headers, :version, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element] }

    specify { expect(described_class::OPTIONS).to eql options }
  end

  describe 'attributes' do
    it '#id' do
      expect(dummy.attributes).to have_key :id
    end
  end

  describe '.global_headers=' do
    let(:global_headers) do
      {
        'X-Locale' => 'en',
        'Authorization' => 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
      }
    end

    after { described_class.global_headers = nil }

    it 'sets the global headers Thread variable' do
      expect{ described_class.global_headers = global_headers }.to change{ Thread.current[:global_headers] }.from(nil).to global_headers
    end
  end

  describe '.global_headers' do
    let(:global_headers) do
      {
        'X-Locale' => 'en',
        'Authorization' => 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
      }
    end

    before { described_class.global_headers = global_headers }
    after  { described_class.global_headers = nil }

    it 'returns the global headers Thread variable' do
      expect(described_class.global_headers).to eql global_headers
    end
  end

  describe '.connection_options' do
    it 'instantiates as a RemoteResource::ConnectionOptions' do
      expect(dummy_class.connection_options).to be_a RemoteResource::ConnectionOptions
    end

    it 'uses the implemented class as base_class' do
      expect(dummy_class.connection_options.base_class).to be RemoteResource::Dummy
    end

    it 'sets the name of Thread variable with the implemented class' do
      expect(dummy_class.connection_options).to eql Thread.current['remote_resource.dummy.connection_options']
    end
  end

  describe '.threaded_connection_options' do
    it 'instantiates as a Hash' do
      expect(dummy_class.threaded_connection_options).to be_a Hash
    end

    it 'sets the name of Thread variable with the implemented class' do
      expect(dummy_class.threaded_connection_options).to eql Thread.current['remote_resource.dummy.threaded_connection_options']
    end
  end

  describe '.with_connection_options' do
    let(:connection_options) { {} }

    let(:block_with_connection_options) do
      dummy_class.with_connection_options(connection_options) do
        dummy_class.find_by({ username: 'foobar' }, { content_type: '.json' })
        dummy_class.create({ username: 'bazbar' }, { content_type: '.xml' })
      end
    end

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { double.as_null_object } }

    it 'yields the block' do
      expect(dummy_class).to receive(:find_by).with({ username: 'foobar' }, { content_type: '.json' }).and_call_original
      expect(dummy_class).to receive(:create).with({ username: 'bazbar' }, { content_type: '.xml' }).and_call_original
      block_with_connection_options
    end

    it 'ensures to set the threaded_connection_options Thread variable to nil' do
      dummy_class.threaded_connection_options

      expect{ block_with_connection_options }.to change{ Thread.current['remote_resource.dummy.threaded_connection_options'] }.from(an_instance_of(Hash)).to nil
    end

    context 'when the given connection_options contain headers' do
      let(:connection_options) do
        {
          headers: { "Foo" => "Bar" }
        }
      end

      it 'uses the headers of the given connection_options' do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/dummy.json', params: { username: 'foobar' }, headers: { "Accept" => "application/json", "Foo" => "Bar" }).and_call_original
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/dummy.xml', body: { username: 'bazbar' }, headers: { "Accept" => "application/json", "Foo" => "Bar" }).and_call_original
        block_with_connection_options
      end
    end

    context 'when the given connection_options contain base_url' do
      let(:connection_options) do
        {
          base_url: 'https://api.foobar.eu/dummy'
        }
      end

      it 'uses the base_url of the given connection_options' do
        expect(Typhoeus::Request).to receive(:get).with('https://api.foobar.eu/dummy.json', params: { username: 'foobar' }, headers: { "Accept" => "application/json" }).and_call_original
        expect(Typhoeus::Request).to receive(:post).with('https://api.foobar.eu/dummy.xml', body: { username: 'bazbar' }, headers: { "Accept" => "application/json" }).and_call_original
        block_with_connection_options
      end
    end

    context 'when the given connection_options contain something else' do
      let(:connection_options) do
        {
          collection: true,
          path_prefix: '/api',
          root_element: :bazbar
        }
      end

      it 'uses the given connection_options' do
        expect(Typhoeus::Request).to receive(:get).with('https://foobar.com/api/dummies.json', params: { username: 'foobar' }, headers: { "Accept" => "application/json" }).and_call_original
        expect(Typhoeus::Request).to receive(:post).with('https://foobar.com/api/dummies.xml', body:  { 'bazbar' => { username: 'bazbar' } }, headers: { "Accept" => "application/json" }).and_call_original
        block_with_connection_options
      end
    end
  end

  describe '#connection_options' do
    it 'instanties as a RemoteResource::ConnectionOptions' do
      expect(dummy.connection_options).to be_a RemoteResource::ConnectionOptions
    end

    it 'uses the implemented class as base_class' do
      expect(dummy.connection_options.base_class).to be RemoteResource::Dummy
    end
  end

  describe '#empty?' do
    before { allow(dummy).to receive(:_response) { response } }

    context 'when the response is present' do
      let(:response) { instance_double(RemoteResource::Response, sanitized_response_body: sanitized_response_body) }

      context 'and the #sanitized_response_body is present' do
        let(:sanitized_response_body) do
          { name: 'Mies' }
        end

        it 'returns false' do
          expect(dummy.empty?).to eql false
        end
      end

      context 'and the #sanitized_response_body is blank' do
        let(:sanitized_response_body) do
          {}
        end

        it 'returns true' do
          expect(dummy.empty?).to eql true
        end
      end

      context 'and the #sanitized_response_body is NOT present' do
        let(:sanitized_response_body) { nil }

        it 'returns true' do
          expect(dummy.empty?).to eql true
        end
      end
    end

    context 'when the response is NOT present' do
      let(:response) { nil }

      it 'returns true' do
        expect(dummy.empty?).to eql true
      end
    end
  end

  describe '#persisted?' do
    context 'when id is present' do
      it 'returns true' do
        dummy.id = 10
        expect(dummy.persisted?).to eql true
      end
    end

    context 'when is is NOT present' do
      it 'returns false' do
        expect(dummy.persisted?).to eql false
      end
    end
  end

  describe '#new_record?' do
    context 'when instance persisted' do
      it 'returns false' do
        allow(dummy).to receive(:persisted?) { true }

        expect(dummy.new_record?).to eql false
      end
    end

    context 'when instance does NOT persist' do
      it 'returns true' do
        allow(dummy).to receive(:persisted?) { false }

        expect(dummy.new_record?).to eql true
      end
    end
  end

  describe '#success?' do
    let(:response) { instance_double(RemoteResource::Response) }

    before { allow(dummy).to receive(:_response) { response } }

    context 'when response is successful' do
      before { allow(response).to receive(:success?) { true } }

      context 'and the resource has NO errors present' do
        it 'returns true' do
          expect(dummy.success?).to eql true
        end
      end

      context 'and the resource has errors present' do
        it 'returns false' do
          dummy.errors.add :id, 'must be present'

          expect(dummy.success?).to eql false
        end
      end
    end

    context 'when response is NOT successful' do
      before { allow(response).to receive(:success?) { false } }

      it 'returns false' do
        expect(dummy.success?).to eql false
      end
    end
  end

  describe '#errors?' do
    context 'when resource has errors present' do
      it 'returns true' do
        dummy.errors.add :id, 'must be present'

        expect(dummy.errors?).to eql true
      end
    end

    context 'when resource has NO errors present' do
      it 'returns false' do
        expect(dummy.errors?).to eql false
      end
    end
  end

  describe '#handle_response' do
    let(:response) { instance_double(RemoteResource::Response) }

    before { allow(dummy).to receive(:rebuild_resource_from_response) { dummy } }

    context 'when the response is a unprocessable_entity' do
      before do
        allow(response).to receive(:unprocessable_entity?) { true }

        allow(dummy).to receive(:assign_errors_from_response)
      end

      it 'rebuilds the resource from the response' do
        expect(dummy).to receive(:rebuild_resource_from_response).with response
        dummy.handle_response response
      end

      it 'assigns the errors from the response to the resource' do
        expect(dummy).to receive(:assign_errors_from_response).with response
        dummy.handle_response response
      end
    end

    context 'when the response is NOT a unprocessable_entity' do
      before { allow(response).to receive(:unprocessable_entity?) { false } }

      it 'rebuilds the resource from the response' do
        expect(dummy).to receive(:rebuild_resource_from_response).with response
        dummy.handle_response response
      end
    end
  end

  describe '#assign_response' do
    let(:response) { instance_double(RemoteResource::Response) }

    it 'assigns the #_response' do
      expect{ dummy.assign_response response }.to change{ dummy._response }.from(nil).to response
    end
  end

  describe '#assign_errors_from_response' do
    let(:response)                      { instance_double(RemoteResource::Response) }
    let(:error_messages_response_body)  { double('error_messages_response_body') }

    it 'calls the #assign_errors method with the #error_messages_response_body of the response' do
      allow(response).to receive(:error_messages_response_body) { error_messages_response_body }

      expect(dummy).to receive(:assign_errors).with error_messages_response_body
      dummy.assign_errors_from_response response
    end
  end

  describe '#assign_errors' do
    context 'with errors in the error_messages' do
      let(:error_messages) do
        {
          "foo" => ["is required"],
          "bar" => ["must be greater than 5"]
        }
      end

      it 'assigns the error_messages as errors' do
        dummy.send :assign_errors, error_messages
        expect(dummy.errors.messages).to eql foo: ["is required"], bar: ["must be greater than 5"]
      end
    end

    context 'with an empty Hash in the error_messages' do
      let(:error_messages) do
        {}
      end

      it 'does NOT assign the error_messages as errors' do
        dummy.send :assign_errors, error_messages
        expect(dummy.errors.messages).to eql({})
      end
    end

    context 'with a String in the error_messages' do
      let(:error_messages) do
        "unauthorized"
      end

      it 'does NOT assign the error_messages as errors' do
        dummy.send :assign_errors, error_messages
        expect(dummy.errors.messages).to eql({})
      end
    end
  end

end

