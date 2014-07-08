module RemoteResource
  module Base
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      extend ActiveModel::Naming
      extend ActiveModel::Translation
      include ActiveModel::Conversion
      include ActiveModel::Validations

      extend RemoteResource::UrlNaming
      extend RemoteResource::Connection
      include RemoteResource::REST

      attr_accessor :_response

      OPTIONS = [:base_url, :site, :headers, :path_prefix, :path_postfix, :content_type, :collection, :collection_name, :root_element]

      attribute :id

    end

    module ClassMethods

      attr_accessor :root_element

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

      def find(id, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash

        response = connection.get determined_request_url(connection_options, id), headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
        if response.success?
          new JSON.parse(response.body)
        end
      end

      def find_by(params, connection_options = {})
        root_element = connection_options[:root_element] || self.connection_options.root_element

        new get(pack_up_request_body(params, root_element), connection_options) || {}
      end

      private

      def determined_request_url(connection_options = {}, id = nil)
        base_url     = connection_options[:base_url].presence     || self.connection_options.base_url
        content_type = connection_options[:content_type].presence || self.connection_options.content_type

        if id.present?
          "#{base_url}/#{id}#{content_type}"
        else
          "#{base_url}#{content_type}"
        end
      end

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

    private

    def determined_request_url(connection_options = {})
      if connection_options[:collection] && self.id.present?
        self.class.send :determined_request_url, connection_options, self.id
      else
        self.class.send :determined_request_url, connection_options
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
