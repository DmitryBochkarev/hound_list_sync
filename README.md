# hound_list_sync

There is a great program to search by source code - [hound](https://github.com/hound-search/hound). But there is a drawback - you need to keep the list of indexed repositories up to date.
**hound_list_sync** solves this problem for organizations on Github and the list of projects in Gitlab.

The concept is simple: you specify the base settings of the hound and a list of extensions applied to it.

It is possible to extend the base configuration with a static repository list and repository lists downloaded from github for organization or projects in gitlab.

## Installation

### Prerequisites

- [ruby](https://ruby-lang.org) >= 2.4

```sh
gem install hound_list_sync
```

## Usage

<details>

<summary>hound_list_sync --help<summary>

```txt
Usage: hound_list_sync [options]
        --base=FILE                  Base Hound Config(required)
        --out=FILE                   Resulting Hound Config(required)
        --extension=FILE             Extension config, allow to have multiple
    -h, --help                       Print this help

    Base config is regular hound config:
        {
          "dbpath" : "db",
          "vcs-config" : {
            "git": {
              "ref" : "main"
            }
          },
          "repos" : {
            "Hound" : {
              "url" : "https://github.com/hound-search/hound.git"
            }
          }
        }

    Extensions configs allow to specify how to enrich base config:
        {
          "repos": {
            "hound_list_sync": {
              "url": "https://github.com/DmitryBochkarev/hound_list_sync.git"
            }
          },
          "lists": {
            "wallarm": {
              "hosting": "github",
              "org": "wallarm",
              "credentials": {
                "login": "DmitryBochkarev",
                "pass": "[OAuth Token]"
              }
            },
            "example.com": {
              "hosting": "gitlab",
              "api_endpoint": "https://gitlab.example.com",
              "token": "[OAuth Token]",
              "allow_list": [
                "example/site/", "example/backoffice/"
              ],
              "block_list": [
                ".*secrets.*"
              ]
            }
          }
        }
```

</details>

Let's take the [basic config](https://github.com/hound-search/hound/blob/main/config-example.json) for the hound as an example:

```json
{
  "dbpath": "db",
  "vcs-config": {
    "git": {
      "ref": "main"
    }
  },
  "repos": {
    "Hound": {
      "url": "https://github.com/hound-search/hound.git"
    }
  }
}
```

Suppose we want to additionally index the list of repositories for the github organization and the list of projects on gitlab:

```json
{
  "lists": {
    "github.com": {
      "hosting": "github",
      "org": "github",
      "credentials": {
        "login": "DmitryBochkarev",
        "pass": "[OAuth token]"
      },
      "block_list": [
        ".*secrets.*",
        ".*example.*",
        ".*terraform.*",
        "\\Agithub/docs\\z"
      ]
    },
    "example.com": {
      "hosting": "gitlab",
      "api_endpoint": "https://gitlab.example.com",
      "token": "[OAuth Token]",
      "allow_list": ["example/site/", "example/backoffice/"],
      "block_list": [".*secrets.*"]
    }
  }
}
```

You can specify `allow_list` and `block_list` lists with regular expressions that filter the final list of repositories.

```sh
hound_list_sync --base=hound_base.json --extension=hound_extension.json --out=hound_config.json
```

This will give us a hound configuration to index the organization's repositories https://github.com/github and the list of projects from our server at gitlab.example.com.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DmitryBochkarev/hound_list_sync.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
