# TODO: Add comment
# 
# Author: jstevens
###############################################################################



# Global constants --------------------------------------------------------


# Each of our "small" plate dryers could hold 20 trays of microtiter plates. 50
# plates could fit in each tray: 10 plates across and 5 plates deep, in portrait
# orientation.

TRAYS_PER_DRYER = 20
PLATES_WIDE = 10
PLATES_DEEP = 5

# Each tray holds 50 plates
PLATES_PER_TRAY = PLATES_WIDE * PLATES_DEEP

# Each of the "small" dryers holds up to 1000 plates
TOTAL_PLATES = TRAYS_PER_DRYER * PLATES_WIDE * PLATES_DEEP


# The OD range of a typical plate reader reading a non-empty plate
MIN_OD <- 0.030
MAX_OD <- 4.000