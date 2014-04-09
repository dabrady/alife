# Genome.rb
# 
# Daniel Brady, Spring 2014
# 
# This file defines a genome structure for a genetic algorithm.

class Genome
    # The Comparable mixin is used by classes whose objects may be ordered. The
    # class must define the <=> operator, which compares the receiver against
    # another object, returning -1, 0, or +1 depending on whether the receiver
    # is less than, equal to, or greater than the other object. If the other
    # object is not comparable then the <=> operator should return nil.
    include Comparable, Enumerable

    # The weight vector representing the genome and the fitness value of this genome
    attr_accessor :weights, :fitness

    def initialize(weights=[], fitness=0.0)
        @weights = weights
        @fitness = fitness
    end

    # Comparable uses <=> to implement the conventional comparison operators
    # (<, <=, ==, >=, and >) and the method between?.
    def <=>(other)
        # Compare genomes by fitness value
        @fitness <=> other.fitness
    end

    # Enumerable method allows for iterating over the weights in this Genome.
    def each(&block)
        @weights.each &block
    end

    # Wrapper/delegator for pushing weights into this Genome.
    def <<(weight)
        @weights << weight
    end

    # Wrapper/delegator for joining an array with this Genome's weights.
    def concat(array)
        @weights.concat array
        self
    end

    # Wrapper/delegator for accessing this Genome's weights
    def [](index)
        @weights[index]
    end

    # Wrapper/delegator for mapping over this Genome's weights
    def map!(&block)
        @weights.map! &block
    end
end

# x = Genome.new
# p x
# x.concat [1,2,3]
# p x