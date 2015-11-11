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
# Copyright 2015 Matthieu Foucault <foucaultmatthieu@gmail.com>

require 'oj'
require 'rugged'
require 'singleton'
require_relative 'log'
require_relative 'entries'

class String
	# Returns a underscore cased version of the string.
	# @return [String]
	def underscore
		gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
				.gsub(/([a-z\d])([A-Z])/, '\1_\2'). tr("-", "_").downcase
	end

	# Returns a camel cased version of the string.
	# @return [String]
	def camel_case
		return self if self !~ /_/ && self =~ /[A-Z]+.*/
		split('_').map(&:capitalize).join
	end

	# Returns a version of the string that can be safely used as a folder name.
	# @return [string]
	def id
		gsub(/[^[\w-]]+/, "_")
	end
end

class Module
	# Return the simple name of a module.
	# The simple name is the underscore cased name of the module without namespaces.
	# FIXME: name returns module/class instead of module::class.
	def simple_name
		to_s.gsub(/^.*::/, '').underscore
	end
end

module Diggit
	class Source
		attr_reader :url, :repository, :entry

		def initialize(url)
			@url = url
			@entry = SourceEntry.new
			@repository = nil
		end

		def id
			@url.id
		end

		def folder
			Dig.it.file_path("sources/#{id}")
		end

		def clone
			@entry.error = nil
			if File.exist?(folder)
				Rugged::Repository.new(folder)
			else
				Rugged::Repository.clone_at(url, folder)
			end
			@entry.state = :cloned
		rescue => e
			Log.error "Error cloning #{url}."
			@entry.error = e
		end

		def load_repository
			fail "Source not cloned #{url}." if @entry.new?
			@repository = Rugged::Repository.new(folder)
			@repository.checkout("origin/master")
		end
	end

	class Journal
		attr_reader :sources, :workspace

		def initialize
			@sources = {}
			@workspace = WorkspaceEntry.new
		end

		def sources
			@sources.values
		end

		def sources_by_state(state, error = false)
			@sources.select { |_u, s| s.state == state && s.error? == error }.values
		end

		def sources_by_ids(*ids)
			return sources if ids.empty?
			source_array = sources
			result = []
			ids.each do |id|
				fail "No such source index #{id}." if id >= source_array.length
				result << source_array[id]
			end
			result
		end

		def source?(url)
			@sources.key?(url)
		end

		def add_source(url)
			@sources[url] = Source.new(url) unless @sources.key?(url)
			Dig.it.save_journal
		end
	end

	class Config
		attr_reader :analyses, :joins

		def initialize(hash)
			@analyses = []
			@joins = []
			hash[:analyses].each { |a| load_analysis(a) }
			hash[:joins].each { |j| load_join(j) }
		end

		def to_hash
			{ analyses: @analyses.map(&:simple_name), joins: @joins.map(&:simple_name) }
		end

		def add_analysis(name)
			load_analysis(name) unless @analyses.map(&:simple_name).include?(name)
			Dig.it.save_config
		end

		def load_analysis(name)
			@analyses << Dig.it.plugin_loader.load_plugin(name, :analysis)
		end

		def del_analysis(name)
			@analyses.delete_if { |a| a.simple_name == name }
			Dig.it.save_config
		end

		def del_all_analyses
			@analyses = []
			Dig.it.save_config
		end

		def get_analyses(*names)
			return analyses if names.empty?
			analyses.select { |a| names.include?(a.simple_name) }
		end

		def add_join(name)
			load_join(name) unless @joins.map(&:simple_name).include?(name)
			Dig.it.save_config
		end

		def load_join(name)
			@joins << Dig.it.plugin_loader.load_plugin(name, :join)
		end

		def del_join(name)
			@joins.delete_if { |j| j.simple_name == name }
			Dig.it.save_config
		end

		def del_all_joins
			@joins = []
			Dig.it.save_config
		end

		def get_joins(*names)
			return joins if names.empty?
			joins.select { |j| joins.include?(j.simple_name) }
		end

		def self.empty_config
			{ analyses: [], joins: [] }
		end
	end

	# Class to handle loading of diggit plugins.
	# Diggit plugins are defined in camel cased classes derived from Plugin.
	# Their name is the underscore cased version of the class name (example +MyPlugin+ becomes +my_plugin+).
	# It uses a singleton pattern, so you have to create an instance like that:
	# @example
	# 	PluginLoader.instance
	# @see Plugin
	class PluginLoader
		include Singleton

		PLUGINS_TYPES = [:addon, :analysis, :join]

		# Load the plugin with the given name and type.
		# @param name [String] the name of the plugin
		# @param type [Symbol] the type of the plugin: +:addon+, +:analysis+ or +:join+.
		# @param instance [Boolean] +true+ for retrieving an instance or +false+ for retrieving the class.
		# @return [Plugin, Class] the instance or class of the plugin.
		def load_plugin(name, type, instance = false)
			plugin = search_plugin(name, type)
			if plugin
				if instance
					return plugin.new(Dig.it.options)
				else
					return plugin
				end
			else
				fail "Plugin #{name} not found."
			end
		end

		def self.plugin_paths(name, type, root)
			Dir.glob(File.join(root, 'plugins', type.to_s, '**{,/*/**}', "#{name}.rb"))
		end

		# Constructor. Should not be called directly. Use {.instance} instead.
		# @return [PluginLoader]
		def initialize
			@plugins = {}
		end

			private

		def search_plugin(name, type)
			return @plugins[name] if @plugins.key?(name)
			fail "Unknown plugin type #{type}." unless PLUGINS_TYPES.include?(type)
			fail "File #{name}.rb in #{type} directories not found." unless load_file(name, type)

			base_class = Object.const_get("Diggit::#{type.to_s.camel_case}")
			plugins = ObjectSpace.each_object(Class).select { |c| c < base_class && c.simple_name == name }

			fail "No plugin #{name} of kind #{type} found." if plugins.empty?
			warn "Ambiguous plugin name: several plugins of kind #{type} named #{name} were found." if plugins.size > 1

			@plugins[name] = plugins[0]
			plugins[0]
		end

		def load_file(name, type)
			f_glob = PluginLoader.plugin_paths(name, type, File.expand_path('../..', File.dirname(File.realpath(__FILE__))))
			f_home = PluginLoader.plugin_paths(name, type, File.join(Dir.home, Dig::DGIT_FOLDER))
			f_local = PluginLoader.plugin_paths(name, type, Dig.it.folder)
			Log.debug "Plugin files in global: #{f_glob}."
			Log.debug "Plugin files in home: #{f_home}."
			Log.debug "Plugin files in local directory: #{f_local}."
			found = true
			if !f_local.empty?
				f_local.each { |f| require File.expand_path(f) }
			elsif !f_home.empty?
				f_home.each { |f| require File.expand_path(f) }
			elsif !f_glob.empty?
				f_glob.each { |f| require File.expand_path(f) }
			else
				found = false
			end
			found
		end
	end

	# Main diggit class.
	# It must be runned in a folder containing a +.dgit+ folder with a proper configuration.
	# Access configuration, options, sources and journal from this object.
	# It implements the singleton pattern.
	# You can initialize it via {.init} and retrieve the instance via {.it}.
	# @!attribute [r] config
	# 	@return [Config] the config.
	# @!attribute [r] options
	# 	@return [Hash<String,Object>] the options.
	# @!attribute [r] journal
	# 	@return [Journal] the journal.
	# @!attribute [r] folder
	# 	@return [String] the folder in which diggit is running.
	# @!attribute [r] plugin_loader
	# 	@return [PluginLoader] utility classes to load plugins.
	class Dig
		DGIT_FOLDER = ".dgit"
		DGIT_SOURCES = "sources"
		DGIT_CONFIG = "config"
		DGIT_OPTIONS = "options"
		DGIT_JOURNAL = "journal"

		private_constant :DGIT_SOURCES, :DGIT_CONFIG, :DGIT_OPTIONS, :DGIT_JOURNAL

		attr_reader :config, :options, :journal, :plugin_loader, :folder

		@diggit = nil

		# Returns the diggit instance.
		# @return [Dig] the instance.
		def self.it
			fail "Diggit has not been initialized." if @diggit.nil?
			@diggit
		end

		# Initialize and return the diggit instance into the given folder.
		# @param folder [String] the path to the folder.
		# @return [Dig] the instance.
		def self.init(folder = '.')
			@diggit = Dig.new(folder)
			@diggit.load_options
			@diggit.load_config
			@diggit.load_journal
			@diggit
		end

		# Initialize a folder to be a diggit folder by creating an empty configuration.
		# It creates a +.dgit+ folder containing a +journal+, +config+, +options+ files.
		# It creates a +sources+ folder.
		# It creates a +plugins+ folder.
		# Directory creation is skipped if folder already exist.
		# @param folder [String] the path to the folder.
		# @return [void]
		def self.init_dir(folder = '.')
			dgit_folder = File.expand_path(DGIT_FOLDER, folder)
			unless File.exist?(dgit_folder)
				FileUtils.mkdir(dgit_folder)
				Oj.to_file(File.expand_path(DGIT_CONFIG, dgit_folder), Config.empty_config)
				Oj.to_file(File.expand_path(DGIT_OPTIONS, dgit_folder), {})
				FileUtils.touch(File.expand_path(DGIT_SOURCES, dgit_folder))
				Oj.to_file(File.expand_path(DGIT_JOURNAL, dgit_folder), Journal.new)
			end
			FileUtils.mkdir(File.expand_path('sources', folder)) unless File.exist?(File.expand_path('sources', folder))
			unless File.exist?(File.expand_path("plugins", folder))
				FileUtils.mkdir_p(File.expand_path("plugins", folder))
				FileUtils.mkdir_p(File.expand_path("plugins/analysis", folder))
				FileUtils.mkdir_p(File.expand_path("plugins/addon", folder))
				FileUtils.mkdir_p(File.expand_path("plugins/join", folder))
			end
		end

		# Return the path of the given config file
		# @param name [String] name of the file
		# @return [String] the path to the file.
		def config_path(name)
			File.expand_path(name, File.expand_path(DGIT_FOLDER, @folder))
		end

		# Return the path of the given file in the diggit folder
		# @param name [String] name of the file
		# @return [String] the path to the file.
		def file_path(name)
			File.expand_path(name, @folder)
		end

		# Constructor. Should not be called directly.
		# Use {.init} and {.it} instead.
		# @return [Dig] a diggit object.
		def initialize(folder)
			fail "Folder #{folder} is not a diggit folder." unless File.exist?(File.expand_path(DGIT_FOLDER, folder))
			@plugin_loader = PluginLoader.instance
			@folder = folder
		end

		# Load the journal from +.dgit/journal+
		# @return [void]
		def load_journal
			url_array = []
			IO.readlines(config_path(DGIT_SOURCES)).each { |l| url_array << l.strip }
			@journal = Oj.load_file(config_path(DGIT_JOURNAL))
			url_array.each do |url|
				@journal.add_source(url)
			end
		end

		# Save the journal to +.dgit/journal+
		# @return [void]
		def save_journal
			File.open(config_path(DGIT_SOURCES), "w") { |f| @journal.sources.each { |source| f.puts(source.url) } }
			Oj.to_file(config_path(DGIT_JOURNAL), @journal, indent: 2)
		end

		# Load the options from +.dgit/options+
		# @return [void]
		def load_options
			@options = Oj.load_file(config_path(DGIT_OPTIONS))
		end

		# Save the options to +.dgit/options+
		# @return [void]
		def save_options
			Oj.to_file(config_path(DGIT_OPTIONS), options)
		end

		# Load the config from +.dgit/config+
		# @return [void]
		def load_config
			@config = Config.new(Oj.load_file(config_path(DGIT_CONFIG)))
		end

		# Save the config to +.dgit/config+
		# @return [void]
		def save_config
			config_hash = @config.to_hash
			Oj.to_file(config_path(DGIT_CONFIG), config_hash)
		end

		# Clone the repository of all sources with the given source ids.
		# @param source_ids [Array<Integer>] the ids of the sources.
		# @return [void]
		def clone(*source_ids)
			@journal.sources_by_ids(*source_ids).select { |s| s.entry.new? }.each(&:clone)
		ensure
			save_journal
		end

		# Perform the given analyses on sources with the given ids using the given mode.
		# @param source_ids [Array<Integer>] the ids of the sources.
		# @param analyses [Array<String>] the names of the analyses.
		# @param mode [Symbol] the mode: +:run+, +:rerun+ or +:clean+.
		# @return [void]
		def analyze(source_ids = [], analyses = [], mode = :run)
			@journal.sources_by_ids(*source_ids).select { |s| s.entry.cloned? }.each do |s|
				@config.get_analyses(*analyses).each do |klass|
					a = klass.new(@options)
					s.load_repository
					a.source = s
					clean(a, s.entry) if clean_mode?(mode) && s.entry.has?(a)
					run(a, s.entry) if run_mode?(mode) && !s.entry.has?(a)
				end
			end
		end

		# Perform the given joins on sources with the given ids using the given mode.
		# @param source_ids [Array<Integer>] the ids of the sources.
		# @param joins [Array<String>] the names of the analyses.
		# @param mode [Symbol] the mode: +:run+, +:rerun+ or +:clean+.
		# @return [void]
		def join(source_ids = [], joins = [], mode = :run)
			@config.get_joins(*joins).each do |klass|
				j = klass.new(@options)
				clean(j, @journal.workspace) if clean_mode?(mode) && @journal.workspace.has?(j)
				source_array = @journal.sources_by_ids(*source_ids).select do |s|
					s.entry.cloned? && (klass.required_analyses - s.entry.performed.map(&:name)).empty?
				end
				j.sources = source_array
				run(j, @journal.workspace) if run_mode?(mode) && !source_array.empty? && !@journal.workspace.has?(j)
			end
		end

			private

		def clean_mode?(mode)
			mode == :rerun || mode == :clean
		end

		def run_mode?(mode)
			mode == :rerun || mode == :run
		end

		def clean(runnable, placeholder)
			placeholder.clean(runnable)
			entry = RunnableEntry.new(runnable)
			begin
				runnable.clean
			rescue => e
				entry.toc
				entry.error = e
				placeholder.canceled << entry
				Log.error "Error cleaning #{runnable.name}"
			ensure
				save_journal
			end
		end

		def run(runnable, placeholder)
			entry = RunnableEntry.new(runnable)
			begin
				runnable.run
			rescue => e
				entry.toc
				entry.error = e
				placeholder.canceled << entry
				Log.error "Error running #{runnable.name}"
			else
				entry.toc
				placeholder.performed << entry
			ensure
				save_journal
			end
		end
	end
end
