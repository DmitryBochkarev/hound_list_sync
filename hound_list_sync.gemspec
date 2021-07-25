# frozen_string_literal: true

require_relative "lib/hound_list_sync/version"

Gem::Specification.new do |spec|
  spec.name          = "hound_list_sync"
  spec.version       = HoundListSync::VERSION
  spec.authors       = ["Dmitry Bochkarev"]
  spec.email         = ["dimabochkarev@gmail.com"]

  spec.summary       = "Auto generate Hound config from remote lists"
  spec.description   = "Sync Hound repositories with Github organization and Gitlab projects"
  spec.homepage      = "https://github.com/DmitryBochkarev/hound_list_sync"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/DmitryBochkarev/hound_list_sync"

  spec.add_dependency "faraday", "~> 1.5.1"
  spec.add_dependency "faraday_middleware", "~> 1.0.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
