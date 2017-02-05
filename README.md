# Pupa Scrapers for Canada in Ruby

The [bulk of Pupa scrapers](http://github.com/opencivicdata/scrapers-ca) for Canada are written in Python.

The `ca` scraper in the [`scrapers-ca`](https://github.com/opencivicdata/scrapers-ca/) repository depends on the `ca` scraper in this repository.

The `ca_qc_montreal` scraper in this repository is intended for `mamairie.ca`. [Represent](https://represent.opennorth.ca/) uses the `ca_qc_montreal` scraper in the [`scrapers-ca`](https://github.com/opencivicdata/scrapers-ca/) repository, which is dedicated to elected officials' contact information.

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

## API

    foreman start

* `GET /memberships?in_network_of=ocd-organization/country:ca/csd:2466023/council`
* `GET /memberships?organization_id=ocd-organization/country:ca/csd:2466023/council`
* `GET /memberships?person_id=3e305d54-75b4-431b-adb2-eb6b9e546013`
* `GET /memberships?id=1e305d54-75b4-431b-adb2-eb6b9e546013`
* `GET /organizations?in_network_of=ocd-organization/country:ca/csd:2466023/council`
* `GET /organizations?id=2e305d54-75b4-431b-adb2-eb6b9e546013`
* `GET /people?member_of=ocd-organization/country:ca/csd:2466023/council`
* `GET /people?id=3e305d54-75b4-431b-adb2-eb6b9e546013`
* `GET /posts?organization_id=ocd-organization/country:ca/csd:2466023/council`
* `GET /posts?id=4e305d54-75b4-431b-adb2-eb6b9e546013`
* `GET /ocd-organization/country:ca/csd:2466023/council`

## Deployment

    heroku apps:create
    heroku addons:add flydata
    heroku addons:add memcachier
    heroku addons:add mongolab
    heroku addons:add rediscloud
    heroku addons:add scheduler

Schedule jobs to run daily, for example:

    ruby ca/scraper.rb --pipelined -q -a scrape -a import -a update
    ruby ca_qc_montreal/scraper.rb --pipelined -q -t organizations -t posts -t people

## Bugs? Questions?

This repository is on GitHub: [http://github.com/opennorth/scrapers-ca-ruby](http://github.com/opennorth/scrapers-ca-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
