# frozen_string_literal: true

module HoundListSync
  module Repositories
    class Raw
      include Repositories
      include Enumerable

      class Repo
        include Repositories::Repo

        def initialize(name, config)
          @name = name
          @config = config
        end

        attr_reader :name

        def to_config
          @config
        end

        def indexable?
          true
        end
      end

      def initialize(raw)
        @raw = raw
      end

      def each
        return to_enum unless block_given?

        @raw.each do |name, config|
          yield Repo.new(name, config)
        end
      end
    end
  end
end
