# ZOrder.rb
# 
# Daniel Brady, Spring 2014
# 
# A simple module to hold the z-order of the various elements of our simulation.

module ZOrder
    # Background = 0, Food = 1, Agent = 2, ON_TOP = 3 (using 'ON_TOP' ensures drawing is
    # rendered on top of everything else except other ON_TOP objects)
    Background, Food, Agent, ON_TOP = *0..3
end