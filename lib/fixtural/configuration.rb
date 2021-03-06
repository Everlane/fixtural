
module Fixtural
  class Configuration
    # Controlling where the output goes
    attr_accessor :output_store, :download_directory, :output_format

    # Properties for downloading from the remote
    attr_accessor :remote_db, :download_tables,
                  :allow_tables, :disallow_tables

    # Or for downloading from a filesystem
    attr_accessor :source_store

    DOWNLOAD_PROPERTIES = [
      ['Remote database', 'remote_db'],
      ['Download directory', 'download_directory']
    ]
    def print
      puts 'Downloading:'
      print_properties DOWNLOAD_PROPERTIES
    end

    def initialize
      # Set defaults
      self.output_format = 'yaml'
    end

    private
      def print_properties props
        props.each do |pair|
          name, key = pair
          puts " - #{name} (#{key})".ljust(42)+' = '+self.send(key.to_sym).inspect
        end
      end
  end# Configuration
end
