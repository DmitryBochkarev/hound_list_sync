# frozen_string_literal: true

module HoundListSync
  module Repositories
    class BlockList
      include Repositories
      include Enumerable

      def initialize(original, names: [])
        @original = original
        @names = names.map { |n| ::Regexp.new(n, ::Regexp::MULTILINE | ::Regexp::IGNORECASE) }
      end

      def each
        return to_enum unless block_given?

        @original.each do |repo|
          next if @names.any? { |name| name.match?(repo.name) }

          yield repo
        end
      end
    end
  end
end
