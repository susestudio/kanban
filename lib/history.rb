class History

  def initialize
    @data = Hash.new
  end
  
  def read_data file_name
    if !File.exists? file_name
      STDERR.puts "Unable to open file '#{file_name}'"
    else
      File.read( file_name ).each_line do |line|
        fields = line.split ","

        date = DateTime.parse fields[0]

        (1..fields.size-1).each do |i|
          fields[i] =~ /"(.*)":(\d+)\/(\d+)/
          column = $1
          actual = $2
          limit = $3

          if !@data.has_key? column
            @data[ column ] = Graph.new
          end

          graph = @data[column]

          graph.push1 date, actual
          graph.push2 date, limit
        end
      end
    end
  end

  def graph column
    @data[ column ]
  end

  def columns
    @data.keys
  end
  
end
