
module Fixtural
  class Configuration
    # Controlling where the output goes
    attr_accessor :output_store, :download_directory

    # Properties for downloading from the remote
    attr_accessor :remote_db, :download_tables,
                  :allow_tables, :disallow_tables

    DOWNLOAD_PROPERTIES = [
      ['Remote database', 'remote_db'],
      ['Download directory', 'download_directory']
    ]
    def print
      puts 'Downloading:'
      print_properties DOWNLOAD_PROPERTIES
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

