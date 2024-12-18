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
