# Freno Throtter [![Build Status](https://travis-ci.org/github/freno-throttler.svg)](https://travis-ci.org/github/freno-throttler)

A ruby throttling system based on [Freno](https://github.com/github/freno): the cooperative, highly available throttler service.

## Current status

`Freno::Throttler`, as [Freno](https://github.com/github/freno) itself, is in active development and its API can still change.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "freno-throttler"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install freno-throttler

## Usage

TBC

## Development

After checking out the repo, run `script/bootstrap` to install dependencies. Then, run `script/test` to run the tests. You can also run `script/console` for an interactive prompt that will allow you to experiment.

## Contributing

This repository is open to [contributions](CONTRIBUTING.md). Contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Releasing

If you are the current maintainer of this gem:

1. Create a branch for the release: `git checkout -b cut-release-vx.y.z`
1. Make sure your local dependencies are up to date: `script/bootstrap`
1. Ensure that tests are green: `bundle exec rake test`
1. Bump gem version in `lib/freno/client/version.rb`
1. Merge a PR to github/freno-throttler containing the changes in the version file
1. Tag and push: `git tag vx.xx.xx; git push --tags`
1. Build the gem: `gem build freno-throttler`
1. Push to rubygems.org: `gem push freno-throttler-x.y.z.gem`

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
