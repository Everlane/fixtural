require 'set'
require 'uri'
require 'psych'
require 'ruby-progressbar'

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

    # Connect to the remote database (specified in the `Configuration`) and
    # download its tables' contents as fixtures.
    def run!
      db_uri = URI.parse(@configuration.remote_db)
      @adapter = (Fixtural.adapter_for_uri db_uri).new(self, db_uri)
      # Actually connect to the database and figure out which tables we need
      # to download
      @adapter.connect!

      # Figure out the tables we need to download
      tables = compute_table_list()

      total = tables.length
      puts "Downloading #{total.to_s} tables:"
      tables.each_with_index do |table, index|
        path = File.join(@download_directory, "#{table}.yml")
        progressbar = ProgressBar.create(
          format: "- #{table} (#{(index+1).to_s}/#{total.to_s}) (%j%%)"
        )
        File.open(path, 'w') do |fd|
          writer = ::Fixtural::YAMLOutputWriter.new(fd)
          download_table table, writer, progressbar
          writer.done
        end
      end
    end

    # Computes which tables to download from the remote; either via
    # configuration or by querying the remote for its actual list
    # of tables.
    def compute_table_list
      if @configuration.download_tables
        # If the list is explicitly set then use that
        tables = @configuration.download_tables.to_set
      else
        # Otherwise guess via the tables actually in the database
        tables = @adapter.guess_tables.to_set

        if @configuration.allow_tables
          # Only allow tables tables that we specify
          tables = tables.intersection @configuration.allow_tables
        end
        if @configuration.disallow_tables
          # Remove any tables that we don't want included
          tables = tables.difference @configuration.disallow_tables
        end
      end
      return tables
    end

    def download_table table, output_writer, progressbar
      results = @adapter.query_table(table)
      progressbar.total = results.count
      index = 0
      results.each do |row|
        data = {}
        data[index] = row
        output_writer.write data

        index += 1
        progressbar.increment
      end
    end

  end# Downloader
end# Fixtural

