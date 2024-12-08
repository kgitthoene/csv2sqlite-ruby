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
(%w[tempfile fileutils yaml csv sqlite3] \
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
  options[:merge] = false
  options[:separator] = ","
  options[:pidfile] = nil
  options[:output] = nil
  options[:overwrite_output_file_if_exist] = false
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$g_myname} [-dvqyCHm] [-c CONFIG] [--pidfile PIDFILE] [-s SEPARATOR] -o OUTPUT [T:TABLENAME] CSV-FILE [[T:TABLENAME] CSV-FILE ...]"
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
    opts.on("-m", "--merge", String, "Merge with existing database. (Default: #{(!options[:merge]).to_s})") do |_data|
      options[:merge] = true
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
    opts.on("-o OUTPUT", "--output OUTPUT", String, "Write to this database.") do |_data|
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
      puts <<EOF

CSV files and table names.
Ahead each CSV file you may define the table name for the csv data.
  T:TABLENAME defines the name of a table, without the leading 'T:'.

Without table names the cleaned name of the CSV file is taken.

EOF
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
    raise(OptionParser::MissingArgument, "No output (database file) given!") if It.is_empty?(options[:output])
    raise(OptionParser::InvalidArgument, "Output database exists! Use '-y' to overwrite or '-m' to merge!") if File.exist?(options[:output]) && !options[:overwrite_output_file_if_exist] && !options[:merge]
    raise(OptionParser::InvalidArgument, "Config file not found!") if options[:config] && !File.exist?(options[:config])
    ARGV.each { |fn| raise(OptionParser::InvalidArgument, "File not readable! FILE='#{fn}'") if !File.readable?(fn) and !(fn =~ /^T:/) }
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

    def get_db_column_name(key, index)
      key = get_column_name(index) if It.is_empty?(key)
      return It.slugify(key.to_s)
    end

    def get_db_value(value, type = :db_text)
      str = value.to_s
      case type
      when :db_date, :db_datetime
        case str
        when /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/ # Date DD.MM.YYYY
          return "#{"%04d" % $3.to_i}-#{"%02d" % $2.to_i}-#{"%02d" % $1.to_i} 00:00:00.000"
        when /^(\d{4})-(\d{1,2})-(\d{1,2})$/ # Date YYYY-MM-DD
          return "#{"%04d" % $1.to_i}-#{"%02d" % $2.to_i}-#{"%02d" % $3.to_i} 00:00:00.000"
        when /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\.(\d{1,3})){0,1}$/
          return str
        end
      end
      return str
    end

    def get_db_data_type(value)
      str = value.to_s
      case str
      when /^$/ # Empty field:
        return :db_null
      when /^[+-]?\d+$/ # An integer:
        return :db_integer
      when /^[+-]?\d+$/, /^[+-]?\d+(\.\d+)?$/ # A simple floating point number:
        return :db_float
      when /^(wahr|true|falsch|false)$/i # Boolean true:
        return :db_boolean
      when /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/, /^(\d{4})-(\d{1,2})-(\d{1,2})$/ # Date DD.MM.YYYY, Date YYYY-MM-DD
        return :db_date
      when /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\.(\d{1,3})){0,1}$/
        return :db_datetime
      else
        return :db_text
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

    def write_csv_to_sqlite_database(csv, db, table_name, **kwargs)
      raise(It::Exception, "Invalid parameter! 'csv' not set!") if It.is_empty?(csv)
      raise(It::Exception, "Invalid parameter! 'db' not set!") if db.nil?
      raise(It::Exception, "Invalid parameter! 'table_name' not set!") if It.is_empty?(table_name)
      headers = kwargs.fetch(:headers, false)
      begin
        #
        # (1) Analyse column data types.
        #
        row_1st = csv[0]
        column_data_types = [:db_unknown] * row_1st.size
        csv.each do |row|
          index = 0
          first_element_flag = true
          if headers
            converted_row = row.to_hash
          else
            converted_row = row.to_ary
          end
          values = []
          while converted_row.size > 0
            key, value = if headers
                converted_row.shift
              else
                return get_column_name(index), converted_row.shift
              end
            data_type = get_db_data_type(value)
            if column_data_types[index] == :db_unknown
              column_data_types[index] = data_type
            elsif column_data_types[index] != data_type
              column_data_types[index] = :db_text
            end
            index += 1
          end
        end
        #
        # (2) Get column names and types.
        #
        column_names_comma_list = ""
        column_names_with_type = []
        converted_row = []
        if headers
          converted_row = row_1st.to_hash
        else
          converted_row = row_1st.to_ary
        end
        index = 0
        while converted_row.size > 0
          key, value = if headers
              converted_row.shift
            else
              return get_column_name(index), converted_row.shift
            end
          column_names_comma_list += (It.is_empty?(column_names_comma_list) ? "" : ", ") + "\"#{get_db_column_name(key, index)}\""
          literal_data_type = case column_data_types[index]
            when :db_integer, :db_boolean
              "INTEGER"
            when :db_float
              "REAL"
            else
              "TEXT"
            end
          column_names_with_type << "\"#{get_db_column_name(key, index)}\" #{literal_data_type}"
          index += 1
        end
        column_length = index
        It.debug("COLUMN-NAMES='#{column_names_comma_list}'")
        It.debug("COLUMN-NAMES='#{column_names_with_type.inspect}'")
        #
        # (3) Create table.
        #
        db_cmd_table_name = "\"#{It.slugify(table_name.to_s)}\""
        db.execute("CREATE TABLE IF NOT EXISTS #{db_cmd_table_name} (#{column_names_with_type.join(", ")})")
        #
        # (4) Write data to database:
        #
        csv.each do |row|
          index = 0
          first_element_flag = true
          if headers
            converted_row = row.to_hash
          else
            converted_row = row.to_ary
          end
          values = []
          while converted_row.size > 0
            key, value = if headers
                converted_row.shift
              else
                return get_column_name(index), converted_row.shift
              end
            values << get_db_value(value, column_data_types[index])
            #It.debug("KEY='#{key}' VALUE='#{value}'")
            #It.debug("DATA -- #{get_db_column_name(key, index)}: #{get_yaml_value(value)}")
            index += 1
          end
          db.execute("INSERT INTO #{db_cmd_table_name} (#{column_names_comma_list}) VALUES (#{(["?"] * column_length).join(", ")})", values)
        end
        #
      rescue StandardError => e
        It.pp_exception(e)
        return false
      end
      return true
    end  # def write_csv_to_sqlite_database
  end
