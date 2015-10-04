# DaDem analysis

[DaDem](https://github.com/mysociety/internal-services/blob/master/services/DaDem/DaDem.pm) is [RABX](https://github.com/mysociety/commonlib/blob/master/perllib/RABX.pm) server and an internal service of [mySociety](https://www.mysociety.org/).

There are DaDem clients in:

* [Perl](https://github.com/mysociety/commonlib/blob/master/perllib/mySociety/DaDem.pm)
* [PHP](https://github.com/mysociety/commonlib/blob/master/phplib/dadem.php)
* [Python](https://github.com/mysociety/commonlib/blob/master/pylib/mysociety/dadem.py)

A recipient has the properties:

* `id`: integer
* `voting_area`: integer, MapIt area ID
* `type`: string, voting area type, three-letter Ordnance Survey-like code
* `name`: string
* `party`: string
* `email`: string
* `fax`: string
* `method`: string, `"either"`, `"fax"`, `"email"`, `"via"`, `"shame"`, `"unknown"`
* `deleted`: boolean
* `last_editor`: string, `"import"`, `"dadem_csv_load"`, `"fyr-queue"` or username
* `parlparse_person_id`: string, e.g. `"uk.org.publicwhip/person/12345"`
* `edit_times`: integer
* `whencreated`: UNIX timestamp
* `whenlastedited`: UNIX timestamp

DaDem data is sourced from:

* [scrapers](https://github.com/mysociety/internal-services/tree/master/services/mapit-dadem-loading/scrapers)
* [GovEval](http://www.goveval.com/) for the names and parties of councillors

## Analysis

```
bundle exec ruby dadem/scraper.rb -q
mongo pupa variety.js --eval 'var collection = "representatives"'
mongo pupa analyze.js
```
