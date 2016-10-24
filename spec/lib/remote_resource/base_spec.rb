require 'spec_helper'

RSpec.describe RemoteResource::Base do

  module RemoteResource
    class Dummy
      include RemoteResource::Base

      self.site = 'https://foobar.com'

      attr_accessor :name

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
      expect{ described_class.global_headers = global_headers }.to change{ described_class.global_headers }.from({}).to(global_headers)
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

    it 'does NOT memorize the connection options' do
      expect(dummy_class.connection_options.object_id).not_to eql dummy_class.connection_options.object_id
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
    it 'yields the block' do
      expect(dummy_class).to receive(:find_by).with({ username: 'foobar' }, { path_prefix: '/archive' })
      expect(dummy_class).to receive(:create).with({ username: 'bazbar' }, { path_prefix: '/featured' })

      dummy_class.with_connection_options({ version: '/api/v1', headers: { 'Foo' => 'Bar' } }) do
        dummy_class.find_by({ username: 'foobar' }, { path_prefix: '/archive' })
        dummy_class.create({ username: 'bazbar' }, { path_prefix: '/featured' })
      end
    end

    it 'ensures to set the threaded_connection_options back to the default' do
      allow(dummy_class).to receive(:find_by)
      allow(dummy_class).to receive(:create)

      expect(dummy_class.threaded_connection_options).to eql({})

      dummy_class.with_connection_options({ version: '/api/v1', headers: { 'Foo' => 'Bar' } }) do
        dummy_class.find_by({ username: 'foobar' }, { path_prefix: '/archive' })
        dummy_class.create({ username: 'bazbar' }, { path_prefix: '/featured' })
      end

      expect(dummy_class.threaded_connection_options).to eql({})
    end
  end

  describe '#connection_options' do
    it 'instantiates as a RemoteResource::ConnectionOptions' do
      expect(dummy.connection_options).to be_a RemoteResource::ConnectionOptions
    end

    it 'uses the implemented class as base_class' do
      expect(dummy.connection_options.base_class).to be RemoteResource::Dummy
    end
  end

  describe '#persistence' do
    context 'when #persisted?' do
      it 'returns the resource' do
        dummy.id = 10
        expect(dummy.persistence).to eql dummy
      end
    end

    context 'when NOT #persisted?' do
      it 'returns nil' do
        dummy.id = nil
        expect(dummy.persistence).to be_nil
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

    context 'when id is present and destroyed is present' do
      it 'returns false' do
        dummy.id = 10
        dummy.destroyed = true
        expect(dummy.persisted?).to eql false
      end
    end

    context 'when id is NOT present' do
      it 'returns false' do
        dummy.id = nil
        expect(dummy.persisted?).to eql false
      end
    end

    context 'when id is NOT present and destroyed is present' do
      it 'returns false' do
        dummy.id = nil
        dummy.destroyed = true
        expect(dummy.persisted?).to eql false
      end
    end
  end

  describe '#new_record?' do
    context 'when #persisted?' do
      it 'returns false' do
        dummy.id = 10
        expect(dummy.new_record?).to eql false
      end
    end

    context 'when NOT #persisted?' do
      it 'returns true' do
        dummy.id = nil
        expect(dummy.new_record?).to eql true
      end
    end
  end

  describe '#success?' do
    context 'when last response is successful' do
      it 'returns true' do
        dummy.last_response = instance_double(RemoteResource::Response, success?: true)

        expect(dummy.success?).to eql true
      end
    end

    context 'when last response is successful and (validation) errors are present' do
      it 'returns false' do
        dummy.last_response = instance_double(RemoteResource::Response, success?: true)
        dummy.errors.add(:id, 'is invalid')

        expect(dummy.success?).to eql false
      end
    end

    context 'when last response is NOT successful' do
      it 'returns false' do
        dummy.last_response = instance_double(RemoteResource::Response, success?: false)

        expect(dummy.success?).to eql false
      end
    end
  end

  describe '#errors?' do
    context 'when (validation) errors are present' do
      it 'returns true' do
        dummy.errors.add(:id, 'is invalid')

        expect(dummy.errors?).to eql true
      end
    end

    context 'when (validation) errors are NOT present' do
      it 'returns false' do
        expect(dummy.errors?).to eql false
      end
    end
  end

  describe '#handle_response' do
    context 'when the response is a unprocessable_entity' do
      let(:response) { instance_double(RemoteResource::Response, success?: false, unprocessable_entity?: true, attributes: {}, errors: { 'name' => ['is required'] }, meta: {}, request: instance_double(RemoteResource::Request)) }

      it 'calls #rebuild_resource_from_response with the response' do
        expect(dummy).to receive(:rebuild_resource_from_response).with(response).and_call_original
        dummy.handle_response(response)
      end

      it 'calls #assign_errors_from_response with the response' do
        expect(dummy).to receive(:assign_errors_from_response).with(response).and_call_original
        dummy.handle_response(response)
      end

      it 'returns the same resource' do
        expected_object_id = dummy.object_id

        expect(dummy.handle_response(response).object_id).to eql expected_object_id
      end
    end

    context 'when the response is NOT a unprocessable_entity' do
      let(:response) { instance_double(RemoteResource::Response, success?: true, unprocessable_entity?: false, attributes: { 'id' => 12, 'name' => 'Mies' }, errors: {}, meta: {}, request: instance_double(RemoteResource::Request)) }

      it 'calls #rebuild_resource_from_response with the response' do
        expect(dummy).to receive(:rebuild_resource_from_response).with(response).and_call_original
        dummy.handle_response(response)
      end

      it 'does NOT calls #assign_errors_from_response' do
        expect(dummy).not_to receive(:assign_errors_from_response)
        dummy.handle_response(response)
      end

      it 'returns the same resource' do
        expected_object_id = dummy.object_id

        expect(dummy.handle_response(response).object_id).to eql expected_object_id
      end
    end
  end

  describe '#assign_errors_from_response' do
    let(:response) { instance_double(RemoteResource::Response, success?: false, unprocessable_entity?: true, attributes: {}, errors: { 'name' => ['is required'], 'virtual_attribute' => ['is invalid'] }, meta: {}, request: instance_double(RemoteResource::Request)) }

    it 'calls #assign_errors with the errors of the response' do
      expect(dummy).to receive(:assign_errors).with(response.errors).and_call_original
      dummy.assign_errors_from_response(response)
    end

    it 'assigns the errors of the response' do
      expect(dummy.errors).to be_blank

      dummy.assign_errors_from_response(response)

      expect(dummy.errors).to be_present
      expect(dummy.errors[:name]).to match_array ['is required']
      expect(dummy.errors[:base]).to match_array ['is invalid']
    end
  end

  describe '#_response' do
    it 'warns that the method is deprecated' do
      expect(dummy).to receive(:warn).with('[DEPRECATION] `._response` is deprecated. Please use `.last_response` instead.')
      dummy._response
    end
  end

end

