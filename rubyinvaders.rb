require 'curses'

def curses_init
	Curses.noecho
	Curses.init_screen
	Curses.stdscr.keypad(true)
	Curses.cbreak 
	Curses.timeout=1
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
	attr_accessor :defen, :blist, :plist, :ilist, :dir, :gameover
	
	def initialize()
		@blist = (0...5).collect { |i| Block.new((i * 15) + 3)}
		@plist = []
		@ilist = (0...5).collect { |n| 
				 	(0...(6 + (n%2))).collect { |i| Invader.new(n * 3, 10 + i * 10 +( -5 * (n%2)) )}
				 }.flatten
		@defen = Defender.new(35)
		@dir = 0
		@gameover = false
		draw
	end
	
	def update		
		@plist.reject!{|pr| pr.done}
		@ilist.reject!{|il| il.done}

		hivemind
		@plist.each { |pr| 
			pr.update 
			check_collision(pr) 
			} 
		##@ilist.each { |inv| 
		##	check_collision(inv) 
		##	} 
		@plist.reject!{|pr| pr.done}
		@ilist.reject!{|il| il.done}
		draw
	end
	
	def hivemind 
		x = 0
		y = 0
		
		inpos = @ilist.collect { |i| i.xpos }
		
		if(inpos.max && !gameover)
			case @dir 
				when 0 ##nach rechts
					inpos.max < 70 ? x = 1 : @dir = 1
				when 1 ##nach links
					inpos.min > 0 ? x = -1 : @dir = 2
				when 2 ##nach unten
					y = 1
					@dir = 0
			end
			@ilist.each { |i| i.move(x,y) } 
		else 
			@gameover = true
		end
	end
	
	def draw
		Curses.clear
		blist.each { |bl| bl.draw } 
		plist.each { |pr| pr.draw } 
		ilist.each { |i| i.draw } 
		defen.draw
	end
	
	def move(x)
		defen.move(x)
		update
	end
	
	def fire
		plist.push(Projectile.new(defen.xpos + 1, 29, -1))
		update
	end
	
	def check_collision(object)
		x = object.xpos
		y = object.ypos
		@blist.each do |bl| 
			if bl.hit(x, y)
				object.done = true
				return
			end
		end
		@ilist.flatten.each do |inv| 
			if inv.hit(x, y)
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
	end
	
	def move(x)
		@xpos = ([0,@xpos + x,70].sort)[1]
	end
	
	def draw
		text(@ypos, @xpos, "lol")
	end
end

class Invader
	attr_accessor :sp, :ypos, :xpos, :done
	
	def initialize(ypos, xpos)
		@sp =  [" .. ",
				"/[]\\"]
				
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
			@sp.inject(1) do |x, chars| 
				text(@ypos + x, @xpos, chars)
				x+=1
			end
		end
	end

	def hit(x, y)
		difx = x - @xpos;
		dify = y - @ypos
		
		if( difx >= 0 && difx < 3  && dify >= 0 && dify < 2)
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
		@bb.inject(1) do |x, chars| 
			text(@ypos + x, @xpos, chars)
			x+=1
		end
	end
	
	def hit(x, y)
		difx = x - @xpos;
		dify = y - @ypos
		if( difx >= 0 && difx < 7  && dify >= 0 && dify < 3 && @bb[dify][difx] != 32)
			@bb[dify][difx] = " "
			true
		else false
		end
	end
end

class Projectile
	attr_accessor :xpos, :ypos, :done, :dir
	
	def initialize(xpos, ypos, dir)
		@xpos = xpos
		@ypos = ypos
		@dir = dir
		@done = false
	end
	
	def update
		@ypos += @dir
	end
	
	def draw 
		if !done and ((@ypos) >= 0) 
			text(@ypos, @xpos, ":")
		else 
			@done = true
		end
	end
end


curses_init do 
			
		wor = World.new
		wor.gameover = true
	loop do
		if(!wor.gameover)
			key = Curses.getch
			case key
			when Curses::Key::RIGHT 
				wor.move(1)
			when Curses::Key::LEFT 
				wor.move(-1) 
			when 32, Curses::Key::UP 
				wor.fire
			end
		else 
			text( 8, 8,  "|-------------------------------------|")			
			text( 9, 8,  "|                                     | ")			
			text( 10, 8, "|    GAME OVER                        |")
			text( 11, 8, "|                                     |")
			text( 12, 8, "|                                     |")
			text( 13, 8, "|                                     |")
			text( 14, 8, "| Press ANYKEY to start!              |")
			text( 15, 8, "|                                     |")
			text( 16, 8, "| MOVE Left and Right with Arrow-Keys |")
			text( 17, 8, "|                                     |")
			text( 18, 8, "| Fire with Space                     |")
			text( 19, 8, "|                                     |")
			text( 20, 8, "|-------------------------------------|")
			
			key = Curses.getch
			
			if(key != 4294967295) 
				wor = World.new
			end
		end 

  end
end