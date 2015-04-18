require 'uri'
require 'psych'

module Fixtural
  class Downloader
    def initialize configuration
      @configuration = configuration
      # Unpack and check some stuff from the config
      @download_directory = @configuration.download_directory
      unless @download_directory
        raise 'Missing `download_directory` to download databasae-as-fixtures into'
      end
    end

    def run!
      db_uri = URI.parse(@configuration.remote_db)
      @adapter = (adapter_for_uri db_uri).new(self, db_uri)
      # Actually connect to the database and figure out which tables we need
      # to download
      @adapter.connect!

      if @configuration.download_tables
        tables = @configuration.download_tables
      else
        tables = @adapter.guess_tables
      end
      tables = tables.slice 0, 10
      
      total = tables.length
      tables.each_with_index do |table, index|
        path = File.join(@download_directory, "#{table}.yml")
        File.open(path, 'w') do |fd|
          writer = YAMLOutputWriter.new(fd)
          download_table table, writer
          writer.done
        end
        puts "- Downloaded #{table} (#{index.to_s}/#{total.to_s})"
      end
    end

    class YAMLOutputWriter
      def initialize io
        @io = io
        @io.write "---\n"
      end
      def write object
        # Convert the index-object to YAML and strip off the document start and end tag
        data = object.to_yaml
        data.sub!(/^---\n/, '')
        data.sub!(/\.\.\.\n$/, '')
        @io.write data
      end
      def done
      end
    end

    def download_table table, output_writer
      index = 0
      @adapter.query_table(table) do |row|
        data = {}
        data[index] = row
        output_writer.write data
        index += 1
      end
    end

    def adapter_for_uri uri
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

  end# Downloader
end# Fixtural

