# frozen_string_literal: true
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

# An addon to manage options specific to sources. To use it, you need to create a `.dgit/sources_options` file.
# This file must contain a Json object where the source URLs are the keys, and the values will be given to in
# return to the call of {[]} with the corresponding source. Example:
# ```
# "https://github.com/jrfaller/diggit": {
#   "name": "An option object for the diggit source.",
#   "useful": true
# }
# ```
class SrcOpt < Diggit::Addon
	SOURCES_OPTIONS_FILE = 'sources_options'.freeze

	def initialize(*args)
		super
		sources_options_path = Diggit::Dig.it.config_path(SOURCES_OPTIONS_FILE)
		@sources_options = {}
		@sources_options = Oj.load_file(sources_options_path) if File.exist? sources_options_path
	end

	# Return the option object for the source.
	# @param source [Source].
	# @return [Hash] the option object.
	def [](source)
		@sources_options[source.url]
	end
end
