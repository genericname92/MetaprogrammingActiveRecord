require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map { |key, value| "#{key} = ?" }.join(" AND ")
    query = DBConnection.execute(<<-SQL, params.values)
      select * from #{self.new.class.table_name} where #{where_line}
    SQL
    return [] if query.empty?
    self.parse_all(query)
  end
end

class SQLObject
  extend Searchable
end
