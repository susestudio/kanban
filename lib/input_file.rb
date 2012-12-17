class InputFile

  def self.default_file
    File.expand_path("../../data.txt",__FILE__)
  end

  def self.parse_file input_file
    begin
      parse_text File.read input_file
    rescue ParseError => e
      STDERR.puts e
    end
  end
  
  def self.parse_text text
    board = Board.new
    column = nil
    subcolumn = nil

    line_number = 1
    text.each_line do |line|
      if line =~ /^# (.*)/
        title = $1
        
        board.title = title
      elsif line =~ /^## (.*)/
        column_line = $1

        subcolumn = nil
        
        column = Column.new
        column.parse column_line
        
        board.add_column column
      elsif line =~ /^### (.*)/
        subcolumn = $1

        column.add_subcolumn subcolumn
      elsif line =~ /^\* (.*)/
        item_line = $1
        
        item = Item.new
        begin
          item.parse item_line
        rescue StandardError => e
          raise ParseError.new( "Line #{line_number}: #{e}" )
        end
        
        item.subcolumn = subcolumn
        
        board.add_item item, column
      elsif line =~ /^(\w.*)$/
        if column
          column.add_description $1
        else
          STDERR.puts "Text outside of section not allowed. Line #{line_number}"
        end
      else
        if line !~ /^\s*$/
          STDERR.puts "Unable to parse line #{line_number}: #{line}"
        end
      end
      line_number += 1
    end

    # Mark old done items as hidden, so they only show up on the all done list, not
    # on the board
    board.items.each do |item|
      if item.done && item.done < Date.today - 7
        item.hidden = true
      end
    end

    board
  end

  def self.create_new_item string, input_file
    output = ""
    File.open input_file do |file|
      in_column = false
      file.each_line do |line|
        if in_column && !line.strip.empty?
          output += parse_new_item( string ) + "\n"
          in_column = false
        end
        if line =~ /^## In/
          in_column = true
        end

        output += line
      end
    end

    File.open input_file, "w" do |file|
      file.print output
    end
  end

  def self.parse_new_item string
    parameters = Array.new
    if string =~ /#e/
      parameters.push "#emergency"
      string.gsub! /#e/,""
    elsif string =~ /#b/
      parameters.push "#bug"
      string.gsub! /#b/,""
    elsif string =~ /#f/
      parameters.push "#feature"
      string.gsub! /#f/,""
    elsif string =~ /#m/
      parameters.push "#maintenance"
      string.gsub! /#m/,""
    elsif string =~ /@(.*)/
      parameters.push "@#{$1}"
      string.gsub! /@(.*)/,""
    end
    
    parameters.push "in:#{Date.today}"

    "* #{string} (#{parameters.join(",")})".squeeze(" ")
  end
  
end
