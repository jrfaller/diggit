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
# Copyright 2018 Jean-Rémy Falleri <jr.falleri@gmail.com>

require 'yaml'
require 'yard'

# List all conflicts from a repository.
# Useful alias to explore the results :
#   alias fconflicts "find . -iname '*.diff3' | sed -e 's/\.\///g' | sed -e 's/\/.*/\//g' | uniq -u"
class YardDup < Diggit::Analysis
	require_addons 'out'

	def initialize(options)
		super(options)
	end

	def run
		Log.info "processing #{@source.id}"
		doc_hash = {}
		YARD::Registry.load(Dir["**/*.rb"], true)
		objects = YARD::Registry.all(:method)
		Log.info "processing #{objects.size} documented methods"
		objects.each do |obj|
			insert_to_map("@main #{obj.docstring}", doc_hash) unless obj.docstring.empty?
			obj.tags.each do |tag|
				next if tag.nil?
				tag_tokens = []
				tag_tokens << "@#{tag.tag_name}" unless tag.tag_name.nil?
				tag_tokens << tag.types.join(',') unless tag.types.nil? || tag.types.empty?
				tag_tokens << tag.text unless tag.text.nil?
				insert_to_map(tag_tokens.join(' '), doc_hash)
			end
		end
		doc_hash.each { |key, value| Log.info "#{key}: #{value}" if value > 1 }
	end

	def insert_to_map(key, hash)
		hash[key] = if hash.key?(key)
															hash[key] + 1
														else
															0
														end
	end

	def clean
		out.clean_analysis(self)
	end
end
