# encoding: utf-8

class Output < Diggit::Addon

	attr_reader :out, :tmp

	DEFAULT_OUT = 'out'
	DEFAULT_TMP = 'tmp'

	def initialize(*args)
		super

		out = DEFAULT_OUT
		out = @options[:output][:out] if @options.has_key?(:output) && @options[:output].has_key?(:out)
		tmp = DEFAULT_TMP
		tmp = @options[:output][:tmp] if @options.has_key?(:output) && @options[:output].has_key?(:tmp)

		@out = File.absolute_path(out)
		@tmp = File.absolute_path(tmp)

		FileUtils.mkdir_p(@out) unless File.exist?(@out)
		FileUtils.mkdir_p(@tmp) unless File.exist?(@tmp)
	end

	def name
		:output
	end

end
