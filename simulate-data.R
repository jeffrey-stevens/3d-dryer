# sample-data.R
#
# Build a sample data set for the 3D dryer heatmap.


source("global.R")

library(ggplot2)


# Constants ---------------------------------------------------------------

# The sizes

# The default random seed for the simulated data set
DEFAULT_SEED <- 520

# These are fairly good values for the parameters of create_data:
DEFAULT_MIN_OD <- 0.100
DEFAULT_MAX_OD <- 1.000

# r = (N / 2) * ln(2) gives the rate where the half-life equals N / 2.
# This as a scaling factor makes it easier to choose a good rate...
# These values seem to work okay...
DEFAULT_RATE1 <- (2 / TRAYS_PER_DRYER) * log(2) * 0.3
DEFAULT_RATE2 <- (2 / PLATES_PER_TRAY) * log(2) * 3

DEFAULT_NOISE1 <- 0.050
DEFAULT_NOISE2 <- 0.050

DEFAULT_missing_rate <- 1 / 50  # 1 out of every 50 plates are discarded
DEFAULT_BAD_RATE <- 1 / 100  # 1 out of every 100 plates are bad
# This is about what the fault rates were in practice (conservatively)


# Functions ---------------------------------------------------------------


# This roughly simulates the pattern seen in the median-ODs of all wells / plate
# in a production run.  Note that the ODs exhibited a 50-plate ramp-up sawtooth
# pattern when plotted in order of manufacture, where the effect was strong
# initially, but which diminished with higher-numbered plates.
#
# This function will simulate the *median" OD across all wells of the plate.
# It isn't necessary to simulate the individual wells---only the medians
# are used in the 3D rendering.

create_data <- function(ymin0 = DEFAULT_MIN_OD, ymax0 = DEFAULT_MAX_OD,
                        rate1 = DEFAULT_RATE1, rate2 = DEFAULT_RATE2,
                        noise1 = DEFAULT_NOISE1, noise2 = DEFAULT_NOISE2,
                        sim_defects = FALSE,
                        missing_rate = ifelse(sim_defects, DEFAULT_missing_rate, 0),
                        bad_rate = ifelse(sim_defects, DEFAULT_BAD_RATE, 0),
                        seed = DEFAULT_SEED) {
  # ymin0:    The minimum median OD for all plates
  # ymax0:    The maximum median OD for all plates
  # rate1:    The within-groups rate constant
  # rate2:    The between-groups rate constant
  # noise1:   The within-groups noise standard deviation (for both ymin and ymax)
  # noise2:   The between-groups noise standard deviation
  # sim_defects:  Simulate missing or misrun plates?
  # missing_rate:  The rate of "missing" plates
  # bad_rate:  The rate of "bad" plates
  # seed:     The random seed
  
  set.seed(seed)
  
  GROUP_SIZE <- 50
  
  # Create the list of plates
  plates <- seq_len(TOTAL_PLATES)
  
  # Group the plates into 50-plate groups, indexed from 0
  groups <- (plates - 1) %/% GROUP_SIZE
  
  # Get the index of each plate within the groups of 50
  index <- (plates - 1) %% GROUP_SIZE
  
  
  # Calculate the minimum OD within each group.
  #
  # The between-groups emperical data appears to have exhibited an exponential
  # decay pattern, crudely speaking.  Tack on some noise, for realism.  Remember
  # that we're interested in the between-groups rate and noise...
  
  # The noise should only vary by group:
  grp_noise_min <- rnorm(length(groups), 0, noise2)
  grp_noise_min_all <- rep(grp_noise_min, each = GROUP_SIZE)
  
  ymin <- ymin0 + (ymax0 - ymin0) * (1 - exp(-rate2 * groups)) + grp_noise_min_all
  
  # Clip the ODs to be within range
  ymin <- pmax(MIN_OD, ymin)
  ymax <- pmin(ymin, MAX_OD)
  
  
  # Add some noise to the maximum within-group OD.
  #
  # The group maxima tend to be about the same, likely subject to the maximum
  # performance threshold of the assay:
  grp_noise_max <- rnorm(length(groups), 0, noise2)
  grp_noise_max_all <- rep(grp_noise_max, each = GROUP_SIZE)
  
  ymax <- ymax0 + grp_noise_max_all
  ymax <- pmax(MIN_OD, ymax)
  ymax <- pmin(ymax, MAX_OD)
  
  # The within-group OD depends on the minimum OD for that group, and demonstrates
  # an exponential sawtooth pattern.
  
  # Add some independent noise to each plate...
  noise <- rnorm(length(plates), 0, noise1)
  
  y <- ymin + (ymax - ymin) * (1 - exp(-rate1 * index)) + noise
  y <- pmax(MIN_OD, y)
  y <- pmin(y, MAX_OD)
  
  
  # Not everything goes perfectly during production and testing.  Some plates
  # are removed during manufacture, either due to a manufacturing fault or to QC
  # testing.  And sometimes things go wrong in testing, calling the results in
  # question.
  #
  # I've broken the plates into 3 categories:  "good", "missing" (discarded
  # during manufacture), and "bad" (suspect testing).  The category can be
  # simulated with multinomial statistics.
  
  # Format the multinomial probabilities:
  probs <- c(defect = missing_rate, bad = bad_rate, good = (1 - missing_rate - bad_rate))
  # Now randomly select 1 of the 3 designations for each plate:
  choices <- rmultinom(length(plates), 1, probs)
  
  # "choices" is essentially a random matrix of triples (1 triple per column);
  # collapse this into a more descriptive vector
  categories <- unlist( apply(choices, 2, function(triple) {
    # The elements of the triple are binary and sum to 1:
    # (1,0,0) : The plate was missing
    # (0,1,0) : The plate was bad
    # (0,0,1) : The plate is good
    
    # Which slot contains the 1 for this tuple?
    choice <- which(triple == 1)
    # Find the designation ("category")
    category <- switch(choice, "missing", "bad", "good")
    
    return(category)
  }) )
  
  
  # Set the OD of the missing plates to NA, since they were never run.
  # Leave the OD of the bad plates, since they were run; let the user decide
  # if these results should be discarded or not:
  y <- ifelse(categories == "missing", NA_real_, y)
  
  # Return a data frame
  #
  #
  # Note that we're really interested in the average (i.e. median)
  # OD across all wells in the plate.
  sim_data <- data.frame(Plate = plates, Category = categories, MedianOD = y)
  
  return(sim_data)
}


# Plot the simulation data, in order of manufacture
plot_sim <- function(sim_data) {
  
  # Should filter out bad or discarded data here...
  
  p <- ggplot(sim_data, aes(x = Plate, y = MedianOD)) +
    geom_point(size = 0.5) + 
    ylim(0, NA) +
    theme_bw()
    
  return(p)
}