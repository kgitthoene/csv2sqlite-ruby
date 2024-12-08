#!/usr/bin/ruby
class It
  class FN
    class << self
      #----------
      # Remove the extension from a filename.
      #
      # Params:
      # +*args+:: Array of filenames.
      #
      # Returns:
      # +String+:: If +*args+ contains only one string.
      # +Array+:: Array of strings, if +*args+ contains more than one string.
      #
      # Examples:
      #    basename_without_extension = It::FD.rm_ext("data.csv")
      #    => "data"
      #
      #    basenames_without_extension = It::FD.rm_ext([ "data.csv", "data2.csv" ])
      #    => [ "data", "data2" ]
      def rm_ext(*args)
        result = []
        args.each do |arg|
          arg = arg.to_s.strip
          result << File.basename(arg, File.extname(arg))
        end
        return ((result.length == 1) ? result[0] : ((result.length == 0) ? [] : result))
      end  # rm_ext
      #
    end  # class << self
  end  # class FN
end  # class It
#----------
