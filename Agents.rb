# Agents.rb
# 
# Daniel Brady, Spring 2014
# 
# This class defines all of the various Agents of the world.

require 'gosu'
["NeuralNets",
 "Params",
 "ZOrder"].each {|file| require_relative file}

module Agency
    # Updates the agent's brain with info from the environment and returns
    # true if update is successful, false otherwise.
    # An update will be unsuccessful in the event that an agent's brain
    # outputs less than the required number of outputs (which only happens
    # when given an incorrect number of inputs)
    # Default implementation ignores its environment and merely turns randomly.
 	def respond_to(env)
 		turn rand(-Params::MAX_TURN_ANGLE..Params::MAX_TURN_ANGLE)
 		move @speed
 	end

 	# Render's the agent to the window.
 	# Including classes need to have these instance variables to be drawn:
 	# @position = {:x => _, :y => _}
 	# @scale = some number
 	# @angle = some number in radians
    # @color = some Gosu::Color object
 	def draw()
        @sprite.draw_rot(@position[:x],
                         @position[:y],
                         ZOrder::Agent,
                         Params::rad_to_degrees(@angle),
                         0.5, 0.5,
                         @scale, @scale,
                         @color)
 	end

    # Used to turn the agent (update its angle and heading).
 	def turn(this_much)
        @angle += this_much
        calculate_heading
    end

    # Used to convert this agent's current angle into a direction vector.
    def calculate_heading()
        @heading = {:x => Math.cos(@angle), :y => Math.sin(@angle)}
    end

    # Move the agent.
    # Including classes need to have a @position and an @angle to be moved.
 	def move(this_fast=Params::MAX_SPEED)
 		# Update position by applying acceleration in a specific direction.
        @position[:x] += Gosu::offset_x(Params::rad_to_degrees(@angle),
                                        this_fast)
        @position[:y] += Gosu::offset_y(Params::rad_to_degrees(@angle),
                                        this_fast)
        # Ensure our position is bounded by the window dimensions.
        @position[:x] %= Params::WINDOW_WIDTH
        @position[:y] %= Params::WINDOW_HEIGHT
 	end

    # Parses the environment based on the agent's sensory organs.
    # The default implementation is omnipotent, and so the original environment
    # is returned.
    def parse(env); env; end

    # Checks agent's position to see if a goal has been reached.
    # Returns the closest goal within reach or else nil.
 	def try_for_goal(env)
        # Get the closest goal. Note that in this default implementation, the
        # agent utilizes an omnipotent knowledge of the environment.
        find_closest parse(env)

        # Don't do anything if @closest_goal doesn't exist (e.g. the env
        # contained no goals)
        return nil if not @closest_goal
        # Calculate the distance to the goal.
        distance_to_goal = Gosu::distance(@position[:x], @position[:y], @closest_goal.x, @closest_goal.y)
        # Return the closest goal if it can be reached, nil otherwise.
        return @closest_goal if distance_to_goal < (Params::FOOD_SCALE * Params::FOOD_WIDTH)
        return nil
    end

    # Returns a vector from the agent to the closest goal or nil if the
    # environment contains no goals.
    def find_closest(env)
        # Grab the x and y coordinates of the agent's position.
        x, y = @position.values
        # A hash to store DIST=>GOAL pairs.
        hash = {}

        # Iterate over env, populating hash with pairs containing the
        # distance to a goal as keys and the goal itself as values.
        env.each do |o|
            hash[Gosu::distance(x, y, o.x, o.y)] = o if o.kind_of? Goal
        end
        # Take the goal corresponding to the minimum key (closest distance)
        # in the hash.
        @closest_goal = hash[hash.keys.min]

        # Return a vector to the closest goal if one exists.
        # (The only reason one wouldn't exist is if the environment had no
        # goals.)
        return @closest_goal.x - x, @closest_goal.y - y if @closest_goal
        return @closest_goal # Will be nil if it ever gets here.
    end

    # Reset the agent's position, rotation, fitness, and/or any other
    # necesssary variables.
 	def reset()
        # Reset to random position, bounded by the window dimensions
        @position = {:x => rand((0.5*@sprite.width)..Params::WINDOW_WIDTH-(0.5*@sprite.width)),
                     :y => rand((0.5*@sprite.width)..Params::WINDOW_HEIGHT-(0.5*@sprite.height))}
        # Reset fitness to base fitness
        @fitness = Params::BASE_FITNESS
        # Reset rotation to random angle (in radians).
        @angle = rand(0.0..Params::TWO_PI)
    end

    # Replace the weights of this agent's brain.
    # Default implementation assumes no brain, and merely returns the agent
    # unchanged.
 	def set_weights(weights); self;end

    # Updates this agent's fitness (and goals reached in tandem).
    # Side effect of assignment is the returning of the new fitness.
    # Including classes need to have a @fitness, @goals_reached, and
    # @deathly_illness to have their fitness updated.
    def update_fitness(goal=nil)
        if goal
            @fitness += goal.value
            @goals_reached += 1
        end
        # Slowly die.
        slowly_die
    end

    # Returns true if this agent's fitness has dropped to zero or below, else
    # returns false.
    def dead?()
        @fitness <= 0
    end

    def slowly_die()
        # Apply death.
        @fitness += @deathly_illness
        # Cap health.
        @fitness = [@fitness, Params::MAX_FITNESS].min
        
        ## Adjust transparency to reflect deathliness by converting the fitness
        ## to an alpha value.
        fitness2alpha
    end

    def fitness2alpha()
        # Fitness range = MAX_FITNESS - MIN_FITNESS
        fitness_min = 0
        fitness_range = Params::MAX_FITNESS - fitness_min
        old_value = @fitness

        # Alpha range = MAX_ALPHA - MIN_ALPHA
        alpha_min = 25
        alpha_max = 256
        alpha_range = alpha_max - alpha_min

        # New alpha is a simple linear transformation of this form:
        new_alph = alpha_min + (alpha_range / fitness_range) * (old_value - fitness_min)
        @color.alpha = new_alph
    end

    # Get the total number of weights in this agent's brain.
    # Default implementation assumes no brain, and so returns 0.
 	def num_weights(); 0;end

 	# String representation of this agent.
 	def to_s(); "#<Agent: fitness=#@fitness, position=#@position>";end
