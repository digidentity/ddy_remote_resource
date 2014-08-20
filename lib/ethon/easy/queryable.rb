# This is a monkey patch to pass Array
# params without an index.
#
# The problem is described in typhoeus/typhoeus issue #320:
# https://github.com/typhoeus/typhoeus/issues/320
#
# The fix is described in dylanfareed/ethon commit 548033a:
# https://github.com/dylanfareed/ethon/commit/548033a8557a48203b7d49f3f98812bd79bc05e4
#

require 'ethon'

module Ethon
  class Easy
    module Queryable

      private

      def recursively_generate_pairs(h, prefix, pairs)
        case h
        when Hash
          h.each_pair do |k,v|
            key = prefix.nil? ? k : "#{prefix}[#{k}]"
            pairs_for(v, key, pairs)
          end
        when Array
          h.each_with_index do |v, i|
            key = "#{prefix}[]"
            pairs_for(v, key, pairs)
          end
        end
      end

    end
  end
end
