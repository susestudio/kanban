class Lane

  attr_accessor :key, :title, :limit

  def initialize key, title, limit
    @key = key
    @title = title
    @limit = limit
  end
  
end
