# NeuralNets.rb
# 
# Daniel Brady, Spring 2014
# 
# This file contains the class definitions of various neural networks.

require_relative "Network"

class BasicNet; include Network
    attr_reader :num_inputs, :num_outputs, :num_hidden_layers,
                :num_per_hidden, :max_weight, :num_weights
    attr_accessor :layers

    def initialize(agent=nil,
                   num_inputs=Params::NUM_INPUTS,
                   num_hidden_layers=Params::NUM_HIDDEN,
                   num_per_hidden=Params::NEURONS_PER_HIDDEN_LAYER,
                   num_outputs=Params::NUM_OUTPUTS,
                   max_weight=Params::MAX_WEIGHT)
        @agent = agent
        @num_inputs = num_inputs
        @num_hidden_layers = num_hidden_layers
        @num_outputs = num_outputs
        @num_per_hidden = num_per_hidden
        @max_weight = max_weight

        # Create the network.
        build_network
    end
end

# b = BasicNet.new
# p b.num_weights
# puts "#{b.layers[0].row_size}x#{b.layers[0].column_size}"
# puts "#{b.layers[1].row_size}x#{b.layers[1].column_size}"
# inputs = Array.new(4){rand (-1.0..1)}
# p inputs
# puts b.weights.inspect
# puts b.num_weights
# outputs = b.respond_to(inputs)
# puts outputs

####################################################
# A neural network with a rudimentary visual system.
# 
# Attains goal-seeking behavior through the use of a 3-layer neural net:
# one input layer, one hidden layer, and one output layer.
# This net uses the visual sensors (essentially just light sensors; goals 
# emit light, empty space is dark) of the agent to turn the agent's body
# towards objects. The first layer contains one neuron for each bit of visual
# input, a neuron which calculates the weighted sum of its
# inputs, which is fed to the second layer. The second layer is connected
# in a "winner takes all" network, which activates only the brightest of
# the input neurons (i.e. the closest goal). The last layer of the network is
# connected to every neuron in the "winner take all" layer; each of these
# connections is weighted with the angle (in radians) to the corresponding
# goal. The end result of this network is to produce a single output which is 
# the angle of the brightest neuron, effectively steering the agent into the
# light.

