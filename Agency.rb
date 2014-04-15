# Agency.rb
# 
# Daniel Brady, Spring 2014
# 
# This module defines what it means to be an Agent of this world.

require_relative "Params"
require_relative "ZOrder"

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

    def report(genome=nil)
        "#{self.to_s}
        Age: #{@age}
        Genetics: #{genome}
        Goals reached: #{@goals_reached}\n"
    end

    # Used to turn the agent (update its angle and heading).
 	def turn(this_much)
        @angle += this_much
        calculate_heading
    end

    # Used to convert this agent's current angle into a direction vector.
    def calculate_heading()
        @heading[:x], @heading[:y] = Params::directional_vector @angle
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

    # Determines if an object is within reach of the agent.
    def within_reach?(obj)
        # Don't do anything if object doesn't exist.
        return false if not obj

        # Calculate the distance to the goal.
        distance_to_obj = Params::distance_to(*@position.values, obj.x, obj.y)

        # Determine if it is within reach, based on graphics things.
        return distance_to_obj <= Params::AGENT_REACH
    end

    # Checks agent's position to see if a goal has been reached.
    # Returns the closest goal within reach or else nil.
 	def try_for_goal(env)
        # Get the closest goal. Note that a goal does not have to be in sight
        # to be collected; what matters is distance, because if the agent is on
        # top of the goal, he obviously can't see it but should still be able
        # to collect it.
        find_closest env

        # Return the closest goal if it can be reached, nil otherwise.
        if within_reach? @closest_goal
            g = @closest_goal
        else
            g = nil
        end
        return g
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
            hash[Params::distance_to(x, y, o.x, o.y)] = o if o.kind_of? Goal
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
        # Reset age to zero.
        @age = 0
        # Reset number of goals reached.
        @goals_reached = 0
        # Reset rotation to random angle (in radians).
        @angle = rand(0.0..Params::TWO_PI)
    end

    # Replace the weights of this agent's brain.
    # Default implementation assumes no brain, and merely returns the agent
    # unchanged.
 	def set_weights(weights); self;end

    # Updates this agent's fitness (and goals reached in tandem).
    # Including classes need to have a @fitness, @goals_reached, and
    # @deathly_illness to have their fitness updated.
    def update_fitness(goal=nil)
        if goal
            @fitness += goal.value
            @goals_reached += 1
        end
        # Slowly die.
        slowly_die
        # Return updated fitness.
        @fitness
    end

    # Returns true if this agent's fitness has dropped to zero or below, else
    # returns false.
    def dead?()
        @fitness <= 0
    end

    def update_age()
        @age += 1
    end

    def slowly_die()
        # Apply death.
        @fitness += @deathly_illness
        # Cap health.
        @fitness = [@fitness, Params::MAX_FITNESS].min
        
        ## Adjust transparency to reflect deathliness by converting the fitness
        ## to an alpha value.
        to_alpha @fitness
    end

    def to_alpha(fitness)
        # Fitness range = MAX_FITNESS - MIN_FITNESS
        fitness_min = 0
        fitness_range = Params::MAX_FITNESS - fitness_min
        old_value = fitness

        # Alpha range = MAX_ALPHA - MIN_ALPHA
        alpha_min = 25
        alpha_max = 256
        alpha_range = alpha_max - alpha_min

        # New alpha is a simple linear transformation of this form:
        new_alph = alpha_min + (alpha_range / fitness_range) * (old_value - fitness_min)
        @color.alpha = new_alph + 15 # magic factor to boost their opaqueness
    end

    # Get the total number of weights in this agent's brain.
    # Default implementation assumes no brain, and so returns 0.
 	def num_weights(); 0;end

 	# String representation of this agent.
 	def to_s(); "#<#{self.class}: fitness=#@fitness, position=#@position>";end
end

#### Omnipotent Agent
# def respond_to(env)
#         # This will store all inputs for the neural net.
#         inputs = []
#         # Look for a goal.
#         goal_vector = find_closest parse(env)
#         if goal_vector
#             # Add in the coordinates to the closest goal, normalized
#             inputs.push(*goal_vector.normalize)
#             # Add in our current heading.
#             inputs.push(*@heading.values)

#             # p "inputs: #{inputs}"
#             # p "position: #{@position}"

#             # Update the brain and get feedback.
#             outputs = @brain.respond_to inputs
#             return false if outputs.size < Params::NUM_OUTPUTS

#             # p "outputs: #{outputs}"

#             # Assign the outputs to the agent's legs/motors/mobile appendages.
#             @left_leg, @right_leg = outputs                               
#         end

#         # Calculate the steering forces.
#         this_much = @left_leg - @right_leg
#         this_fast = [(@left_leg + @right_leg) * 20, Params::MAX_SPEED].min # magic speed scaling number to scoot them along at a reasonable pace

#         # Turn the agent.
#         turn this_much
#         # Update position, wrapping around window limits.
#         move this_fast

#         return true
#     end


