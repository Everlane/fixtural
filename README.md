# Fixtural

Fixtural makes it easy to safely download production data into local fixtures YAML files use in development/test databases.

## Installation and usage

Fixtural integrates with your existing Rake task set.

First add it to your application's Gemfile or similar:

```ruby
gem 'fixtural'
```

Then add the loader to your Rakefile:

```ruby
require 'fixtural/rakelib'
```

You'll then have some helpful Rake tasks to download a database into your fixtures:

```bash
# Downloading a database
REMOTE_DB=mysql://username:password@host/db rake fixtural:download

# Fixtures will now be in test/fixtures/ or spec/fixtures/, whichever
# is found first.
```

## Configuration

Fixtural supports three ways for downloading fixture data:

1. Tables from any accessible database server
2. Tables-as-files from the filesystem
3. Tables-as-files from Amazon S3

It can then output that downloaded data to:

1. The local filesystem
2. Amazon S3

Downloaded data is currently only available in the S3 format, however MySQL-compatible SQL output is in development.

## To-do

- Additional database adapters (MySQL (pull request [#1](https://github.com/Everlane/fixtural/pull/1)), PostgreSQL)
- Downloading fixtures from remote (ie. admin downloads production DB to S3, then users download from S3 to local)
- Multi-environment support (for the above, so you can do `FIXTURAL_ENV=admin` for privileged downloading)

## Contributing

1. Fork it
2. Create a branch and implement your changes
3. Push to the branch
4. Create a [pull request](https://github.com/Everlane/fixtural/pull/new)
