# frozen_string_literal: true

require "json"

module HoundListSync
  module Repositories
    class Gitlab
      include Repositories
      include Enumerable

      URL_TEMPLATE = "%{base}/api/v4/projects?page=%{page}"

      class Repo
        include Repositories::Repo

        def initialize(raw)
          @raw = raw
        end

        def indexable?
          !@raw["archived"] && !@raw["empty_repo"]
        end

        def name
          @raw["path_with_namespace"]
        end

        def to_config
          {
            "url" => url,
            "url-pattern" => {
              "base-url" => base_url,
              "anchor" => anchor
            },
            "vcs-config" => {
              "ref" => branch
            }
          }
        end

        def url
          @raw["ssh_url_to_repo"]
        end

        def branch
          @raw["default_branch"] || "master"
        end

        def base_url
          "#{@raw["web_url"]}/blob/#{branch}/{path}{anchor}"
        end

        def anchor
          "#L{line}"
        end
      end

      def initialize(
        api_endpoint,
        token: nil,
        url_template: URL_TEMPLATE,
        http: HoundListSync::Http::Net.new
      )
        @api_endpoint = api_endpoint
        @token = token
        @url_template = url_template
        @http = http
      end

      def each
        return to_enum unless block_given?

        page = "1"

        loop do
          response = @http.get(url(page), headers: auth_headers)

          repos = JSON.parse(response.body)

          break if repos.length.zero?

          repos.each do |repo|
            yield Repo.new(repo)
          end

          next_page = response.headers["x-next-page"]
          break if next_page.empty?

          page = next_page
        end
      end

      def url(page)
        format(@url_template, base: @api_endpoint, page: page)
      end

      def auth_headers
        @auth_headers ||=
          if @token.nil?
            {}
          else
            { "Authorization" => "Bearer #{@token}" }
          end
      end
    end
  end
end
