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

      attribute :id

    end

    module ClassMethods

      attr_accessor :content_type, :root_element

      def find(id)
        response = connection.get "#{base_url}/#{id}#{content_type.presence}", headers: headers
        if response.success?
          new JSON.parse(response.body)
        end
      end

      def find_by(params)
        new get(pack_up_request_body(params)) || {}
      end

      def get(attributes = {}, &options)

        if block_given?
          connection_options = OpenStruct.new
          options.call(connection_options)
        end

        response = connection.get connection_options.try(:url) || "#{base_url}#{content_type.presence}", body: attributes, headers: headers
        if response.success?
          unpack_response_body(response.body)
        end
      end

      private

      def pack_up_request_body(body)
        if root_element.present?
          Hash[root_element.to_s, body]
        else
          body
        end
      end

      def unpack_response_body(body)
        if root_element.present?
          JSON.parse(body)[root_element.to_s]
        else
          JSON.parse(body)
        end
      end

    end

    module InstanceMethods

      THREADED_OPTIONS = [:site, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element]

      def initialize(*args)
        super.tap do |resource|
          resource.thread_safe!
        end
      end

      def thread_safe!
        THREADED_OPTIONS.each do |option|
          self.class.send :attr_accessor, option
          instance_variable_set "@#{option}", self.class.public_send(option)
        end
      end

      def persisted?
        id.present?
      end

      def new_record?
        !persisted?
      end

      def save
        create_or_update params
      end

      def create_or_update(attributes = {})
        if attributes.has_key? :id
          patch pack_up_request_body(attributes)
        else
          post pack_up_request_body(attributes)
        end
      end

      def post(attributes = {})
        response = self.class.connection.post "#{self.class.base_url}#{self.class.content_type.presence}", body: attributes, headers: self.class.headers
        if response.success?
          true
        elsif response.response_code == 422
          assign_errors JSON.parse(response.body)
          false
        else
          false
        end
      end

      def patch(attributes = {})
        response = self.class.connection.patch collection_determined_url, body: attributes, headers: self.class.headers
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
          "#{self.class.base_url}/#{self.id}#{self.class.content_type.presence}"
        else
          "#{self.class.base_url}#{self.class.content_type.presence}"
        end
      end

      def pack_up_request_body(body)
        self.class.send :pack_up_request_body, body
      end

      def unpack_response_body(body)
        self.class.send :unpack_response_body, body
      end

      def assign_errors(error_data)
        error_messages = find_error_messages error_data
        error_messages.each do |attribute, attribute_errors|
          attribute_errors.each do |error|
            self.errors.add attribute, error
          end
        end
      end

      def find_error_messages(error_data)
        if error_data.has_key? "errors"
          error_data["errors"]
        elsif self.class.root_element.present?
          error_data[self.class.root_element.to_s]["errors"]
        end
      end

    end
  end
end
