# 3D Microtiter Plate Dryer

![](https://github.com/jeffrey-stevens/3d-dryer/dryer-movie.gif)

Microtiter plate ELISAs can be a pain to manufacture.  Back in 2014 -- 2015 I
was tasked with investigating the cause of high manufacturing failure of
one of our leading products.

Deep into the investigation it became clear that something was up with the
drying process.  To help us visualize the problem, I created a 3D representation
of how each plate of a rejected plate lot was arranged spatially in our
industrial dryers. This visualization ultimately pointed me to the root cause of
failure for this defect.

This is a recreation of that program.  The shade of blue indicates the median
signal of the plate upon testing---white means low signal, blue means high
signal (high is good).  The original dataset isn't available, but here I did my
best to simulate the pattern of the original data set.


## To run

This was written in RGL---a high-level OpenGL interface for R.  You'll need a
recent version of R to run this script.

First, source `"build.R"` in R to install the package dependencies.  Note that this
will take some time.  This only needs to be done once.

To run a demo, source `"run.R"` in an R session, then type `run()` to open the 3D
plot.  Note that the window may be hidden behind others, so you may have to
activate it manually.  This will show the dryer head-on.  Just click and drag
the mouse within the window to view the dryer from different perspectives.  Or
cooler yet, run `run(animate = TRUE)` and sit back for a leisurely tour!


## A cautionary tale...

So, can you see where the problem is?  Clearly there's something wrong with the
dryer, right?  Not so fast!

The plates were loaded sequentially on trays, from the front of the bottom tray,
then back, then to the front of the next tray.  Thus the loading order was
confounded with the position in the dryer.  To decouple these two factors, I
initiated a coating and loaded the dryers as usual, but then swapped plates
from the "good" and "bad" reagions just before turning the dryers on (a "swap"
experiment).  The defect _followed the moved plates_---the location in the dryer
had no effect!

It turns out that the immobolized ELISA analyte was particularly sensitive to air
drying. It takes about an hour to fill one of these dryers during a production
run.  The plates loaded first (the ones at the bottom) were "exposed" for longer
than the plates at the top. And presumably the plates toward the back of the
dryer were more sheltered from evaporation than the ones toward the front.
Stabilizing the analyte through this loading phase completely eliminated the
problem!