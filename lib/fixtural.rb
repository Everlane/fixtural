# require 'fog'
require 'yaml'

require 'fixtural/version'

require 'fixtural/adapter'
require 'fixtural/configuration'
require 'fixtural/downloader'
require 'fixtural/stores/source'
require 'fixtural/stores/destination'

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
        read_configuration(::YAML.load_file configuration_path)
      end

      # Default to file destination store if one wasn't set up by the
      # config file
      unless @configuration.destination_store
        @configuration.destination_store = FileDestinationStore.new @configuration.download_directory
      end
    end

    def read_configuration config
      [
        'allow_tables',
        'disallow_tables',
        'download_directory'
      ].each do |prop|
        if config[prop]
          @configuration.send (prop+'=').to_sym, config[prop]
        end
      end

      # Default to the top-level-configured output store (if present);
      # override that with environment-specific output store
      # configurations below.
      if config['destination']
        configure_destination_store config['destination']
      end

      env = ENV['FIXTURAL_ENV']
      environments = config['environments']
      if env && environments
        current_env = environments[env]
        if current_env
          configure_destination_store(current_env['destination']) if current_env['destination']
          configure_source_store(current_env['source']) if current_env['source']
        end
        puts "Using environment '#{env}'"
      end
    end

    def configure_destination_store destination_config
      store = destination_config['store']
      case store
      when 'local'
        @configuration.destination_store = FileDestinationStore.new destination_config['path']
      when 'S3'
        @configuration.destination_store = S3DestinationStore.new destination_config
      else
        raise "Don't know how to configure destination store of type '#{store}'"
      end
    end
    def configure_source_store source_config
      store = source_config['store']
      case store
      when 'local'
        @configuration.source_store = FileSourceStore.new source_config['path']
      when 'S3'
        @configuration.source_store = S3SourceStore.new source_config
      else
        raise "Don't know how to configure source store of type '#{store}'"
      end
    end

    def configure
      @configuration.remote_db = ENV['REMOTE_DB'] if ENV['REMOTE_DB']
    end

    def setup_downloader
      if @configuration.remote_db
        return DatabaseDownloader.new @configuration
      elsif @configuration.source_store
        return FileDownloader.new(
          @configuration.source_store,
          @configuration.destination_store
        )
      else
        raise 'No remote database or file store from which to download'
      end
    end


    def create_s3_storage opts
      # Convert keys to symbols
      opts = opts.inject({}) do |acc, pair|
        key, value = pair
        acc[key.to_sym] = value
        acc
      end
      opts.delete :store
      opts[:provider]              = 'AWS'
      opts[:aws_access_key_id]     = opts.delete :access_key_id
      opts[:aws_secret_access_key] = opts.delete :secret_access_key
      return Fog::Storage.new opts
    end

  end# << self
end# Fixtural
