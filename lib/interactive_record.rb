require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name
    self.name.downcase.pluralize
  end
  
  def self.column_names
    sql = "pragma table_info('#{self.table_name}')"
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names
  end

  def initialize(hash={})
    hash.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names[1..-1].join(", ")
  end
  
  def values_for_insert
    values = []
    self.class.column_names[1..-1].each do |c_name|
      values << "'#{self.send(c_name)}'" unless send(c_name).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{self.values_for_insert});
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

  def self.find_by_name(search_name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = ?
    SQL
    DB[:conn].execute(sql, search_name)
  end

  def self.find_by(attr_hash)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{attr_hash.keys.join} = #{attr_hash.values.join}
    SQL
    # binding.pry

    result = DB[:conn].execute(sql)
    result
  end
end