require 'curses'

def curses_init
  Curses.noecho
  Curses.init_screen
  Curses.stdscr.keypad(true)
  Curses.cbreak 
  Curses.timeout = 80
  begin 
    yield
  ensure
    Curses.close_screen
  end
end

def text(line, column, text)
  Curses.setpos(line, column)
  Curses.addstr(text);
end

class World
  attr_accessor :defen, :blist, :plist, :pilist, :ilist, :dir, :gameover
  
  def initialize(gs = false)
    @blist = (0...5).map { |i| Block.new((i * 15) + 3)}
    @plist = []
    @pilist = []
    @ilist = (0...5).map { |n| 
           (0...(6 + (n%2))).map { |i| Invader.new(n * 3, 10 + i * 10 +( -5 * (n % 2)) )}
         }.flatten
    @defen = Defender.new(35)
    @dir = :right
    @gameover = gs
    draw
  end

  def update    
    @plist.reject!{|pr| pr.done}
    @pilist.reject!{|pr| pr.done}
    @ilist.reject!{|il| il.done}

    hivemind
    @plist.each { |pr| 
      pr.update 
      check_collision(pr) 
      } 

    @pilist.each { |pr| 
      pr.update 
      check_collision(pr, :inv) 
      } 
    ##@ilist.each { |inv| 
    ##  check_collision(inv) 
    ##  } 
    @plist.reject!{|pr| pr.done}
    @pilist.reject!{|pr| pr.done}

    @ilist.reject!{|il| il.done}
    draw
  end
  
  def hivemind 
    x = 0
    y = 0
    
    inpos = @ilist.map(&:xpos)
    
    if inpos.max && !gameover
      case @dir 
        when :right ##nach rechts
          inpos.max < 70 ? x = 1 : @dir = :left
        when :left ##nach links
          inpos.min > 0 ? x = -1 : @dir = :down
        when :down ##nach unten
          y = 1
          @dir = :right
      end
      @ilist.each { |i| 
	                i.move(x,y) 
	                rand(100) == 2 && pilist.size < 18 ? 
					  pilist << Projectile.new(i.xpos + 1, i.ypos + 1, 1, :inv) : nil 
				  } 
    else 
      @gameover = true
    end
	
    @ilist.map(&:ypos).max == 28 ? @gameover = true : nil
	
  end
  
  def draw
    Curses.clear
    blist.each { |bl| bl.draw } 
    plist.each { |pr| pr.draw } 
    pilist.each { |pr| pr.draw } 
    ilist.each { |i| i.draw } 
    defen.draw
  end
  
  def move(x)
    defen.move(x)
    update
  end
  
  def fire
    plist.size < 4 ? plist << Projectile.new(defen.xpos + 1, 29, -1) : nil
    update
  end
  
  def check_collision(object, kill = :all)
    x = object.xpos
    y = object.ypos
	
	if defen.hit(x, y)
	  @gameover = true
	  return
    end
	
    (@blist + (kill == :all ? @ilist : [])).each do |bl| 
      if bl.hit(x, y)
        object.done = true
        return
      end
    end
  end
  
end

class Defender
  attr_accessor :xpos, :ypos
    
  def initialize(xpos)
    @xpos = xpos
    @ypos = 30
	@done = false
  end
  
  def move(x)
    @xpos = [0, @xpos + x, 70].sort[1]
  end
  
  def draw
    text(@ypos, @xpos, "lol")
  end
  
  def hit(x, y)
    difx = x - @xpos;
    dify = y - @ypos
    
    if (0..3).member?(difx) && dify == 0
	  return true
	end
  end

end

class Invader
  attr_accessor :sp, :ypos, :xpos, :done
  
  def initialize(ypos, xpos)
    @sp =  [
	        " .. ",
            "/[]\\"
           ]
        
    @ypos = ypos
    @xpos = xpos
    @done = false
  end
  
  def move(x,y)
    @ypos += y
    @xpos += x
  end
    
  def draw
    if !@done
      @sp.each_with_index do |chars, x| 
        text(@ypos + x, @xpos, chars)
      end
    end
  end

  def hit(x, y)
    difx = x - @xpos;
    dify = y - @ypos
    
    if difx >= 0 && difx < 3  && dify >= 0 && dify < 2
      @done = true
    else false
    end
  end
end

class Block
  attr_accessor :bb, :lb, :xpos, :ypos
       
  def initialize(xpos)
    @xpos = xpos
    @ypos = 24
    
    @bb = ["@@@@@@@", 
           "@Block@",
           "@@@@@@@"]
  end
  
  def draw
    @bb.each_with_index do |chars, x| 
      text(@ypos + x, @xpos, chars)
    end
  end
  
  def hit(x, y)
    difx = x - @xpos;
    dify = y - @ypos
    if difx >= 0 && difx < 7  && dify >= 0 && dify < 3 && @bb[dify][difx] != 32
      @bb[dify][difx] = " "
      true
    else false
    end
  end
end

class Projectile
  attr_accessor :xpos, :ypos, :done, :dir, :type
  
  def initialize(xpos, ypos, dir, type = :dev)
    @xpos = xpos
    @ypos = ypos
    @dir = dir
    @done = false
	@type = type
  end
  
  def update
    @ypos += @dir
  end
  
  def draw 
    if !done && (@ypos >= 0 && @ypos <= 30 ) 
      text(@ypos, @xpos, @type == :dev ? ":" : "|")
    else 
      @done = true
    end
  end
end

GAME_OVER = [
            "|-------------------------------------|",
            "|                                     |",
            "|    GAME OVER                        |",
            "|                                     |",
            "|                                     |",
            "|                                     |",
            "| Press [BACKSPACE] to start!         |",
            "|                                     |",
            "| MOVE Left and Right with Arrow-Keys |",
            "|                                     |",
            "| Fire with UP-Arrow                  |",
            "|                                     |",
            "|-------------------------------------|",
           ]


curses_init do 
  
  wor = World.new(true)
  
  loop do
    if wor.gameover
      GAME_OVER.each_with_index do |s, i|
        text(8 + i, 8, s)
      end
      if Curses.getch == Curses::Key::BACKSPACE
        wor = World.new
	  end
    else 
      case Curses.getch
      when Curses::Key::RIGHT 
        wor.move(1)
      when Curses::Key::LEFT 
        wor.move(-1) 
      when Curses::Key::UP 
        wor.fire
	  else 
	    wor.update
      end
    end 

  end
end