class Graph

  attr_reader :data1, :data2
  
  def initialize
    @data1 = Array.new
    @data2 = Array.new
  end
  
  def push1 date, value
    @data1.push [ date.strftime( "%Q" ), value ]
  end

  def push2 date, value
    @data2.push [ date.strftime( "%Q" ), value ]
  end

end
