# frozen_string_literal: true

require "hound_list_sync/http/fake"

RSpec.describe HoundListSync::Repositories::Gitlab do
  let(:repositories) do
    described_class.new(
      "https://gitlab.example.com",
      token: token,
      http: http
    )
  end
  let(:http) { HoundListSync::Http::Fake.new(responses) }
  let(:token) { "qwe123" }

  def repo(name, archived: false, empty_repo: false, default_branch: "main")
    {
      "name" => name,
      "name_with_namespace" => "Example / Site / #{name}",
      "path" => name,
      "path_with_namespace" => "example/site/#{name}",
      "default_branch" => default_branch,
      "ssh_url_to_repo" => "git@gitlab.example.com:example/site/#{name}.git",
      "http_url_to_repo" => "https://gitlab.example.com/example/site/#{name}.git",
      "web_url" => "https://gitlab.example.com/example/site/#{name}",
      "empty_repo" => empty_repo,
      "archived" => archived
    }
  end

  describe "#to_a" do
    subject(:to_a) { repositories.to_a }

    let(:responses) do
      [
        HoundListSync::Http::Response.new(
          200,
          {
            "x-next-page" => "2"
          },
          JSON.generate(
            [
              repo("application"),
              repo("archived_application", archived: true)
            ]
          )
        ),
        HoundListSync::Http::Response.new(
          200,
          {
            "x-next-page" => ""
          },
          JSON.generate(
            [
              repo("empty_application", empty_repo: true),
              repo("legacy_application", default_branch: "master")
            ]
          )
        )
      ]
    end

    let(:by_name) { to_a.map { |r| [r.name, r] }.to_h }

    it do
      expect(to_a.map(&:name)).to eq(
        [
          "example/site/application",
          "example/site/archived_application",
          "example/site/empty_application",
          "example/site/legacy_application"
        ]
      )
    end
    it { expect { to_a }.to change { http.requests.length }.from(0).to(2) }
    it do
      expect { to_a }.to change { http.requests.map(&:url) }
        .to(
          [
            "https://gitlab.example.com/api/v4/projects?page=1",
            "https://gitlab.example.com/api/v4/projects?page=2"
          ]
        )
    end
    it do
      expect { to_a }.to change { http.requests.map { |r| r.headers["Authorization"] } }
        .to(["Bearer qwe123", "Bearer qwe123"])
    end

    describe "Repo#to_config" do
      context "when regular repo" do
        it do
          expect(by_name.fetch("example/site/application").to_config).to eq(
            {
              "url" => "git@gitlab.example.com:example/site/application.git",
              "url-pattern" => {
                "base-url" => "https://gitlab.example.com/example/site/application/blob/main/{path}{anchor}",
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
          expect(by_name.fetch("example/site/legacy_application").to_config).to eq(
            {
              "url" => "git@gitlab.example.com:example/site/legacy_application.git",
              "url-pattern" => {
                "base-url" => "https://gitlab.example.com/example/site/legacy_application/blob/master/{path}{anchor}",
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
        it { expect(by_name.fetch("example/site/application")).to be_indexable }
      end

      context "when archived repo" do
        it { expect(by_name.fetch("example/site/archived_application")).not_to be_indexable }
      end

      context "when empty repo" do
        it { expect(by_name.fetch("example/site/empty_application")).not_to be_indexable }
      end
    end
  end
end
