# frozen_string_literal: true

# Generate all parse files using racc and kpeg. This is not necessary for regular gem installation, but it is when
# installing RDoc from the git source. Without this, the generated parse files would not exist and RDoc would not work
system("rake generate") if File.exist?("../../.git")

# RDoc doesn't actually have a native extension, but a Makefile needs to exist in order to successfully install the gem
require "mkmf"
create_makefile("rdoc/rdoc")
