require 'thor'
require 'fileutils'

require_relative 'diggit_core'

module Diggit

	module Utils

		def diggit
			@diggit = Diggit.new if @diggit.nil?
			return @diggit
		end

		def dump_error(e)
			{ name: e.class.name, message: e.to_s, backtrace: e.backtrace }
		end

		def class_exist?(class_name)
			obj = Object::const_get(class_name)
			return obj.is_a?(Class)
		rescue NameError
			return false
		end

		def source_color(source_hash)
			if source_hash[:log][:error].empty?
				return :blue
			else
				return :red
			end
		end

		def status_color(status)
			if status == Cli::DONE
				return :green
			else
				return :red
			end
		end

	end

	module CloneUtils

		def clone_error(source, e)
			source[:log][:error] = dump_error(e)
			say_status(Cli::ERROR, "error cloning #{source[:url]}", :red)
		end

		def clone_done(source)
			source[:log][:state] = :cloned
			source[:log][:error] = {}
			say_status(Cli::DONE, "#{source[:url]} cloned", :blue)
		end

	end

	module Cli

		DONE = '[done]'
		WARNING = '[warning]'
		ERROR = '[error]'
		INFO = '[info]'

		class SourcesCli < Thor
			include Thor::Actions
			include Utils

			desc 'list', "Display the list of sources."
			def list
				idx = 1
				diggit.sources.hashes.each do |s|
					say_status("[#{s[:log][:state]}]", "#{idx}: #{s[:url]}", source_color(s))
					idx += 1
				end
				errors = diggit.sources.get_all(nil, {error: true}).size
				status = (errors== 0 && DONE) || ERROR
				say_status(status, "listed #{diggit.sources.size} sources including #{errors} errors", status_color(status))
			end

			desc 'info [SOURCE_DEF]', "Display informations on the provided source definition (either source URL or id)."
			def info(source_def)
				s = diggit.sources.get(source_def)
				say_status("[#{s[:log][:state]}]", "#{s[:url]}", source_color(s))
				say_status('[folder]', "#{s[:folder]}", :blue)
				unless s[:log][:error].empty?
					say_status(ERROR, "#{s[:log][:error][:name]}", :red)
					say_status('[message]', "#{s[:log][:error][:message]}", :red)
					say_status('[backtrace]', "", :red)
					say(s[:log][:error][:backtrace].join("\n"))
				end
			end

			desc "errors", "Display informations on all source that have encountered an error."
			def errors
				diggit.sources.get_all(nil, {error: true}).each{|s| invoke :info, [s[:url]]}
			end

			desc 'import [FILE]', "Import a list of sources from a file (one URL per line)."
			def import(urls_file)
				IO.readlines(urls_file).each{ |line| diggit.sources.add(line.strip) }
			end

			desc "add [URL*]", "Add the provided urls to the list of sources."
			def add(*urls)
				urls.each{ |u| diggit.sources.add(u) }
			end

			desc "rem [SOURCE_DEF*]", "Remove the sources correspondign to the provided source definitions (id or URL) from the list of sources."
			def rem(*sources_defs)
				sources_defs.each { |s| diggit.sources.rem(s) }
			end
		end

		class AddonsCli < Thor
			include Thor::Actions
			include Utils

			desc "add [ADDON*]", "Add the provided addons to the list of active addons."
			def add(*addons)
				addons.each do |a|
					if class_exist?(a)
						diggit.config.add_addon(a)
					else
						say_status(ERROR, "addon #{a} not found", :red)
					end
				end
			end

			desc "rem [ADDON*]", "Remove the provided addons from the list of active addons."
			def rem(*addons)
				addons.each{ |a| diggit.config.rem_addon(a) }
			end

		end

		class JoinsCli < Thor
			include Thor::Actions
			include Utils

			desc "add [JOIN*]", "Add the provided joins to the list of active joins."
			def add(*joins)
				joins.each do |j|
					if class_exist?(j)
						diggit.config.add_join(j)
					else
						say_status(ERROR, "join #{j} not found", :red)
					end
				end
			end

			desc "rem [JOIN*]", "Remove the provided joins from the list of active joins."
			def rem(*joins)
				joins.each{ |j| diggit.config.rem_join(j) }
			end

		end

		class AnalysesCli < Thor
			include Thor::Actions
			include Utils

			desc "add [ANALYSIS*]", "Add the provided analyses to the list of active analyses."
			def add(*analyses)
				analyses.each do |a|
					if class_exist?(a)
						diggit.config.add_analysis(a)
					else
						say_status(ERROR, "analysis #{a} not found", :red)
					end
				end
			end

			desc "rem [ANALYSIS*]", "Remove the provided analyses from the list of active analyses."
			def rem(*analyses)
				analyses.each{ |a| diggit.config.rem_analysis(a) }
			end

		end

		class PerformCli < Thor
			include Thor::Actions
			include Utils, CloneUtils

			desc "clones [SOURCE_DEFS*]", "Clone the sources corresponding to the provided source definitions (id or URL). Clone all sources if no source definitions are provided."
			def clones(*source_defs)
				diggit.sources.get_all(source_defs, {state: :new}).each do |s|
					begin
						Rugged::Repository::clone_at(s[:url], s[:folder])
					rescue Rugged::InvalidError
						# In case of InvalidError, check if the source has already been cloned, e.g. copied from a previous diggit workspace.
						begin
							repo = Rugged::Repository::new(s[:folder])
						rescue => e
							clone_error(s,e)
						else
							clone_done(s)
						end
					rescue => e
						clone_error(s,e)
					else
						clone_done(s)
					ensure
						diggit.sources.update(s)
					end
				end
			end

			desc "analyses [SOURCE_DEFS*]", "Perform the configured analyses to the sources corresponding to the provided source definitions (id or URL). Analyze all sources if no source definitions are provided."
			def analyses(*source_defs)
				addons = diggit.config.load_addons
				diggit.sources.get_all(source_defs, {state: :cloned}).each do |s|
					FileUtils.cd(s[:folder])
					globs = {}
					performed_analyses = []
					begin
						repo = Rugged::Repository.new('.')
						diggit.config.load_analyses(s[:url], repo, addons, globs).each do |a|
							performed_analyses << a.class.to_s
							a.run
						end
					rescue => e
						s[:log][:error] = dump_error(e)
						s[:log][:analyses] = performed_analyses[1..-2]
						say_status(ERROR, "error performing #{performed_analyses.last} on #{s[:url]}", :red)
					else
						s[:log][:analyses] = performed_analyses
						s[:log][:state] = :finished
						s[:log][:error] = {}
						say_status(DONE, "source #{s[:url]} analyzed", :blue)
					ensure
						FileUtils.cd(diggit.root)
						diggit.sources.update(s)
					end
				end
			end

			desc "joins", "Perform the configured joins."
			def joins
				addons = diggit.config.load_addons
				globs = {}
				diggit.config.load_joins(diggit.sources.get_all([], {state: :finished, error: false}), addons, globs).each{ |j| j.run }
				say_status(DONE, "joins performed", :blue)
			end

		end

		class CleanCli < Thor
			include Thor::Actions
			include Utils

			desc "analyses", "Clean the configured analyzes on the provided source definitions (id or URL). Clean all sources if no source definitions are provided."
			def analyses(*source_defs)
				addons = diggit.config.load_addons
				diggit.sources.get_all(source_defs, {state: :finished}).each do |s|
					globs = {}
					diggit.config.load_analyses(s[:url], nil, addons, globs).each{ |a| a.clean}
					s[:log][:state] = :cloned
					s[:log][:analyses] = []
					s[:log][:error] = {}
					diggit.sources.update(s)
					say_status(DONE, "cleaned analyses on #{s[:url]}", :blue)
				end
			end

			desc "joins", "Clean the configured joins."
			def joins
				addons = diggit.config.load_addons
				globs = {}
				diggit.config.load_joins(diggit.sources.get_all([], {state: :finished, error: false}), addons, globs).each{ |j| j.clean }
			end

		end

		class DiggitCli < Thor
			include Thor::Actions
			include Utils

			def initialize(*args)
				super
				cmd = args[2][:current_command].name
				unless 'init'.eql?(cmd) || 'help'.eql?(cmd)
					unless File.exist?(DIGGIT_RC)
						say_status(ERROR, "this is not a diggit directory", :red)
					else
						diggit
					end
				end
			end

			desc "init", "Initialize the current folder as a diggit folder."
			def init
				FileUtils.touch(DIGGIT_SOURCES)
				Oj.to_file(DIGGIT_LOG, {})
				Oj.to_file(DIGGIT_RC, { addons: [], analyses: [], joins: [], options: {} })
				say_status(DONE, "folder initialized")
			end

			desc 'status', "Display the status of the current diggit folder."
			def status
				color = (diggit.sources.get_all(nil, {error: true}).size > 0 && :red) || :blue
				say_status('[sources]', "#{diggit.sources.get_all([], {state: :new}).size} new (#{diggit.sources.get_all([], {state: :new, error: true}).size} errors), #{diggit.sources.get_all([], {state: :cloned}).size} cloned (#{diggit.sources.get_all([], {state: :cloned, error: true}).size} errors), #{diggit.sources.get_all([], {state: :finished}).size} finished", color)
				say_status('[addons]', "#{diggit.config.addons.join(', ')}", :blue)
				say_status('[analyses]', "#{diggit.config.analyses.join(', ')}", :blue)
				say_status('[joins]', "#{diggit.config.joins.join(', ')}", :blue)
				say_status('[options]', "#{diggit.config.options}", :blue)
			end

			desc "sources SUBCOMMAND ...ARGS", "manage sources for the current diggit folder."
			subcommand "sources", SourcesCli

			desc "joins SUBCOMMAND ...ARGS", "manage joins for the current diggit folder."
			subcommand "joins", JoinsCli

			desc "analyses SUBCOMMAND ...ARGS", "manage analyses for the current diggit folder."
			subcommand "analyses", AnalysesCli

			desc "addons SUBCOMMAND ...ARGS", "manage addons for the current diggit folder."
			subcommand "addons", AddonsCli

			desc "perform SUBCOMMAND ...ARGS", "perform actions in the current diggit folder."
			subcommand "perform", PerformCli

			desc "clean SUBCOMMAND ...ARGS", "clean the current diggit folder."
			subcommand "clean", CleanCli

		end

	end

end
