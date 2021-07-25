# frozen_string_literal: true

module HoundListSync
  class HoundConfig
    def initialize(raw)
      @raw = raw
      @raw["repos"] ||= {}
    end

    def extend_with(extensions)
      extensions.repositories.each do |repo|
        next unless repo.indexable?

        @raw["repos"][repo.name] = repo.to_config
      end
    end

    def to_json(*args)
      @raw.to_json(*args)
    end

    def total_repos
      @raw["repos"].keys.length
    end
  end
end
