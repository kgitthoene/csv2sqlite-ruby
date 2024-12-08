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
Dir.chdir($g_myabsdir) { require "./lib/it/it" }
#
#----------
# Load some files / modules.
(%w[nokogiri] \
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
  options[:csvfile] = nil
  options[:csvfile_search_term] = true
  options[:scroll] = 1
  options[:lat] = nil
  options[:lon] = nil
  options[:headless] = true
  options[:from_database] = nil
  options[:literally_location] = ""
  options[:literally_location_slugified] = ""
  options[:pidfile] = nil
  options[:client] = false
  options[:crawl_only] = false
  options[:no_crawling] = false
  options[:zoom] = 9
  options[:batch] = nil
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$g_myname} [-dvCH] [-c CONFIG] [--pidfile PIDFILE] [--client] [-o CSV-OUTPUT-FILE] [-n SCROLL] [-l {LATITUDE:LONGITUDE|LOCATION}] [-D PLACES-DATABASE-FILE] [SEARCH-TERM] [...]"
    opts.on("-d", "--debug", "Enable debugging.") do |_dummy|
      options[:debug] = true
    end
    opts.on("-v", "--verbose", "Talk more.") do |_dummy|
      options[:verbose] = true
    end
    opts.on("-q", "--quiet", "Talk nothing.") do |_dummy|
      options[:quiet] = true
    end
    opts.on("-C", "--write-sample-config-file", "Writes a sample config file.") do |_dummy|
      options[:write_sample_config_file] = true
    end
    opts.on("-H", "--not-headless", String, "Start browser visible, i.e. not headless. (Default: #{(!options[:headless]).to_s})") do |_data|
      options[:headless] = false
    end
    opts.on("-c CONFIG", "--config CONFIG", String, "Config file. (Default: '#{options[:config_default]}')") do |_data|
      options[:config] = _data
    end
    opts.on("--pidfile PIDFILE", String, "File for process-id. (Default: Not set. Not written.)") do |_data|
      options[:pidfile] = _data
    end
    opts.on("--client", String, "Work as web-server client program. (Default: #{(!options[:client]).to_s})") do |_data|
      options[:client] = true
    end
    opts.on("-n SCROLL", "--scroll SCROLL", Integer, "Scroll the result list SCROLL times down to get more results. Scroll to end of list with value 0. (Default: #{options[:scroll]})") do |_data|
      options[:scroll] = _data
    end
    opts.on("-l {LATITUDE:LONGITUDE|LOCATION}", "--location {LATITUDE:LONGITUDE|LOCATION}", String, /^.*$/, "Geo position to start the search. Numeric latitude and longitude or location name. (Default: Determined by your Geo-IP-Location.)") do |_data|
      _data = "GEO-IP" if _data.empty?
      if _data =~ /^(-{0,1}\d+([,.]\d+){0,1}):(-{0,1}\d+([,.]\d+){0,1})$/
        a, b = $1, $3
        options[:lat] = a.sub(/,/, ".").to_f
        options[:lon] = b.sub(/,/, ".").to_f
        [options[:lat], options[:lon]].each do |x|
          raise(OptionParser::InvalidArgument, "Either latitude and longitude must be in the range from -180 to 180.") if (x > 180) or (x < -180)
        end
        options[:literally_location] = "#{"%f" % options[:lat]}:#{"%f" % options[:lon]}"
        options[:literally_location_slugified] = options[:literally_location]
      elsif _data == "GEO-IP"
        gpos = GeoLocation.search(nil)
        if !gpos.nil?
          options[:literally_location] = _data
          options[:literally_location_slugified] = It.slugify(_data)
          options[:lat] = gpos.latitude
          options[:lon] = gpos.longitude
        end
      else
        gpos = GeoLocation.search(_data)
        if !gpos.nil?
          options[:literally_location] = _data
          options[:literally_location_slugified] = It.slugify(_data)
          options[:lat] = gpos.latitude
          options[:lon] = gpos.longitude
        else
          raise(OptionParser::InvalidArgument, "No geo-position found! LOCATION='#{_data}'")
        end
      end
    end
    opts.on("-D PLACES-DATABASE-FILE", "--get-data-from-database PLACES-DATABASE-FILE", String, "Reads the database and writes output.") do |_data|
      options[:from_database] = _data
    end
    opts.on("-o CSV-OUTPUT-FILE", "--output CSV-OUTPUT-FILE", String, "Output data as CSV to this file. (Default: Not set.)") do |_data|
      options[:csvfile] = _data
      options[:csvfile_search_term] = false
    end
    opts.on("-z ZOOM", "--zoom-level ZOOM", Integer, "Zoom level of Google map. Allowed range: 9-19. (Default: #{options[:zoom]})") do |_data|
      options[:zoom] = _data
    end
    opts.on("-b BATCH", "--batch BATCH", String, "Read YAML batch file with parameters. (Default: Not set.)") do |_data|
      options[:batch] = _data
    end
    opts.on("--crawl-only", String, "(Default: #{options[:crawl_only]})") do |_data|
      options[:crawl_only] = true
    end
    opts.on("--no-crawling", String, "(Default: #{options[:no_crawling]})") do |_data|
      options[:no_crawling] = true
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
    raise(OptionParser::InvalidArgument, "Unreadable batch file! FILE='#{options[:batch]}'") if !options[:batch].nil? and !File.readable?(options[:batch])
    raise(OptionParser::InvalidArgument, "Invalid zoom level! Allowed range: 0-19.") if options[:zoom] < 9 or options[:zoom] > 19
    raise(OptionParser::MissingArgument, "No search term given!") if (ARGV.length == 0) and (options[:from_database].nil?) and (options[:batch].nil?)
    raise(OptionParser::InvalidArgument, "Database file is not readable!") if (!options[:from_database].nil?) and (!File.readable?(options[:from_database]))
    raise(OptionParser::InvalidArgument, "Number of scrolls must be greater or equal to 0!") if options[:scroll] < 0
    raise(OptionParser::InvalidArgument, "Config file not found!") if options[:config] && !File.exist?(options[:config])
    raise(OptionParser::AmbiguousOption, "Can only have '-b BATCH' or search terms!") if (ARGV.length > 0) and (!options[:batch].nil?)
    raise(OptionParser::AmbiguousOption, "Can only have '-D PLACES-DATABASE-FILE' or '-b BATCH'!") if (!options[:batch].nil?) and (!options[:from_database].nil?)
    raise(OptionParser::AmbiguousOption, "Can only have '-D PLACES-DATABASE-FILE' or search terms!") if (ARGV.length > 0) and (!options[:from_database].nil?)
  rescue OptionParser::ParseError => e
    It.error e.to_s
    optparse.parse("-h")
    exit(1)
  end
  if ARGV[0] == "help"
    ARGV[1..-1].each do |arg|
      case arg
      when "scroll"
        It.info("Option: -n SCROLL or --scroll SCROLL:")
        It.out("+---------------------------------------------------------------------+")
        It.out("| https://www.google.de/maps/search/Restaurant/@-34.89,138.61,9z/     |")
        It.out("|---------------------------------------------------------------------|")
        It.out("|  Results      |                                                     |")
        It.out("|               |      -n SCROLL  or  --scroll SCROLL  / Default: 1   |")
        It.out("|  Abcdef       |                                                     |")
        It.out("|---------------| <--- Scrolls this list SCROLL times down to get     |")
        It.out("|  Ghijklm      |      more search results.                           |")
        It.out("|---------------|                                                     |")
        It.out("|  Nopqrst      |                                                     |")
        It.out("|---------------|      -n 0  or  --scroll 0                           |")
        It.out("|  Uvwxyz       |                                                     |")
        It.out("|---------------| <--- Scrolls the list down to its end.              |")
        It.out("|               |      (I.e. get all search results)                  |")
      when "zoom"
        It.info("Option: -z ZOOM or --zoom ZOOM:")
        It.out("Typical search URI:")
        It.out("https://www.google.de/maps/search/Restaurant/@-34.89,138.61,9z/")
        It.out("                                                            =")
        It.out("                       Zoom factor (in this case: 9) -------/")
        It.out("")
        It.out("    -z ZOOM  or  --zoom ZOOM  / Default: 9")
        It.out("    ")
        It.out("    Changes the zoom factor of the map.")
        It.out("    Valid values are from 9 to 19.")
        It.out("    The smaller, the more you see on the map.")
        It.out("    To, hopefully, get more results. (I's all in the hands of Google!)")
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
#
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
