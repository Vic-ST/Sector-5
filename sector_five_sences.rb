require 'gosu'
require_relative 'player'
require_relative 'enemy'
require_relative 'bullet'
require_relative 'explosion'
require_relative 'credit'

class SectorFive < Gosu::Window
	WIDTH = 1200
	HEIGHT = 1000
	MAX_ENEMIES = 500
	ENEMY_FREQUENCY = 0.1
	def initialize
		super(WIDTH, HEIGHT)
		self.caption = "Sector Five"
		@background_image = Gosu::Image.new('images/start_screen.png')
		@scene = :start
		@start_music = Gosu::Song.new('sounds/Lost Frontier.ogg')
		@font = Gosu::Font.new(30)
		@font2 = Gosu::Font.new(30)
		@font3 = Gosu::Font.new(30)
		@font4 = Gosu::Font.new(30)
		@start_music.play(true)
	end
	
	def draw
		case @scene
		when :start
			draw_start
		when :game
			draw_game
		when :end
			draw_end
		end
	end
	
	def draw_start
		@background_image.draw(0,0,0)
	end
	
	def draw_game
		@player.draw
		@enemies.each do |enemy|
			enemy.draw
		end
		@bullets.each do |bullet|
			bullet.draw
		end
		@explosions.each do |explosion|
			explosion.draw
		end
		@font.draw("Points: #{@enemies_destroyed.to_s}", 700, 20, 2)
		@font.draw("Enemies Appeared: #{@enemies_appeared.to_s}", 700, 40, 2)
		@font.draw("Ammo: #{@ammo.to_s}", 700, 80, 2)
		@font.draw("Health: #{@health.to_s}", 700, 60, 2)
	end
	
	def update
		case @scene
		when :game
			update_game
		when :end
			update_end
		end
	end
	
	def button_down(id)
		case @scene
		when :start
			button_down_start(id)
		when :game
			button_down_game(id)
		when :end
			button_down_end(id)
		end
	end
	
	def button_down_start(id)
		initialize_game
	end
	
	def initialize_game
		@player = Player.new(self)
		@enemies = []
		@bullets = []
		@explosions = []
		@scene = :game
		@health = 450
		@ammo = 1000
		@enemies_appeared = 0
		@enemies_destroyed = 0
		@game_music = Gosu::Song.new('sounds/Cephalopod.ogg')
		@game_music.play(true)
		@explosion_sound = Gosu::Sample.new('sounds/explosion.ogg')
		@shooting_sound = Gosu::Sample.new('sounds/shoot.ogg')
	end
	
	def update_game
		@player.turn_left if button_down?(Gosu::KbA) # left
		@player.turn_right if button_down?(Gosu::KbD) # right
		@player.accelerate if button_down?(Gosu::KbW) # up
		@player.turn_left if button_down?(Gosu::KbLeft) # left
		@player.turn_right if button_down?(Gosu::KbRight) # right
		@player.accelerate if button_down?(Gosu::KbUp) # up
		@player.move
		if rand < ENEMY_FREQUENCY
			@enemies.push Enemy.new(self)
			@enemies_appeared += 1
		end
		@enemies.each do |enemy|
			enemy.move
		end
		@bullets.each do |bullet|
			bullet.move
		end
		@enemies.dup.each do |enemy|
			@bullets.dup.each do |bullet|
				distance = Gosu.distance(enemy.x, enemy.y, bullet.x, bullet.y)
				if distance < enemy.radius + bullet.radius
					@enemies.delete enemy
					@bullets.delete bullet
					@explosions.push Explosion.new(self, enemy.x, enemy.y)
					@enemies_destroyed += 1
					@explosion_sound.play
				end
			end
		end
		@explosions.dup.each do |explosion|
			@explosions.delete explosion if explosion.finished
		end
		@enemies.dup.each do |enemy|
			if enemy.y > HEIGHT + enemy.radius
				@enemies.delete enemy
				@health -= 1
			end
		end
		@bullets.dup.each do |bullet|
			@bullets.delete bullet unless bullet.onscreen?
		end
		
		initialize_end(:count_reached) if @enemies_appeared > MAX_ENEMIES
		@enemies.each do |enemy|
			distance = Gosu.distance(enemy.x, enemy.y, @player.x, @player.y)
			initialize_end(:hit_by_enemy) if distance < @player.radius + enemy.radius
		end
		initialize_end(:off_top) if @player.y < -@player.radius
		initialize_end(:health_dead) if @health <= 0
	end
	
	def button_down_game(id)
		if id == Gosu::KbSpace
			if @ammo > 0
				@bullets.push Bullet.new(self, @player.x, @player.y, @player.angle)
				@bullets.push Bullet.new(self, @player.x, @player.y, @player.angle + 5)
				@bullets.push Bullet.new(self, @player.x, @player.y, @player.angle + 10)
				@ammo -= 1
				@shooting_sound.play(0.5)
			else
				@ammo = 0
			end
		end
	end
	
	def initialize_end(fate)
		case fate
		when :count_reached
			@message = "You made it! You destroyed #{@enemies_destroyed} ships"
			@message2= "and #{MAX_ENEMIES - @enemies_destroyed} reached the base."
			@message3= "" 
		when :hit_by_enemy
			@message = "You were struck by an enemy ship."
			@message2 = "Before your ship was destroyed, "
			@message2 += " you took out #{@enemies_destroyed} enemy ships."
			@message3 = "If you had taken out #{MAX_ENEMIES - @enemies_appeared.to_i} more ships, you would have won."
		when :off_top
			@message = "You got too close to the enemy mother ship."
			@message2 = "Before your ship was destroyed, "
			@message2 += " you took out #{@enemies_destroyed} enemy ships."
			@message3 = "If you had taken out #{MAX_ENEMIES - @enemies_appeared.to_i} more ships, you would have won."
		when :health_dead
			@message = "To many ships reached the bottom"
			@message2= "Before you died,"
			@message2 += " you took out #{@enemies_destroyed} enemy ships."
			@message3 = "If you had taken out #{MAX_ENEMIES - @enemies_appeared.to_i} more ships, you would have won."
		end
		@bottom_message = "Press P to play again, or Q to quit."
		@message_font = Gosu::Font.new(28)
		@credits = []
		y = 700
		@ammo = 900
		File.open('credit.txt').each do |line|
			@credits.push(Credit.new(self,line.chomp,100,y))
			y+=30
		end
		@scene = :end
		@end_music = Gosu::Song.new('sounds/FromHere.ogg')
		@end_music.play(true)
	end
	
	def draw_end
		clip_to(50,140,700,360) do
			@credits.each do |credit|
				credit.draw
			end
		end
		draw_line(0,140,Gosu::Color::RED,WIDTH,140,Gosu::Color::RED)
		@message_font.draw(@message,40,40,1,1,1,Gosu::Color::FUCHSIA)
		@message_font.draw(@message2,40,75,1,1,1,Gosu::Color::FUCHSIA)
		@message_font.draw(@message3,40,110,1,1,1,Gosu::Color::FUCHSIA)
		draw_line(0,500,Gosu::Color::RED,WIDTH,500,Gosu::Color::RED)
		@message_font.draw(@bottom_message,180,540,1,1,1,Gosu::Color::AQUA)
	end
	
	def update_end
		@credits.each do |credit|
			credit.move
		end
		if @credits.last.y < 150
			@credits.each do |credit|
				credit.reset
			end
		end
	end
	
	def button_down_end(id)
		if id == Gosu::KbP
			initialize_game
		elsif id == Gosu::KbQ
			close
		end
	end
end

window = SectorFive.new
window.show
