require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'

# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    list = DBConnection.execute2(<<-SQL)
      select * from "#{self.table_name}"
    SQL

    list[0].map { |col| col.to_sym }
  end

  def self.finalize!
    self.columns.each do |col|
        define_method("#{col}") { attributes[col] }
        define_method("#{col}=") { |value| attributes[col] = value }
    end
  end

  def self.table_name=(table_name)
    table_name
  end

  def self.table_name
    self.new.class.to_s.underscore + "s"
  end

  def self.all
    db_query = DBConnection.execute(<<-SQL)
      select * from "#{self.table_name}"
    SQL
    self.parse_all(db_query)
  end

  def self.parse_all(results)
    object_list = []
    results.each do |hash|
      object_list << self.new.class.new(hash)
    end
    object_list
  end

  def self.find(id)
    db_query = DBConnection.execute("Select * from #{self.table_name} where #{id} = id")
    self.parse_all(db_query).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      raise Exception.new "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=".to_sym, value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| attributes[col] }.compact
  end

  def insert
    col_names = self.class.columns.reject { |col| col == :id }.join(", ")
    question_marks = (["?"] * self.attribute_values.length).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values )
      insert into #{self.class.table_name} (#{col_names}) VALUES (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.reject { |col| col == :id }
    attributes = attribute_values
    object_id = attributes.shift
    sql_frag = []
    col_names.each_index do |idx|
      sql_frag << "#{col_names[idx]} = ?"
    end
    sql_frag = sql_frag.join(", ")
    DBConnection.execute(<<-SQL, *attributes, object_id)
      update #{self.class.table_name} SET #{sql_frag} WHERE id = ?
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
