require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    query = <<-SQL
      SELECT
        *
      From
        #{table_name}
    SQL

     DBConnection.execute2(query).first.map! {|col| col.to_sym}
  end

  def self.finalize!

    self.columns.each do |col|
      define_method(col) do 
        self.attributes[col]
      end
      define_method("#{col}=") do |value|
        #instance_variable_set("@#{col}".to_sym, stuff)
        self.attributes[col] = value
      end
     
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    query = <<-SQL
    SELECT 
      #{table_name}.*
    FROM
      #{table_name}
    SQL
    
    results = DBConnection.execute(query)#.select {|obj| obj.attributes}
    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    query = <<-SQL
    SELECT
      #{table_name}.*
    FROM 
      #{table_name}
    WHERE
     #{table_name}.id = ?
    SQL

    parse_all(DBConnection.execute(query, id)).first
  end

  def initialize(params = {})
    params.each do |key, value|
      if self.class.columns.include?(key.to_sym)
        self.send("#{key}=", value)
      else
        raise "unknown attribute '#{key}'"  
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|key| self.send(key)}
  end

  def insert

    col_names = self.class.columns.map(&:to_s).join(', ')
    questions_marks = (["?"] * self.class.columns.count).join(', ')
    query = <<-SQL
      INSERT INTO
        #{ self.class.table_name } (#{ col_names })
      VALUES 
        (#{ questions_marks })
      SQL

    DBConnection.execute(query, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns.map {|el| "#{el} = ?"}.join(', ')

    query = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
      SQL

      DBConnection.execute(query, *attribute_values, self.id)
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end



