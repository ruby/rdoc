# frozen_string_literal: true

##
# Aliki RDoc HTML Generator - A modern documentation theme
#
# Based on Darkfish by Michael Granger (ged@FaerieMUD.org)
#
# == Description
#
# Aliki brings modern design patterns to RDoc documentation with:
#
# * Three-column responsive layout (navigation, content, table of contents)
# * Dark mode support with theme toggle and localStorage persistence
# * Auto-generated right sidebar TOC with scroll spy (Intersection Observer)
# * Mobile-optimized search modal with keyboard shortcuts
# * Enhanced syntax highlighting for light and dark themes
# * Responsive design with mobile navigation
# * Zero additional JavaScript dependencies
# * Modern CSS Grid and Flexbox layout
#
# == Usage
#
#   rdoc --format=aliki --op=doc/
#
# == Author
#
# Based on Darkfish by Michael Granger
# Modernized as Aliki theme by Stan Lo
#

class RDoc::Generator::Aliki < RDoc::Generator::Darkfish

  RDoc::RDoc.add_generator self

  ##
  # Version of the Aliki generator

  VERSION = '1'

  ##
  # Description of this generator

  DESCRIPTION = 'Modern HTML generator based on Darkfish'

  ##
  # Initialize the Aliki generator with the aliki template directory

  def initialize(store, options)
    super
    aliki_template_dir = File.expand_path(File.join(__dir__, 'template', 'aliki'))
    @template_dir = Pathname.new(aliki_template_dir)
  end

  ##
  # Copy only the static assets required by the Aliki theme. Unlike Darkfish we
  # don't ship embedded fonts or image sprites, so limit the asset list to keep
  # generated documentation lightweight.

  def write_style_sheet
    debug_msg "Copying Aliki static files"
    options = { verbose: $DEBUG_RDOC, noop: @dry_run }

    install_rdoc_static_file @template_dir + 'css/rdoc.css', "./css/rdoc.css", options

    unless @options.template_stylesheets.empty?
      FileUtils.cp @options.template_stylesheets, '.', **options
    end

    Dir[(@template_dir + 'js/**/*').to_s].each do |path|
      next if File.directory?(path)
      next if File.basename(path).start_with?('.')

      dst = Pathname.new(path).relative_path_from(@template_dir)

      install_rdoc_static_file @template_dir + path, dst, options
    end
  end
end
