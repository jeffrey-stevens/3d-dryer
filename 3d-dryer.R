# TODO: Add comment
# 
# Author: jstevens
###############################################################################


source("global.R")

library(rgl)



# Constants ---------------------------------------------------------------


# Define the plate geometry
# 
# This is a relative, not physical scale.  Eventually I should scale the dryer
# to real physical scales.
PLATE_HEIGHT <- 0.2
PLATE_WIDTH <- 0.35
PLATE_DEPTH <- 0.27


# Define the scene geometry

## Define the orientation arrows size
## 
## This seems like a good fit
BARB_SIZE = 1/10  # As fraction of the line size



# Data-manipulation functions ---------------------------------------------


# The plates are loaded onto the trays in serpentine fashion, starting from the
# front-left corner of the tray, then working to the front-right corner (10
# plates), then to the plate behind this, then all the way left, then the plate
# behind that one and all the way right, etc.  The trays are loaded into the
# dryer from the bottom-up (20 trays).
#
# This function maps the plate ID (the sequential order of manufacture) to
# the position in the dryer.

location_in_dryer <- function() {
 
  # The plate IDs, in order of manufacture
  plates <- seq_len(TOTAL_PLATES)
  
  # The tray that each plate is loaded on, with the remainder
  trays <- ((plates - 1) %/% PLATES_PER_TRAY) + 1
  trays_rem <- ((plates - 1) %% PLATES_PER_TRAY) + 1
  
  # The row of the plate on the tray, counting from the front facing the tray,
  # with the remainder
  row <- ((trays_rem - 1) %/% PLATES_WIDE) + 1
  row_rem <- ((trays_rem - 1) %% PLATES_WIDE) + 1
  
  # The column of the plate on the tray, counting from the left facing the tray.
  # Note that the loading may occur left -> right or right -> left,
  # depending on the row:
  col <- ifelse(row %% 2 == 1,
                # Odd rows are loaded from left-to-right
                row_rem,
                # Even rows are loaded from right-to-left
                PLATES_WIDE - row_rem + 1 )
  
  locations <- data.frame(Plate = plates, Tray = trays,
                          TrayRow = row, TrayCol = col)
  
  return(locations)
}


# Merge the median plate ODs with the location of the plate in the dryer
merge_readings_loc <- function(med_readings) {
  
  locations <- location_in_dryer()
  
  full_data <- merge(locations, med_readings, by = "Plate")
  full_data <- full_data[c("Plate", "Category", "Tray", "TrayRow", "TrayCol", "MedianOD")]
  
  return(full_data)
}


# Scaling the median ODs helps to create more visual contrast
# between the plates.
scaled_medians <- function(dataset) {
  
	min_med <- min(dataset$MedianOD)
	max_med <- max(dataset$MedianOD)
	
	return((dataset$MedianOD - min_med)/(max_med - min_med))
}

	

# Rendering functions -----------------------------------------------------


# Translate OD readings to a color scale (color "ramp")
colors <- function(x) {
  
  # colorRamp returns a function that translates values from 0 to 1
  # to an rgb color in the specified range:
  colramp <- colorRamp(c("#FFFFFF", "#0000FF"))
  colmat <- colramp(x)
  
  # The color ramp returns an RGB matrix, with the columns as primary color
  # values in the range of 1 - 255, and the rows as RGB color triplets:
  cols <- apply(colmat, 1, function(y) {
    red <- y[[1]]
    green <- y[[2]]
    blue <- y[[3]]
    
    rgb(red, green, blue, maxColorValue=255)
  })
  
  return(cols)
}


