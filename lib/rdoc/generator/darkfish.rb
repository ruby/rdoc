#!ruby

require 'rubygems'
gem 'rdoc', '>= 2.3'

require 'pp'
require 'pathname'
require 'fileutils'
require 'erb'
require 'yaml'

require 'rdoc/rdoc'
require 'rdoc/generator/xml'
require 'rdoc/generator/html'

#
#  Darkfish RDoc HTML Generator
#  
#  $Id: darkfish.rb 52 2009-01-07 02:08:11Z deveiant $
#
#  == Author/s
#  * Michael Granger (ged@FaerieMUD.org)
#  
#  == Contributors
#  * Mahlon E. Smith (mahlon@martini.nu)
#  * Eric Hodel (drbrain@segment7.net)
#  
#  == License
#  
#  Copyright (c) 2007, 2008, Michael Granger. All rights reserved.
#  
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#  
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  
#  * Neither the name of the author/s, nor the names of the project's
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#  
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#  
class RDoc::Generator::Darkfish < RDoc::Generator::XML

	RDoc::RDoc.add_generator( self )

	include ERB::Util

	# Subversion rev
	SVNRev = %$Rev: 52 $
	
	# Subversion ID
	SVNId = %$Id: darkfish.rb 52 2009-01-07 02:08:11Z deveiant $

	# Path to this file's parent directory. Used to find templates and other
	# resources.
	GENERATOR_DIR = Pathname.new( __FILE__ ).expand_path.dirname

	# Release Version
	VERSION = '1.1.6'

	# Directory where generated classes live relative to the root
	CLASS_DIR = nil

	# Directory where generated files live relative to the root
	FILE_DIR = nil


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	### Standard generator factory method
	def self::for( options )
		new( options )
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Initialize a few instance variables before we start
	def initialize( options )
		@template = nil
		@template_dir = GENERATOR_DIR + 'template/darkfish'
		
		@files      = []
		@classes    = []
		@hyperlinks = {}

		@basedir = Pathname.pwd.expand_path

		options.inline_source = true
		options.diagram = false

		super
	end
	
	
	######
	public
	######

	# The output directory
	attr_reader :outputdir
	
	
	### Output progress information if debugging is enabled
	def debug_msg( *msg )
		return unless $DEBUG
		$stderr.puts( *msg )
	end
	
	
	### Create the directories the generated docs will live in if
	### they don't already exist.
	def gen_sub_directories
		@outputdir.mkpath
	end
	

	### Copy over the stylesheet into the appropriate place in the
	### output directory.
	def write_style_sheet
		debug_msg "Copying over static files"
		staticfiles = %w[rdoc.css js images]
		staticfiles.each do |path|
			FileUtils.cp_r( @template_dir + path, '.', :verbose => $DEBUG, :noop => $dryrun )
		end
	end
	
	

	### Build the initial indices and output objects
	### based on an array of TopLevel objects containing
	### the extracted information. 
	def generate( toplevels )
		@outputdir = Pathname.new( @options.op_dir ).expand_path( @basedir )
		if RDoc::Generator::Context.respond_to?( :build_indicies)
	    	@files, @classes = RDoc::Generator::Context.build_indicies( toplevels, @options )
		else
	    	@files, @classes = RDoc::Generator::Context.build_indices( toplevels, @options )
		end

		# Now actually write the output
		generate_xhtml( @options, @files, @classes )

	rescue StandardError => err
		debug_msg "%s: %s\n  %s" % [ err.class.name, err.message, err.backtrace.join("\n  ") ]
		raise
	end


	### No-opped
	def load_html_template # :nodoc:
	end


	### Generate output
	def generate_xhtml( options, files, classes )
		files = gen_into( @files )
		classes = gen_into( @classes )

		# Make a hash of class info keyed by class name
		classes_by_classname = classes.inject({}) {|hash, classinfo|
			hash[ classinfo[:full_name] ] = classinfo
			hash[ classinfo[:full_name] ][:outfile] =
				classinfo[:full_name].gsub( /::/, '/' ) + '.html'
			hash
		}

		# Make a hash of file info keyed by path
		files_by_path = files.inject({}) {|hash, fileinfo|
			hash[ fileinfo[:full_path] ] = fileinfo
			hash[ fileinfo[:full_path] ][:outfile] = fileinfo[:full_path] + '.html'
			hash
		}

		self.write_style_sheet
		self.generate_index( options, files_by_path, classes_by_classname )
		self.generate_class_files( options, files_by_path, classes_by_classname )
		self.generate_file_files( options, files_by_path, classes_by_classname )
	end



	#########
	protected
	#########

	### Return a list of the documented modules sorted by salience first, then by name.
	def get_sorted_module_list( classes )
		nscounts = classes.keys.inject({}) do |counthash, name|
			toplevel = name.gsub( /::.*/, '' )
			counthash[toplevel] ||= 0
			counthash[toplevel] += 1
			
			counthash
		end

		# Sort based on how often the toplevel namespace occurs, and then on the name 
		# of the module -- this works for projects that put their stuff into a 
		# namespace, of course, but doesn't hurt if they don't.
		return classes.keys.sort_by do |name| 
			toplevel = name.gsub( /::.*/, '' )
			[
				nscounts[ toplevel ] * -1,
				name
			]
		end
	end
	
	
	### Generate an index page which lists all the classes which
	### are documented.
	def generate_index( options, files, classes )
		debug_msg "Rendering the index page..."

		templatefile = @template_dir + 'index.rhtml'
		template_src = templatefile.read
		template = ERB.new( template_src, nil, '<>' )
		template.filename = templatefile.to_s
		context = binding()

		modsort = self.get_sorted_module_list( classes )
		output = nil
		begin
			output = template.result( context )
		rescue NoMethodError => err
			raise "Error while evaluating %s: %s (at %p)" % [
				templatefile,
				err.message,
				eval( "_erbout[-50,50]", context )
			]
		end

		outfile = @basedir + @options.op_dir + 'index.html'
		unless $dryrun
			debug_msg "Outputting to %s" % [outfile.expand_path]
			outfile.open( 'w', 0644 ) do |fh|
				fh.print( output )
			end
		else
			debug_msg "Would have output to %s" % [outfile.expand_path]
		end
	end



	### Generate a documentation file for each class present in the
	### given hash of +classes+.
	def generate_class_files( options, files, classes )
		debug_msg "Generating class documentation in #@outputdir"
		templatefile = @template_dir + 'classpage.rhtml'
		outputdir = @outputdir

		modsort = self.get_sorted_module_list( classes )

		classes.sort_by {|k,v| k }.each do |classname, classinfo|
			debug_msg "  working on %s (%s)" % [ classname, classinfo[:outfile] ]
			outfile    = outputdir + classinfo[:outfile]
			rel_prefix = outputdir.relative_path_from( outfile.dirname )
			svninfo    = self.get_svninfo( classinfo )

			debug_msg "  rendering #{outfile}"
			self.render_template( templatefile, binding(), outfile )
		end
	end


	### Generate a documentation file for each file present in the
	### given hash of +files+.
	def generate_file_files( options, files, classes )
		debug_msg "Generating file documentation in #@outputdir"
		templatefile = @template_dir + 'filepage.rhtml'

		modsort = self.get_sorted_module_list( classes )

		files.sort_by {|k,v| k }.each do |path, fileinfo|
			outfile     = @outputdir + fileinfo[:outfile]
			debug_msg "  working on %s (%s)" % [ path, outfile ]
			rel_prefix  = @outputdir.relative_path_from( outfile.dirname )
			context     = binding()

			debug_msg "  rendering #{outfile}"
			self.render_template( templatefile, binding(), outfile )
		end
	end


	### Return a string describing the amount of time in the given number of
	### seconds in terms a human can understand easily.
	def time_delta_string( seconds )
		return 'less than a minute' if seconds < 1.minute 
		return (seconds / 1.minute).to_s + ' minute' + (seconds/60 == 1 ? '' : 's') if seconds < 50.minutes
		return 'about one hour' if seconds < 90.minutes
		return (seconds / 1.hour).to_s + ' hours' if seconds < 18.hours
		return 'one day' if seconds < 1.day
		return 'about one day' if seconds < 2.days
		return (seconds / 1.day).to_s + ' days' if seconds < 1.week
		return 'about one week' if seconds < 2.week
		return (seconds / 1.week).to_s + ' weeks' if seconds < 3.months
		return (seconds / 1.month).to_s + ' months' if seconds < 1.year
		return (seconds / 1.year).to_s + ' years'
	end


	# %q$Id: darkfish.rb 52 2009-01-07 02:08:11Z deveiant $"
	SVNID_PATTERN = /
		\$Id:\s 
			(\S+)\s					# filename
			(\d+)\s					# rev
			(\d{4}-\d{2}-\d{2})\s	# Date (YYYY-MM-DD)
			(\d{2}:\d{2}:\d{2}Z)\s	# Time (HH:MM:SSZ)
			(\w+)\s				 	# committer
		\$$
	/x

	### Try to extract Subversion information out of the first constant whose value looks like
	### a subversion Id tag. If no matching constant is found, and empty hash is returned.
	def get_svninfo( classinfo )
		return {} unless classinfo[:sections]
		constants = classinfo[:sections].first[:constants] or return {}
	
		constants.find {|c| c[:value] =~ SVNID_PATTERN } or return {}

		filename, rev, date, time, committer = $~.captures
		commitdate = Time.parse( date + ' ' + time )
		
		return {
			:filename    => filename,
			:rev         => Integer( rev ),
			:commitdate  => commitdate,
			:commitdelta => time_delta_string( Time.now.to_i - commitdate.to_i ),
			:committer   => committer,
		}
	end


	### Load and render the erb template in the given +templatefile+ within the specified 
	### +context+ (a Binding object) and write it out to +outfile+. Both +templatefile+ and 
	### +outfile+ should be Pathname-like objects.
	def render_template( templatefile, context, outfile )
		template_src = templatefile.read
		template = ERB.new( template_src, nil, '<>' )
		template.filename = templatefile.to_s

		output = begin
			template.result( context )
		rescue NoMethodError => err
			raise "Error while evaluating %s: %s (at %p)" % [
				templatefile.to_s,
				err.message,
				eval( "_erbout[-50,50]", context )
			]
		end

		unless $dryrun
			outfile.dirname.mkpath
			outfile.open( 'w', 0644 ) do |ofh|
				ofh.print( output )
			end
		else
			debug_msg "  would have written %d bytes to %s" %
			[ output.length, outfile ]
		end
	end

