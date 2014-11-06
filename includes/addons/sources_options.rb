# encoding: utf-8

class SourcesOptions < Diggit::Addon

	SOURCES_OPTIONS_FILE = ".dgitsources-options"

	def initialize(*args)
		super
		@sources_options = {}
		@sources_options = Oj.load_file(SOURCES_OPTIONS_FILE) if File.exists? SOURCES_OPTIONS_FILE
	end

	def name
		:sources_options
	end

	def method_missing(meth, *args, &block)
		@sources_options.send meth, *args, &block
	end

end
