# run.R
#
# Run a simple simulated example plot.


source("simulate-data.R")
source("3d-dryer.R")


run <- function( animate = FALSE ) {
  
  # Simulate some data using the default values
  sim_data <- create_data()
  
  # Draw the scene and animate
  dev <- draw_scene(sim_data)
  
  # Animate?
  if (animate) {
    
    # RGL will complain if the window is closed during the animation...Just
    # snuff this...
    try( {animate_scene(dev)}, silent = TRUE )
  }
  
  invisible(dev)
}
