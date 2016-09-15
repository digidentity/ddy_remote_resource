module RemoteResource
  module Util

    FILTERED = '[FILTERED]'.freeze

    def self.filter_params(query_string_or_json_body, filtered_params:)
      filtered = query_string_or_json_body
      filtered_params.each do |filtered_param|
        filtered = filtered.to_s.gsub(/(?<="#{filtered_param}":|#{filtered_param}=)(.*?)(?=,|}|&|$)/, FILTERED)
      end
      filtered
    end

    def self.encode_params_to_query(params)
      if params.is_a?(String)
        pairs = [params]
      else
        pairs = recursively_generate_query(params, nil)
      end

      URI.encode_www_form(pairs)
    end

    # This method is based on the monkey patched method:
    # Ethon::Easy::Queryable#recursively_generate_pairs
    #
    # The monkey patch was needed to pass Array
    # params without an index.
    #
    # The problem is described in typhoeus/typhoeus issue #320:
    # https://github.com/typhoeus/typhoeus/issues/320
    #
    # The fix is described in dylanfareed/ethon commit 548033a:
    # https://github.com/dylanfareed/ethon/commit/548033a8557a48203b7d49f3f98812bd79bc05e4
    #
    def self.recursively_generate_query(component, prefix, pairs = [])
      case component
      when Hash
        component.each do |key, value|
          key = prefix.nil? ? key : "#{prefix}[#{key}]"

          if value.respond_to?(:each)
            recursively_generate_query(value, key, pairs)
          else
            pairs.push([key, value.to_s])
          end
        end
      when Array
        component.each do |value|
          key = "#{prefix}[]"

          if value.respond_to?(:each)
            recursively_generate_query(value, key, pairs)
          else
            pairs.push([key, value.to_s])
          end
        end
      end

      pairs
    end

  end
end