end # Roc::Generator::Darkfish

# :stopdoc:

### Time constants
module TimeConstantMethods # :nodoc:
	
	### Number of seconds (returns receiver unmodified)
	def seconds
		return self
	end
	alias_method :second, :seconds

	### Returns number of seconds in <receiver> minutes
	def minutes
		return self * 60
	end
	alias_method :minute, :minutes  

	### Returns the number of seconds in <receiver> hours
	def hours
		return self * 60.minutes
	end
	alias_method :hour, :hours

	### Returns the number of seconds in <receiver> days
	def days
		return self * 24.hours
	end
	alias_method :day, :days

	### Return the number of seconds in <receiver> weeks
	def weeks
		return self * 7.days
	end
	alias_method :week, :weeks

	### Returns the number of seconds in <receiver> fortnights
	def fortnights
		return self * 2.weeks
	end
	alias_method :fortnight, :fortnights

	### Returns the number of seconds in <receiver> months (approximate)
	def months
		return self * 30.days
	end
	alias_method :month, :months

	### Returns the number of seconds in <receiver> years (approximate)
	def years
		return (self * 365.25.days).to_i
	end
	alias_method :year, :years


	### Returns the Time <receiver> number of seconds before the 
	### specified +time+. E.g., 2.hours.before( header.expiration )
	def before( time )
		return time - self
	end
	

	### Returns the Time <receiver> number of seconds ago. (e.g., 
	### expiration > 2.hours.ago )
	def ago
		return self.before( ::Time.now )
	end


	### Returns the Time <receiver> number of seconds after the given +time+.
	### E.g., 10.minutes.after( header.expiration )
	def after( time )
		return time + self
	end

	# Reads best without arguments:  10.minutes.from_now
	def from_now
		return self.after( ::Time.now )
	end
end # module TimeConstantMethods


# Extend Numeric with time constants
class Numeric # :nodoc:
	include TimeConstantMethods
end

