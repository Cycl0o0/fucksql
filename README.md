# F*ck SQL

A powerful Ruby CLI tool to convert SQL scripts between different database dialects.

**Supported dialects:** MySQL ↔ PostgreSQL ↔ SQLite

## Features

- 🔄 **Bidirectional conversion** between MySQL, PostgreSQL, and SQLite
- 📁 **File conversion** with automatic or custom output naming
- 💻 **Interactive mode** for quick conversions
- 🛡️ **Robust error handling** with clear error messages
- 🔧 **Type mapping** for database-specific data types
- ⚡ **Fast and lightweight** - pure Ruby, no dependencies

## Installation

```bash
git clone https://github.com/yourusername/fucksql.git
cd fucksql
```

No gems required! Just Ruby 2.7+.

## Usage

### Command Line Options

```
Usage:
  ruby main.rb [options]
  ruby main.rb <file.sql> <source_dialect> <target_dialect>

Options:
  -h, --help           Show help message
  -v, --version        Show version
  -c, --convert        Convert SQL string directly
  -f, --file           Convert file with explicit input/output paths
  -i, --interactive    Interactive mode
  -l, --list-dialects  List supported dialects
```

### Quick Examples

**Convert a file (auto-named output):**
```bash
ruby main.rb schema.sql mysql postgres
# Creates: schema_postgres.sql
```

**Convert a file with custom output:**
```bash
ruby main.rb -f input.sql output.sql mysql postgres
```

**Convert a SQL string directly:**
```bash
ruby main.rb -c "CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY)" mysql postgres
# Output: CREATE TABLE users (id SERIAL PRIMARY KEY)
```

**Interactive mode:**
```bash
ruby main.rb -i
```

### Supported Dialects

| Dialect    | Aliases                     |
|------------|----------------------------|
| `mysql`    | `mariadb`                  |
| `postgres` | `postgresql`, `pg`, `pgsql`|
| `sqlite`   | `sqlite3`                  |

## What Gets Converted

### MySQL → PostgreSQL

| MySQL                  | PostgreSQL           |
|------------------------|----------------------|
| `INT AUTO_INCREMENT`   | `SERIAL`             |
| `BIGINT AUTO_INCREMENT`| `BIGSERIAL`          |
| `TINYINT`              | `SMALLINT`           |
| `DATETIME`             | `TIMESTAMP`          |
| `DOUBLE`               | `DOUBLE PRECISION`   |
| `BLOB`, `LONGBLOB`     | `BYTEA`              |
| `LONGTEXT`             | `TEXT`               |
| `` `backticks` ``      | `"double quotes"`    |
| `ENGINE=InnoDB`        | *(removed)*          |
| `CHARSET=utf8`         | *(removed)*          |
| `IFNULL()`             | `COALESCE()`         |
| `LIMIT 10, 20`         | `LIMIT 20 OFFSET 10` |

### PostgreSQL → MySQL

| PostgreSQL             | MySQL                |
|------------------------|----------------------|
| `SERIAL`               | `INT AUTO_INCREMENT` |
| `BIGSERIAL`            | `BIGINT AUTO_INCREMENT`|
| `BOOLEAN`              | `TINYINT(1)`         |
| `BYTEA`                | `BLOB`               |
| `UUID`                 | `CHAR(36)`           |
| `JSONB`                | `JSON`               |
| `TIMESTAMPTZ`          | `DATETIME`           |
| `"double quotes"`      | `` `backticks` ``    |

### SQLite ↔ MySQL/PostgreSQL

| SQLite                          | MySQL/PostgreSQL      |
|---------------------------------|-----------------------|
| `INTEGER PRIMARY KEY AUTOINCREMENT` | `SERIAL PRIMARY KEY` (PG) / `INT AUTO_INCREMENT PRIMARY KEY` (MySQL) |
| `REAL`                          | `DOUBLE` / `DOUBLE PRECISION` |
| `BLOB`                          | `BLOB` / `BYTEA`      |
| `TEXT`                          | `TEXT`                |

## Interactive Mode Commands

When running in interactive mode (`-i`), you can use:

| Command        | Description              |
|----------------|--------------------------|
| `help`, `?`    | Show help                |
| `dialects`     | List supported dialects  |
| `clear`, `cls` | Clear screen             |
| `exit`, `quit` | Exit interactive mode    |

## Project Structure

```
fucksql/
├── main.rb          # CLI entry point
├── converter.rb     # Conversion logic
├── dictionnary.rb   # Type mappings
├── test_mysql.sql   # MySQL test file
├── test_postgres.sql# PostgreSQL test file
└── test_sqlite.sql  # SQLite test file
```

## Debug Mode

Enable debug output for troubleshooting:

```bash
DEBUG=1 ruby main.rb schema.sql mysql postgres
```

## Limitations

- **Comments:** SQL comments are preserved but not parsed
- **Stored procedures:** Complex PL/SQL or PL/pgSQL may need manual adjustment
- **Dialect-specific features:** Some features (e.g., PostgreSQL arrays, MySQL spatial types) have no direct equivalent
- **Views & Triggers:** Converted but may need manual review

## Examples

### Convert MySQL Schema to PostgreSQL

```sql
-- Input (MySQL)
CREATE TABLE `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `data` LONGBLOB
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Output (PostgreSQL)
CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "data" BYTEA
);
```

### Convert PostgreSQL to SQLite

```sql
-- Input (PostgreSQL)
CREATE TABLE "sessions" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER,
    "data" JSONB
);

-- Output (SQLite)
CREATE TABLE "sessions" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "user_id" INTEGER,
    "data" TEXT
);
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Author

Made with ❤️ by [@Cycl0o0](https://github.com/Cycl0o0)

---

*Because sometimes you just need to say "F\*ck it" and convert that SQL.*
