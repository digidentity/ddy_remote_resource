module RemoteResource
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("2.0", "RemoteResource")
  end
end
