# frozen_string_literal: true

require "json"

module HoundListSync
  class CLI
    def initialize(base, extensions, out, logger:)
      @base = base
      @extensions = extensions
      @out = out
      @logger = logger
    end

    def run
      @logger.info("Loading base config #{@base}")
      base = HoundConfig.new(read_config(@base))

      if @extensions.any?
        @logger.info("Loading extensions from #{@extensions.join(", ")}")
        extensions =
          Extensions.new(
            @extensions.map { |e| read_config(e) },
            http: Http::Net.new(logger: @logger)
          )

        @logger.info("Extending base config")
        base.extend_with(extensions)
      end

      @logger.info("Total repositories: #{base.total_repos}")

      @logger.info("Generating new config")
      config = JSON.pretty_generate(base)
      old_config = File.read(@out) if File.exist?(@out)

      if config == old_config
        @logger.info("Config not changed")
      else
        @logger.info("Saving to #{@out}")
        File.write(@out, config)
      end

      @logger.info("Done")
    end

    def read_config(file)
      unless File.exist?(file)
        @logger.error("File missing: #{file}")
        exit(1)
      end

      JSON.parse(File.read(file))
    end
  end
end
