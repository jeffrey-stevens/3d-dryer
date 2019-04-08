
# No need to install packrat; should bootstrap itself

message("Installing dependencies...\nPlease be patient; this could take a very long time!")
packrat::restore(prompt = FALSE, restart = interactive())

