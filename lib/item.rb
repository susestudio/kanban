class Item

  attr_accessor :name, :subcolumn, :tags, :persons, :in, :done, :trashed,
    :hidden, :blocked, :references
  
  def initialize
    @tags = Array.new
    @persons = Array.new
    @hidden_tags = [ "emergency", "bug", "feature", "maintenance" ]
    @references = Array.new
  end

  def to_s
    name
  end

  def lead_time
    (@done - @in)
  end
  
  def due
    if @due
      @due.strftime "%Y-%m-%d"
    else
      ""
    end
  end

  def parse line
    line =~ /(.*)\((.*)\)/
    name = $1
    arg_string = $2

    @name = name.strip

    args = arg_string.split(",")
    args.each do |arg|
      arg.strip!
      if arg =~ /^#(.*)/
        add_tag $1
      elsif arg =~ /^(.+)#(.*)/
        add_reference $1, $2
      elsif arg =~ /^@(.*)/
        add_person $1
      elsif arg =~ /^blocked:(.*)/
        @blocked = $1
      elsif arg =~ /^in:(.*)/
        @in = Date.parse $1
      elsif arg =~ /^done:(.*)/
        @done = Date.parse $1
      elsif arg =~ /^due:(.*)/
        @due = Date.parse $1        
      elsif arg =~ /^trashed:(.*)/
        @trashed = Date.parse $1        
      else
        STDERR.puts "Unrecognized parameter: #{arg}"
      end
    end
    
    if !@in
      raise "Item is missin in: attribute"
    end
  end

  def add_tag tag
    @tags.push tag
  end
  
  def add_person person
    @persons.push person
  end

  def add_reference key, id
    @references.push [ key.to_sym, id ]
  end

  def formatted_ids
    @references.map do |r|
      formatted_id r[0], r[1]
    end
  end
  
  def formatted_id key, id
    prefix = ""
    prefix = "#{key}:" unless key == :bnc
    begin
      "#{prefix}<a target='_blank' href='#{reference_url(key,id)}'>#{id}</a>"
    rescue => e
      STDERR.puts "Warning: #{e}"
      "#{key}:#{id}"
    end
  end
  
  def reference_url key, id
    case key
    when :bnc
      return "https://bugzilla.novell.com/show_bug.cgi?id=#{id}"
    when :github
      return "https://github.com/#{id}/issues/milestones"
    else
      raise "Unknown reference key: #{key}"
    end
  end
  
  
  def effective_tags
    @tags.select { |tag| !@hidden_tags.include? tag }
  end
  
end
