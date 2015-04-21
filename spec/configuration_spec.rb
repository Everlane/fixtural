require 'spec_helper'

describe Fixtural do
  let :config_string do <<-END.gsub(/^ {4}/, '')
    allow_tables:
      - a

    disallow_tables:
      - b
    END
  end

  it 'reads configuration' do
    config_hash = YAML.load config_string
    Fixtural.read_configuration config_hash
    # Extract the Fixtural::Configuration instance
    expect(Fixtural.configuration).to be
  end

  describe 'configuration' do
    subject { Fixtural.configuration }

    it 'correctly read configuration' do
      expect(subject.allow_tables).to eql(['a'])
      expect(subject.disallow_tables).to eql(['b'])
    end
  end

end

