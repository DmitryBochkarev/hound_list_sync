# frozen_string_literal: true

module HoundListSync
  module Http
    class Fake
      include Http

      Error = Class.new(StandardError)
      NoMoreResponses = Class.new(Error)

      class Get
        attr_reader :url, :headers, :basic_auth, :response

        def initialize(url, headers:, basic_auth:, response:)
          @url = url
          @headers = headers
          @basic_auth = basic_auth
          @response = response
        end
      end

      attr_reader :requests, :responses

      def initialize(responses)
        @requests = []
        @responses = responses
      end

      def get(url, headers:, basic_auth: [])
        response = @responses.shift

        raise NoMoreResponses, "no more response for GET #{url}" unless response

        @requests.push(Get.new(url, headers: headers, basic_auth: basic_auth, response: response))

        response
      end
    end
  end
end
