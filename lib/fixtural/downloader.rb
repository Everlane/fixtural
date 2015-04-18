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
      @adapter = (Fixtural.adapter_for_uri db_uri).new(self, db_uri)
      # Actually connect to the database and figure out which tables we need
      # to download
      @adapter.connect!

      if @configuration.download_tables
        tables = @configuration.download_tables
      else
        tables = @adapter.guess_tables
      end

      total = tables.length
      tables.each_with_index do |table, index|
        path = File.join(@download_directory, "#{table}.yml")
        File.open(path, 'w') do |fd|
          writer = ::Fixtural::YAMLOutputWriter.new(fd)
          download_table table, writer
          writer.done
        end
        puts "- Downloaded #{table} (#{index.to_s}/#{total.to_s})"
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

  end# Downloader
end# Fixtural

