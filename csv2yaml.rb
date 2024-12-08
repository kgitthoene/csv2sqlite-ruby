#!/usr/bin/ruby
# -*- encoding : utf-8 -*-
# #region[rgba(0, 255, 0, 0.05)] SOURCE-STUB
#
#
#----------
# Set some global variables.
#
$g_me = $PROGRAM_NAME.to_s
$g_myname = File.basename($g_me)
$g_mydir = File.dirname($g_me)
$g_myabsdir = File.absolute_path($g_mydir)
#
#
#----------
# Get setup token.
#
begin
  b_setup = false
  ARGV.each { |arg| if arg == "++setup" then b_setup = true; break; end }
  if b_setup
    require "open3"
    captured_stdout = ""
    captured_stderr = ""
    exit_status = Open3.popen3("sudo", "-H", "/bin/sh", "-i") do |stdin, stdout, stderr, wait_thr|
      _pid = wait_thr.pid # pid of the started process.
      stdin.puts <<~EOF
                   #!/bin/sh
                   ##apt -y install ruby-libxml
                   ##gem install rspreadsheet
                   echo HI
                   exit 0
                 EOF
      stdin.close
      captured_stdout = stdout.read
      captured_stderr = stderr.read
      wait_thr.value # Process::Status object returned.
    end
    if exit_status.success?
      warn "SETUP -- OK."
    else
      warn "ERROR -- Setup failed!"
      warn captured_stdout
      warn captured_stderr
    end
    exit exit_status.success? ? 0 : 1
  end
end
#
#
#----------
# Load some files / modules.
Dir.chdir($g_myabsdir) { require File.join("./lib/it/it".split("/")) }
#
#----------
# Load some files / modules.
(%w[yaml csv] \
  + %W[]).each do |s_module_name|
  begin
    require s_module_name
  rescue LoadError => e
    warn "[MODULE=\"#{s_module_name}\"] ERROR -- #{e}"
    exit 1
  end
end
#
#----------
# Handle command line.
#
It.optparse do |options|
  options = options || {}
  options[:stop_after_optionparser] = false
  options[:debug] = false
  options[:write_sample_config_file] = false
  options[:verbose] = false
  options[:quiet] = false
  options[:config_default] = (File.readable?("config.yaml") ? "config.yaml" : (File.readable?(File.join("config", "config.yaml")) ? File.join("config", "config.yaml") : "config.yaml"))
  options[:config] = nil
  options[:header_in_csv] = false
  options[:separator] = ","
  options[:pidfile] = nil
  options[:output] = "stdout"
  options[:overwrite_output_file_if_exist] = false
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$g_myname} [-dvqyCH] [-c CONFIG] [--pidfile PIDFILE] [-s SEPARATOR] [-o OUTPUT] CSV-FILE [...]"
    opts.on("-d", "--debug", "Enable debugging.") do |_dummy|
      options[:debug] = true
    end
    opts.on("-v", "--verbose", "Talk more.") do |_dummy|
      options[:verbose] = true
    end
    opts.on("-q", "--quiet", "Talk nothing.") do |_dummy|
      options[:quiet] = true
    end
    opts.on("-y", "--overwrite", "Overwrite output files.") do |_dummy|
      options[:overwrite_output_file_if_exist] = true
    end
    opts.on("-C", "--write-sample-config-file", "Writes a sample config file.") do |_dummy|
      options[:write_sample_config_file] = true
    end
    opts.on("-H", "--header", String, "First line of csv contains header. (Default: #{(!options[:header_in_csv]).to_s})") do |_data|
      options[:header_in_csv] = true
    end
    opts.on("-c CONFIG", "--config CONFIG", String, "Config file. (Default: '#{options[:config_default]}')") do |_data|
      options[:config] = _data
    end
    opts.on("--pidfile PIDFILE", String, "File for process-id. (Default: Not set. Not written.)") do |_data|
      options[:pidfile] = _data
    end
    opts.on("-s SEPARATOR", "--column-separator SEPARATOR", String, "CSV separator for columns. (Default: '#{options[:separator]}')") do |_data|
      options[:separator] = _data
    end
    opts.on("-o OUTPUT", "--output OUTPUT", String, "Output filename or use 'stdout', 'stderr', 'self'. 'self' writes to the name of the CSV file with '.yaml' extension. (Default: '#{options[:output].to_s}')") do |_data|
      options[:output] = _data
    end
    # opts.on('-g GROUPS', '--groups GROUPS', Integer, /[0-9]*/, "(Default: #{options[:nr_groups]}) Number of groups (>= 1).") do |num|
    #  options[:nr_groups] = num.to_i
    # end
    # opts.on('-t TEMPLATE', '--template TEMPLATE', String, "(Default: '#{options[:html_template]}') HTML template file.") do |file|
    #  options[:html_template] = file
    # end
    opts.on_tail("-h", "-?", "--help", "Display this screen.") do
      puts opts
      # msg =<<EOF
      # Description
      #  Send a wakeup to all MAC addresses.
      # EOF
      # puts msg
      options[:stop_after_optionparser] = true
    end
  end
  begin
    optparse.parse!(ARGV)
    exit(0) if options[:stop_after_optionparser]
    # raise(OptionParser::MissingArgument, "No MAC address given!") if ARGV.empty?
    # OptionParser::AmbiguousArgument
    # OptionParser::AmbiguousOption
    # OptionParser::InvalidArgument
    # OptionParser::InvalidOption
    # OptionParser::MissingArgument
    # OptionParser::NeedlessArgument
    # OptionParser::ParseError
    # raise(OptionParser::ParseError, "GROUPS must be >= 1!") if options[:nr_groups] and options[:nr_groups] < 1
    # raise(OptionParser::ParseError, "GROUP-SIZE must be >= 2!") if options[:group_size] and options[:group_size] < 2
    raise(OptionParser::InvalidArgument, "Config file not found!") if options[:config] && !File.exist?(options[:config])
    ARGV.each { |fn| raise(OptionParser::InvalidArgument, "File not readable! FILE='#{fn}'") if !File.readable?(fn) }
    raise(OptionParser::MissingArgument, "No file names given!") if ARGV.empty?
  rescue OptionParser::ParseError => e
    It.error e.to_s
    optparse.parse("-h")
    exit(1)
  end
  if ARGV.include?("help")
    ARGV.each do |arg|
      case arg
      when "scroll"
        It.info("Option: Help for command '#{arg}':")
      when "zoom"
        It.info("Option: Help for command '#{arg}':")
      end
    end
    exit(0)
  end
