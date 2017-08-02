module RemoteResource
  module Base
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      extend ActiveModel::Naming
      extend ActiveModel::Translation
      include ActiveModel::Conversion
      include ActiveModel::Validations

      include RemoteResource::Builder
      include RemoteResource::UrlNaming
      include RemoteResource::Connection

      extend RemoteResource::REST
      include RemoteResource::REST

      include RemoteResource::Querying::FinderMethods
      include RemoteResource::Querying::PersistenceMethods

      attr_accessor :last_request, :last_response, :meta
      attr_writer :destroyed, :persisted

      class_attribute :root_element, instance_accessor: false

      attribute :id
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

    def persistence
      self if persisted?
    end

    def persisted?
      if destroyed?
        false
      else
        !!@persisted || id.present?
      end
    end

    def new_record?
      !persisted? && !destroyed?
    end

    def destroyed?
      !!@destroyed
    end

    def success?
      last_response.success? && !errors?
    end

    def errors?
      errors.present?
    end

    def handle_response(response)
      if response.unprocessable_entity?
        rebuild_resource_from_response(response)
        assign_errors_from_response(response)
      else
        rebuild_resource_from_response(response)
      end and self
    end

    def assign_errors_from_response(response)
      assign_errors(response.errors)
    end

    def _response
      warn '[DEPRECATION] `._response` is deprecated. Please use `.last_response` instead.'
    end

    private

    def assign_errors(error_messages)
      return unless error_messages.respond_to?(:each)

      error_messages.each do |attribute, attribute_errors|
        attribute_errors.each do |attribute_error|
          if respond_to?(attribute)
            self.errors.add(attribute, attribute_error)
          else
            self.errors.add(:base, attribute_error)
          end
        end
      end
    end

  end
end
