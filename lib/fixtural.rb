# require 'fog'

require 'fixtural/version'
require 'fixtural/configuration'
require 'fixtural/downloader'

module Fixtural
  # Initialize module instance variables
  @configuration = Configuration.new

  class << self
    attr_reader :configuration
    
    def infer_configuration
      pwd = Rake.application.original_dir

      spec_fixtures_path = File.join(pwd, 'spec', 'fixtures')
      test_fixtures_path = File.join(pwd, 'test', 'fixtures')
      if Dir.exist? spec_fixtures_path
        @configuration.download_directory = spec_fixtures_path
      elsif Dir.exist? test_fixtures_path
        @configuration.download_directory = test_fixtures_path
      end
    end

    def configure
      @configuration.remote_db = ENV['REMOTE_DB'] if ENV['REMOTE_DB']
    end

  end# << self
end# Fixtural