# Build the dryer "frame"
build_dryer <- function() {
	
  # Set the dryer chamber dimensions
  bottom.z <- 0
  top.z <- TRAYS_PER_DRYER + 1
  left.x <- 0
  right.x <- PLATES_WIDE + 1
  front.y <- 0.5
  back.y <- PLATES_DEEP + 0.5
  
  # Define the 8 corners of the dryer chamber, bottom four corners first,
  # counter-clockwise looking from above, starting the corner closest to the
  # origin (the left-front-bottom corner):
  chamber_corners <- 
    matrix( c(
      left.x, front.y, bottom.z,
      right.x, front.y, bottom.z,
      right.x, back.y, bottom.z,
      left.x, back.y, bottom.z,
      left.x, front.y, top.z,
      right.x, front.y, top.z,
      right.x, back.y, top.z,
      left.x, back.y, top.z
    ), byrow = TRUE, ncol = 3 )
	
	# Now define the corners making up each side ("quad") of the chamber.
	# Given here are indices of the chamber_corners matrix above:
	bottom.v <- c(1,2,3,4)
	top.v <- c(5,6,7,8)
	left.v <- c(1,4,8,5)
	right.v <- c(2,3,7,6)
	back.v <- c(4,3,7,8)
	front.v <- c(1,2,6,5)
	
	
	# Draw the 6 sides ("quads") of the dryer chamber as RGL "quad" objects:
	
	# Bottom
	bottom_quad <-
		quads3d(
			chamber_corners[bottom.v,],
			color=gray(0.3), front="fill", back="cull", lit=FALSE
		)
	
	# Back
	back_quad <- 
		quads3d(
			chamber_corners[back.v,],
			color=gray(0.5), front="fill", back="cull", lit=FALSE
		)

	# Front
	front_quod <-
		quads3d(
			chamber_corners[front.v,],
			color=gray(0.5), front="cull", back="fill", lit=FALSE
	)
	
	# Right
	right_quod <-
		quads3d(
			chamber_corners[right.v,],
			color=gray(0.7), front="cull", back="fill", lit=FALSE
	)
	
	# Left
	left_quod <-
		quads3d(
			chamber_corners[left.v,],
			color=gray(0.7), front="fill", back="cull", lit=FALSE
	)
	
	# Top
	top_quod <-
		quads3d(
			chamber_corners[top.v,],
			color=gray(0.3), front="cull", back="fill", lit=FALSE
	)
	
	
	# Add some arrows for orientation
	
	## Arrows along the bottom-left and bottom-right sides of the dryer
	arrow3d(c(left.x, back.y, bottom.z), c(left.x, front.y, bottom.z),
	        s = BARB_SIZE, type = "rotation")
	arrow3d(c(right.x, back.y, bottom.z), c(right.x, front.y, bottom.z),
	        s = BARB_SIZE, type = "rotation")
	
	## Arrows along the back-left and back-right sides of the dryer, pointing up
	arrow3d(c(left.x, back.y, bottom.z), c(left.x, back.y, top.z),
	        s = BARB_SIZE, type = "rotation")
	arrow3d(c(right.x, back.y, bottom.z), c(right.x, back.y, top.z),
	        s = BARB_SIZE, type = "rotation")

}
	


make_frame <- function(dataset) {
	# Eventually this should consist of raw commands only...
  
	plot3d( x = dataset$TrayCol,
		y = dataset$TrayRow,
		z = dataset$Tray,
		col = colors(scaled_medians(dataset)),
		size = 1.5, type = "n",
		xlim = c(0,11), ylim = c(0.5,5.5), zlim = c(0, 21),
		xlab = "", ylab = "", zlab = "",
		box = FALSE, axes = FALSE)
	
	# Remove axes!
	
	#title3d(main="Chamber")
}



add_plates <- function(dataset) {
	
  # Define the geometry for a single plate
	plate <- cube3d(scaleMatrix(PLATE_WIDTH, PLATE_DEPTH, PLATE_HEIGHT))
	
	x <- dataset$TrayCol
	y <- dataset$TrayRow
	z <- dataset$Tray + PLATE_HEIGHT
	col <- colors(scaled_medians(dataset))
	
	# Create a list of plate objects
	plates <- shapelist3d(plate, x = x, y = y, z = z, color = col, lit = FALSE)
	# RGL 0.100.19 has a bug where the class of the result of shapelist3d isn't
	# correct.  It should be set to c("shapelist3d", "shape3d"):
	class(plates) <- c("shapelist3d", "shape3d")
	
	wire3d(plates, color="black")
}



draw_scene <- function(readings, draw_dryer = TRUE, rm_bad = TRUE) {
  # rm_bad : Remove bad plates?
	
  # Get the location in the dryer of each plate
  dataset <- merge_readings_loc(readings)
  
  # Filter out any missing plates
  dataset <- dataset[dataset$Category != "missing",]
  
  # Filter out any bad plates, if desired
  if (rm_bad) {
    dataset <- dataset[dataset$Category != "bad",]
  }
  
  
  # Now render this
  
  open3d()
  make_frame(dataset)
  
  # Build the dryer, if desired
  if (draw_dryer) {
    build_dryer()
  }
  
  add_plates(dataset)
  
  # Return a reference to the rendering device (invisibly)
  dev <- rgl.cur()
  invisible(dev)
}


