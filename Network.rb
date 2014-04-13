# Network.rb
# 
# Daniel Brady, Spring 2014
# 
# This module outlines the basic functions necessary to build and operate a
# matrix-based neural network.

require_relative "Params"
require 'matrix' # also defines Vector
require 'CSV'

module Network
      # The activation function.
    ACTIVATION_FN = ->(x) {x/20}  # Scale the output

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

    # Weight initialization function. Returns an mx(n+1) matrix randomly
    # initialized in
    # range (-max_weight..max_weight). The +1 accounts for a bias vector that
    # is horizontally
    # concatenated upon creation of the layer.
    # A good value for max_weight is 1 / sqrt(input_count).
    def build_layer(max_weight, m, n)
        # Create the mxn randomized weight matrix.
        w = Matrix.build(m, n) { rand (-max_weight..max_weight) }
        # Add the bias vector.
        w.horiz_concat(Matrix.build(m,1){1})
    end

    # Apply the feed-forward function to a layer of the network.
    # Computes the net input of an input matrix with a bias and weights
    # matrix, and activates it.
    # The bias is a constant column vector of 1's with as many rows as the
    # input matrix.
    # Returns the output matrix and the net input matrix.
    def activate_layer(inputs,
                       weights,
                       fn=Network::ACTIVATION_FN,
                       bias=Matrix.build(inputs.column_size, 1){1})
        net_input = weights * inputs.vert_extend(bias)
        output = activate(net_input, fn)
        return output, net_input
    end

    # Apply the feed-forward function to the entire network.
    # Expects a flat array of inputs.
    # Returns the outputs as a flattened array of length @num_outputs
    def respond_to(inputs, activation_fn=Network::ACTIVATION_FN)
        outputs = Matrix.column_vector inputs
        net = nil
        @layers.each do |layer|
            inputs = outputs
            outputs, net = activate_layer(inputs, layer, activation_fn)
        end
        # Return outputs as a flattened array.
        return *convert(outputs)#, net.to_a.flatten
    end

    # Maps the activation function component-wise over a matrix.
    def activate(matrix, fn=Network::ACTIVATION_FN)
        matrix.map { |x| fn.(x) }
    end

    # Converts an mx1 output matrix to a number array of size m.
    def convert(output_matrix)
        # Map over the column vectors of this matrix, creating an array of the
        # translated columns.
        return output_matrix.column_vectors
            .map{|col| col.map {|val| [-Params::MAX_TURN_ANGLE,
                                       val.round(3), # round to 3 places
                                       Params::MAX_TURN_ANGLE].sort[1]}}[0]
    end

    # Replaces the weights of this network with a given set.
    # Takes a flat array containing an equal number of weights as this network.
    def set_weights(weights)
         # Current index of 'weights'
        index = -1
        # There might be a better way to do this...
        @layers.each do |layer|
            layer = layer.map {index += 1; weights[index]}            
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
        @weights ||= @layers.map {|layer| layer.to_a}.flatten
    end

    # Write out weights (a matrix, vector, anything that can be converted to
    # an array, really) to a CSV file.
    def write_to_file(weights)
        CSV.open("./weights.csv", "wb") do |csv|
            csv << weights.to_a
        end
        true
    end
end

# x = Vector.elements(Array.new(5){rand 5})
# y = Vector.elements(Array.new(5){rand 5})
# p y
# p Network::write_to_file y
# e = x.error_vector(y)
# p e
# p e.reduce(:+) / x.size

# x = Matrix[[0,1],[0,1],[1,0],[0,1],[1,0]]
# p Network::activate x
# i = Matrix.column_vector [rand(0..1.0), rand(0..1.0), rand(10), rand(10)]
# w = Network::build(10, Params::NUM_INPUTS, Params::NUM_INPUTS)
# b = Matrix.column_vector [1,1,1,1]
# puts i.to_s, "\n"
# puts w.to_s, "\n"

# puts Network::activate(w*i+b).to_s

# output, net = Network::update i, w
# puts net.to_s, "\n"
# puts output.to_s, "\n"
# puts Network::convert(output).to_s