require File.expand_path('../test_helper', __FILE__)

class InputFileTest < Test::Unit::TestCase

  def test_parse_new_item
    pairs = [
      [ "Eins zwei", "Eins zwei (in:#{Date.today})" ],
      [ "Drei #b", "Drei (#bug,in:#{Date.today})" ],
      [ "Drei #e", "Drei (#emergency,in:#{Date.today})" ],
      [ "Drei #f", "Drei (#feature,in:#{Date.today})" ],
      [ "Drei #m", "Drei (#maintenance,in:#{Date.today})" ],
      [ "Drei vier @hwurst", "Drei vier (@hwurst,in:#{Date.today})" ],
    ]
    pairs.each do |pair|
      assert_equal "* #{pair[1]}", InputFile.parse_new_item( pair[0] )
    end
  end

  def test_parse_file
    
    text=<<EOF
# Title of board

## Column One

Description of first column
in two lines
    
* Item 1 (#tag,blocked:external,in:2011-11-09)
* Item 3 (#tag,bnc#456,in:2011-11-09)
* Item 4 (#tag,github#jippie,in:2011-11-08)
* Item 5 (#tag,bnc#111,bnc#222,in:2011-11-08)
          
## Column Two

* Item 3 (#tag,in:2011-11-09)
EOF
    board = InputFile.parse_text text

    assert_equal 5, board.items.count
    assert_equal "Column Two", board.columns[1].name
    assert_equal "Description of first column in two lines",
      board.columns[0].description
    assert_equal [ [ :bnc, "456"] ], board.columns[0].items[1].references
    assert_equal [ [ :github, "jippie" ] ], board.columns[0].items[2].references
    assert_equal "external", board.columns[0].items[0].blocked
    assert_equal [ [ :bnc, "111" ], [ :bnc, "222" ] ], board.columns[0].items[3].references
         
  end

  def test_parse_file_error
    text=<<EOF
# Title of board

## Column One

* Item without attributes
EOF

    assert_raise ParseError do
      board = InputFile.parse_text text
    end

  end
  
  def test_effective_tags
    item = Item.new
    item.add_tag "bug"
    item.add_tag "hello"

    assert_equal [ "hello" ], item.effective_tags
  end
         
end
