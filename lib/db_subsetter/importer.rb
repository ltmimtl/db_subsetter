require 'sqlite3'

module DbSubsetter
  class Importer

    def initialize(filename)
      raise ArgumentError.new("invalid input file") unless File.exists?(filename)

      @data = SQLite3::Database.new(filename)
    end

    def tables
      all_tables = []
      @data.execute("SELECT name FROM tables") do |row|
        all_tables << row[0]
      end
      all_tables
    end

    def import
     ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0;")
     tables.each do |table|
        import_table(table)
      end
     ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1;")
    end

    private
    def import_table(table)
      ActiveRecord::Base.connection.truncate(table)
      @data.execute("SELECT data FROM #{table.underscore}") do |row|
        insert_sql = "INSERT INTO #{quoted_table_name(table)} (#{quoted_column_names(table).join(",")}) VALUES (#{quoted_values(row).join(",")})"
        ActiveRecord::Base.connection.execute(insert_sql)
      end
    end

    def quoted_values(row)
      out = JSON.parse(row[0])
      out = out.map{|x| ActiveRecord::Base.connection.type_cast(x, nil) } #.first, x.last) }
      out = out.map{|x| ActiveRecord::Base.connection.quote(x) }
      out
    end

    def columns(table)
      raw = @data.execute("SELECT columns FROM tables WHERE name = ?", [table]).first[0]
      JSON.parse(raw)
    end

    def quoted_table_name(table)
      ActiveRecord::Base.connection.quote_table_name(table)
    end

    def quoted_column_names(table)
      columns(table).map{ |column| ActiveRecord::Base.connection.quote_column_name(column) }
    end

  end
end