# Rotate a rendered dryer model about the Z-axis in real time (really cool!)
rotate_chamber <- function(device = rgl.cur()) {
  # device:  The RGL device of the image to rotate
	
  if (device!=rgl.cur()) {
    olddev <- rgl.cur()
    on.exit({rgl.set(olddev)})
    rgl.set(device)
  }
	
	play3d(spin3d(rpm=3, axis=c(0,0,1)), 20)
}


# Render the plot in a browser.
#
# It's really cool to see this rendered in a browser, but it's slow as molasses!
render_webgl <- function(readings, draw_dryer = TRUE, rm_bad = TRUE, ...) {
  
  draw_scene(readings, draw_dryer = draw_dryer, rm_bad = rm_bad)
  writeWebGL(...)
  
}


# Pan around the dryer (freakin' awesome!)
animate_scene <- function(device = rgl.cur(), speed = 1,
                          save = FALSE, ...) {
  
  # Get the current orientation
  M <- par3d("userMatrix")
  
  # The rotation matrices:
  
  M1 <-
    matrix(c(0.151658296585083, 0.115712389349937, -0.981634855270386, 
           0, -0.988232135772705, -0.00218606297858059, -0.15293525159359, 
           0, -0.0198423117399216, 0.993278563022614, 0.11401928961277, 
           0, 0, 0, 0, 1), nrow = 4L)
  
  M2 <-
    matrix(c(0.999962329864502, -0.00171241408679634, -0.0080450838431716, 
             0, -0.0035510822199285, -0.972111225128174, -0.234476760029793, 
             0, -0.00741934450343251, 0.234497383236885, -0.97208434343338, 
             0, 0, 0, 0, 1), nrow = 4L)
  
  M3 <-
    matrix(c(0.161702886223793, -0.037893284112215, 0.986104488372803, 
             0, 0.986806213855743, -0.00103915121871978, -0.161857977509499, 
             0, 0.00715823564678431, 0.999274253845215, 0.0372256189584732, 
             0, 0, 0, 0, 1), nrow = 4L)
  
  M4 <-
    matrix(c(-0.281097531318665, 0.00732422946020961, -0.959649682044983, 
             0, -0.95947128534317, 0.018594067543745, 0.281187176704407, 0, 
             0.0199033077806234, 0.999798595905304, 0.00180055166129023, 0, 
             0, 0, 0, 1), nrow = 4L)
  
  M5 <-
    matrix(c(-0.13795031607151, -0.0990343615412712, 0.985473096370697, 
             0, 0.990430414676666, -0.0173882991075516, 0.136896789073944, 
             0, 0.00357817206531763, 0.994929254055023, 0.100485555827618, 
             0, 0, 0, 0, 1), nrow = 4L)
  
  M6 <-
    matrix(c(-0.999168574810028, -0.00937796570360661, -0.0395828522741795, 
             0, -0.00994312763214111, -0.887239694595337, 0.461193978786469, 
             0, -0.0394445993006229, 0.46120548248291, 0.886411726474762, 
             0, 0, 0, 0, 1), nrow = 4L)
  
  M8 <-
    matrix(c(-0.452049046754837, -0.408395260572433, 0.793009221553802, 
             0, 0.89179390668869, -0.225671976804733, 0.392140775918961, 0, 
             0.0188115555793047, 0.884468197822571, 0.466219514608383, 0, 
             0, 0, 0, 1), nrow = 4L)
  
  
  # The sequence of rotation events 
  events <- list(M, M4, M4, M2, M2, M)
  
  # The delay between transitions and the duration of each rotation
  delay <- 2  # s
  dur <- 10  # s
  
  # The durations of the rotations
  durations <- c(dur, delay, dur, delay, dur)
  
  
  # The sequence of rotation transformations and the times of each
  # transformation (in seconds)
  times <- cumsum(c(0, durations)) * speed  # s
  
  # Now move the scene
  move <- 
    par3dinterp(
      times = times,
      userMatrix = events,
      # Linear extrapolation appears more natural than smooth transitions
      # (like cubic splines)
      method = "linear", extrapolate = "constant"
    )
  
  # Play the animation, or save it as an .mpeg file
  if (save) {
    movie3d(move, duration=70, ...)   
  } else {
    play3d(move, duration=70, ...)    
  }

}