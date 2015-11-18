require 'tempfile'

require 'fog/core'
require 'fog/aws'

module Fixtural

  class DestinationStore
    def open path, &block
      raise NotImplementedError
    end
  end

  class FileDestinationStore < DestinationStore
    attr_reader :root
    def initialize root
      @root = root
    end
    def open path, &block
      path = File.join @root, path
      fd = File.open(path, 'w')
      if block
        block.call fd
        fd.close
      end
    end
  end

  class S3DestinationStore < DestinationStore
    def initialize opts
      @path       = opts.delete 'path'
      @connection = Fixtural.create_s3_storage opts

      raise 'Missing path for fixtures' unless @path

      @directory = @connection.directories.get(@path)
      # Create directory if it doesn't exist
      if @directory.nil?
        @directory = @connection.directories.create key: @path
      end
    end
    def open path, &block
      raise 'Block required' unless block
      temp = Tempfile.new path
      begin
        block.call temp
        # Upload the file
        file = @directory.files.create(
          key: path,
          body: temp
        )
      ensure
        # Always cleanup the temp resource
        temp.close
        temp.unlink
      end
    end# open
  end# S3OutputStore

  def self.output_writer_for_name name
    case name
    when 'yaml'
      YAMLOutputWriter
    when 'mysql2'
      MySQL2OutputWriter
    else
      raise RuntimeError, "Output writer not found: '#{name}'"
    end
  end

  class OutputWriter
    def initialize io, table_name, columns
      raise NotImplementedError
    end

    # Return the extension to use for the file written by this output-writer
    def self.extension
      raise NotImplementedError
    end

    # Write a key-value object (hash-like) to the output
    def write object, index
      raise NotImplementedError
    end

    # Called once-and-only-once after all items have been written
    def done
      raise NotImplementedError
    end
  end

  class YAMLOutputWriter < OutputWriter
    def initialize io, _table_name, _columns
      @io = io
      @io.write "---\n"
      @checked = false
    end

    def self.extension
      'yml'
    end

    # Write a given `object` to the fixture output stream.
    def write row, _index
      # Rails' fixture format has each row be a hash mapping the index
      # to the row data hash
      object = {index => row}

      # Convert the index-object to YAML
      data = object.to_yaml
      # Check conformance of the objects if we haven't already
      if !@checked
        detect_slicing_offsets data
        @checked = true
      end
      # Figure out which parts we need to chop off
      data = data.slice(@head_offset, data.length - @tail_offset)
      @io.write data
    end

    def done
    end

    protected
      def detect_slicing_offsets data
        @strip_head = (data =~ /^---\n/) ? true : false
        @strip_tail = (data =~ /\.\.\.\n$/) ? true: false
        @head_offset = @strip_head ? 4 : 0
        @tail_offset = (@strip_tail ? 4 : 0) + @head_offset
      end

  end# YAMLOutputWriter

  class MySQL2OutputWriter < OutputWriter
    BATCH_SIZE = 20

    def initialize io, table_name, columns
      @io         = io
      @table_name = table_name
      @columns    = columns

      self.class.require_sequel

      # Create non-connected SQL adapter
      @database = ::Sequel.mysql2 :preconnect => false

      @batch = []
    end

    def self.extension
      'sql'
    end
    def self.require_sequel
      require 'sequel'
    end

    def write row, _index
      @batch << row

      flush if @batch.length >= BATCH_SIZE
    end

    def done
      flush if @batch.length > 0
    end

    private

    def flush
      rows = @batch

      columns = @columns.map &:to_sym

      # `rows` is an array of hashes, we need to convert it into an array
      # of arrays for generating the INSERT
      rows.map! do |row|
        columns.map { |column| row[column]  }
      end

      sql_statements = @database[@table_name.to_sym].multi_insert_sql columns, rows

      @io.write sql_statements[0]
      @io.write ";\n"

      @batch = []
    end

  end
end# Fixtural
