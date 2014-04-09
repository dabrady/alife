# Food.rb
# 
# Daniel Brady, Spring 2014
# 
# This class defines a Food, eaten by Agents in A-Life. Foods are essentially
# glorified points: they have a value, a position and a sprite.

["ZOrder",
 "Params",
 "Goal"].each {|file| require_relative file}
require 'gosu'

class Food; include Goal
	attr_reader :x, :y, :value

	def initialize(window)
		# The food sprite.
		@sprite = Gosu::Image.new(window, "food.bmp", false)
		# Initialize to random position bounded by the window.
		@x = rand(0.5*@sprite.width..Params::WINDOW_WIDTH-0.5*@sprite.width)
		@y = rand(0.5*@sprite.height..Params::WINDOW_HEIGHT-0.5*@sprite.height)
		# The value of this food.
		@value = 1
	end

	def draw()
		@sprite.draw(@x, @y, ZOrder::Food, Params::FOOD_SCALE, Params::FOOD_SCALE)
	end
end