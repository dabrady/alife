# Params.rb
# 
# Daniel Brady, Spring 2014
# 
# This file defines a set of parameters to be used in a neural network.
# It also monkey-patches the Array class with a new #normalize method.
require 'matrix'

module Params
    PI             = Math::PI
    HALF_PI        = PI/2
    TWO_PI         = PI*2
    WINDOW_WIDTH   = 1920
    WINDOW_HEIGHT  = 1080
    NUM_INPUTS     = 4
    NUM_OUTPUTS    = 2
    NUM_HIDDEN     = 1
    NEURONS_PER_HIDDEN_LAYER = 6
    ACTIVATION_RESPONSE = 1
    BIAS           = 1
    MAX_WEIGHT     = 1/Math.sqrt(NUM_INPUTS)
    MAX_TURN_ANGLE = PI/40 # in radians; translates to ~ 4.5*
    MAX_SPEED      = 3.0
    NUM_GOALS      = 40
    NUM_AGENTS     = 30
    NUM_TICKS      = 1800 # 60/sec = 30 sec generations
    FOOD_SCALE     = 0.5
    FOOD_WIDTH     = 30 # pixel width of Food sprite; used for food detection by agents
    BASE_FITNESS   = 375.0
    MAX_FITNESS    = 800.0
    DEATH          = -0.2
    AGENT_SCALE    = 1
    AGENT_REACH    = FOOD_SCALE * FOOD_WIDTH
    AGENT_NUM_SENSORS = 6
    AGENT_VISUAL_RANGE = HALF_PI # ~90*
    AGENT_SENSOR_RANGE_THETA = 15*PI/180 # translates to a 15* field of view
    AGENT_SENSOR_RANGE_MAG   = 600  # with edge vectors of magnitude 600
    XOVER_RATE     = 0.7
    MUTATION_RATE  = 0.1
    MAX_PERTURBATION = 0.3
    NUM_ELITE      = 4
    NUM_COPIES_ELITE = 1 

    ## Some utility functions.
    # Converter for angles. Converts from radians to degrees.
    def Params::rad_to_degrees(n)
        n * 180/PI
    end

    # Rotate a head point about an origin point THETA degrees.
    def Params::rotate_point(origin, head, theta)
        ox, oy = origin
        hx, hy = head
        sin = Math.sin(theta)
        cos = Math.cos(theta)
        # Translate point to origin, rotate by theta, and translate back.
        x = cos * (hx - ox) - sin * (hy - oy) + ox
        y = sin * (hx - ox) + cos * (hy - oy) + oy
        return x,y
    end

    # Calculate the distance between two points.
    def Params::distance_to(x1, y1, x2, y2)
        return Math.hypot(x2-x1, y2-y1)
    end

    # Convert an angle to a directional vector.
    def Params::directional_vector(theta)
        return Math.cos(theta), Math.sin(theta)
    end
end

# Special exceptions
class NNetProcessingError < StandardError; end
class ExtinctionEvent < StandardError; end

# Monkey-patch Array with normalize() method.
class Array
    # Treating the array as a vector, returns a new vector with the same
    # direction but with norm (length) 1.
    def normalize()
        magnitude = Math.sqrt(self.inject(0) {|v, e| v + e*e})
        raise ZeroDivisionError, "Magnitude is zero, cannot be normalized" if magnitude == 0
        self.map{|e| e / magnitude}
    end
end

# Monkey-patch the Ruby Matrix class with a bit of extra functionality.
class Matrix
    # Hadamard (component-wise) multiplication.
    def hadamult(m)
        # Hadamard multiplication is restricted to matrices of the same dimension.
        Matrix.Raise ErrDimensionMismatch unless row_size == m.row_size && column_size == m.column_size

        # Traverse both matrices in parallel, multiplying parallel components
        # and storing them in a new matrix.
        result = Array.new(row_size) do |i|
            Array.new(column_size) do |j|
                self[i,j] * m[i,j]
            end
        end

        # new_matrix is some sort of private constructor which takes the rows of the matrix and a column size.
        # Could have just as easily used 'return Matrix.rows rows', but I saw this in the source code and figured
        # it might be better, more native, to do it this way.
        return new_matrix result, column_size
    end

    # Kronecker multiplication of a column and row vector.
    # Defined by: Z[i][j] = X[i][0] * Y[0][j]
    def kronemult(m)
        # Ensure self is a column vector and m is a row vector.
        Matrix.raise ErrDimensionMismatch unless column_size == 1 && m.row_size == 1

        # The form of our result is an mpXnq matrix.
        result = Array.new(row_size){ Array.new(m.column_size) }

        row_size.times do |i|
            m.column_size.times do |j|
                result[i][j] = self[i,0] * m[0,j]
            end
        end
        return new_matrix result, m.column_size
    end

    # Horizontal concatenation of two matrices with the same row dimension.
    def horiz_concat(m)
        # Matrices must have same number of rows to be horizontally concatenated.
        Matrix.raise ErrDimensionMismatch unless row_size == m.row_size
        # Return the concatenated matrix.
        return Matrix.build(row_size, column_size + m.column_size) do |row, col|
            if col < column_size
                self[row,col]
            else
                m[row, col-column_size]
            end
        end
    end

    # Vertically extend a matrix by another by essentially stacking one atop the other.
    # Must be of same column dimension.
    def vert_extend(m)
        # Ensure same column dimension.
        Matrix.raise ErrDimensionMismatch unless column_size == m.column_size
        # Return extended matrix.
        return Matrix.build(row_size + m.row_size, column_size) do |row, col|
            if row < row_size
                self[row,col]
            else
                m[row-row_size, col]
            end
        end
    end

    # Pretty print.
    def to_s()
        self.to_a.map {|row|
            row.join "\t"
        }.join "\n"
    end

    # Unsure if getting the size (number of elements) of a matrix is optimized,
    # so I've written one here.
    def size()
        row_size * column_size
    end

    # Not sure why this isn't already built in.
    def dimensions()
        [row_size, column_size]
    end
end


# Monkey-patch the Vector class with an extra method that calculates an error vector
# between two vectors of the same size.
class Vector
    # Returns a binary vector (containing only 1's and 0's) of SIZE size, with a 1 in
    # positions where corresponding components of self and v2 are NOT equal, and a 0
    # everywhere else.
    def error_vector(v2)
        error = []
        self.each2(v2) do |i,j|
            error << (i == j ? 0 : 1)
        end
        Vector.elements error
    end
    # Round all numbers in the vector to the nearest whole number.
    def round()
        self.map(&:round)
    end
end