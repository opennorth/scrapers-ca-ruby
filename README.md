# Pupa Scrapers for Canada in Ruby

The [bulk of Pupa scrapers](http://github.com/opencivicdata/scrapers-ca) for Canada are written in Python.

## Getting Started

Install Git, Ruby 2.x and MongoDB. We recommend [rbenv](https://github.com/sstephenson/rbenv) to manage your Rubies.

Install the Bundler gem:

    gem install bundler

Get the code:

    git clone https://github.com/opennorth/scrapers-ca-ruby.git
    cd scrapers-ca-ruby

Install gem dependencies:

    bundle

Run a scraper with, for example:

    ruby ca_qc_montreal/scraper.rb

## Deployment

    heroku addons:add memcachier
    heroku addons:add rediscloud
    heroku addons:add mongolab
    heroku addons:add scheduler

Schedule job, for example:

    ruby ca_ns/scraper.rb --pipelined --no-validate -q -t people

## Bugs? Questions?

This repository is on GitHub: [http://github.com/opennorth/scrapers-ca-ruby](http://github.com/opennorth/scrapers-ca-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
