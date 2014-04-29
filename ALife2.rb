# ALife2.rb
# 
# Daniel Brady, Spring 2014
# 
# This class defines the controller for my A-life simulation.

require 'gosu'
["Agents",
 "GenAlg",
 "Params",
 "ZOrder",
 "Food"].each {|file| require_relative file}

class ALife2 < Gosu::Window
    attr_reader :agents, :env, :Henry
	def initialize(goal=Food, agent=BasicAgent, brain=BasicNet)
		# Create a WIDTH x HEIGHT non-fullscreen window.
		super Params::WINDOW_WIDTH, Params::WINDOW_HEIGHT, false
		# Title of the window.
		self.caption = "ALife Simulator 3"

        # The background color
        @bg_color = Gosu::Color.new(255, 10, 72, 13)
        # The font color
        @font_color = Gosu::Color::BLACK
        # A font for displaying text.
        @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
        
        # Number of agents currently inhabiting the world
        @num_agents = Params::NUM_AGENTS
        # Number of goals currently existing in the world
        @num_goals = Params::NUM_GOALS
        
        # The agents
        @agents = Array.new(@num_agents) { agent.new(self, brain) }
        # The environment
        @env = Array.new(@num_goals) { goal.new self }
        # Reverse look-up table for environment.
        @ENV_TABLE = {}
        @env.each_with_index do |goal, i|
            @ENV_TABLE[goal] = i
        end

        # Create the genetic algorithm for the simulation.
        # Number of weights in the neural net of each agent is assumed to be
        # the same if all Agents are the same type.
        @GA = GenAlg.new(@num_agents,
                         Params::MUTATION_RATE,
                         Params::XOVER_RATE,
                         @agents[0].num_weights)
        # The population of agents and their genomes
        @population = {}
        # Get the chromosomes/genomes of the GA, one for each agent.
        chromos = @GA.chromosomes
        # Associate each genome with an agent by initializing the agent's
        # weights to those of a particular genome and populating the
        # @population hash.
        @agents.each do |agent|
            chromo = chromos.next
            agent.set_weights(chromo.weights)
            @population[agent] = chromo
        end

        # Henry, an agent whom we will monitor throughout the duration.
        @Henry = @agents[rand(0...@agents.size)]
        # Identify Henry.
        @Henry.sprite = Gosu::Image.new(self, "henry.bmp", false)
        puts @Henry.report(@population[@Henry]), "\n"

        # Average fitness per generation (used in graphing)
        @fitness_averages = []
        # Best fitness per generation (used in graphing)
        @hall_of_fame = []
        # Cycles per generation
        @ticks = 0
        # Generation counter
        @generation = 0
	end

    # This is the meat and potatoes of the entire simulation.
    def update()
        # Make sure we've still got a population to update!
        raise ExtinctionEvent, "Everyone has died." if @agents.empty?

        # Run the agents through a generation cycle.
        # During this iteration, each agent's neural net is updated with the
        # appropriate information from its surroundings. The output from the
        # neural net is obtained and the agent is moved. If it encounters a
        # goal, its fitness is updated appropriately.
        if @ticks < Params::NUM_TICKS
            # Update each agent.
            @agents.each do |agent|
                # Update our position.
                if (not agent.respond_to @env) # error in neural net processing
                    # Save before exiting.
                    save_stats
                    raise NNetProcessingError,
                          "Incorrect number of inputs!"
                end

                # See if we've reached a goal.
                goal = agent.try_for_goal @env
                if goal
                    # We've discovered a goal, so increase fitness and update
                    # our corresponding genome.
                    @population[agent].fitness = agent.update_fitness goal
                    # 'Consume' the goal.
                    consume goal
                else
                    # We haven't reached a goal, so decrease fitness and update
                    # our corresponding genome.
                    @population[agent].fitness = agent.update_fitness
                end

                # Increment age counter.
                agent.update_age

                # Check if this agent has died.
                if agent.dead?
                    @population.delete agent
                    @agents.delete agent
                end
            end
        else
            # Another generation has been completed.
            # Time to run the GA and update the agents with new brains.

            # Keep track of Henry.
            puts @Henry.report(@population[@Henry]), "\n"

            # Increment the generation counter.
            @generation += 1

            # Reset the cycle counter.
            @ticks = 0

            # Run the GA to create a new population.
            chromos = @GA.epoch @population.values # returns an enum

            # Update the stats of the generation.
            @fitness_averages << @GA.average_fitness.round(3)
            @hall_of_fame << @GA.best_fitness.round(3)

            # Save the stats.
            save_stats

            # Replace the old population with the new one by replacing each
            # agent's chromosome and brain instead of unnecessarily creating
            # new agents.
            @population.keys.each do |agent|
                @population[agent] = chromos.next
                # Insert the new (hopefully) improved brains back into the
                # agents.
                agent.set_weights(@population[agent].weights)
                # Reset the agent's position, fitness, and orientation.
                agent.reset
            end
        end
        # Tick.
        @ticks += 1

        quit if @generation >= Params::END_OF_THE_WORLD
        return true
    end

    def draw()
        # Draws the background (just a colored rectangle).
        draw_background
        # Draw each object in the environment.
        @env.each {|obj| obj.draw}
        # Draw each agent.
        @agents.each {|agent| agent.draw}
        # Draw stats.
        draw_stats
    end

    def draw_background()
        draw_quad(0,          0,           @bg_color, # top left corner
                  self.width, 0,           @bg_color, # top right corner
                  0,          self.height, @bg_color, # bottom left corner
                  self.width, self.height, @bg_color, # bottom right corner
                  ZOrder::Background) # z-index
    end

    def draw_stats()
        # Generation counter.
        @font.draw("Generation: #{@generation}", 10, 10, ZOrder::ON_TOP, 1.0, 1.0, @font_color)
        # Population of previous generation.
        @font.draw("Current Population: #{@agents.size}", 10, 30, ZOrder::ON_TOP, 1.0, 1.0, @font_color)
        # Average fitnesses of previous generations.
        @font.draw("Average fitnesses: #{@fitness_averages.size > 7 ? "..." : ""}#{@fitness_averages.last(7).join(", ")}", 10, 50, ZOrder::ON_TOP, 1.0, 1.0, @font_color)
        # Best fitnesses of previous generations.
        @font.draw("Best fitnesses: #{@hall_of_fame.size > 7 ? "..." : ""}#{@hall_of_fame.last(7).join(", ")}", 10, 70, ZOrder::ON_TOP, 1.0, 1.0, @font_color)
    end

    def save_stats()
        File.open("stats.txt", "a") {|file|
            file.write \
"#{Time.now.asctime}{
    Generations: #{@generation}
    Population: #{@agents.size}
    Average fitnesses: #{@fitness_averages}
    Best fitnesses: #{@hall_of_fame}
    HENRY'S REPORT:
    #{@Henry.report @population[@Henry]}
}\n"
        }
    end

    # Key listener
    def button_down(id)
        # Exit simulation on ESCAPE
        if id == Gosu::KbEscape
            quit
        end
    end

    def quit()
        save_stats
        close
    end

    private
    # 'Consume' the goal by replacing it with another, generated at a random
    # position in the world.
    def consume(goal)
        new_goal = Food.new self
        i_of_old = @ENV_TABLE.delete goal
        @env[i_of_old] = new_goal
        @ENV_TABLE[new_goal] = i_of_old
        nil
    end
end

sim = ALife2.new(Food, SeekingAgent, SeekingNet)
# h = sim.Henry
sim.show


# b = SeekingAgent.new(ALife2.new)