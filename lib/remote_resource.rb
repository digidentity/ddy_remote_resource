require 'active_support/all'
require 'active_model'
require 'virtus'
require 'typhoeus'

require_relative 'ethon/easy/queryable'

require 'remote_resource/version'
require 'remote_resource/base'
require 'remote_resource/url_naming_determination'
require 'remote_resource/url_naming'
require 'remote_resource/connection'
require 'remote_resource/builder'
require 'remote_resource/connection_options'
require 'remote_resource/rest'
require 'remote_resource/response'
require 'remote_resource/querying/finder_methods'
require 'remote_resource/querying/persistence_methods'
require 'remote_resource/request'


module RemoteResource
end
