require 'spec_helper'

describe Fixtural do
  let :config_string do <<-END.gsub(/^ {4}/, '')
    allow_tables:
      - a

    disallow_tables:
      - b

    environments:
      test:
        destination:
          store: 'local'
          path:  'spec/data/output'
    END
  end

  before :all do
    ENV['FIXTURAL_ENV'] = 'test'
  end

  it 'reads configuration' do
    config_hash = YAML.load config_string
    expect {
      Fixtural.read_configuration config_hash
    }.to output.to_stdout
    # Extract the Fixtural::Configuration instance
    expect(Fixtural.configuration).to be_a(Fixtural::Configuration)
  end

  describe 'configuration' do
    subject { Fixtural.configuration }

    it 'correctly read allow/disallow' do
      expect(subject.allow_tables).to eql(['a'])
      expect(subject.disallow_tables).to eql(['b'])
    end

    it 'correctly read configured destination' do
      output = subject.destination_store
      expect(output).to be_a(Fixtural::FileDestinationStore)
      expect(output.root).to eql('spec/data/output')
    end
  end

end
