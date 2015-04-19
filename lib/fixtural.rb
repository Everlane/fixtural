# require 'fog'
require 'yaml'

require 'fixtural/version'

require 'fixtural/adapter'
require 'fixtural/configuration'
require 'fixtural/downloader'
require 'fixtural/output'

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

      # Check for the configuration file
      configuration_path = File.join(pwd, 'config', 'fixtures.yml')
      if File.exist? configuration_path
        read_config_file configuration_path
      end

      # Default to file output storage if one wasn't set up by the
      # config file.
      unless @configuration.output_store
        @configuration.output_store = FileOutputStore.new @configuration.download_directory
      end
    end

    def read_config_file path
      config = ::YAML.load_file path
      ['allow_tables', 'disallow_tables'].each do |prop|
        if config[prop]
          @configuration.send (prop+'=').to_sym, config[prop]
        end
      end

      if config['output']
        setup_output_store config['output']
      end

      env = ENV['FIXTURAL_ENV']
      environments = config['environments']
      if env && environments
        current_env = environments[env]
        if current_env
          setup_output_store(current_env['output']) if current_env['output']
        end
        puts "Using environment '#{env}'"
      end
    end

    def setup_output_store output_config
      store  = output_config['store']
      case store
      when 'local'
        @configuration.output_store = FileOutputStore.new output_config['path']
      else
        raise "Don't know how to configure output store of type '#{store}'"
      end
    end

    def configure
      @configuration.remote_db = ENV['REMOTE_DB'] if ENV['REMOTE_DB']
    end

  end# << self
end# Fixtural

