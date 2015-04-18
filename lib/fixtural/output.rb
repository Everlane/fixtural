
module Fixtural
  class YAMLOutputWriter
    def initialize io
      @io = io
      @io.write "---\n"
      @checked = false
    end
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
    def detect_slicing_offsets data
      @strip_head = (data =~ /^---\n/) ? true : false
      @strip_tail = (data =~ /\.\.\.\n$/) ? true: false
      @head_offset = @strip_head ? 4 : 0
      @tail_offset = (@strip_tail ? 4 : 0) + @head_offset
    end
    def done
    end
  end
end
