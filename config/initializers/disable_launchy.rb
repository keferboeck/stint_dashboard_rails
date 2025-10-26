# If any code still tries to use the plain :letter_opener (which uses Launchy),
# this disables the auto-open behavior.
ENV["LAUNCHY_DRY_RUN"] = "true"