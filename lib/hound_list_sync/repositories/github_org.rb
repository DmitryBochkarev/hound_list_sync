# frozen_string_literal: true

require "json"

module HoundListSync
  module Repositories
    class GithubOrg
      include Repositories
      include Enumerable

      URL_TEMPLATE = "%{base}/orgs/%{org}/repos?page=%{page}"
      API_GITHUB_COM = "https://api.github.com"
      HEADERS = { "Accept" => "application/vnd.github.v3+json" }.freeze

      class Repo
        include Repositories::Repo

        def initialize(raw)
          @raw = raw
        end

        def indexable?
          !@raw["archived"] && !@raw["disabled"]
        end

        def name
          @raw["full_name"]
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
          @raw["ssh_url"]
        end

        def branch
          @raw["default_branch"] || "master"
        end

        def base_url
          "#{@raw["html_url"]}/blob/#{branch}/{path}{anchor}"
        end

        def anchor
          "#L{line}"
        end
      end

      def initialize(
        orgname,
        api_endpoint: nil,
        credentials: {},
        url_template: URL_TEMPLATE,
        http: HoundListSync::Http::Net.new
      )
        @orgname = orgname
        @api_endpoint = api_endpoint || API_GITHUB_COM
        @credentials = credentials
        @url_template = url_template
        @http = http
      end

      def each
        return to_enum unless block_given?

        page = 1

        loop do
          repos =
            JSON.parse(
              @http
                .get(url(page), headers: HEADERS, basic_auth: basic_auth)
                .body
            )

          break if repos.length.zero?

          repos.each do |repo|
            yield Repo.new(repo)
          end

          page += 1
        end
      end

      def url(page)
        format(@url_template, base: @api_endpoint, org: @orgname, page: page)
      end

      def basic_auth
        @basic_auth ||=
          if @credentials.any?
            [@credentials.fetch(:login), @credentials.fetch(:pass)]
          else
            []
          end
      end
    end
  end
end
