class Column
  
  attr_accessor :name, :subcolumns, :limit, :description
  
  def initialize
    @subcolumns = Array.new
    @items = Array.new
    @description = ""
  end

  def parse line
    if line =~ /^(.*) \((.*)\)$/
      @name = $1
      @limit = $2.to_i
    else
      @name = line
      @limit = 0
    end
  end

  def add_subcolumn name
    @subcolumns.push name
  end
  
  def has_subcolumns?
    !@subcolumns.empty?
  end

  def add_item item
    @items.push item
  end
  
  def items subcolumn=nil
    if subcolumn.nil?
      return @items
    else
      items = Array.new
      @items.each do |item|
        if item.subcolumn == subcolumn
          items.push item
        end
      end
      return items
    end
  end
  
  def add_description text
    if @description.empty?
      @description = text
    else
      @description += " " + text
    end
  end
end
