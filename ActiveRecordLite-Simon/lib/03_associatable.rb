require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    (class_name+"s").downcase.underscore
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
       foreign_key: (name.to_s+"_id").to_sym,
       primary_key: :id,
       class_name: name.to_s.camelcase
    }
    options = defaults.merge(options)
    @method_name = name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: self_class_name[0..-1].underscore.concat("_id").to_sym,
      primary_key: :id,
      class_name: name[0...-1].camelcase
    }

    options = defaults.merge(options)
    @method_name = name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]

  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options = {})
    define_method(name) do
      fk = options.send(:foreign_key)
      model_class.where(self.primary_key => fk).first
    end
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
