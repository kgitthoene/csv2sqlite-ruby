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
%w[optparse pty open3 pp yaml fileutils tempfile highline/import date time tzinfo tzinfo/data net/http securerandom base64].each do |s_module_name|
  begin
    require s_module_name
  rescue LoadError => e
    warn "[MODULE=\"#{s_module_name}\"] ERROR -- #{e}"
    exit 1
  end
end
require_relative "lib/gl.rb"
require_relative "lib/fn.rb"
require_relative "lib/dthelp.rb"
require_relative "lib/finders.rb"
#
#----------
# Define some essential functions.
#
class It
  @@me = __FILE__.to_s
  @@myname = File.basename(@@me)
  @@mydir = File.dirname(@@me)
  @@options = Gl.options
  @@is_logging_initialized = false
  @@is_configuration_read = false
  @@logger = nil
  LOG_LEVEL = { OUT: 0, DEBUG: 1, INFO: 2, WARN: 3, ERROR: 4, FATAL: 5 }
  @@log_level = LOG_LEVEL[:INFO]

  class << self
    def tmpchdir(dn_p, **kwargs)
      begin
        dn = dn_p.to_s
        wd = "."
        if dn != "."
          wd = Dir.getwd
          # This could raise an exception, but it's probably
          # best to let it propagate and let the caller
          # deal with it, since they requested x
          Dir.chdir(dn)
        end
        if block_given?
          yield(kwargs)
        end
      rescue => e
        It.error("EXCEPTION='#{e.to_s}'")
        raise e
      ensure
        Dir.chdir(wd) if dn != "."
      end
    end  # tmpchdir

    def is_dict?(*args, **kwargs)
      return false if !args.each { |arg| break false if !arg&.is_a?(Hash) }
      return true
    end  # is_dict

    def is_empty?(*args, **kwargs)
      return false if !args.each do |arg|
        #It.debug("[is_empty?] LENGTH-TEST=#{(arg&.respond_to?(:length) and (arg&.length > 0)).to_s} VALUE=#{arg.inspect}")
        break false if arg&.respond_to?(:length) and (arg&.length > 0)
        break false if arg&.is_a?(Numeric) and (arg != 0)
        break false if arg&.is_a?(TrueClass)
        true
      end
      return true
    end  # is_empty

    def strtobool(val_p)
      #"""Convert a string representation of truth to true (1) or false (0).
      #True values are 'y', 'yes', 't', 'true', 'on', and '1'; false values
      #are 'n', 'no', 'f', 'false', 'off', and '0'.  Raises ValueError if
      #'val' is anything else.
      #"""
      return false if val_p.nil?
      val = val_p.to_s.downcase
      return true if %w[y yes t true on 1].include?(val)
      return false if %w[n no f false off 0].include?(val)
      raise(StandardError::RangeError, "Invalid truth value! VALUE='#{val}'")
    end  # strtobool

    def is_valid_email?(*args, **kwargs)
      return false if !args.each { |arg| break false if !(arg =~ /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\Z/) }
      return true
    end  # is_valid_email?

    def is_valid_uuid4?(*args, **kwargs)
      return false if !args.each { |arg| break false if !(arg =~ /\A[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}\Z/) }
      return true
    end  # is_valid_uuid4?

    def replace_ext(*args, **kwargs)
      result = []
      ext = kwargs.fetch(:ext, "")
      args.each { |arg| result << "#{arg.sub(/#{File.extname(arg)}$/, "")}#{ext}" }
      return ((result.length == 1) ? result[0] : ((result.length == 0) ? [] : result))
    end  # replace_ext

    def slugify(*args, allow_unicode: false, **kwargs)
      # Turn String into acceptable file name.
      result = []
      args.each do |arg|
        arg = arg.to_s.strip
        #It.info("[slugify:1] '#{arg}'")
        a_components = arg.split(File::SEPARATOR)
        a_components.each_index do |component_index|
          component = a_components[component_index]
          component = component.encode("ASCII", "UTF-8", invalid: :replace, undef: :replace, replace: "") if !allow_unicode
          component.gsub!(/\-+/, "-")
          component.gsub!(/[^\w\s\-\.]/, "")
          component.gsub!(/\s+/, "_")
          component.gsub!(/[\\<>":\|\?\*\[\]\(\)\`\{\}\$]/, "")
          component.gsub!(/[\x00-\x1F]/, "")
          component.sub!(/^\-_/, "")
          component.sub!(/\-_$/, "")
          a_components[component_index] = component
        end
        arg = a_components.join(File::SEPARATOR)
        #It.info("[slugify:2] '#{arg}'")
        result << arg
      end
      return ((result.length == 1) ? result[0] : ((result.length == 0) ? [] : result))
    end  # slugify

    def img2html_base64(*args, style: "", alt: "", **kwargs)
      style = kwargs.fetch(:style, "")
      alt = kwargs.fetch(:alt, "")
      finder = Finders.new
      result = []
      args.each do |arg|
        if !It.is_empty?(arg)
          location = finder.find(arg.to_s.strip)
          if !location.nil?
            It.debug("[img2html_base64] LOCATION='#{location}'")
            begin
              bn = File.basename(location)
              ext = File.extname(bn)
              ext = ext[1..].downcase
              base64_data = ""
              File.open(location, "rb") do |f|
                base64_data = Base64.encode64(f.read()).gsub(/\s/, "")
              end
              alt = ((alt == "") ? " alt=\"#{It.slugify(bn)}\"" : " alt=\"#{alt}\"")
              style = " style=\"#{style}\"" if style != ""
              result << "<img src=\"data:image/#{ext};base64,#{base64_data}\"#{alt}#{style}>"
            rescue => e
              It.error("EXCEPTION='#{e}'")
              raise e
            end
          end
        end
      end
      return ((result.length == 1) ? result[0] : ((result.length == 0) ? [] : result))
    end  # img2html_base64

    def out(msg_p, is_internal_call: false)
      Kernel.warn msg_p.to_s
      msg_p.to_s.each_line { |l| @@logger.debug("#{Gl.myname}: #{l}".chomp) } if !@@logger.nil? and @@log_level <= LOG_LEVEL[:OUT] and !is_internal_call
    end

    def debug(msg_p)
      #Kernel.warn("DEBUG=#{@@options[:debug].to_s}")
      msg_p.to_s.each_line { |l| out("#{HighLine.color("D", :blue, :bold)} #{Gl.myname}: #{l.chomp}", is_internal_call: true) } if @@options[:debug] && !@@options[:quiet]
      msg_p.to_s.each_line { |l| @@logger.debug("#{Gl.myname}: #{l}".chomp) } if !@@logger.nil? and @@log_level <= LOG_LEVEL[:DEBUG]
    end

    def info(msg_p)
      msg_p.to_s.each_line { |l| out("#{HighLine.color("I", :cyan, :bold)} #{Gl.myname}: #{l.chomp}", is_internal_call: true) } if @@options[:info] && !@@options[:quiet]
      msg_p.to_s.each_line { |l| @@logger.info("#{Gl.myname}: #{l}".chomp) } if !@@logger.nil? and @@log_level <= LOG_LEVEL[:INFO]
    end

    def warn(msg_p)
      msg_p.to_s.each_line { |l| out("#{HighLine.color("W", :yellow, :bold)} #{Gl.myname}: #{l.chomp}", is_internal_call: true) } if @@options[:warn] && !@@options[:quiet]
      msg_p.to_s.each_line { |l| @@logger.warn("#{Gl.myname}: #{l}".chomp) } if !@@logger.nil? and @@log_level <= LOG_LEVEL[:WARN]
    end

    def error(msg_p)
      msg_p.to_s.each_line { |l| out("#{HighLine.color("E", :red, :bold)} #{HighLine.color("#{Gl.myname}: #{l.chomp}", :bold)}", is_internal_call: true) } if @@options[:error] && !@@options[:quiet]
      msg_p.to_s.each_line { |l| @@logger.error("#{Gl.myname}: #{l}".chomp) } if !@@logger.nil? and @@log_level <= LOG_LEVEL[:ERROR]
    end

    def fatal(msg_p)
      msg_p.to_s.each_line { |l| out("#{HighLine.color("F", :black, :bold, :on_red)}#{HighLine.color(" ", :black, :on_red)}#{HighLine.color("#{Gl.myname}: #{l.chomp}", :black, :on_white)}", is_internal_call: true) } if @@options[:error] && !@@options[:quiet]
      msg_p.to_s.each_line { |l| @@logger.fatal("#{Gl.myname}: #{l}".chomp) } if !@@logger.nil? and @@log_level <= LOG_LEVEL[:FATAL]
    end

    def verbose(msg_p)
      msg_p.to_s.each_line { |l| out("#{HighLine.color("V", :blue, :bold)} #{Gl.myname}: #{l.chomp}", is_internal_call: true) } if @@options[:verbose] && !@@options[:quiet]
    end

    def setup(opts = {})
      opts.each_pair do |k, v|
        @@options[k] = v if k.instance_of?(Symbol)
      end
    end

    # FROM:https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd)
      exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
      ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end

    def check_tools(a_tools_p)
      a_tools_p.each do |tool|
        next unless which(tool).nil?
        error "Cannot find needed external tool '#{tool}'!"
        exit 1
      end
      true
    end

    def yesno(prompt = "Continue?", default = true)
      a = ""
      s = default ? "[Y/n]" : "[y/N]"
      d = default ? "y" : "n"
      until %w[y n].include? a
        a = ask("#{prompt} #{s} ") { |q| q.limit = 1; q.case = :downcase }
        a = d if a.empty?
      end
      a == "y"
    end

    def deltat2dhms(deltat_p)
      seconds = deltat_p * 24 * 3600
      days = (seconds / 3600 / 24).floor
      seconds -= days * 3600 * 24
      hours = (seconds / 3600).floor
      seconds -= hours * 3600
      minutes = (seconds / 60).floor
      seconds -= minutes * 60
      [days, hours, minutes, seconds]
    end # deltat2dhms

    # rc, stdout, stderr = It.execute_command(...)
    # rc, stdout, stderr = It.execute_command(..., :capture = true, :stdin = [String | File])
    def execute_command(*args, **kwargs)
      #It.info("execute_command: OPTIONS=#{kwargs.inspect}")
      is_capture = kwargs[:capture].nil? ? true : !!kwargs[:capture]
      captured_stdout = ""
      captured_stderr = ""
      rc = 0
      if is_capture
        exit_status = Open3.popen3(*args) do |stdin, stdout, stderr, wait_thr|
          unless kwargs.nil? || kwargs[:stdin].nil?
            if kwargs[:stdin].is_a?(String)
              File.open(kwargs[:stdin]) { |f| stdin.write_nonblock(f.read) }
            else
              stdin.write_nonblock(kwargs[:stdin].read)
            end
          end
          _pid = wait_thr.pid # pid of the started process.
          stdin.close
          captured_stdout = stdout.read
          captured_stderr = stderr.read
          wait_thr.value # Process::Status object returned.
        end
        rc = exit_status.exitstatus
      else
        rc = !!system(*args) ? 0 : 1
      end
      # exit_status.success? => true, false
      # exit_status.exitstatus => Fixnum
      [rc, captured_stdout, captured_stderr]
    end # execute_command

    # rc, stdout, stderr = It.execute_command(...)
    # rc, stdout, stderr = It.execute_command(..., :stdin = [String | File])
    def execute_command_bg(*args)
      options = args.pop if args[-1].is_a?(Hash)
      #It.info("execute_command: OPTIONS=#{options.inspect}")
      captured_stdout = ""
      captured_stderr = ""
      stdin, stdout, stderr, wait_thr = Open3.popen3(*args)
      It.debug("[execute_command] CHILD-PID=#{wait_thr.pid}")
      Thread.new do
        unless options.nil? || options[:stdin].nil?
          if options[:stdin].is_a?(String)
            File.open(options[:stdin]) { |f| stdin.write_nonblock(f.read) }
          else
            stdin.write_nonblock(options[:stdin].read)
          end
        end
        _pid = wait_thr.pid # pid of the started process.
        stdin.close
        captured_stdout = stdout.read
        captured_stderr = stderr.read
      end.join
      exit_status = wait_thr.value # Process::Status object returned.
      # exit_status.success? => true, false
      # exit_status.exitstatus => Fixnum
      [exit_status.exitstatus, captured_stdout, captured_stderr]
    end # execute_command_bg

    def optparse(*args)
      options = {}
      #It.info("[#{File.basename(__FILE__)}] OPTIONS='#{options.inspect}'") if defined?(options)
      if block_given?
        yield(options)
      end
      options[:config] = options[:config_default] if options[:config].nil?
      options.delete(:stop_after_optionparser)
      # Write sample config file.
      if options[:write_sample_config_file]
        cfg = options[:config]
        sample_config = "---\nconfig: #{cfg}\n"
        if File.exist?(cfg)
          It.error "Config file '#{cfg}' exists!"
          It.info "A sample config file is displyed here:"
          $stdout << sample_config
        else
          File.open(cfg, "w") { |of| of << sample_config }
          It.info "Config was written to file '#{cfg}'!"
        end
      end
      setup({ debug: options[:debug], verbose: options[:verbose], quiet: options[:quiet] })
      Gl.merge(options)
      options
    end # optparse

    def config(filename = nil, convert_strings_to_symbols_p = false)
      config = {}
      # Read config file.
      #It.info("It.config: FILENAME=#{filename.inspect}")
      if !filename.nil? && File.readable?(filename)
        config = begin
            YAML.load(File.open(filename))
          rescue StandardError => e
            It.error("EXCEPTION='#{e}'")
            It.pp_exception(e)
            {}
          end
        # if $g_options[:start_year].nil? or $g_options[:uri].nil?
        #  It.error "Invalid config file '#{$g_options[:config]}'!"
        #  exit 1
        # end
      end
      # If possible convert names to symbols.
      if convert_strings_to_symbols_p && config.is_a?(Hash)
        nc = {}
        config.each_pair do |k, v|
          if k.is_a?(String)
            nc[k.to_sym] = v
          else
            nc[k] = v
          end
        end
        config = nc
      end
      #It.info("[It.config] CONFIG=#{config.inspect}")
      config.fetch(:options, {}).each_pair do |key, val|
        #It.info("KEY='#{key.inspect}' VALUE='#{val.inspect}'")
        if It::Gl.options.key?(key)
          config[:options][key] = It::Gl.options[key]
        else
          It::Gl.options[key] = val
        end
      end
      Gl.merge(config, is_config: true)
      @@is_configuration_read = true
      config
    end # config

    def logging(fn_p = STDERR, log_level = LOG_LEVEL[:INFO])
      if !@@is_logging_initialized
        @@logger = Logger.new(fn_p == STDERR ? fn_p : slugify(fn_p.to_s))
        @@logger.formatter = proc do |severity, datetime, progname, msg|
          date_format = datetime.strftime("%Y%m%dT%H%M%S.%L")
          "#{severity[0]} [#{date_format}] #{msg}\n"
        end
        @@is_logging_initialized = true
        @@log_level = LOG_LEVEL[:DEBUG] if Gl.fetch(:debug, default: false)
      end
    end  # logging

    # Write object as YAML-file.
    def write(obj_p, fn_p)
      begin
        fn = slugify(fn_p.to_s)
        raise(StandardError::ArgumentError, "Invalid slugified file name! FILE='#{fn}' ORIGINAL='#{fn_p}'") if is_empty?(fn)
        File.open(fn_p, "w") do |f|
          f.write(YAML.dump(obj_p))
        end
        It.debug("Object successfull writen to file. FILE='#{fn}'")
        return fn
      rescue => e
        It.error("EXCEPTION='#{e}'")
        raise e
      end
      return nil
    end

    class AssertionError < RuntimeError
    end

    def assert(*args)
      msg = nil
      if args.length >= 2
        msg = args.pop if args.last.is_a?(String)
      end
      if block_given?
        unless yield(args)
          backtrace = []
          caller_locations.each { |l| backtrace << l.to_s }
          e = AssertionError.new(msg)
          e.set_backtrace(backtrace)
          raise e
        end
      else
        args.each do |arg|
          next if arg
          # error "AssertionError " + (msg ? "-- #{msg} " : "") + "/ BACKTRACE="
          backtrace = []
          caller_locations.drop(2).each { |l| backtrace << l.to_s }
          e = AssertionError.new(msg)
          e.set_backtrace(backtrace)
          raise e
        end
      end
    end # assert

    def pp_backtrace(exception_p)
      # $stderr.print "\r" << (' ' * 50) << "\n"
      first_line_flag = true
      stacktrace = exception_p.backtrace.map do |call|
        if parts = call.match(/^(?<file>.+):(?<line>\d+):in `(?<code>.*)'$/)
          file = parts[:file].sub /^#{Regexp.escape(File.join(Dir.getwd, ""))}/, ""
          msg_lines = exception_p.to_s.split(/\n/)
          msg_header = msg_lines[0]
          msg_tail = msg_lines[1..-1].join("\n")
          #It.debug("LINES='#{msg_lines.inspect}'")
          cline = "#{HighLine.color("E", :red, :bold)} #{HighLine.color(file, :cyan)}:#{HighLine.color(parts[:line], :green)}: #{HighLine.color(parts[:code], :bright_red)}#{first_line_flag ? ": #{HighLine.color("#{msg_header} (", :bold)}#{HighLine.color(exception_p.class.to_s, :underline, :bold)}#{HighLine.color(")", :bold)}#{msg_lines.length > 1 ? "\n#{HighLine.color(msg_tail, :bold)}" : ""}" : "" }"
          line = "#{file}:#{parts[:line]}: #{parts[:code]}#{first_line_flag ? ": #{msg_header} (#{exception_p.class.to_s})#{msg_lines.length > 1 ? "\n"+msg_tail : ""}" : ""}"
        else
          cline = HighLine.color(call, :red)
          line = call
        end
        first_line_flag = false
        { colorline: cline, line: line }
      end
      #STDERR.puts("STACKTRACE=#{stacktrace.inspect}")
      stacktrace.each do |line|
        $stderr.print("#{line[:colorline]}\n")
        @@logger.error(line[:line]) if !@@logger.nil?
      end
    end  # pp_backtrace

    def pp_exception(exception_p)
      #$stderr.print(" ")
      #$stderr.print "#{HighLine.color($g_myname, :cyan)}: #{HighLine.color("ERROR", :red, :bold)}[#{HighLine.color(exception_p.class.to_s, :black, :on_white)}] #{HighLine.color(exception_p.to_s, :bright_red)}"
      #@@logger.error("#{Gl.myname}: ERROR[#{exception_p.class.to_s}] #{exception_p.to_s}") if !@@logger.nil?
      if exception_p.to_s != $ERROR_INFO.to_s
        $stderr.print HighLine.color($ERROR_INFO ? " #{$ERROR_INFO}" : "", :bright_red).to_s
        @@logger.error($ERROR_INFO) if !@@logger.nil? and $ERROR_INFO
      end
      #$stderr.print "\n"
      pp_backtrace(exception_p)
    end  # pp_exception

    def pp_s(obj)
      obj.pretty_inspect
    end

    #SEE:https://stackoverflow.com/questions/13787746/creating-a-thread-safe-temporary-file-name
    def tempfn(dir = "", ext = "")
      filename = begin
          Dir::Tmpname.make_tmpname(["x", ext], nil)
        rescue NoMethodError
          require "securerandom"
          "#{SecureRandom.urlsafe_base64}#{ext}"
        end
      File.join((dir.empty? ? Dir.tmpdir : dir), filename)
    end

    def ms_sice_epoch
      return DTHelp.ms_sice_epoch
    end

    def s_now
      return DTHelp.s_now
    end

    def s_now_day
      return DTHelp.s_now_day
    end

    def s_day_to_date(value)
      return DTHelp.s_day_to_date(value)
    end

    def dt_now
      return DTHelp.dt_now
    end

    def s_uuid4
      return SecureRandom.uuid.to_s
    end

    def s_random_id(**kwargs)
      result = []
      number_of_characters = kwargs.fetch(:count, 8).to_i
      number_of_ids = kwargs.fetch(:nid, 1).to_i
      do_upcase = !!kwargs.fetch(:upcase, false)
      do_only_letters = !!kwargs.fetch(:alpha, false)
      do_result_as_array = !!kwargs.fetch(:array, false)
      digits_pool = do_only_letters ? "abcdefghijklmnopqrstuvwxyz" : "0123456789abcdefghijklmnopqrstuvwxyz"
      number_of_ids.times do
        n_tries = 0
        is_failed = false
        loop do
          entry = (0...number_of_characters).map { digits_pool[rand(digits_pool.length)] }.join.to_s
          entry = entry.upcase if do_upcase
          n_tries += 1
          raise(StandardError::RangeError, "To many entries requested! NID=#{number_of_ids}") if n_tries > (digits_pool.length * number_of_characters)
          if !result.include?(entry)
            result << entry
            break
          end
        end
      end
      return (do_result_as_array ? result : ((result.length == 1) ? result[0] : result))
    end  # s_random_id

    def open_default_browser(url_p = "", background: false)
      rc = 0
      thread = Thread.new do
        if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
          rc = 1 unless system("start", url_p)
        elsif RbConfig::CONFIG["host_os"] =~ /darwin/
          rc = 1 unless system("open", url_p)
        elsif RbConfig::CONFIG["host_os"] =~ /linux|bsd/
          rc = 1 unless system("xdg-open", url_p)
        end
      end
      thread.join() if !background
      return rc
    end  # open_default_browser
  end  # class << self

  class Exception < StandardError
    def initialize(msg="It::Exception default message!")
      super
    end
  end
end # class It
