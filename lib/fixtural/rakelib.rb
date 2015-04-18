require 'fixtural'

# First guess the configuration from the environment
Fixtural.infer_configuration

# Then overwrite that with user-provided configuration
Fixtural.configure

namespace :fixtural do

  desc 'Download database into local storage'
  task :download do
    downloader = Fixtural::Downloader.new(Fixtural.configuration)
    downloader.run!
  end

  desc 'Load downloaded database into local environment'
  task :load do
  end

  desc 'Show configuration information'
  task :configuration do
    Fixtural.configuration.print
  end

end

