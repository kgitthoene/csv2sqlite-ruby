#!/usr/bin/ruby
class It
  class Gl
    @@me = $PROGRAM_NAME.to_s
    @@myname = File.basename(@@me)
    @@mydir = File.dirname(@@me)
    @@myabsdir = File.absolute_path(@@mydir)
    @@options = { debug: false, info: true, warn: true, error: true, verbose: false, quiet: false }
    @@config = {}
    @@variables = {}
    @@logger = nil

    class << self
      def __str__
        a_attr = []
        #for attribute in [attr for attr in dir(cls) if not callable(getattr(cls, attr)) and not attr.startswith("__")]:
        #  a_attr.append(f"{attribute}='{str(getattr(cls, attribute))}'")
        #return f"<class {cls.__name__}: {', '.join(a_attr)}>" if a_attr else f"<class {cls.__name__}>"
      end

      def merge(*args, is_config: false, **kwargs)
        object = (is_config ? @@config : @@options)
        args.each do |arg|
          if It.is_dict?(arg)
            #It.info("[merge] ARG='#{arg.inspect}'")
            arg.each_pair { |key, value| object[key] = value }
          end
        end
        return object
      end  # merge

      def fetch(*args, is_config: false, default: nil, **kwargs)
        object = (is_config ? @@config : @@options)
        begin
          args.each { |arg| object = object[arg] }
          #It.info("ARGS=#{args.inspect} RETURN-VALUE='#{object.inspect}'")
          return object
        rescue => e
          It.warn("Cannot fetch key chain from #{is_config ? "CONFIG" : "OPTIONS"}! KEY-CHAIN='#{args.join(' > ')}'")
        end
        return default
      end  # fetch

      def to_s
        return Gl.inspect
      end  # to_s

      def to_json
        return JSON.generate(Gl)
      end  # to_json

      def to_py
        return f'OPTIONS={str(Gl.options)}'
      end  # to_rb

      def options
        @@options
      end

      def config
        @@config
      end

      def variables
        @@variables
      end

      def me
        return @@me
      end

      def myname
        return @@myname
      end

      def mydir
        return @@mydir
      end

      def myabsdir
        return @@myabsdir
      end
    end  # class << self
  end  # class Gl
end  # class It
#----------
