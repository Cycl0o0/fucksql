# F*ck SQL : a Ruby program to convert SQL from one dialect to another
# Supports: MySQL <-> PostgreSQL <-> SQLite
# frozen_string_literal: true

require_relative 'converter'
require_relative 'dictionnary'

class Main
  VERSION = "1.0.0"

  def self.run(args = ARGV)
    # Handle empty args
    if args.empty?
      show_help
      return 0
    end

    begin
      case args[0]
      when '-h', '--help'
        show_help
        0
      when '-v', '--version'
        puts "F*ck SQL v#{VERSION} - SQL Converter - by @Cycl0o0"
        0
      when '-c', '--convert'
        handle_convert(args[1..])
      when '-i', '--interactive'
        interactive_mode
      when '-l', '--list-dialects'
        list_dialects
        0
      when '-f', '--file'
        handle_file_with_output(args[1..])
      else
        if args[0]&.start_with?('-')
          puts "Error: Unknown option '#{args[0]}'"
          puts "Use -h or --help for usage information"
          1
        else
          handle_file_conversion(args)
        end
      end
    rescue Interrupt
      puts "\nOperation cancelled by user"
      130
    rescue StandardError => e
      puts "Fatal error: #{e.message}"
      puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
      1
    end
  end

  def self.show_help
    puts <<~HELP
      F*ck SQL - SQL Converter for multiple dialects

      Usage:
        ruby main.rb [options]
        ruby main.rb <file.sql> <source_dialect> <target_dialect>

      Options:
        -h, --help           Show this message
        -v, --version        Show version
        -c, --convert        Convert SQL string directly
        -f, --file           Convert file with explicit input/output paths
        -i, --interactive    Interactive mode
        -l, --list-dialects  List supported dialects

      File conversion:
        ruby main.rb <input.sql> <source> <target>
            Converts input.sql and creates input_<target>.sql

        ruby main.rb -f <input.sql> <output.sql> <source> <target>
            Converts input.sql and writes to output.sql

      Supported dialects:
        - mysql (aliases: mariadb)
        - postgres (aliases: postgresql, pg, pgsql)
        - sqlite (aliases: sqlite3)

      Examples:
        ruby main.rb schema.sql mysql postgres
        ruby main.rb -f input.sql output.sql mysql postgres
        ruby main.rb -c "CREATE TABLE users (id INT AUTO_INCREMENT)" mysql postgres
        ruby main.rb -i

      Environment:
        DEBUG=1    Enable debug output

    HELP
  end

  def self.list_dialects
    puts "Supported dialects:"
    Converter.supported_dialects.each do |dialect|
      puts "  - #{dialect}"
    end
    puts "\nAliases:"
    puts "  - postgresql, pg, pgsql -> postgres"
    puts "  - mariadb -> mysql"
    puts "  - sqlite3 -> sqlite"
  end

  def self.handle_convert(args)
    if args.nil? || args.length < 3
      puts "Error: Insufficient arguments"
      puts "Usage: ruby main.rb -c \"<sql>\" <source> <target>"
      return 1
    end

    sql = args[0]
    source = args[1]
    target = args[2]

    if sql.nil? || sql.strip.empty?
      puts "Error: SQL string cannot be empty"
      return 1
    end

    converter = Converter.new(sql, source, target)
    result = converter.convert

    if converter.valid?
      puts "=== Results ==="
      puts result
      converter.warnings.each { |w| puts "⚠️  #{w}" }
      0
    else
      puts "=== Failure ==="
      converter.errors.each { |e| puts "❌ #{e}" }
      1
    end
  end

  def self.handle_file_conversion(args)
    if args.nil? || args.length < 3
      puts "Error: Insufficient arguments"
      puts "Usage: ruby main.rb <file.sql> <source_dialect> <target_dialect>"
      return 1
    end

    file_path = args[0]
    source = args[1]
    target = args[2]

    # Validate file exists
    unless File.exist?(file_path)
      puts "Error: File '#{file_path}' not found"
      return 1
    end

    # Validate file is readable
    unless File.readable?(file_path)
      puts "Error: File '#{file_path}' is not readable"
      return 1
    end

    # Check file size (max 10MB)
    file_size = File.size(file_path)
    if file_size > 10_000_000
      puts "Error: File is too large (#{file_size / 1_000_000}MB). Maximum is 10MB"
      return 1
    end

    if file_size == 0
      puts "Error: File is empty"
      return 1
    end

    begin
      sql = File.read(file_path, encoding: 'UTF-8')
    rescue Encoding::InvalidByteSequenceError
      # Try reading with binary encoding
      sql = File.read(file_path, encoding: 'ASCII-8BIT')
      puts "⚠️  Warning: File contains non-UTF8 characters"
    rescue StandardError => e
      puts "Error: Failed to read file: #{e.message}"
      return 1
    end

    converter = Converter.new(sql, source, target)
    result = converter.convert

    if converter.valid?
      # Generate output filename
      base_name = File.basename(file_path, '.*')
      extension = File.extname(file_path)
      output_file = "#{base_name}_#{target}#{extension.empty? ? '.sql' : extension}"

      # Check if output file already exists
      if File.exist?(output_file)
        puts "⚠️  Warning: Overwriting existing file '#{output_file}'"
      end

      begin
        File.write(output_file, result, encoding: 'UTF-8')
        puts "✅ Conversion successful: #{output_file}"
        puts "   Input: #{file_size} bytes -> Output: #{result.bytesize} bytes"
        converter.warnings.each { |w| puts "⚠️  #{w}" }
        0
      rescue StandardError => e
        puts "Error: Failed to write output file: #{e.message}"
        1
      end
    else
      puts "=== Failure ==="
      converter.errors.each { |e| puts "❌ #{e}" }
      1
    end
  end

  def self.handle_file_with_output(args)
    if args.nil? || args.length < 4
      puts "Error: Insufficient arguments"
      puts "Usage: ruby main.rb -f <input.sql> <output.sql> <source> <target>"
      return 1
    end

    input_file = args[0]
    output_file = args[1]
    source = args[2]
    target = args[3]

    # Validate input file exists
    unless File.exist?(input_file)
      puts "Error: Input file '#{input_file}' not found"
      return 1
    end

    # Validate input file is readable
    unless File.readable?(input_file)
      puts "Error: Input file '#{input_file}' is not readable"
      return 1
    end

    # Check file size (max 10MB)
    file_size = File.size(input_file)
    if file_size > 10_000_000
      puts "Error: File is too large (#{file_size / 1_000_000}MB). Maximum is 10MB"
      return 1
    end

    if file_size == 0
      puts "Error: Input file is empty"
      return 1
    end

    # Check if output file path is valid (directory exists)
    output_dir = File.dirname(output_file)
    unless output_dir == '.' || File.directory?(output_dir)
      puts "Error: Output directory '#{output_dir}' does not exist"
      return 1
    end

    # Check if output directory is writable
    unless File.writable?(output_dir == '.' ? Dir.pwd : output_dir)
      puts "Error: Output directory '#{output_dir}' is not writable"
      return 1
    end

    # Read input file
    begin
      sql = File.read(input_file, encoding: 'UTF-8')
    rescue Encoding::InvalidByteSequenceError
      sql = File.read(input_file, encoding: 'ASCII-8BIT')
      puts "⚠️  Warning: File contains non-UTF8 characters"
    rescue StandardError => e
      puts "Error: Failed to read input file: #{e.message}"
      return 1
    end

    # Convert
    converter = Converter.new(sql, source, target)
    result = converter.convert

    if converter.valid?
      # Check if output file already exists
      if File.exist?(output_file)
        puts "⚠️  Warning: Overwriting existing file '#{output_file}'"
      end

      begin
        File.write(output_file, result, encoding: 'UTF-8')
        puts "✅ Conversion successful!"
        puts "   Input:  #{input_file} (#{file_size} bytes)"
        puts "   Output: #{output_file} (#{result.bytesize} bytes)"
        puts "   #{source} -> #{target}"
        converter.warnings.each { |w| puts "⚠️  #{w}" }
        0
      rescue StandardError => e
        puts "Error: Failed to write output file: #{e.message}"
        1
      end
    else
      puts "=== Failure ==="
      converter.errors.each { |e| puts "❌ #{e}" }
      1
    end
  end

  def self.interactive_mode
    puts "F*ck SQL - Interactive mode"
    puts "Type 'exit' or press Ctrl+C to quit"
    puts "Type 'help' for commands"
    puts "-" * 40

    loop do
      print "\nSource dialect (mysql/postgres/sqlite): "
      source = safe_gets
      break if exit_command?(source)
      next if handle_interactive_command(source)
      next if source.empty?

      print "Target dialect (mysql/postgres/sqlite): "
      target = safe_gets
      break if exit_command?(target)
      next if handle_interactive_command(target)
      next if target.empty?

      puts "Enter your SQL (end with an empty line or 'END'):"
      sql_lines = []
      loop do
        line = safe_gets
        break if line.empty? || line.upcase == 'END' || exit_command?(line)
        sql_lines << line
      end

      sql = sql_lines.join("\n")
      if sql.strip.empty?
        puts "⚠️  No SQL entered, skipping..."
        next
      end

      converter = Converter.new(sql, source, target)
      result = converter.convert

      puts "\n=== Results ==="
      if converter.valid?
        puts result
        converter.warnings.each { |w| puts "⚠️  #{w}" }
      else
        converter.errors.each { |e| puts "❌ #{e}" }
      end
      puts "-" * 40
    end

    puts "\nGoodbye! Made with <3 by @Cycl0o0"
    0
  rescue Interrupt
    puts "\n\nGoodbye! Made with <3 by @Cycl0o0"
    0
  end

  # Private helper methods
  class << self
    private

    def safe_gets
      input = $stdin.gets
      return "" if input.nil?
      input.chomp.strip
    rescue IOError
      ""
    end

    def exit_command?(input)
      return true if input.nil?
      %w[exit quit q].include?(input.downcase)
    end

    def handle_interactive_command(input)
      case input.downcase
      when 'help', '?'
        show_interactive_help
        true
      when 'dialects', 'list'
        list_dialects
        true
      when 'clear', 'cls'
        system('clear') || system('cls')
        true
      else
        false
      end
    end

    def show_interactive_help
      puts <<~HELP
        
        Interactive Commands:
          help, ?      Show this help
          dialects     List supported dialects
          clear, cls   Clear screen
          exit, quit   Exit interactive mode
        
        SQL Input:
          Enter your SQL statements line by line
          End with an empty line or 'END'
        
      HELP
    end
  end
end

# Point d'entrée
exit(Main.run) if __FILE__ == $PROGRAM_NAME
