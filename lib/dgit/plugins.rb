# encoding: utf-8
#
# This file is part of Diggit.
#
# Diggit is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Diggit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Diggit.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2015 Jean-Rémy Falleri <jr.falleri@gmail.com>

require 'dgit/core'

module Diggit
	# Base class for plugins. They have associated options.
	#
	# @abstract Abstract superclass for all plugins.
	# @!attribute [r] options
	# 	@return [Hash<String, Object>] the hash of options.
	class Plugin
		attr_reader :options

		def initialize(options)
			@options = options
		end

		def name
			self.class.name
		end

		def self.name
			to_s.underscore
		end

		def repo
			@source.repository
		end
	end

	class Addon < Plugin
		def initialize(options)
			super(options)
		end
	end

	# Base class for analyses and joins.
	# Runnables can be runned or cleaned.
	# A clean of a runnable should always work, even if it has never been run.
	# These methods have to be implemented in the subclasses.
	# Addons can be made available to a runnable through a call to {.require\_addons}.
	# Addons can be accessed through the addons attribute, and they contain
	# automatically methods that has names of their addons.
	# @see Addon
	# @abstract Abstract superclass for analysis and joins.
	# @!attribute [r] addons
	# 	@return [Hash<String, Addon>] the hash of addons.
	class Runnable < Plugin
		attr_reader :addons

		def initialize(options)
			super(options)
			@addons = {}
			self.class.required_addons.each { |a| @addons[a] = Dig.it.plugin_loader.load_plugin(a, :addon, true) }
			@addons.each_key { |a| self.class.class_eval { define_method(a) { return @addons[a] } } }
		end

		# Run the runnable.
		# @abstract This method must be overrided.
		# @return [void]
		def run
		end

		# Clean the runnable.
		# @abstract This method must be overrided.
		# @return [void]
		def clean
		end

		# Add an addon as a required addon.
		#
		# @param names Array<String> the names of addons to require.
		# 	They correspond to the name of their class with underscore case.
		# @return [void]
		def self.require_addons(*names)
			@required_addons = names
		end

		def self.required_addons
			base_addons = superclass < Runnable ? superclass.required_addons : []
			return base_addons if @required_addons.nil?
			base_addons + @required_addons
		end
	end

	# Base class for joins. Joins are applied on each source that has been:
	# 1. succesfully cloned,
	# 2. has been analyzed by the required analyses.
	# Required analyses are added with a call to {.require\_analyses}.
	# They can access addons through the addons attribute or with a method having the addon name.
	# @see Runnable
	# @abstract Subclass and override run and clean to implement a custom join class.
	# @!attribute [rw] sources
	# 	@return [Array<Source>] the sources to be joined.
	# @example A sample join using an addon.
	# 	class JoinWithAddon < Diggit::Join
	# 		require_addons "db"
	#
	# 		def run
	# 			db.do_something
	# 			puts @options
	# 			puts @sources
	# 			puts "Runned!"
	# 		end
	#
	# 		def clean
	# 			puts "Cleaned!"
	# 		end
	# 	end
	class Join < Runnable
		attr_accessor :sources

		def initialize(options)
			super(options)
			@sources = []
		end

		# Add an analysis as a required analysis.
		#
		# @param names Array<String> the names of analyses to require.
		# 	They correspond to the name of their class with underscore case.
		# @return [void]
		def self.require_analyses(*names)
			@required_analyses = names
		end

		def self.required_analyses
			return [] if @required_analyses.nil?
			@required_analyses
		end
	end

	# Base class for analyses. Diggit analyses are applied on each source that has been succesfully cloned.
	# They can access the Diggit addons through the addons attribute.
	# @see Runnable
	# @abstract Subclass and override run and clean to implement a custom analysis class.
	# @!attribute [rw] source
	# 	@return [Source] the source to be analyzed.
	# @example A sample analysis using an addon
	# 	class AnalysisWithAddon < Diggit::Analysis
	# 		require_addons "db"
	#
	# 		def run
	# 			db.do_something
	# 			puts @options
	# 			puts @source
	# 			puts "Runned!"
	# 		end
	#
	# 		def clean
	# 			puts "Cleaned!"
	# 		end
	# 	end
	class Analysis < Runnable
		attr_accessor :source

		def initialize(options)
			super(options)
			@source = nil
		end
	end
end
