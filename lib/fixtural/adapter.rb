
module Fixtural

  def self.adapter_for_uri uri
    if uri.scheme == 'mysql'
      require 'mysql2'
      return MySQLAdapter
    else
      raise "No adapter found for scheme '#{uri.scheme}'"
    end
  end

  class MySQLAdapter
    SKIP_TABLES = ['schema_migrations']

    def initialize downloader, uri
      @downloader = downloader
      @uri        = uri
    end
    def connect!
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
      return results.to_a.map {|t| t.first }.select {|t| !SKIP_TABLES.include? t }
    end

    def query_table table, &block
      results = @client.query "SELECT * FROM #{table};"
      results.each do |row|
        block.call row
      end
    end
  end# MySQLAdapter
end

