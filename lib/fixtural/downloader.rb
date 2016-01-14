require 'set'
require 'uri'
require 'psych'

require 'ruby-progressbar'

module Fixtural
  class DatabaseDownloader
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
      @adapter.connect()

      # Figure out the tables we need to download
      tables = compute_table_list()

      total = tables.length
      puts "Downloading #{total.to_s} tables:"
      # Setup the output store and write tables to it
      destination_store = @configuration.destination_store
      tables.each_with_index do |table, index|
        progressbar = ProgressBar.create(
          format: "- #{table} (#{(index+1).to_s}/#{total.to_s}) (%j%%)"
        )
        name = "#{table}.yml"
        destination_store.open(name) do |fd|
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
  end# DatabaseDownloader

  # Downloads files from `source_store` into `destination_store`
  class FileDownloader
    def initialize source_store, destination_store
      @source      = source_store
      @destination = destination_store
    end

    def run!
      files = @source.files

      total = files.length
      index = 0
      puts "Downloading #{total.to_s} files:"
      files.each do |name|
        # Skip files not ending with .yml
        next unless name =~ /\.yml$/
        # Then copy from the input store to the output store
        @destination.open name do |fd|
          fd.write @source.read(name)
        end
        puts "- #{name} (#{(index+1).to_s}/#{total.to_s})"
        index += 1
      end
    end
  end# FileDownloader

end# Fixtural
