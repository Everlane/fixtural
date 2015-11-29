require 'spec_helper'

require 'tempfile'
require 'psych'

describe Fixtural do
  before :all do
    # Setup the database file
    db_path = File.expand_path('../data/database.sqlite', __FILE__)
    if File.exist? db_path
      File.unlink db_path
    end
    FileUtils.touch db_path

    # Then actually setup the database
    @db = SQLite3::Database.new db_path
    @db.execute 'CREATE TABLE rows (num int);'

    (1..3).each do |i|
      @db.execute "INSERT INTO rows (num) VALUES (#{i});"
    end

    rows_path = File.expand_path('../data/output/rows.yml', __FILE__)
    File.unlink(rows_path) if File.exist? rows_path
  end

  it 'has a version number' do
    expect(Fixtural::VERSION).not_to be nil
  end

  it 'downloads the database' do
    data_path = File.expand_path '../data', __FILE__
    output    = nil
    Dir.chdir data_path do
      output = `REMOTE_DB=sqlite3://database.sqlite rake fixtural:download`
    end

    # Check that it exited without error and outputted something sensible
    expect($?).to eq(0)
    expect(output).to include('Downloading 1 tables:')
  end

  it 'produces a fixtures file' do
    rows_path = File.expand_path '../data/output/rows.yml', __FILE__
    expect(File.exist? rows_path).to be true

    data = YAML.load_file rows_path
    # Check that it produced the right ordering of rows
    expect(data.keys).to eql([0, 1, 2])
    expect(data[0]).to eql({:num => 1})
    expect(data[1]).to eql({:num => 2})
    expect(data[2]).to eql({:num => 3})
  end
end
