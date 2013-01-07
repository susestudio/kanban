class Output

  attr_accessor :board, :compact_lanes, :has_lanes, :extra_css, :plain_table
  
  def initialize board
    @board = board
    @compact_lanes = false
    @has_lanes = true
  end

  def create output_dir
    @output_dir = output_dir
    
    if !File.exists? output_dir
      Dir::mkdir output_dir
    end

    public_dir = File.expand_path( "public", output_dir )
    if !File.exists? public_dir
      Dir::mkdir public_dir
    end
    public_source_dir = File.expand_path("../../view/public", __FILE__)
    cmd = "cp #{public_source_dir}/* #{public_dir}"
    system cmd
    
    create_file output_dir + "/index.html"
    create_file output_dir + "/done.html"
    create_file output_dir + "/people.html"
    create_file output_dir + "/history.html"
    create_file output_dir + "/leadtimes.html"
  end

  def create_file filename
    template_name = "../../view/" + File.basename( filename, ".*" ) + ".haml"
    template = File.read File.expand_path(template_name, __FILE__)
    engine = Haml::Engine.new template

    File.open filename, "w" do |file|
      file.puts engine.render( binding )
    end
  end
  
  def css
    css_out = File.read File.expand_path("../../view/board.css",__FILE__)
    if @extra_css
      css_out << File.read( @extra_css )
    end
    css_out
  end

  def render_navigation
    @out = ""

    o "<ul>"
    o "<li><a href='index.html'>Board</a></li>"
    o "<li><a href='https://github.com/susestudio/kanban/edit/master/data.txt'>Edit on GitHub</a></li>"
    o "<li><a href='done.html'>All done tasks</a></li>"
    o "<li><a href='history.html'>History</a></li>"
    o "<li><a href='leadtimes.html'>Lead times</a></li>"
    o "<li><a href='people.html'>Who does what?</a></li>"
    o "</ul>"
    
    @out
  end

  def render_history
    @out = ""

    history = History.new

    history.read_data "#{@output_dir}/history.data"

    i = 0
    history.columns.each do |column|
      on "<h2>#{column}</h2>"
      on "<div id='graph#{i}' style='width:800px;height:300px;'></div>"
      i += 1
    end

    on "<script type='text/javascript'>"
    on "  $(function () {"

    i = 0
    history.columns.each do |column|
      on "    var d#{i} = #{history.graph(column).data1.inspect};"
      on "    var l#{i} = #{history.graph(column).data2.inspect};"
      on "    $.plot($('#graph#{i}'), [ d#{i}, l#{i} ], { xaxis: { mode: 'time' } } );"
      i += 1
    end

    on "  });"
    on "</script>"
  end

  def render_leadtimes
    @out = ""

    on "<h2>Lead times</h2>"
    on "<div id='graph2' style='width:800px;height:300px;'></div>"

    on "<h2>Number of done items</h2>"
    on "<div id='graph1' style='width:800px;height:300px;'></div>"

    on "<script type='text/javascript'>"
    on "  $(function () {"

    on "    var d1 = #{board.frequency.inspect};"
    on "    $.plot($('#graph1'), [ d1 ], {"
    on "      xaxis: { mode: 'time' },"
    on "      series: {"
    on "        lines: { show: false },"
    on "        points: { show: true }"
    on "      }"
    on "    } );"

    on "    var d2 = #{board.leadtimes.inspect};"
    on "    $.plot($('#graph2'), [ d2 ], {"
    on "      xaxis: { mode: 'time' },"
    on "      series: {"
    on "        lines: { show: false },"
    on "        points: { show: true }"
    on "      }"
    on "    } );"

    on "  });"
    on "</script>"
  end
  
  def render_done
    @out = ""

    items = Array.new

    board.items.each do |item|
      if item.done
        items.push item
      end
    end

    items.sort! { |a,b| b.done <=> a.done }
    items.each do |item|
      render_item item, :show_done_date => true
    end
    
    @out
  end

  def render_trashed
    @out = ""

    board.items.each do |item|
      if item.trashed
        render_item item
      end
    end

    @out
  end
 
  def render_people
    @out = ""
    
    people = Hash.new
    board.items.each do |item|
      item.persons.sort.each do |person|
        if !people.has_key? person
          people[person] = Array.new
        end
        people[person].push item
      end
    end
    
    people.sort.each do |person,items|
      o "<h3>#{person}</h3>"
      items.each do |item|
        render_item item
      end
    end

    @out
  end
  
  def render_board
    @out = ""

    o "<table border='1'>\n"
  
    render_column_headers
    render_column_limits
    render_subcolumn_headers

    if @compact_lanes || !@has_lanes
      o "<tr>\n"
      board.columns.each do |column|
        render_column column
      end
      o "</tr>\n"
    else
      board.lanes.each do |lane|
        render_lane lane
      end
    end

    if !@plain_table
      render_subcolumn_headers
      render_column_limits
      render_column_headers "-bottom"
    end

    o "</table>\n"
    
    @out
  end

  def render_column_headers( title_qualifier = "" )
    o "<tr>\n"
    @board.columns.each do |column|
      o "  <th class='title#{title_qualifier}'"
      if column.has_subcolumns?
        o " class='has-subcolumns' colspan='#{column.subcolumns.count}'"
      end
      o "><div>"
      if !column.description.empty?
        o "<span class='help' title='#{column.description}'>#{column.name}</span>"
      else
        o "#{column.name}"
      end
      o "</div>"
      o "</th>\n"
    end
    o "</tr>\n"
  end
  
  def render_column_limits
    o "<tr>\n"
    @board.columns.each do |column|
      o "  <th class='sub-title'"
      if column.has_subcolumns?
        o " colspan='#{column.subcolumns.count}'"
      end
      o ">"
      if column.limit > 0
        o " <div class='"
        if column.limit < column.items.count
          o "over-limit"
        elsif column.limit == column.items.count
          o "at-limit"
        else
          o "under-limit"
        end
        o "'>(#{column.items.count}/#{column.limit})"
        o "</div>"
      end
      o "</th>\n"
    end
    o "</tr>\n"
  end
  
  def render_subcolumn_headers
    if @board.has_subcolumns?
      o "<tr>\n"
      @board.columns.each do |column|
        if column.has_subcolumns?
          column.subcolumns.each do |subcolumn|
            o "  <th class='sub-title'>#{subcolumn}</th>\n"
          end
        else
          o "  <th class='sub-title'></th>\n"
        end
      end
      o "</tr>\n"
    end
  end
  
  def render_column column
    first = true
    if column.has_subcolumns?
      column.subcolumns.each do |subcolumn|
        o "  <td>\n"
        if @has_lanes
          @board.lanes.each do |lane|
            render_items column, column.items( subcolumn ), lane, first
          end
        else
          render_items column, column.items( subcolumn ), nil, first
        end
        o "  </td>\n"
        first = false
      end
    else
      o "  <td>\n"
      if @has_lanes
        @board.lanes.each do |lane|
          render_items column, column.items, lane, first
        end
      else
        render_items column, column.items, nil, first
      end
      o "  </td>\n"
      first = false
    end
  end

  def render_lane lane
    o "<tr>\n"
    first = true
    @board.columns.each do |column|
      if column.has_subcolumns?
        column.subcolumns.each do |subcolumn|
          o "  <td>\n"
          render_items column, column.items( subcolumn ), lane, first
          o "  </td>\n"
          first = false
        end
      else
        o "  <td>\n"
        render_items column, column.items, lane, first
        o "  </td>\n"
        first = false
      end
    end
    o "</tr>\n"

    o "<tr>\n"
    @board.columns.each do |column|
      o "<td"
      if column.subcolumns.count > 1
        o " colspan='#{column.subcolumns.count}'"
      end
      o ">"
      
      item_count = 0
      column.items.each do |item|
        next if !item.tags.include? lane.key
        next if item.trashed
        item_count += 1
      end

      limit = ""
      limit_class = ""
      if column.limit == 0
        limit = ""
      else
        actual = item_count * 100 / column.limit
        limit = "(#{actual}%/#{lane.limit}%)"
        if actual > lane.limit && item_count > 1
          limit_class = " lane-exceeded"
        end
      end
      o "<div class='lane-limits #{limit_class}'>#{limit}</div>"

      o "</td>"
    end
      
    o "</tr>\n"  
  end

  def render_lane_limits
  end  

  def render_items column, items, lane, first
    if lane && first
      o "    <div class='lane-header'>#{lane.title}</div>"
    end
    items.each do |item|
      next if lane && !item.tags.include?( lane.key )
      next if item.trashed
      if !item.hidden
        o "    "
        render_item item
      end
    end
  end

  def render_item item, options = {}
    o "<div class='item"
    item.effective_tags.each do |tag|
      o " tag_#{tag}"
    end
    o "'>"
    if !item.formatted_ids.empty?
      o "<div class='item_id'>#{item.formatted_ids.join(', ')}</div>"
    end
    o "<div>#{item.name}"
    if item.blocked
      o " <span class='blocked' title='#{item.blocked}'>blocked</span>"
    end
    o "</div>"
    if !item.persons.empty?
      o "<div class='persons'>"
      o "<em>" + item.persons.join( ", " ) + "</em>"
      o "</div>"
    end
    o "<div class='tags'>#{item.effective_tags.join(", ")}</div>"
    o "<div class='date-info'>"
    if item.done
      o item.lead_time
      o " days"
      if options[:show_done_date]
        o " (done on #{item.done})"
      end
    elsif item.trashed
      o "trashed"
    else
      if item.in == Date.today
        o "today"
      elsif item.in == Date.today - 1
        o "yesterday"
      else
        o Date.today - item.in
        o " days ago"
      end
    end
    if !item.due.empty?
      o " due: "
      o item.due
    end
    o "</div>"

    o "</div>\n"
  end

  def img name
    "<img src='public/#{name}.png'/>"
  end
  
  protected
  
  def o txt
    @out += txt.to_s
  end

  def on txt
    o txt + "\n"
  end
  
end
