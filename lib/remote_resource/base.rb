module RemoteResource
  module Base
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      extend ActiveModel::Naming
      extend ActiveModel::Translation
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include InstanceMethods

      extend RemoteResource::UrlNaming
      extend RemoteResource::Connection

      OPTIONS = [:site, :headers, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element]

      attribute :id

    end

    module ClassMethods

      attr_accessor :content_type, :root_element
      def connection_options
        Thread.current['remote_resource.connection_options'] ||= RemoteResource::ConnectionOptions.new(self)
      end

      def find(id, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash

        response = connection.get "#{base_url}/#{id}#{connection_options[:content_type].presence}", headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
        if response.success?
          new JSON.parse(response.body)
        end
      end

      def find_by(params, connection_options = {})
        root_element = connection_options[:root_element] || self.connection_options.root_element

        new get(pack_up_request_body(params, root_element), connection_options) || {}
      end

      def get(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash

        response = connection.get "#{base_url}#{connection_options[:content_type].presence}", body: attributes, headers: connection_options[:default_headers] || headers.merge(connection_options[:headers])
        if response.success?
          unpack_response_body(response.body, connection_options[:root_element])
        end
      end

      private

      def pack_up_request_body(body, root_element = nil)
        if root_element.present?
          Hash[root_element.to_s, body]
        else
          body
        end
      end

      def unpack_response_body(body, root_element = nil)
        if root_element.present?
          JSON.parse(body)[root_element.to_s]
        else
          JSON.parse(body)
        end
      end

    end

    module InstanceMethods

      def connection_options
        @connection_options ||= RemoteResource::ConnectionOptions.new(self.class)
      end

      def persisted?
        id.present?
      end

      def new_record?
        !persisted?
      end

      def save(connection_options = {})
        create_or_update params, connection_options
      end

      def create_or_update(attributes = {}, connection_options = {})
        root_element = connection_options[:root_element] || self.connection_options.root_element

        if attributes.has_key? :id
          patch(pack_up_request_body(attributes, root_element), connection_options)
        else
          post(pack_up_request_body(attributes, root_element), connection_options)
        end
      end

      def post(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash

        response = self.class.connection.post "#{self.class.base_url}#{connection_options[:content_type].presence}", body: attributes, headers: connection_options[:default_headers] || self.class.headers.merge(connection_options[:headers])
        if response.success?
          true
        elsif response.response_code == 422
          assign_errors JSON.parse(response.body), connection_options[:root_element]
          false
        else
          false
        end
      end

      def patch(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash

        response = self.class.connection.patch "#{collection_determined_url}#{connection_options[:content_type].presence}", body: attributes, headers: connection_options[:default_headers] || self.class.headers.merge(connection_options[:headers])
        if response.success?
          true
        elsif response.response_code == 422
          assign_errors JSON.parse(response.body)
          false
        else
          false
        end
      end

      private

      def collection_determined_url
        if self.class.collection
          "#{self.class.base_url}/#{self.id}"
        else
          self.class.base_url
        end
      end

      def pack_up_request_body(body, root_element = nil)
        self.class.send :pack_up_request_body, body, root_element
      end

      def unpack_response_body(body, root_element = nil)
        self.class.send :unpack_response_body, body, root_element
      end

      def assign_errors(error_data, root_element = nil)
        error_messages = find_error_messages error_data, root_element
        error_messages.each do |attribute, attribute_errors|
          attribute_errors.each do |error|
            self.errors.add attribute, error
          end
        end
      end

      def find_error_messages(error_data, root_element = nil)
        if error_data.has_key? "errors"
          error_data["errors"]
        elsif root_element.present?
          error_data[root_element.to_s]["errors"]
        end
      end

    end
  end
end
