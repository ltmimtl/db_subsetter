require 'random-word'

module DbSubsetter
  # Clean or redact data to be exported
  class Scrambler
    def scramble(table, row)
      scramble_method = "scramble_#{table.downcase}"
      if respond_to? scramble_method
        send(scramble_method, row)
      else
        row
      end
    end

    def initialize
      @column_index_cache = {}
    end

    protected

    def scramble_column(table, column, row_data, value)
      row_data[column_index(table, column)] = value
    end

    private

    def column_index(table, column)
      @column_index_cache["#{table}##{column}"] ||=
        ActiveRecord::Base.connection.columns(table).map.(&:name).index(column.to_s)
    end
  end
end