end  # class Main
#
#----------
#
temporary_db_file = nil
db = nil
begin
  #
  # Prepare temporary database file:
  #
  temporary_db_file = Tempfile.new(It::Gl.options[:output])
  #
  # Clone database, if we want to merge.
  #
  if File.exist?(It::Gl.options[:output]) and It::Gl.options[:merge]
    FileUtils.cp(It::Gl.options[:output], temporary_db_file.path)
  end
  #
  # Open database:
  #
  db = SQLite3::Database.new(temporary_db_file.path)
  #
  table_name = nil
  ARGV.each do |arg|
    argument_is_table_name_flag = false
    It.debug("ARG='#{arg}'")
    if arg =~ /^T:(.*)/
      table_name = $1
      argument_is_table_name_flag = true
    end
    unless argument_is_table_name_flag
      table_name = It.slugify(It::FN.rm_ext(File.basename(arg))) if table_name.nil?
      It.debug("TABLENAME='#{table_name}'")
      It.debug("Read file. FILE='#{arg}'")
      begin
        csv = CSV.read(arg, headers: It::Gl.options[:header_in_csv], col_sep: It::Gl.options[:separator])
        columns = (csv.length > 0 ? csv[0].size : 0)
        It.debug("ROWS=#{csv.length} COLS=#{columns} #{csv[0].inspect}")
        #
        Main.write_csv_to_sqlite_database(csv, db, table_name, headers: It::Gl.options[:header_in_csv])
        #
      rescue StandardError => e
        It.pp_exception(e)
      end
      table_name = nil
    end
  end
  #
  # Close database and copy database file to destination:
  db.close
  db = nil
  #
  FileUtils.cp(temporary_db_file.path, It::Gl.options[:output])
  #
ensure
  db&.close
  temporary_db_file&.unlink
end
exit(0)
