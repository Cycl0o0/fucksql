# frozen_string_literal: true

class Dictionnary
  # MySQL -> PostgreSQL type mappings
  MYSQL_TO_POSTGRES = {
    'TINYINT' => 'SMALLINT',
    'MEDIUMINT' => 'INTEGER',
    'INT' => 'INTEGER',
    'BIGINT' => 'BIGINT',
    'FLOAT' => 'REAL',
    'DOUBLE' => 'DOUBLE PRECISION',
    'DECIMAL' => 'NUMERIC',
    'DATETIME' => 'TIMESTAMP',
    'TINYTEXT' => 'TEXT',
    'MEDIUMTEXT' => 'TEXT',
    'LONGTEXT' => 'TEXT',
    'TINYBLOB' => 'BYTEA',
    'MEDIUMBLOB' => 'BYTEA',
    'LONGBLOB' => 'BYTEA',
    'BLOB' => 'BYTEA',
    'VARBINARY' => 'BYTEA',
    'BINARY' => 'BYTEA',
    'BIT' => 'BIT',
    'UNSIGNED' => '',
    'ZEROFILL' => ''
  }.freeze

  # PostgreSQL -> MySQL type mappings
  POSTGRES_TO_MYSQL = {
    'SMALLINT' => 'SMALLINT',
    'INTEGER' => 'INT',
    'BIGINT' => 'BIGINT',
    'REAL' => 'FLOAT',
    'DOUBLE PRECISION' => 'DOUBLE',
    'NUMERIC' => 'DECIMAL',
    'TIMESTAMP' => 'DATETIME',
    'TIMESTAMPTZ' => 'DATETIME',
    'BYTEA' => 'BLOB',
    'UUID' => 'CHAR(36)',
    'JSON' => 'JSON',
    'JSONB' => 'JSON',
    'BOOLEAN' => 'TINYINT(1)',
    'BOOL' => 'TINYINT(1)',
    'INET' => 'VARCHAR(45)',
    'CIDR' => 'VARCHAR(45)',
    'MACADDR' => 'VARCHAR(17)',
    'MONEY' => 'DECIMAL(19,2)',
    'INTERVAL' => 'VARCHAR(255)',
    'TEXT' => 'LONGTEXT'
  }.freeze

  # SQLite -> MySQL type mappings
  SQLITE_TO_MYSQL = {
    'REAL' => 'DOUBLE',
    'NUMERIC' => 'DECIMAL',
    'BLOB' => 'BLOB',
    'TEXT' => 'TEXT'
  }.freeze

  # SQLite -> PostgreSQL type mappings
  SQLITE_TO_POSTGRES = {
    'REAL' => 'DOUBLE PRECISION',
    'NUMERIC' => 'NUMERIC',
    'BLOB' => 'BYTEA',
    'TEXT' => 'TEXT'
  }.freeze

  # MySQL -> SQLite type mappings
  MYSQL_TO_SQLITE = {
    'TINYINT' => 'INTEGER',
    'SMALLINT' => 'INTEGER',
    'MEDIUMINT' => 'INTEGER',
    'INT' => 'INTEGER',
    'BIGINT' => 'INTEGER',
    'FLOAT' => 'REAL',
    'DOUBLE' => 'REAL',
    'DECIMAL' => 'NUMERIC',
    'DATETIME' => 'TEXT',
    'TIMESTAMP' => 'TEXT',
    'DATE' => 'TEXT',
    'TIME' => 'TEXT',
    'YEAR' => 'INTEGER',
    'TINYTEXT' => 'TEXT',
    'MEDIUMTEXT' => 'TEXT',
    'LONGTEXT' => 'TEXT',
    'TINYBLOB' => 'BLOB',
    'MEDIUMBLOB' => 'BLOB',
    'LONGBLOB' => 'BLOB',
    'JSON' => 'TEXT',
    'BOOLEAN' => 'INTEGER',
    'BOOL' => 'INTEGER'
  }.freeze

  # PostgreSQL -> SQLite type mappings
  POSTGRES_TO_SQLITE = {
    'SMALLINT' => 'INTEGER',
    'INTEGER' => 'INTEGER',
    'BIGINT' => 'INTEGER',
    'REAL' => 'REAL',
    'DOUBLE PRECISION' => 'REAL',
    'NUMERIC' => 'NUMERIC',
    'BOOLEAN' => 'INTEGER',
    'BOOL' => 'INTEGER',
    'TIMESTAMP' => 'TEXT',
    'TIMESTAMPTZ' => 'TEXT',
    'DATE' => 'TEXT',
    'TIME' => 'TEXT',
    'TIMETZ' => 'TEXT',
    'INTERVAL' => 'TEXT',
    'UUID' => 'TEXT',
    'JSON' => 'TEXT',
    'JSONB' => 'TEXT',
    'BYTEA' => 'BLOB',
    'INET' => 'TEXT',
    'CIDR' => 'TEXT',
    'MACADDR' => 'TEXT',
    'MONEY' => 'REAL'
  }.freeze

  # SQL Keywords
  SQL_KEYWORDS = %w[
    SELECT INSERT UPDATE DELETE FROM WHERE AND OR NOT IN
    JOIN LEFT RIGHT INNER OUTER FULL CROSS ON AS
    CREATE TABLE DROP ALTER ADD COLUMN PRIMARY KEY
    FOREIGN REFERENCES CASCADE SET NULL DEFAULT
    INDEX UNIQUE CONSTRAINT CHECK
    ORDER BY GROUP HAVING LIMIT OFFSET
    UNION INTERSECT EXCEPT ALL DISTINCT
    BEGIN COMMIT ROLLBACK TRANSACTION
    GRANT REVOKE PRIVILEGES
    VIEW TRIGGER FUNCTION PROCEDURE
    IF EXISTS NOT NULL AUTO_INCREMENT SERIAL
  ].freeze

  def initialize
    # Instance can be extended with custom mappings
    @custom_mappings = {}
  end

  def mysql_to_postgres_types
    MYSQL_TO_POSTGRES.merge(@custom_mappings[:mysql_to_postgres] || {})
  end

  def postgres_to_mysql_types
    POSTGRES_TO_MYSQL.merge(@custom_mappings[:postgres_to_mysql] || {})
  end

  def sqlite_to_mysql_types
    SQLITE_TO_MYSQL.merge(@custom_mappings[:sqlite_to_mysql] || {})
  end

  def sqlite_to_postgres_types
    SQLITE_TO_POSTGRES.merge(@custom_mappings[:sqlite_to_postgres] || {})
  end

  def mysql_to_sqlite_types
    MYSQL_TO_SQLITE.merge(@custom_mappings[:mysql_to_sqlite] || {})
  end

  def postgres_to_sqlite_types
    POSTGRES_TO_SQLITE.merge(@custom_mappings[:postgres_to_sqlite] || {})
  end

  def sql_keywords
    SQL_KEYWORDS
  end

  # Add custom type mapping
  def add_custom_mapping(conversion_type, source_type, target_type)
    raise ArgumentError, "conversion_type must be a Symbol" unless conversion_type.is_a?(Symbol)
    raise ArgumentError, "source_type must be a String" unless source_type.is_a?(String)
    raise ArgumentError, "target_type must be a String" unless target_type.is_a?(String)

    @custom_mappings[conversion_type] ||= {}
    @custom_mappings[conversion_type][source_type.upcase] = target_type.upcase
  end

  # Get mapping for specific conversion
  def get_mapping(conversion_type)
    case conversion_type
    when :mysql_to_postgres then mysql_to_postgres_types
    when :postgres_to_mysql then postgres_to_mysql_types
    when :sqlite_to_mysql then sqlite_to_mysql_types
    when :sqlite_to_postgres then sqlite_to_postgres_types
    when :mysql_to_sqlite then mysql_to_sqlite_types
    when :postgres_to_sqlite then postgres_to_sqlite_types
    else
      raise ArgumentError, "Unknown conversion type: #{conversion_type}"
    end
  end

  # Check if a type exists in any mapping
  def type_exists?(type_name)
    all_types = [
      MYSQL_TO_POSTGRES.keys,
      POSTGRES_TO_MYSQL.keys,
      SQLITE_TO_MYSQL.keys,
      MYSQL_TO_SQLITE.keys
    ].flatten.uniq

    all_types.include?(type_name.upcase)
  end
end
