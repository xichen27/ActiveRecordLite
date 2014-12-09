class AttrAccessorObject
  def self.my_attr_accessor(*names)
    self.my_attr_writer(*names)
    self.my_attr_reader(*names)
  end

  def self.my_attr_reader(*names)
  	names.each do |name|
  		define_method "#{name}" do
  			instance_variable_get("@#{name}".to_sym)
  		end
  	end 
  end

  def self.my_attr_writer(*names)
  	names.each do |name|
  		define_method "#{name}=" do |stuff|
  			instance_variable_set("@#{name}".to_sym, stuff)
  		end
  	end
  end
end
