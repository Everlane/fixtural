
module Fixtural
  # Given a `URI` object, return the appropriate adapter `Class` to
  # instantiate or raise an error if no adapter could be found.
  def self.adapter_for_uri uri
    if uri.scheme == 'mysql'
      require 'mysql2'
      return MySQLAdapter
    elsif uri.scheme == 'sqlite3'
      require 'sqlite3'
      return SQLiteAdapter
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

    # Look up the tables from the database.
    def guess_tables
      raise NotImplementedError
    end

    # Runs a 'SELECT * ...' on the given `table`. Returns an `Enumerable` with
    # the results of the query.
    def query_table table
      raise NotImplementedError
    end

    # Returns an `Enumerable` of `String`-likes with the column names of the
    # given table
    def query_table_columns table
      raise NotImplementedError
    end

    protected
      # Called by `guess_tables` to filter the resulting table list
      # according to `SKIP_TABLES`.
      def filter_tables tables
        tables.select {|t| !::Fixtural::Adapter::SKIP_TABLES.include? t }
      end
  end

  class SQLiteAdapter < Adapter
    def initialize downloader, uri
      str = uri.to_s
      path = str.sub /^sqlite3:\/\//, ''
      @path = path
    end
    def connect
      @client = SQLite3::Database.new @path
    end
    def guess_tables
      results = @client.execute "SELECT name FROM sqlite_master WHERE type = 'table';"
      return results.to_a.map {|r| r[0] }
    end
    def query_table table
      rows = @client.execute2("SELECT * FROM #{table};").to_a
      columns = rows.shift

      rows.map do |row|
        columns.each_with_index.inject({}) {|acc, (key, index)|
          acc[key.to_sym] = row[index]
          acc
        }
      end
    end
    def query_table_columns table
      rows = @client.execute2("PRAGMA table_info(#{table});").to_a
      columns = rows.shift

      name_index = columns.index 'name'

      raise RuntimeError, "Missing 'name' column in PRAGMA result" unless name_index

      rows.map { |row| row[name_index] }
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
      filter_tables results.to_a.map {|r| r[0] }
    end

    def query_table table
      @client.query "SELECT * FROM #{table};"
    end
  end# MySQLAdapter
end

