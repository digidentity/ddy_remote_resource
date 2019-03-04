module RemoteResource
  class ConnectionOptions

    AVAILABLE_OPTIONS = [:site, :headers, :default_headers, :version, :path_prefix, :path_postfix, :collection_prefix, :extension, :collection, :collection_name, :root_element, :json_spec].freeze

    attr_reader :base_class

    def initialize(base_class)
      @base_class = base_class
      self.send :initialize_connection_options
    end

    def merge(options = {})
      options.each do |option, value|
        self.public_send "#{option}=", value
      end and self
    end

    def to_hash
      AVAILABLE_OPTIONS.each_with_object(Hash.new) do |option, hash|
        hash[option] = self.public_send option
      end
    end

    def reload
      initialize_connection_options
    end

    def reload!
      reload and self
    end

    private

    def initialize_connection_options
      AVAILABLE_OPTIONS.each do |option|
        self.class.send :attr_accessor, option
        self.public_send "#{option}=", base_class.public_send(option)
      end
    end

  end
end
