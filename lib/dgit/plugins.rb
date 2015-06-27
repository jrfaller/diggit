# encoding: utf-8

require_relative 'core'

module Diggit
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
	end

	class Addon < Plugin
		def initialize(options)
			super(options)
		end
	end

	class Runnable < Plugin
		attr_reader :addons

		def initialize(options)
			super(options)
			@addons = {}
			self.class.required_addons.each { |a| @addons[a] = Dig.it.plugin_loader.load_plugin(a, :addon, true) }
			@addons.each_key { |a| self.class.class_eval { define_method(a) { return @addons[a] } } }
		end

		def run
		end

		def clean
		end

		def self.required_addons
			return [] if @required_addons.nil?
			@required_addons
		end

		def self.require_addons(*names)
			@required_addons = names
		end
	end

	class Join < Runnable
		attr_accessor :sources

		def initialize(options)
			super(options)
			@sources = []
		end

		def self.required_analyses
			return [] if @required_analyses.nil?
			@required_analyses
		end

		def self.require_analyses(*names)
			@required_analyses = names
		end
	end

	class Analysis < Runnable
		attr_accessor :source

		def initialize(options)
			super(options)
			@source = nil
		end
	end
end
