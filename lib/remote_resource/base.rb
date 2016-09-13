module RemoteResource
  module Base
    extend ActiveSupport::Concern

    OPTIONS = [:base_url, :site, :headers, :version, :path_prefix, :path_postfix, :collection_prefix, :extension, :collection, :collection_name, :root_element]

    included do
      include Virtus.model
      extend ActiveModel::Naming
      extend ActiveModel::Translation
      include ActiveModel::Conversion
      include ActiveModel::Validations

      include RemoteResource::Builder
      include RemoteResource::UrlNaming
      include RemoteResource::Connection
      include RemoteResource::REST

      include RemoteResource::Querying::FinderMethods
      include RemoteResource::Querying::PersistenceMethods

      attr_accessor :_response

      attribute :id
      class_attribute :root_element, instance_accessor: false
    end

    def self.global_headers=(headers)
      Thread.current[:global_headers] = headers
    end

    def self.global_headers
      Thread.current[:global_headers] ||= {}
    end

    module ClassMethods

      def connection_options
        RemoteResource::ConnectionOptions.new(self)
      end

      def threaded_connection_options
        Thread.current[threaded_connection_options_thread_name] ||= {}
      end

      def with_connection_options(connection_options = {})
        begin
          Thread.current[threaded_connection_options_thread_name] = threaded_connection_options.merge(connection_options)
          yield
        ensure
          Thread.current[threaded_connection_options_thread_name] = nil
        end
      end

      private

      def threaded_connection_options_thread_name
        "remote_resource.#{_module_name}.threaded_connection_options"
      end

      def _module_name
        self.name.to_s.demodulize.underscore.downcase
      end
    end

    def connection_options
      @connection_options ||= RemoteResource::ConnectionOptions.new(self.class)
    end

    def persisted?
      id.present?
    end

    def new_record?
      !persisted?
    end

    def success?
      _response.success? && !errors?
    end

    def errors?
      errors.present?
    end

    def handle_response(response)
      if response.unprocessable_entity?
        rebuild_resource_from_response(response).tap do |resource|
          resource.assign_errors_from_response response
        end
      else
        rebuild_resource_from_response(response)
      end
    end

    def assign_response(response)
      @_response = response
    end

    def assign_errors_from_response(response)
      assign_errors response.error_messages_response_body
    end

    private

    def assign_errors(error_messages)
      return unless error_messages.respond_to? :each

      error_messages.each do |attribute, attribute_errors|
        attribute_errors.each do |error|
          self.errors.add attribute, error
        end
      end
    end

  end
end
