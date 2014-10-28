# encoding: utf-8

# A output addon for Diggit. The name of the addon is :output, and can be reached in the
# addons hash. This addon might use an :output hash in the global options. In this hash, the
# :out key allows to configure the name of the output folder and :tmp the name of the temporary output
# folder.
# @!attribute [r] out
# 	@return [String] the absolute path of the output folder.
# @!attribute [r] tmp
# 	@return [String] the absolute path of the temporary output folder.
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
