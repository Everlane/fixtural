# require 'fog'
require 'yaml'

require 'fixtural/version'

require 'fixtural/adapter'
require 'fixtural/configuration'
require 'fixtural/downloader'
require 'fixtural/input'
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
        read_configuration(::YAML.load_file configuration_path)
      end

      # Default to file output storage if one wasn't set up by the
      # config file.
      unless @configuration.output_store
        @configuration.output_store = FileOutputStore.new @configuration.download_directory
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
      if config['output']
        configure_output_store config['output']
      end

      env = ENV['FIXTURAL_ENV']
      environments = config['environments']
      if env && environments
        current_env = environments[env]
        if current_env
          configure_output_store(current_env['output']) if current_env['output']
          configure_input_store(current_env['input']) if current_env['input']
        end
        puts "Using environment '#{env}'"
      end
    end

    def configure_output_store output_config
      store = output_config['store']
      case store
      when 'local'
        @configuration.output_store = FileOutputStore.new output_config['path']
      when 'S3'
        @configuration.output_store = S3OutputStore.new output_config
      else
        raise "Don't know how to configure output store of type '#{store}'"
      end
    end
    def configure_input_store input_config
      store = input_config['store']
      case store
      when 'local'
        @configuration.input_store = FileInputStore.new input_config['path']
      when 'S3'
        @configuration.input_store = S3InputStore.new input_config
      else
        raise "Don't know how to configure input store of type '#{store}'"
      end
    end

    def configure
      @configuration.remote_db = ENV['REMOTE_DB'] if ENV['REMOTE_DB']
    end

    def setup_downloader
      if @configuration.remote_db
        return DatabaseDownloader.new @configuration
      elsif @configuration.input_store
        return FileDownloader.new @configuration.input_store, @configuration.output_store
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

