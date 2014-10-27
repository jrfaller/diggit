#!/usr/bin/env ruby
# encoding: utf-8

require 'rugged'
require 'oj'
require 'singleton'

module Diggit

	DIGGIT_RC = '.dgitrrc'
	DIGGIT_LOG = '.dgitlog'
	DIGGIT_SOURCES = '.dgitsources'

	SOURCES_FOLDER = 'sources'
	INCLUDES_FOLDER = 'includes'
	DIGGIT_FOLDER = ".diggit"

	class Addon

		def initialize(options)
			@options = options
		end

		def name
		end

	end

	class Analysis

		def initialize(source, repo, options, addons, globs)
			@source = source
			@repo = repo
			@options = options
			@addons = addons
			@globs = globs
		end

		def run
			raise NoMethodError.new "Subclass responsability"
		end

		def clean
			raise NoMethodError.new "Subclass responsability"
		end

	end

	class Join
		def initialize(sources, options, addons, globs)
			@sources = sources
			@options = options
			@addons = addons
			@globs = globs
		end

		def run
			raise NoMethodError.new "Subclass responsability"
		end

		def clean
			raise NoMethodError.new "Subclass responsability"
		end

	end

	class Config

		def initialize
			@config = Oj.load_file(DIGGIT_RC)
		end

		def save
			Oj.to_file(DIGGIT_RC, @config)
		end

		def analyses
			@config[:analyses]
		end

		def add_analysis(analysis)
			analyses << analysis unless analyses.include?(analysis)
			save
		end

		def rem_analysis(analysis)
			analyses.delete(analysis)
			save
		end

		def load_analyses(source, repo, addons, globs)
			analyses.map{ |a| Object::const_get(a).new(source, repo, options, addons, globs) }
		end

		def addons
			return @config[:addons]
		end

		def add_addon(addon)
			addons << addon unless addons.include?(addon)
			save
		end

		def rem_addon(addon)
			addons.delete(addon)
			save
		end

		def load_addons
			result = {}
			addons.each do |a|
				obj = Object::const_get(a).new(options)
				result[obj.name] = obj
			end
			return result
		end

		def joins
			return @config[:joins]
		end

		def add_join(join)
			joins << join unless joins.include?(join)
			save
		end

		def rem_join(join)
			joins.delete(join)
			save
		end

		def load_joins(finished_sources, addons, globs)
			return joins.map{ |j| Object::const_get(j).new(finished_sources, options, addons, globs) }
		end

		def options
			return @config[:options]
		end

	end

	class Sources

		def initialize
			@log = Log.new
			@sources = []
			IO.readlines(DIGGIT_SOURCES).each{ |line| @sources << line.strip }
		end

		def size
			return @sources.size
		end

		def save
			File.open(DIGGIT_SOURCES, "w") do |f|
				@sources.each{ |s| f.puts(s) }
			end
		end

		def add(url)
			unless @sources.include?(url)
				@sources << url
				@log.init(url)
				save
			end
		end

		def rem(source_def)
			url = url(source_def)
			@sources.delete(url)
			@log.rem(url)
			save
		end

		def get(source_def)
			hash(url(source_def))
		end

		def get_all(source_defs, filter={})
			sources = []
			if source_defs.nil? || source_defs.empty?
				sources = hashes
			else
				sources = source_defs.map{ |d| hash(d) }
			end
			sources = sources.select{ |s| s[:log][:state] == filter[:state] } if (filter.has_key?(:state))
			sources = sources.select{ |s| s[:log][:error].empty? != filter[:error] } if (filter.has_key?(:error))
			return sources
		end

		def update(source_hash)
			@log.update(source_hash)
		end

		def url(source_def)
			url = source_def
			if /\d+/.match(source_def)
				idx = source_def.to_i - 1
				raise "Wrong source identifier" if idx < 0 || idx >= @sources.size
				url = @sources[source_def.to_i - 1]
			end
			url
		end

		def hashes
			@sources.map{ |s| hash(s) }
		end

		def hash(url)
			{url: url, folder: folder(url), log: @log.log(url)}
		end

		def folder(url)
				File.expand_path(url.gsub(/[^[\w-]]+/, "_"), SOURCES_FOLDER)
		end

	end

	class Log

		def initialize
			@log = Oj.load_file(DIGGIT_LOG)
		end

		def save
			Oj.to_file(DIGGIT_LOG, @log)
		end

		def init(url)
			unless @log.has_key?(url)
				@log[url] = default_log
				save
			end
		end

		def update(hash)
			@log[hash[:url]] = hash[:log]
			save
		end

		def rem(url)
			@log.delete(url)
			save
		end

		def log(url)
			return @log[url]
		end

		def default_log
			return {state: :new, error: [], analyses: []}
		end

	end

	class Diggit
		attr_accessor :sources, :config, :root

		def initialize(*args)
			super
			@root = FileUtils.pwd
			@sources = Sources.new
			@config = Config.new
			load_plugins
		end

		def load_plugins
			global = File.expand_path(INCLUDES_FOLDER,File.expand_path('..',File.dirname(File.realpath(__FILE__))))
			Dir["#{global}/**/*.rb"].each{ |f| require f }

			home = File.expand_path(INCLUDES_FOLDER,File.expand_path(DIGGIT_FOLDER,Dir.home))
			Dir["#{home}/**/*.rb"].each{ |f| require f }

			local = File.expand_path(INCLUDES_FOLDER)
			Dir["#{local}/**/*.rb"].each{ |f| require f }
		end

	end

end
