module RemoteResource
  module Base
    extend ActiveSupport::Concern

    OPTIONS = [:base_url, :site, :headers, :version, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element]

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

    module ClassMethods

      def connection_options
        Thread.current[connection_options_thread_name] ||= RemoteResource::ConnectionOptions.new(self)
      end

      def with_connection_options(connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash
        connection_options[:headers].merge! self.connection_options.headers
        begin
          Thread.current[connection_options_thread_name].merge connection_options
          yield
        ensure
          Thread.current[connection_options_thread_name] = nil
        end
      end

      def handle_response(response)
        if response.success?
          build_resource_from_response response
        elsif response.unprocessable_entity?
          build_resource_from_response(response).tap do |resource|
            resource.assign_errors_from_response response
          end
        else
          new.tap do |resource|
            resource.assign_errors_from_response response
          end
        end
      end

      private

      def connection_options_thread_name
        "remote_resource.#{_module_name}.connection_options"
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

    def handle_response(response)
      if response.success?
        rebuild_resource_from_response response
      elsif response.unprocessable_entity?
        rebuild_resource_from_response(response).tap do |resource|
          resource.assign_errors_from_response response
        end
      else
        assign_errors_from_response response
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
      error_messages.each do |attribute, attribute_errors|
        attribute_errors.each do |error|
          self.errors.add attribute, error
        end
      end
    end

  end
end
