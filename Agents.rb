# Agents.rb
# 
# Daniel Brady, Spring 2014
# 
# This class defines all of the various Agents of the world.

require 'gosu'
["NeuralNets",
 "Params",
 "ZOrder",
 "Agency"].each {|file| require_relative file}

# A BasicAgent moves in random directions, never using its brain.
class BasicAgent; include Agency
    attr_reader :position, :heading, :angle, :fitness

    def initialize(window, neural_net=nil)
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
        to_alpha @fitness

        # Speed (pixels to move on #update)
        @speed = Params::MAX_SPEED

        # Render scale of an Agent
        @scale = Params::AGENT_SCALE
        # Incremented with every goal reached/consumed.
        @goals_reached = 0
        # A Food or other goal object. Intended to be utilized solely for
        # determining if this agent has encountered a goal, NOT to cheat! ;)
        # There's definitely a better way to do this.
        @closest_goal = nil

        # Creates a random start position bounded by the dimensions of the window/environment.
        @position = {:x => rand((0.5*@sprite.width)..Params::WINDOW_WIDTH-(0.5*@sprite.width)),
                     :y => rand((0.5*@sprite.width)..Params::WINDOW_HEIGHT-(0.5*@sprite.height))}
        # Start with a random orientation (in radians!)
        @angle = rand(0.0..Params::TWO_PI)
        # Set a course corresponding to our orientation.
        # A hash of the form: {:x=>px, :y=>py}
        @heading = {:x => nil, :y => nil}
        calculate_heading
    end
end

class SeekingAgent < BasicAgent
    attr_reader :sensors, :sensor_range, :visual_range, :field_of_view
    def initialize(window,
                   neural_net=SeekingNet,
                   num_sensors=Params::AGENT_NUM_SENSORS)
        super window
        
        # An array of sensory organs.
        @sensors = Array.new num_sensors
        @visual_range = Params::AGENT_VISUAL_RANGE
        @sensor_range = {:theta=>Params::AGENT_SENSOR_RANGE_THETA,
                         :mag=>Params::AGENT_SENSOR_RANGE_MAG}

        # Populate sensor array and calculate the agent's field of view.
        calculate_fov

        # The neural network behind this little guy's smarts.
        @brain = neural_net.new self
        # Calculate and store number of weights
        num_weights
    end

    # Update this agent's field of view with every turn.
    def turn(this_much)
        super this_much
        calculate_fov
    end

    # Calculate the agent's field of view.
    def calculate_fov()
        ## Calculate the angles of our sensory organs.
        # Each sensor has a range of AGENT_SENSOR_RANGE_THETA, and will be
        # represented by the angle of the left bound of that range.
        # i.e. a sensor whose range is (-15*..0*) will be represented by -15*.
        theta = -@visual_range/2
        @sensors.each_with_index do |sensor, i|
            unless i == @sensors.size/2
                @sensors[i] = @angle + theta
            else
                # This is the sensor facing directly a head of us. In other
                # words, its angle is our current orientation ;) This case is
                # necessary to prevent precision errors caused by working with
                # Pi.
                @sensors[i] = @angle
            end
            theta += @sensor_range[:theta]
        end
        ## We will be rotating our heading around our position in both
        ## directions to get two new vectors which bound our field of view.

        # The pivot point.
        pivot = @position.values
        # The point to rotate.
        head  = @heading.values

        @field_of_view = {}
        # Calculate left bound.
        @field_of_view[:left] = Params::rotate_point(pivot, head,
                                                     -@visual_range/2)
        # Calculate right bound.
        @field_of_view[:right] = Params::rotate_point(pivot, head,
                                                      @visual_range/2)
        return true
    end

    # Determines if a given object is within range of this agent's sensors.
    # By default, uses the agent's entire field of view, but if the left and
    # right bounds are specified can determine if an object is within any given
    # range.
    def in_sight?(obj,
                  fov_left=@field_of_view[:left],
                  fov_right=@field_of_view[:right])
        # Calculate the cross products of each FOV bound and the object.
        # cross(u,v) = u.x*v.y - u.y*v.x
        cross_left = fov_left[0] * obj.y - fov_left[1] * obj.x
        cross_right = fov_right[0] * obj.y - fov_right[1] * obj.x
        # The signs of the cross products will tell us if the object is between
        # our visual bounds, if the left is negative and the right is positive.
        in_range = cross_left < 0 && 0 > cross_right

        # Now determine if we can actually see that far by checking if the
        # distance to the object is within the range of our sensors.
        dist = Params::distance_to(*@position.values, obj.x, obj.y)
        # Object is in sight IFF it is within our visual bounds and within
        # the distance our sensory organs can detect.
        return in_range && dist <= @sensor_range[:mag]
    end

    # Given a sensor and an environment within its sensory range, returns a
    # signal in the form of the distance to the closest object in range.
    # NOTE: Currently assumes the env is sorted from closest to furthest,
    # because right now this agent's brain is the only one calling this method,
    # and the brain has access to a sorted env.
    def get_signal_from(sensor, env_in_range)
    	# Return the highest number possible (weakest signal) if nothing is in
    	# range. Note we can't use Infinity because it doesn't play nicely
    	# with arithmetic (we get NaNs all over the network).
    	return Float::MAX if env_in_range.empty?
    	closest = env_in_range[0]
    	Params::distance_to(*@position.values, closest.x, closest.y)
    end

    # Parses the environment based on the range of a single sensor.
    # Returns the part of the environment within range of the sensor.
    def parse_with_sensor(env, sensor)
        # Calculate sensor range.
        to_the_left  = sensor
        to_the_right = sensor + sensor_range[:theta]
        pivot = @position.values
        head  = @heading.values
        left_bound  = Params::rotate_point(pivot, head, to_the_left)
        right_bound = Params::rotate_point(pivot, head, to_the_right)

        # Parse the environment.
        env.select {|obj| in_sight?(obj, left_bound, right_bound)}
    end

    # Parses the environment based on the agent's sensory organs and
    # sorts the result from closest to furthest to facilitate future
    # handling of the data.
    # Returns only the part of the environment the agent can detect.
    def parse(env)
        # Parse based on sensory organs.
        env.select {|obj| in_sight? obj }.
            # Sort by distance, from closest to furthest.
            sort do |a,b|
                Params::distance_to(*@position.values, a.x, a.y) \
                <=> \
                Params::distance_to(*@position.values, b.x, b.y)
            end
    end

    def respond_to(environment)
        # Reduce the environment to the part we can see.
        visual_input = parse environment

        # Update the brain and get feedback.
        output = @brain.respond_to visual_input.flatten

        # Calculate the steering forces.
        this_much = output
        this_fast = [Params::rad_to_degrees(output).abs, Params::MAX_SPEED].min

        # Turn the agent.
        turn this_much
        # Update position, wrapping around window limits.
        move this_fast

        return true
    end

    def num_weights()
        @num_weights ||= @brain.weights.size
    end

    def set_weights(weights)
        @brain.set_weights weights
    end
end