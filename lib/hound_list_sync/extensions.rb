# frozen_string_literal: true

module HoundListSync
  class Extensions
    def initialize(raw, http:)
      @raw = raw
      @http = http
    end

    def repositories
      Repositories::Join.new(
        @raw.map { |conf| extension(conf).repositories }
      )
    end

    def extension(conf)
      Extension.new(conf, http: @http)
    end
  end
end
