# Install packrat if it isn't already installed
#
# Keep this minimally invasive; simply calling install.packages() may update the
# package, modifying the user's install.  Instead, only install it if it isn't
# already installed.
#
# Note that this could lead to problems if a very old version of packrat is
# installed...
if ( !("packrat" %in% rownames(installed.packages())) ) {
  install.packages("packrat") 
}


message("Installing dependencies...\nPlease be patient; this could take a very long time!")
packrat::restore(prompt = FALSE, restart = interactive())

