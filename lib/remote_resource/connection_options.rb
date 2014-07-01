module RemoteResource
  class ConnectionOptions

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
      RemoteResource::Base::OPTIONS.each_with_object(Hash.new) do |option, hash|
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
      RemoteResource::Base::OPTIONS.each do |option|
        self.class.send :attr_accessor, option
        self.public_send "#{option}=", base_class.public_send(option)
      end
    end

  end
end