class SeekingNet < BasicNet
    def initialize(agent=nil,
                   num_inputs=Params::AGENT_NUM_SENSORS, # one input per sensor
                   num_hidden_layers=2, # Specific to this network
                   num_per_hidden=num_inputs, # same as num_inputs
                   num_outputs=1, # Specific to this network
                   max_weight=Params::MAX_WEIGHT)
        super(agent, num_inputs, num_hidden_layers,
              num_per_hidden, num_outputs, max_weight)
    end

    ### Below was the original plan, but then I realized it wasn't suitable for
    ### an agent who would be evolving, because upon creation of the agent,
    ### its weights would just be reset to random ones corresponding to its
    ### assigned genome :\

    # Build a specific network based on predefined parameters.
    # def build_network()
    #     @layers = Array.new 3
    #     # Create the first hidden layer, a num_per_hiddenX(num_inputs+1) matrix
    #     # The +1 accounts for a bias vector that is horizontally concatenated
    #     # upon creation of the layer.
    #     @layers[0] = build_layer(@max_weight, @num_per_hidden, @num_inputs)
        
    #     ### NOTE: we do not create the second hidden layer until response time,
    #     # because it is a "winner take all" layer whose only non-zero term will
    #     # correspond to the strongest visual signal, and thus cannot be
    #     # calculated until response time nor can it be evolved.

    #     # Create output layer, a num_outputsX(num_per_hidden+1) matrix
    #     # (again, +1 accounts for the bias) with entries corresponding to the
    #     # positions (angles) of this agent's sensory organs.

    #     # Calculate the angles of the sensory organs relative to the agent.
    #     theta = -@agent.visual_range/2
    #     angles = Array.new 6
    #     angles.each_with_index do |e, i|
    #         unless i == @num_per_hidden/2
    #             angles[i] = theta
    #         else
    #             angles[i] = 0
    #         end
    #         theta += @agent.sensor_range[:theta]
    #     end
    #     layer = Matrix.row_vector angles
    #     # Attach the bias and add the output layer to the network.
    #     @layers[2] = layer.horiz_concat(Matrix[[1]])

    #     # Calculate weights
    #     weights # produces attribute @weights upon first invocation
    #     @num_weights = @weights.size
    # end

    # Build a specific network based on predefined parameters.
    def build_network()
        @layers = Array.new 3
        # Create the first hidden layer, a num_per_hiddenX(num_inputs+1) matrix
        # The +1 accounts for a bias vector that is horizontally concatenated
        # upon creation of the layer.
        @layers[0] = build_layer(@max_weight, @num_per_hidden, @num_inputs)

        ### NOTE: we do not create the second hidden layer until response time,
        # because it is a "winner take all" layer whose only non-zero term will
        # correspond to the strongest visual signal, and thus cannot be
        # calculated until response time nor can it be evolved.
        
        # Create the output layer, a num_outputsX(num_per_hidden+1) matrix
        # (again, +1 accounts for the bias). The entries are randomized in the
        # beginning, but are intended to correspond to the positions of this
        # agent's sensory organs. We'll see if they evolve properly.
        @layers[2] = Matrix.row_vector(Array.new(6) {
            rand(-@max_weight..@max_weight)
            }).horiz_concat(Matrix[[1]])

        # Calculate weights
        weights # produces attribute @weights upon first invocation
        @num_weights = @weights.size
    end    

    # Weight initialization function. Returns an mx(n+1) matrix whose diagonal
    # entries are randomly initialized in the range (-max_weight..max_weight),
    # with all other entries being zero. The +1 accounts for a bias vector that
    # is horizontally concatenated upon creation of the layer.
    def build_layer(max_weight, m, n)
        # Create a square weight matrix with randomized diagonals.
        w = Matrix.diagonal( *Array.new(m){rand(-max_weight..max_weight)} )
        # Add the bias vector.
        w.horiz_concat(Matrix.build(m,1){1})
    end

    # Create the second hidden layer of the network based on the inputs.
    # Returns the weight matrix.
    def build_winning_layer(inputs)
        # Get the input value corresponding to the strongest signal. In this
        # case, we want the minimum value 
        # (smaller distance = closer object = stronger signal).
        windex = inputs.find_index(inputs.min)[0]

        # Create the "winner take all" weight matrix by creating a diagonal
        # matrix with only one nonzero term, whose position corresponds to the
        # index of the winner in the input matrix.
        # i.e. winner_index = 1, input_size = 5
        # w = 0 0 0 0 0   where * is a random weight
        #     0 * 0 0 0
        #     0 0 0 0 0
        #     0 0 0 0 0
        #     0 0 0 0 0
        diags = Array.new(inputs.count) do |i|
            i == windex ? rand(-@max_weight..@max_weight) : 0
        end

        # Create the weight matrix from the diagonal entries. When the weight
        # matrix is multiplied by the inputs used to build it, it will produce
        # a column vector whose only nonzero term is the weighted, winning
        # input. This equates to having only one 'neuron' in the layer fire,
        # the one that received the strongest input signal.
        weights = Matrix.diagonal *diags
        # Don't forget to add in the bias!
        return weights.horiz_concat(Matrix.build(weights.row_size,1){1})
    end

    # Replaces the weights of this network with a given set.
    # Takes a flat array containing weights that number the same as the nonzero
    # weights in this network.
    def set_weights(weights)
         # Current index of 'weights'
        index = -1
        # There might be a better way to do this...
        # @layers.each do |layer|
        #     layer = layer.map {index += 1; weights[index]}            
        # end
        
        # Replace the nonzero weights in the summation layer.
        @layer[0] = @layer[0].map {index += 1; weights[index]}

        # Skip over the winning layer; this changes everytime the network is
        # used, so we shouldn't consider it in our calculations.

        # Replace the nonzero weights in the output layer.
        @layer[2] = @layer[2].map do |w|
            index += 1
            w.zero? ? w : weights[index]
        end

        # Return self to facilitate method chaining.
        self
    end

    # Get the weights from the network.
    def weights()
        # This ensures the calculation is performed exactly once.
        # The first time #weights is called, this calculation is performed and
        # stored in the @weights attribute, and that value is returned. All
        # other times, this method simply returns the value in @weights.
        @weights ||= @layers.map {|layer|
            # This network has special weights. They're almost all zero, except
            # the ones that matter. So we only want to return those values as
            # the weights of this network.
            layer.reject {|w| w.zero?}.to_a
        }.flatten
    end

    # Apply the feed-forward function to the entire network.
    # Expects a flat array of objects within range of the agent's sensors.
    # Returns the outputs as a flattened array of length @num_outputs
    def respond_to(env, activation_fn=Network::ACTIVATION_FN)
        # Randomize turn angle in case of no visual input.
        return rand(-Params::MAX_TURN_ANGLE..Params::MAX_TURN_ANGLE) if env.empty?

        # Extract input signals from sensory organs.
        signals = @agent.sensors.map do |sensor|
            @agent.get_signal_from(sensor,
                                   @agent.parse_with_sensor(env, sensor))
        end
        # Create a vector out of the signals.
        inputs = Matrix.column_vector signals

        # This network has only three layers.
        input_layer = @layers.first
        output_layer = @layers.last

        # Compute the standard activation for the input layer.
        outputs, net = activate_layer(inputs, input_layer, activation_fn)

        # Create and process the hidden layer using a "winner takes all"
        # approach.
        hidden_layer = @layers[1] = build_winning_layer(outputs)
        outputs, net = activate_layer(outputs, hidden_layer, activation_fn)
        # Weight the winner and return it.
        outputs, net = activate_layer(outputs, output_layer, activation_fn)
        return convert(outputs)[0]
    end
end