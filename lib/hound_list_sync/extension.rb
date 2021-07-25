# frozen_string_literal: true

module HoundListSync
  class Extension
    def initialize(conf, http:)
      @conf = conf
      @http = http
    end

    def repositories
      repositories = []

      repositories.push(Repositories::Raw.new(@conf["repos"])) if @conf.key?("repos")

      if @conf.key?("lists")
        repositories.push(
          Repositories::Join.new(
            @conf["lists"].map { |name, conf| list_repositories(name, conf) }
          )
        )
      end

      Repositories::Join.new(repositories)
    end

    def list_repositories(name, conf)
      repositories =
        case conf["hosting"]
        when "github"
          Repositories::GithubOrg.new(
            conf.fetch("org"),
            http: @http,
            api_endpoint: conf["api_endpoint"],
            credentials: conf.fetch("credentials", {}).transform_keys(&:to_sym)
          )
        when "gitlab"
          Repositories::Gitlab.new(
            conf.fetch("api_endpoint"),
            http: @http,
            token: conf["token"]
          )
        else
          raise "Invalid config #{name}: #{conf}"
        end

      if conf["allow_list"] && conf['allow_list'].is_a?(Array) && conf["allow_list"].any?
        repositories = Repositories::AllowList.new(
          repositories,
          names: conf["allow_list"]
        )
      end

      if conf["block_list"] && conf['block_list'].is_a?(Array) && conf["block_list"].any?
        repositories = Repositories::BlockList.new(
          repositories,
          names: conf["block_list"]
        )
      end

      repositories
    end
  end
end