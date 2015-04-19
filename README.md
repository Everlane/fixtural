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

## TODO

- Additional database adapters (SQLite, PostgreSQL)
- Downloading fixtures from remote (ie. admin downloads production DB to S3, then users download from S3 to local)
- Multi-environment support (for the above, so you can do `FIXTURAL_ENV=admin` for privileged downloading)

### Contributing

1. Fork it (https://github.com/[my-github-username]/fixtural/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a pull request

