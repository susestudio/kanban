class Board

  attr_accessor :title,:columns,:items,:lanes

  def initialize
    @columns = Array.new
    @items = Array.new

    @lanes = Array.new
    @lanes.push Lane.new( "emergency", "Emergencies", 10 )
    @lanes.push Lane.new( "bug", "Bugs", 30 )
    @lanes.push Lane.new( "feature", "Features", 30 )
    @lanes.push Lane.new( "maintenance", "Code and system maintenance", 30 )
  end

  def add_column column
    @columns.push column
  end

  def has_subcolumns?
    @columns.each do |column|
      return true if column.has_subcolumns?
    end
    return false
  end
  
  def add_item item, column
    column.add_item item
    @items.push item
  end
  
  def check_lanes
    @items.each do |item|
      has_lane = false
      @lanes.each do |lane|
        if item.tags.include? lane.key
          has_lane = true
        end
      end
      if !has_lane
        STDERR.puts "Item '#{item}' is missing a lane tag."
      end
    end
  end

  def frequency
    frequencies = Hash.new
    @items.each do |item|
      next unless item.done
      if frequencies.has_key? item.done
        frequencies[ item.done ] = frequencies[ item.done ] + 1
      else
        frequencies[ item.done ] = 1
      end
    end

    data = Array.new
    frequencies.keys.sort.each do |date|
      data.push [ date.strftime( "%Q" ), frequencies[date] ]
    end
    data
  end

  def leadtimes
    leadtimes = Hash.new
    @items.each do |item|
      next unless item.done
      if leadtimes.has_key? item.done
        leadtimes[ item.done ].push item.lead_time
      else
        leadtimes[ item.done ] = [ item.lead_time ]
      end
    end

    data = Array.new
    leadtimes.keys.sort.each do |date|
      data.push [ date.strftime( "%Q" ), average(leadtimes[date]) ]
    end
    data
  end

  def average a
    a.inject{ |sum, el| sum + el }.to_f / a.size
  end

end
