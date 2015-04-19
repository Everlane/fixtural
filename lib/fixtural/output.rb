
module Fixtural

  class OutputStore
    def open path, &block
      raise NotImplementedError
    end
  end

  class FileOutputStore
    def open path, &block
      fd = File.open(path, 'w')
      if block
        block.call fd
        fd.close
      end
    end
  end

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

