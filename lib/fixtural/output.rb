require 'tempfile'

require 'fog/core'
require 'fog/aws'

module Fixtural

  class OutputStore
    def open path, &block
      raise NotImplementedError
    end
  end

  class FileOutputStore < OutputStore
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

  class S3OutputStore < OutputStore
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


  class OutputWriter
    def write object
      raise NotImplementedError
    end
    def done
      raise NotImplementedError
    end
  end

  class YAMLOutputWriter < OutputWriter
    def initialize io
      @io = io
      @io.write "---\n"
      @checked = false
    end

    # Write a given `object` to the fixture output stream.
    def write object
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
end# Fixtural

