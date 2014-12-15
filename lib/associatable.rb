require_relative 'searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :class_name,
    :foreign_key,
    :primary_key
  )

  def model_class
    @class_name.constantize 
    #self.send(class_name).constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
       defaults = {
      :class_name => name.to_s.camelcase,
      :foreign_key => "#{name}_id".to_sym,
      :primary_key => :id
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      :class_name => name.to_s.singularize.camelcase,
      :foreign_key => "#{self_class_name.underscore}_id".to_sym,
      :primary_key => :id
    }

    defaults.each_key do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

module Associatable
  #Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => key_val).first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => key_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end

  def has_one_through(name, through_name, source_name)

    define_method(name) do

      through_options = self.class.assoc_options[through_name]
      source_options =  through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_primary_key = through_options.primary_key
      through_foreign_key = through_options.foreign_key

      source_table = source_options.table_name
      source_primary_key = source_options.primary_key
      source_foreign_key = source_options.foreign_key
      key_value = self.send(through_foreign_key)
      query = <<-SQL
        SELECT
          #{source_table}.*
        From
          #{through_table}
         JOIN
          #{source_table}
         ON
          #{through_table}.#{source_foreign_key} = #{source_table}.#{source_primary_key}
         WHERE
          #{through_table}.#{through_primary_key} = ?
      SQL

      result = DBConnection.execute(query, key_value)
      source_options.model_class.parse_all(result).first
    end
  end
end

class SQLObject
  extend Associatable
end
