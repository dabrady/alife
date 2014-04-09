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

    def initialize(num_inputs=Params::NUM_INPUTS,
                   num_hidden_layers=Params::NUM_HIDDEN,
                   num_per_hidden=Params::NEURONS_PER_HIDDEN_LAYER,
                   num_outputs=Params::NUM_OUTPUTS,
                   max_weight=Params::MAX_WEIGHT)
        @num_inputs = num_inputs
        @num_outputs = num_outputs
        @num_hidden_layers = num_hidden_layers
        @num_per_hidden = num_per_hidden
        @max_weight = max_weight

        # Create the network.
        build_network
    end

    # Build a basic network based on predefined parameters.
    def build_network()
        @layers = []
        # Create the hidden layers, num_per_hiddenX(num_inputs+1) matrices.
        # The +1 accounts for a bias vector that is horizontally concatenated
        # upon creation of the layer.
        @num_hidden_layers.times do
            # Add a new layer (bias vector is concatenated in the creation
            # method).
            @layers << build_layer(@max_weight, @num_per_hidden, @num_inputs)
        end
        # Create output layer, an num_outputsX(num_per_hidden+1) matrix
        # (again, +1 accounts for the bias).
        @layers << build_layer(@max_weight, @num_outputs, @num_per_hidden)
        # Calculate weights
        weights # produces attribute @weights upon first invocation
        @num_weights = @weights.size
    end
end

class SeekingNet < BasicNet
    def initialize(num_inputs=Params::NUM_INPUTS,
                   num_hidden_layers=Params::NUM_HIDDEN,
                   num_per_hidden=Params::NEURONS_PER_HIDDEN_LAYER,
                   num_outputs=Params::NUM_OUTPUTS,
                   max_weight=Params::MAX_WEIGHT)
    end

    # Build a neural network with a rudimentary visual system.
    # Attains goal-seeking behavior through the use of a 3-layer neural net.
    # This net uses the visual sensors (essentially just light sensors; goals 
    # emit light, empty space is dark) of the agent to turn the agent's body
    # towards objects. The first layer contains one neuron for each visual
    # sensor on the agent, a neuron which sums the values
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