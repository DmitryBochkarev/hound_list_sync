# frozen_string_literal: true

require "faraday"
require "faraday_middleware"

module HoundListSync
  module Http
    class Response
      attr_reader :status, :headers, :body

      def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body
      end
    end

    def get(_url, headers:, basic_auth: []) # rubocop:disable Lint/UnusedMethodArgument
      raise "#{self.class} has not implemented method '#{__method__}'"
    end

    class Net
      include Http

      HEADERS = {
        "User-Agent" => "Hound-List-Sync/#{HoundListSync::VERSION} Faraday/#{Faraday::VERSION} ruby/#{RUBY_VERSION}"
      }.freeze

      def initialize(logger: nil)
        @logger = logger
      end

      def get(url, headers:, basic_auth: [])
        conn = Faraday.new(url: url, headers: HEADERS.merge(headers)) do |faraday|
          faraday.basic_auth(*basic_auth) if basic_auth.any?

          faraday.request :retry

          faraday.response :follow_redirects
          faraday.response :raise_error

          if @logger
            faraday.response :logger, @logger do |logger|
              logger.filter(/(Authorization: )(.+)/i, '\1[REMOVED]')
            end
          end
        end

        resp = conn.get

        Response.new(resp.status, resp.headers, resp.body)
      end
    end
  end
end
