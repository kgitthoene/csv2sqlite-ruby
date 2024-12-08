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
  class DTHelp
    class << self
      #SEE:https://stackoverflow.com/questions/12445336/local-time-zone-in-ruby
      def get_local_tz
        return Time.now.getlocal.zone
      end  # get_local_tz

      #SEE:https://www.kanzaki.com/docs/ical/dateTime.html
      def icaldt2datetime(s_dtical_p = nil)
        dt = nil
        if s_dtical_p.to_s =~ /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z{0,1})$/
          year, month, day, hour, minute, second, timezone = $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_s
          dt = DateTime.new(year, month, day, hour, minute, second, (timezone == "Z" ? 0 : get_local_tz()))
          #It.debug(f"DT={dt.strftime('%Y-%m-%d %H:%M:%S %Z%z')} / LOCAL-TZ='{local_tz}'")
        end
        return dt
      end  # icaldt2datetime

      def datetime(*args, **kwargs)
        result = []
        args.each { |arg| rv = icaldt2datetime(arg); result << rv if !rv.nil? }
        return nil if (result.length == 0)
        return result[0] if (result.length == 1)
        return result
      end  # datetime

      def ms_sice_epoch
        return DateTime.now.strftime("%Q").to_i
      end  # ms_sice_epoch

      def s_now
        now = DateTime.now
        local_tz = Time.now.getlocal.zone.to_s
        return now.strftime("%Y%m%d %H%M%S #{local_tz}%z")
      end  # s_now

      def s_now_day
        return DateTime.now.strftime("%Y%m%d")
      end  # s_now_day

      def s_day_to_date(value)
        if value.to_s =~ /^(\d{4})(\d{2})(\d{2})$/
          year, month, day = $1.to_i, $2.to_i, $3.to_i
          dt = DateTime.new(year, month, day, 0, 0, 0, get_local_tz())
          return dt
        end
        return nil
      end  # s_day_to_date

      def dt_now
        It.debug("HERE dt_now")
        return DateTime.now
      end  # dt_now

      def dt_utc
        t = Time.now
        t_utc = (t + t.utc_offset * 24).utc
        return DateTime.parse(t_utc.to_s)
      end  # dt_utc

      def dt_local(dt_p)
        if dt_p.to_s =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/
          year, month, day, hour, minute, second, timezone = $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i
          dt = DateTime.new(year, month, day, hour, minute, second, get_local_tz())
        end
        return dt
      end  # dt_local

      def human_readable_from_to(cls, dt_start, dt_end)
        d_start = dt_start.to_date
        d_end = dt_end.to_date
        t_start = dt_start
        t_end = dt_end
        if d_start == d_end
          if t_start == t_end
            return dt_start.strftime("%a %d.%m.%Y, %H:%M Uhr")
          else
            return dt_start.strftime("%a %d.%m.%Y, %H:%M") + "-" + dt_end.strftime("%H:%M Uhr")
          end
        end
        return dt_start.strftime("%a %d.%m.%Y, %H:%M Uhr") + " - " + dt_end.strftime("%a %d.%m.%Y, %H:%M Uhr")
      end  # human_readable_from_to
    end  # class << self
  end  # class DTHelp
end  # class It
