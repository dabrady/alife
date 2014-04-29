# GenAlg.rb
# 
# Daniel Brady, Spring 2014
# 
# This file describes a class which models a genetic algorithm, used in an
# artificial feedforward neural network.

require_relative "Genome"

class GenAlg
	# This class has the following attributes:
	# :population, :pop_size, :chromo_length, :total_fitness, :best_fitness,
	# :average_fitness, :worst_fitness, :fittest_genome, :mutation_rate,
	# :xover_rate, :generation

	def initialize(pop_size, mut_rate, xover_rate, num_weights)
		# Initialize the attributes
		@mutation_rate   = mut_rate
		@xover_rate      = xover_rate
		@chromo_length   = num_weights
		@generation      = 0
		@fittest_genome  = nil

		# Initialize the population with chromosomes consisting of random
		# weights and all fitnesses set to zero. Each genome will have a length
		# of size num_weights.
		@population = Array.new(pop_size) {
			Genome.new(Array.new(@chromo_length) {rand -1.0..1})
		}

		reset_stats @population
	end

	#################
	private

	# Given two parent Genomes, this method peforms crossover according to the
	# GA's crossover rate and produces two new offspring
	def crossover(mom, dad)
		# Just return the parents as offspring depending on the xover rate or
		# if the parents are the same, or if @chromo_length is zero.
		return mom, dad if ( mom == dad || @chromo_length.zero? || rand(0..1.0) > @xover_rate )

		# Determine a xover point.
		xover_point = rand(0..@chromo_length - 1)

		# Create the offspring.
		fred, george = Genome.new, Genome.new

		# Copy into baby1 the section of mom's genome ending (and excluding)
		# the xover_point.
		fred.concat   mom[0...xover_point]
		# Copy into baby2 the section of dad's genome ending (and excluding)
		# the xover_point.
		george.concat dad[0...xover_point]

		# Copy the remainder of dad and mom into fred and george, respectively.
		# Notice both Fred and George get half of mom and half of dad.
		fred.concat   dad[xover_point..-1]
		george.concat mom[xover_point..-1]

		return fred, george
	end

	# Mutates the chromosome of a Genome by perturbing its weights by an
	# amount not exceeding Params::MAX_PERTURBATION
	def mutate(genome)
		genome.map! {|weight|
			if (rand(0..1.0) < @mutation_rate)
				weight + rand(-1..Params::MAX_PERTURBATION)
			else
				weight
			end
		}
	end

	# Returns a Genome based on a stochastic-acceptance variation of the
	# typical Roulette wheel selection algortithm
	def sample_genome()
		# Randomly select an individual until it is accepted.
		# Individuals are accepted with a probability equal to
		# their fitness divided by the maximum fitness of the population.
		x = @population.sample

		# In the highly unlikely event that an entire generation goes by
		# without a single agent increasing its fitness from zero, we will
		# divide by 1.
		until rand(0..1) <= (x.fitness / (@best_fitness.zero? ? 1 : @best_fitness))
			x = @population.sample
		end
		x
	end

	# This works like an advanced form of elitism by introducing copies of the
	# n most fit genomes into a population.
	def clone_n_best(n, num_copies, pop)
		# First, sort the population in ascending order by fitness
		# and grab the elites (the last n).
		elites = @population.sort.last n
		# Now add num_copies of the elites to given pop.
		num_copies.times { pop.push *elites }
		nil
	end

	# Calculates the fittest and weakest genome and the average and total
	# fitness scores.
	def calculate_stats()
		# Best
		@fittest_genome  = @population.max
		@best_fitness    = @fittest_genome.fitness
		# Worst
		@worst_fitness   = @population.min.fitness
		# Total
		@total_fitness   = @population.inject(0){|sum, g| sum + g.fitness}
		# Average
		@average_fitness = @total_fitness / @pop_size
	end

	def reset_stats(pop)
		@total_fitness   = 0.0
		@best_fitness    = 0.0
		@worst_fitness   = -Float::INFINITY
		@average_fitness = 0.0
		@pop_size = pop.size
		nil
	end

	#################
	public

	# Takes a population of Agent-Genome pairs (in a hash) and runs the
	# algorithm through one cycle. Returns a new population.
	def epoch(old_pop)
		# Set the given population to be our working population.
		@population = old_pop

		# Reset the appropriate variables.
		reset_stats @population

		# Calculate the necessary statistics.
		calculate_stats
	
		# Create a temporary array to store the new agent-genomes
		new_pop = []

		# Add in a little elitism.
		clone_n_best([@pop_size, Params::NUM_ELITE].min, Params::NUM_COPIES_ELITE, new_pop)

		# Nowe we enter the GA loop.
		# Repeat until the population has been fully generated.
		until new_pop.size == @pop_size
			# Grab two parents.
			mom = sample_genome
			dad = sample_genome

			# Mate them.
			fred, george = crossover(mom, dad)
			# (Potentially) Mutate the offspring.
			mutate fred
			mutate george

			# Now add the twins to the new generation.
			new_pop.push fred, george
		end

		# Finished, so assign the new pop back into @population.
		@population = new_pop
		# Return the new population as an enum to prevent modification.
		chromosomes
	end

	# a few accessors
	def chromosomes()
		# Return an enum to prevent unwanted modification of the population.
		@population.to_enum
	end

	def average_fitness()
		@average_fitness
	end

	def best_fitness()
		@best_fitness
	end
end