end
#
It::Gl.options[:debug] = false if It::Gl.fetch(:write_config_only, default: false)
It.config(It::Gl.options[:config], true)
# Create directories.
%w[lib log run].each do |sdn|
  dn = File.join("var", sdn)
  FileUtils.mkdir_p(dn) unless Dir.exist?(dn)
end
logfn = File.join("var", "log", "#{File.basename($g_myname, File.extname($g_myname))}.log")
It.logging(logfn)
#
It.debug("OPTIONS=#{It.pp_s(It::Gl.options)}")
It.debug("CONFIG=#{It.pp_s(It::Gl.config)}")
if It::Gl.fetch(:write_config_only, default: false)
  if !It.is_empty?(It::Gl.options[:config])
    fn = It.write(It::Gl.config, It::Gl.options[:config])
    It.debug("Config written to file. FILE='#{fn}'")
  end
  exit(0)
end
# #endregion
#
#
#-----------------------------------------------------------------------
# START HERE!
#-------------
#
class Main
  class << self
    COL_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    def get_yaml_key(key, index)
      key = get_column_name(index) if It.empty?(key)
      "'#{key.to_s.gsub(/'/, "\\'")}'"
    end

    def get_yaml_value(value)
      str = value.to_s
      case str
      when /^$/ # Empty field:
        return "~"
      when /^[+-]?\d+$/, /^[+-]?\d+(\.\d+)?$/ # An integer or simple floating point number:
        return str
      when /^wahr$/ # Boolean true:
        return "true"
      when /^falsch$/ # Boolean false:
        return "false"
      when /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/ # Date DD.MM.YYYY
        return "#{"%04d" % $3.to_i}-#{"%02d" % $2.to_i}-#{"%02d" % $1.to_i}"
      when /^(\d{4})-(\d{1,2})-(\d{1,2})$/ # Date YYYY-MM-DD
        return "#{"%04d" % $1.to_i}-#{"%02d" % $2.to_i}-#{"%02d" % $3.to_i}"
      else
        return "'#{str.gsub(/'/, "\\'")}'"
      end
    end

    def get_column_name(index)
      value = index.to_s(COL_CHARACTERS.length)
      It.debug("INDEX=#{index} -> VALUE='#{value}' BASE=#{COL_CHARACTERS.length}")
      result = ""
      while value != ""
        first_char = value[0]
        value = value[1..-1]
        case first_char
        when /^\d$/
          col_char_index = first_char.to_i
        else
          col_char_index = first_char.ord - "a".ord + 10
        end
        result += COL_CHARACTERS[col_char_index]
      end
      return result
    end

    def write_csv_to_yaml(csv, of, **kwargs)
      headers = kwargs.fetch(:headers, false)
      of.puts("---")
      csv.each do |row|
        index = 0
        first_element_flag = true
        if headers
          converted_row = row.to_hash
        else
          converted_row = row.to_array
        end
        while converted_row.size > 0
          if headers
            key, value = converted_row.shift
          else
            key = get_column_name(index)
            value = converted_row.shift
          end
          It.debug("KEY='#{key}' VALUE='#{value}'")
          if first_element_flag
            of.puts("- #{get_yaml_key(key, index)}: #{get_yaml_value(value)}")
            first_element_flag = false
          else
            of.puts("  #{get_yaml_key(key, index)}: #{get_yaml_value(value)}")
          end
          index += 1

        end
      end
      of.puts("...")
    end
  end
end  # class Main
#
#----------
#
ARGV.each do |arg|
  It.debug("Read file. FILE='#{arg}'")
  begin
    csv = CSV.read(arg, headers: It::Gl.options[:header_in_csv], col_sep: It::Gl.options[:separator])
    columns = (csv.length > 0 ? csv[0].size : 0)
    It.debug("ROWS=#{csv.length} COLS=#{columns} #{csv[0].inspect}")
    #
    # Prepare output file:
    output_file = nil
    output_filename = ""
    case It::Gl.options[:output]
    when "self"
      output_filename = It::FN.rm_ext(arg) + ".yaml"
    when "stdout"
      output_file = $stdout
    when "stderr"
      output_file = $stderr
    else
      output_filename = It::Gl.options[:output]
    end
    file_has_been_opened_flag = false
    if output_file.nil?
      if File.exist?(output_filename) and (not It::Gl.options[:overwrite_output_file_if_exist])
        #raise(It::Exception, "Output exist! FILE='#{output_filename}'")
        It.error("Output exist! FILE='#{output_filename}'")
        It.info("Use option '-y' to overwrite files.")
        exit(1)
      end
      output_file = File.open(output_filename, "wb")
      file_has_been_opened_flag = true
    end
    Main.write_csv_to_yaml(csv, output_file, headers: It::Gl.options[:header_in_csv])
    output_file.close() if file_has_been_opened_flag
  rescue StandardError => e
    It.pp_exception(e)
  end
end
exit(0)
