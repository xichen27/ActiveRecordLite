require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    if params.length == 1
      where_line = "#{params.keys.first} = ?"
  	else
      where_line = params.map {|key, value| "#{key} = ?"}.join(' AND ')
    end

    query = <<-SQL
    SELECT
    	* 
    FROM
    	#{table_name}
    WHERE
    	#{where_line}
    SQL

    values = params.map {|key, value| value}
    parse_all(DBConnection.execute(query, *values))
  end
end

class SQLObject
  extend Searchable
end
