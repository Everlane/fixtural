
module Fixtural
  # Given a `URI` object, return the appropriate adapter `Class` to
  # instantiate or raise an error if no adapter could be found.
  def self.adapter_for_uri uri
    if uri.scheme == 'mysql'
      require 'mysql2'
      return MySQLAdapter
    else
      raise "No adapter found for scheme '#{uri.scheme}'"
    end
  end

  class Adapter
    SKIP_TABLES = ['schema_migrations']

    # Connect to the database.
    def connect
      raise NotImplementedError
    end

    # Look up all the tables from the database; skip any tables set in the
    # `SKIP_TABLES` array.
    def guess_tables
      raise NotImplementedError
    end

    # Runs a 'SELECT * ...' on the given `table`. Returns an `Enumerable` with
    # the results of the query.
    def query_table table
      raise NotImplementedError
    end
  end

  class MySQLAdapter < Adapter

    def initialize downloader, uri
      @downloader = downloader
      @uri        = uri
    end

    def connect
      opts = {
        host: @uri.host,
        database: @uri.path.sub(/^\//, '')
      }
      if @uri.userinfo
        username, password = @uri.userinfo.split(':', 2)
        opts[:username] = username
        opts[:password] = password if password
      end
      # TODO: Parse more options from the URI
      @client = Mysql2::Client.new opts
    end

    def guess_tables
      results = @client.query 'SHOW TABLES;', as: :array
      return results.to_a.map {|t| t.first }.select {|t|
        !::Fixtural::Adapter::SKIP_TABLES.include? t
      }
    end

    def query_table table
      @client.query "SELECT * FROM #{table};"
    end
  end# MySQLAdapter
end

