#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#----------
# BSD 2-Clause License
#
# Copyright (c) 2024, Kai Thoene
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.#
#----------
#
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
