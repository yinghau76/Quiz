# PC/UVa IDs: 110107/10196

class Chess
  
  @@capture = 
  { 
    'p' => [[-1,  1, 1], [ 1,  1, 1]],
    'P' => [[-1, -1, 1], [ 1, -1, 1]],
    'r' => [[ 1,  0, 8], [-1,  0, 8], [0,  1, 8], [ 1,  0, 8]],
    'b' => [[-1,  1, 8], [ 1,  1, 8], [1, -1, 8], [-1, -1, 8]],
    'n' => [[-2, -1, 1], [-1, -2, 1], [1, -2, 1], [ 2, -1, 1], [2, 1, 1], [1, 2, 1], [-1, -2, 1], [-2, -1, 1]],
    'k' => [[-1,  1, 1], [ 1,  1, 1], [1, -1, 1], [-1, -1, 1], [1, 0, 1], [0, 1, 1], [-1,  0, 1], [ 0, -1, 1]],
    'q' => [[-1,  1, 8], [ 1,  1, 8], [1, -1, 8], [-1, -1, 8], [1, 0, 8], [0, 1, 8], [-1,  0, 8], [ 0, -1, 8]],
  }
  @@capture.each_key {|p| @@capture[p.upcase] = @@capture[p] unless @@capture.has_key?(p.upcase)}

  def initialize(file)
    @board = Array.new(8) { loop { line = file.gets.chomp.strip; break line if line.length >= 8 } }
  end
  
  def is_empty
    @board.select{|row| row == '.' * 8}.length == 8
  end
  
  def in_check
    0.upto(7) do |y|
      0.upto(7) do |x|
        piece = @board[y][x..x]
        if @@capture[piece]:
          cap = check_capture(piece, x, y)
          return cap[0] if cap.length > 0
        end
      end
    end
    "no"
  end
  
  def check_capture(piece, col, row)
    @@capture[piece].collect{|dir| check_dir(piece, col, row, dir)}.compact
  end
  
  def check_dir(piece, x, y, dir)
    dir[2].times do
      x += dir[0]
      y += dir[1]
      break unless (0..7) === x and (0..7) === y
      case @board[y][x..x]
        when 'k'
          return 'black' if ('A'..'Z') === piece
        when 'K'
          return 'white' if ('a'..'z') === piece
        when '.'
          next
        else 
          break
      end
    end
    nil
  end
  
end

fail "No input is given" if ARGV.length < 1

File.open(ARGV[0], "r") do |file|
  i = 1
  loop do
    c = Chess.new(file)
    break if c.is_empty
    print "Game \##{i}: #{c.in_check} king is in check\n"
    i += 1
  end
end