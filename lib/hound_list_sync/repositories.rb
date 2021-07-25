# frozen_string_literal: true

module HoundListSync
  module Repositories
    module Repo
      def name
        raise "#{self.class} has not implemented method '#{__method__}'"
      end

      def to_config
        raise "#{self.class} has not implemented method '#{__method__}'"
      end

      def indexable?
        raise "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end

require_relative "repositories/github_org"
require_relative "repositories/gitlab"
require_relative "repositories/allow_list"
require_relative "repositories/block_list"
require_relative "repositories/join"
require_relative "repositories/raw"
