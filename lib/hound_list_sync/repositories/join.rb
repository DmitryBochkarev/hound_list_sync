# frozen_string_literal: true

module HoundListSync
  module Repositories
    class Join
      include Repositories
      include Enumerable

      def initialize(list)
        @list = list
      end

      def each(&block)
        return to_enum unless block_given?

        @list.each do |repositories|
          repositories.each(&block)
        end
      end
    end
  end
end
