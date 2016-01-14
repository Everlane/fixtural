
module Fixtural
  class SourceStore
    def files
      raise NotImplementedError
    end
    def read name
      raise NotImplementedError
    end
  end

  class FileSourceStore < SourceStore
    def initialize path
      @path = path
    end
    def files
      Dir.entries(@path).select {|n| !n.start_with? '.' }
    end
    def read name
      return File.read(File.join @path, name)
    end
  end

  class S3SourceStore < SourceStore
    def initialize opts
      @path       = opts.delete 'path'
      @connection = Fixtural.create_s3_storage opts
      @directory  = @connection.directories.get(@path)
      if @directory.nil?
        if Fog.mock?
          @directory = @connection.directories.create key: @path
        else
          raise "Directory not found '#{@path}'"
        end
      end
    end
    def files
      @directory.files.map {|file| file.key }
    end
    def read name
      @directory.files.get(name).body
    end
  end
end