end

# A BasicAgent moves in random directions, never using its brain.
class BasicAgent; include Agency
    attr_reader :position, :heading, :fitness

    def initialize(window, neural_net=nil)
        # This agent does not use its brain, and so ought not to have one.
        @brain = neural_net.new if neural_net
        # The age of this agent in game ticks.
        @age = 0
        # Incremented with every goal reached/consumed, decremented over time.
        @fitness = Params::BASE_FITNESS 
        # Amount by which this agent's fitness decreases with every time step.
        @deathly_illness = Params::DEATH
        
        # The agent's sprite.
        @sprite = Gosu::Image.new(window, "agent.bmp", false)
        # A color to control agent's transparency.
        @color = Gosu::Color.new(0xffffffff)
        # Set alpha value of color according to initial fitness
        fitness2alpha

        # Updated by the brain, used to calculate the rotation and speed.
        @left_leg = @right_leg = Params::MAX_SPEED / 2

        # Speed (pixels to move on #update)
        @speed = @left_leg + @right_leg

        # Render scale of an Agent
        @scale = Params::AGENT_SCALE
        # Incremented with every goal reached/consumed.
        @goals_reached = 0
        # A Food or other goal object
        @closest_goal = nil

        # Creates a random start position bounded by the dimensions of the window/environment.
        @position = {:x => rand((0.5*@sprite.width)..Params::WINDOW_WIDTH-(0.5*@sprite.width)),
                     :y => rand((0.5*@sprite.width)..Params::WINDOW_HEIGHT-(0.5*@sprite.height))}
        # Start with a random orientation (in radians!)
        @angle = rand(0.0..Params::TWO_PI)
        # Set a course corresponding to our orientation.
        calculate_heading # creates @heading on first invocation
    end
end

class SeekingAgent < BasicAgent
    def initialize(window, neural_net=SeekingNet)
        # The neural network behind this little guy's smarts.
        super window, neural_net
        
        # need some sensory organs
    end

    def respond_to(env)
        # This will store all inputs for the neural net.
        inputs = []
        # Look for a goal.
        goal_coords = find_closest parse(env)
        if goal_coords
            # Add in the coordinates to the closest goal, normalized
            inputs.push(*goal_coords.normalize)
            # Add in our current heading.
            inputs.push(*@heading.values)

            # p "inputs: #{inputs}"
            # p "position: #{@position}"

            # Update the brain and get feedback.
            outputs = @brain.respond_to inputs
            return false if outputs.size < Params::NUM_OUTPUTS

            # p "outputs: #{outputs}"

            # Assign the outputs to the agent's legs/motors/mobile appendages.
            @left_leg, @right_leg = outputs                               
        end

        # Calculate the steering forces.
        this_much = @left_leg - @right_leg
        this_fast = @left_leg + @right_leg

        # Turn the agent.
        turn this_much
        # Update position, wrapping around window limits.
        move this_fast

        return true
    end
end