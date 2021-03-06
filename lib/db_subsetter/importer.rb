require 'sqlite3'

module DbSubsetter
  # Manages importing a subset of data
  class Importer
    def initialize(filename)
      raise ArgumentError, 'invalid input file' unless File.exist?(filename)

      @data = SQLite3::Database.new(filename)
      @dialect = case ActiveRecord::Base.connection_config[:adapter]
                 when 'mysql2'
                   DbSubsetter::Dialect::MySQL
                 when 'postgresql'
                   DbSubsetter::Dialect::Postgres
                 when 'sqlite3'
                   DbSubsetter::Dialect::Sqlite
                 when 'sqlserver'
                   DbSubsetter::Dialect::MSSQL
                 else
                   DbSubsetter::Dialect::Generic
                 end
    end

    def tables
      all_tables = []
      @data.execute('SELECT name FROM tables') do |row|
        all_tables << row[0]
      end
      all_tables
    end

    def import(verbose = true)
      @verbose = verbose
      @dialect.import do
        tables.each do |table|
          import_table(table)
        end
      end
    end

    private

    def import_table(table)
      $stdout.sync
      started_at = Time.now
      print "Importing #{table}" if @verbose
      @dialect.truncate_table(table)

      ActiveRecord::Base.connection.begin_db_transaction

      all_rows = @data.execute("SELECT data FROM #{table.underscore}")
      all_rows.each_slice(@dialect::INSERT_BATCH_SIZE) do |rows|
        quoted_rows = rows.map { |row| '(' + quoted_values(row).join(',') + ')' }.join(',')
        insert_sql = "INSERT INTO #{quoted_table_name(table)} (#{quoted_column_names(table).join(',')}) VALUES #{quoted_rows}"
        ActiveRecord::Base.connection.execute(insert_sql)
        print '.' if @verbose
      end

      ActiveRecord::Base.connection.commit_db_transaction
      puts " (#{(Time.now - started_at).round(3)}s)" if @verbose
    end

    def quoted_values(row)
      out = JSON.parse(row[0])
      out = out.map { |x| ActiveRecord::Base.connection.type_cast(x, nil) }
      out = out.map { |x| ActiveRecord::Base.connection.quote(x) }
      out
    end

    def columns(table)
      raw = @data.execute('SELECT columns FROM tables WHERE name = ?', [table]).first[0]
      JSON.parse(raw)
    end

    def quoted_table_name(table)
      ActiveRecord::Base.connection.quote_table_name(table)
    end

    def quoted_column_names(table)
      columns(table).map { |column| ActiveRecord::Base.connection.quote_column_name(column) }
    end
  end
end
