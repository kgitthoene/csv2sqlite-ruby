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
