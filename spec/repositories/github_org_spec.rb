# frozen_string_literal: true

require "hound_list_sync/http/fake"

RSpec.describe HoundListSync::Repositories::GithubOrg do
  let(:repositories) do
    described_class.new(
      "Example",
      credentials: credentials,
      http: http
    )
  end
  let(:http) { HoundListSync::Http::Fake.new(responses) }
  let(:credentials) { { login: "admin", pass: "qwe123" } }

  def repo(name, archived: false, disabled: false, default_branch: "main")
    {
      "name" => name,
      "full_name" => "Example/#{name}",
      "html_url" => "https://github.com/Example/#{name}",
      "git_url" => "git://github.com/Example/#{name}.git",
      "ssh_url" => "git@github.com:Example/#{name}.git",
      "clone_url" => "https://github.com/Example/#{name}.git",
      "svn_url" => "https://github.com/Example/#{name}",
      "archived" => archived,
      "disabled" => disabled,
      "default_branch" => default_branch
    }
  end

  describe "#to_a" do
    subject(:to_a) { repositories.to_a }

    let(:responses) do
      [
        HoundListSync::Http::Response.new(
          200,
          {},
          JSON.generate(
            [
              repo("application"),
              repo("archived_application", archived: true)
            ]
          )
        ),
        HoundListSync::Http::Response.new(
          200,
          {},
          JSON.generate(
            [
              repo("disabled_application", disabled: true),
              repo("legacy_application", default_branch: "master")
            ]
          )
        ),
        HoundListSync::Http::Response.new(
          200,
          {},
          JSON.generate([])
        )
      ]
    end

    let(:by_name) { to_a.map { |r| [r.name, r] }.to_h }

    it do
      expect(to_a.map(&:name)).to eq(
        [
          "Example/application",
          "Example/archived_application",
          "Example/disabled_application",
          "Example/legacy_application"
        ]
      )
    end
    it { expect { to_a }.to change { http.requests.length }.from(0).to(3) }
    it do
      expect { to_a }.to change { http.requests.map(&:url) }
        .to(
          [
            "https://api.github.com/orgs/Example/repos?page=1",
            "https://api.github.com/orgs/Example/repos?page=2",
            "https://api.github.com/orgs/Example/repos?page=3"
          ]
        )
    end
    it do
      expect { to_a }.to change { http.requests.map(&:basic_auth) }
        .to([%w[admin qwe123], %w[admin qwe123], %w[admin qwe123]])
    end

    describe "Repo#to_config" do
      context "when regular repo" do
        it do
          expect(by_name.fetch("Example/application").to_config).to eq(
            {
              "url" => "git@github.com:Example/application.git",
              "url-pattern" => {
                "base-url" => "https://github.com/Example/application/blob/main/{path}{anchor}",
                "anchor" => "#L{line}"
              },
              "vcs-config" => {
                "ref" => "main"
              }
            }
          )
        end
      end

      context "when branch changed" do
        it do
          expect(by_name.fetch("Example/legacy_application").to_config).to eq(
            {
              "url" => "git@github.com:Example/legacy_application.git",
              "url-pattern" => {
                "base-url" => "https://github.com/Example/legacy_application/blob/master/{path}{anchor}",
                "anchor" => "#L{line}"
              },
              "vcs-config" => {
                "ref" => "master"
              }
            }
          )
        end
      end
    end

    describe "#indexable?" do
      context "when regular repo" do
        it { expect(by_name.fetch("Example/application")).to be_indexable }
      end

      context "when archived repo" do
        it { expect(by_name.fetch("Example/archived_application")).not_to be_indexable }
      end

      context "when disabled repo" do
        it { expect(by_name.fetch("Example/disabled_application")).not_to be_indexable }
      end
    end
  end
end
