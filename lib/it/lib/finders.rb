#!/usr/bin/ruby
class It
  class Finders
    attr_accessor :location

    def initialize(*args, **kwargs)
      @location = nil
    end

    def find(fn_p, goto_parent_dir: false, remove_trailing_slash: true, **kwargs)
      @location = nil
      fn = fn_p.to_s.strip
      fn.sub!(/^\/+/, "") if remove_trailing_slash
      if File.readable?(fn)
        @location = fn
      else
        Dir.chdir(goto_parent_dir ? '..' : '.') do
          bn = File.basename(fn)
          files = Dir.glob("./**/#{bn}")
          It.debug("[Finders] RESULT='#{files.inspect}'")
          if files.length > 0
            @location = files[-1]
          else
            @location = nil
          end
        end
      end
      return @location
    end  # find
  end  # class Finders
end  # class It
# ----------
