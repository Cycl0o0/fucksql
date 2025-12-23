# frozen_string_literal: true

require_relative 'dictionnary'

class Converter
  DIALECTS = %w[mysql postgres sqlite].freeze

  attr_reader :sql, :source_dialect, :target_dialect, :output, :errors, :warnings

  class ConversionError < StandardError; end

  def initialize(sql = "", source_dialect = "mysql", target_dialect = "postgres")
    @sql = sql.to_s
    @source_dialect = normalize_dialect(source_dialect)
    @target_dialect = normalize_dialect(target_dialect)
    @output = ""
    @errors = []
    @warnings = []
    @dictionnary = Dictionnary.new
  end

  def convert
    validate_input
    validate_dialects
    return nil unless @errors.empty?

    @output = @sql.dup

    begin
      apply_conversions
    rescue StandardError => e
      @errors << "Conversion error: #{e.message}"
      return nil
    end

    @output
  end

  def convert!
    result = convert
    raise ConversionError, @errors.join(", ") unless valid?
    result
  end

  def valid?
    @errors.empty?
  end

  def self.supported_dialects
    DIALECTS.dup
  end

  def self.dialect_supported?(dialect)
    DIALECTS.include?(dialect.to_s.downcase.strip)
  end

  private

  def normalize_dialect(dialect)
    return "" if dialect.nil?

    normalized = dialect.to_s.downcase.strip

    # Handle common aliases
    case normalized
    when "postgresql", "pg", "pgsql"
      "postgres"
    when "mariadb"
      "mysql"
    when "sqlite3"
      "sqlite"
    else
      normalized
    end
  end

  def validate_input
    if @sql.nil? || @sql.strip.empty?
      @errors << "SQL input cannot be empty"
    elsif @sql.length > 10_000_000 # 10MB limit
      @errors << "SQL input is too large (max 10MB)"
    end
  end

  def validate_dialects
    if @source_dialect.empty?
      @errors << "Source dialect cannot be empty"
    elsif !DIALECTS.include?(@source_dialect)
      @errors << "Invalid source dialect: '#{@source_dialect}'. Supported: #{DIALECTS.join(', ')}"
    end

    if @target_dialect.empty?
      @errors << "Target dialect cannot be empty"
    elsif !DIALECTS.include?(@target_dialect)
      @errors << "Invalid target dialect: '#{@target_dialect}'. Supported: #{DIALECTS.join(', ')}"
    end

    if @source_dialect == @target_dialect && !@source_dialect.empty?
      @warnings << "Source and target dialects are identical - no conversion needed"
    end
  end

  def apply_conversions
    conversion_method = "convert_#{@source_dialect}_to_#{@target_dialect}"
    if respond_to?(conversion_method, true)
      send(conversion_method)
    else
      @warnings << "Conversion from #{@source_dialect} to #{@target_dialect} not implemented"
    end
  end

  # MySQL -> PostgreSQL
  def convert_mysql_to_postgres
    convert_auto_increment_to_serial  # Must be before type conversion
    convert_data_types_mysql_to_postgres
    convert_backticks_to_quotes
    convert_engine_clause
    convert_charset_clause
    convert_mysql_specific_functions
  end

  # PostgreSQL -> MySQL
  def convert_postgres_to_mysql
    convert_serial_to_auto_increment  # Must be before type conversion
    convert_data_types_postgres_to_mysql
    convert_quotes_to_backticks
    convert_postgres_specific_functions
  end

  # SQLite -> MySQL
  def convert_sqlite_to_mysql
    convert_autoincrement_sqlite_to_mysql
    convert_data_types_sqlite_to_mysql
  end

  # SQLite -> PostgreSQL
  def convert_sqlite_to_postgres
    convert_autoincrement_sqlite_to_postgres
    convert_data_types_sqlite_to_postgres
  end

  # MySQL -> SQLite
  def convert_mysql_to_sqlite
    convert_auto_increment_to_autoincrement
    convert_data_types_mysql_to_sqlite
    convert_backticks_to_quotes
    remove_engine_clause
    remove_charset_clause
    remove_mysql_specific_clauses
  end

  # PostgreSQL -> SQLite
  def convert_postgres_to_sqlite
    convert_serial_to_autoincrement
    convert_data_types_postgres_to_sqlite
    remove_postgres_specific_clauses
  end

  # Safe type conversion with regex escaping
  def safe_type_replace(type_mappings)
    type_mappings.each do |source_type, target_type|
      next if target_type.nil? || source_type.nil?

      escaped_source = Regexp.escape(source_type)
      @output.gsub!(/\b#{escaped_source}\b/i, target_type)
    end
  end

  # Conversions de types de données
  def convert_data_types_mysql_to_postgres
    safe_type_replace(@dictionnary.mysql_to_postgres_types)
  end

  def convert_data_types_postgres_to_mysql
    safe_type_replace(@dictionnary.postgres_to_mysql_types)
  end

  def convert_data_types_sqlite_to_mysql
    safe_type_replace(@dictionnary.sqlite_to_mysql_types)
  end

  def convert_data_types_sqlite_to_postgres
    safe_type_replace(@dictionnary.sqlite_to_postgres_types)
  end

  def convert_data_types_mysql_to_sqlite
    safe_type_replace(@dictionnary.mysql_to_sqlite_types)
  end

  def convert_data_types_postgres_to_sqlite
    safe_type_replace(@dictionnary.postgres_to_sqlite_types)
  end

  # Conversions AUTO_INCREMENT / SERIAL / AUTOINCREMENT
  def convert_auto_increment_to_serial
    @output.gsub!(/\bINT(EGER)?\s+AUTO_INCREMENT\s+PRIMARY\s+KEY/i, 'SERIAL PRIMARY KEY')
    @output.gsub!(/\bINT(EGER)?\s+PRIMARY\s+KEY\s+AUTO_INCREMENT/i, 'SERIAL PRIMARY KEY')
    @output.gsub!(/\bBIGINT\s+AUTO_INCREMENT\s+PRIMARY\s+KEY/i, 'BIGSERIAL PRIMARY KEY')
    @output.gsub!(/\bBIGINT\s+PRIMARY\s+KEY\s+AUTO_INCREMENT/i, 'BIGSERIAL PRIMARY KEY')
    @output.gsub!(/\bINT(EGER)?\s+AUTO_INCREMENT/i, 'SERIAL')
    @output.gsub!(/\bBIGINT\s+AUTO_INCREMENT/i, 'BIGSERIAL')
    @output.gsub!(/\bSMALLINT\s+AUTO_INCREMENT/i, 'SMALLSERIAL')
  end

  def convert_serial_to_auto_increment
    @output.gsub!(/\bBIGSERIAL\s+PRIMARY\s+KEY/i, 'BIGINT PRIMARY KEY AUTO_INCREMENT')
    @output.gsub!(/\bSMALLSERIAL\s+PRIMARY\s+KEY/i, 'SMALLINT PRIMARY KEY AUTO_INCREMENT')
    @output.gsub!(/\bSERIAL\s+PRIMARY\s+KEY/i, 'INT PRIMARY KEY AUTO_INCREMENT')
    @output.gsub!(/\bBIGSERIAL\b/i, 'BIGINT AUTO_INCREMENT')
    @output.gsub!(/\bSMALLSERIAL\b/i, 'SMALLINT AUTO_INCREMENT')
    @output.gsub!(/\bSERIAL\b/i, 'INT AUTO_INCREMENT')
  end

  def convert_autoincrement_sqlite_to_mysql
    @output.gsub!(/\bINTEGER\s+PRIMARY\s+KEY\s+AUTOINCREMENT/i, 'INT PRIMARY KEY AUTO_INCREMENT')
  end

  def convert_autoincrement_sqlite_to_postgres
    @output.gsub!(/\bINTEGER\s+PRIMARY\s+KEY\s+AUTOINCREMENT/i, 'SERIAL PRIMARY KEY')
  end

  def convert_auto_increment_to_autoincrement
    @output.gsub!(/\bINT\s+PRIMARY\s+KEY\s+AUTO_INCREMENT/i, 'INTEGER PRIMARY KEY AUTOINCREMENT')
    @output.gsub!(/\bINT\s+AUTO_INCREMENT\s+PRIMARY\s+KEY/i, 'INTEGER PRIMARY KEY AUTOINCREMENT')
    @output.gsub!(/\bINT\s+AUTO_INCREMENT/i, 'INTEGER AUTOINCREMENT')
  end

  def convert_serial_to_autoincrement
    @output.gsub!(/\bSERIAL\s+PRIMARY\s+KEY/i, 'INTEGER PRIMARY KEY AUTOINCREMENT')
    @output.gsub!(/\bBIGSERIAL\s+PRIMARY\s+KEY/i, 'INTEGER PRIMARY KEY AUTOINCREMENT')
    @output.gsub!(/\bSERIAL\b/i, 'INTEGER AUTOINCREMENT')
    @output.gsub!(/\bBIGSERIAL\b/i, 'INTEGER AUTOINCREMENT')
  end

  # Conversions de syntaxe
  def convert_backticks_to_quotes
    @output.gsub!(/`([^`]+)`/, '"\1"')
  end

  def convert_quotes_to_backticks
    # Only convert double quotes that are identifiers, not string literals
    @output.gsub!(/"([^"]+)"(?=\s*(?:,|\)|$|\s+(?:INT|VARCHAR|TEXT|INTEGER|SERIAL|PRIMARY|NOT|NULL|DEFAULT|UNIQUE|CHECK|REFERENCES|CONSTRAINT)))/i, '`\1`')
  end

  # Suppression de clauses spécifiques MySQL
  def convert_engine_clause
    @output.gsub!(/\s*ENGINE\s*=\s*\w+/i, '')
  end

  def remove_engine_clause
    convert_engine_clause
  end

  def convert_charset_clause
    @output.gsub!(/\s*DEFAULT\s+CHARSET\s*=\s*\w+/i, '')
    @output.gsub!(/\s*CHARACTER\s+SET\s+\w+/i, '')
    @output.gsub!(/\s*COLLATE\s*=?\s*\w+/i, '')
  end

  def remove_charset_clause
    convert_charset_clause
  end

  def remove_mysql_specific_clauses
    @output.gsub!(/\s*AUTO_INCREMENT\s*=\s*\d+/i, '')
    @output.gsub!(/\s*ROW_FORMAT\s*=\s*\w+/i, '')
    @output.gsub!(/\s*COMMENT\s*=\s*'[^']*'/i, '')
    @output.gsub!(/\s*UNSIGNED\b/i, '')
    @output.gsub!(/\s*ZEROFILL\b/i, '')
  end

  def remove_postgres_specific_clauses
    @output.gsub!(/\s*WITH\s*\([^)]+\)/i, '')
    @output.gsub!(/\s*TABLESPACE\s+\w+/i, '')
  end

  def convert_mysql_specific_functions
    # NOW() is the same, but some functions differ
    @output.gsub!(/\bIFNULL\s*\(/i, 'COALESCE(')
    @output.gsub!(/\bLIMIT\s+(\d+)\s*,\s*(\d+)/i, 'LIMIT \2 OFFSET \1')
  end

  def convert_postgres_specific_functions
    @output.gsub!(/\bCOALESCE\s*\(/i, 'IFNULL(')
    # Note: PostgreSQL LIMIT/OFFSET to MySQL LIMIT syntax
  end
end
