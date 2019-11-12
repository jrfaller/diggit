# frozen_string_literal: true

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

# A filesystem addon for Diggit. This addon might use an :output hash in the global options. In this hash, the
# `:out` key allows to configure the path of the output folder and ``:tmp` the path of the temporary output
# folder.
# @!attribute [r] out
# 	@return [String] the absolute path of the output folder.
# @!attribute [r] tmp
# 	@return [String] the absolute path of the temporary folder.
class Out < Diggit::Addon
	attr_reader :out, :tmp

	DEFAULT_OUT = 'out'
	DEFAULT_TMP = 'tmp'

	def initialize(*args)
		super

		out = DEFAULT_OUT
		out = @options[:output][:out] if @options.key?(:output) && @options[:output].key?(:out)
		tmp = DEFAULT_TMP
		tmp = @options[:output][:tmp] if @options.key?(:output) && @options[:output].key?(:tmp)

		@out = File.absolute_path(out)
		@tmp = File.absolute_path(tmp)

		FileUtils.mkdir_p(@out) unless File.exist?(@out)
		FileUtils.mkdir_p(@tmp) unless File.exist?(@tmp)
	end

	# Get an output path for a file/directory.
	# @param paths [Array<String>] the different folders of the path.
	# @return [String] the absolute path.
	def out_path(*paths)
		File.join(@out, *paths)
	end

	# Get an output path for an analysis bound to a source.
	# @param analysis [Analysis] an analysis object.
	# @return [String] the absolute path.
	def out_path_for_analysis(analysis, *paths)
		out_path(analysis.name, analysis.source.id, *paths)
	end

	# Get a temporary path for a file/directory.
	# @param paths [Array<String>] the different folders of the path.
	# @return [String] the absolute path.
	def tmp_path(*paths)
		File.join(@tmp, *paths)
	end

	# Get a temporary path for an analysis bound to a source.
	# @param analysis [Analysis] an analysis object.
	# @return [String] the absolute path.
	def tmp_path_for_analysis(analysis, *paths)
		tmp_path(analysis.name, analysis.source.id, *paths)
	end

	# Clean the output and temporary folders.
	# @return [void]
	def clean_all
		FileUtils.rm_rf(@out)
		FileUtils.rm_rf(@tmp)
	end

	def clean_analysis(analysis)
		FileUtils.rm_rf(out_path_for_analysis(analysis))
		FileUtils.rm_rf(tmp_path_for_analysis(analysis))
	end
end
