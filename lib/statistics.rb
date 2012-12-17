class Statistics

  def write_data board, output_dir
    file_name = output_dir + "/history.data"

    data = ""
    if File.exists? file_name   
      data = File.read file_name
    end

    data += Time.now.strftime( "%Y%m%dT%H%M" )
    
    board.columns.each do |column|
      data += ",\"#{column.name}\":#{column.items.count}/#{column.limit}"
    end
    
    File.open file_name, "w" do |file|
      file.puts data
    end
  end

end
