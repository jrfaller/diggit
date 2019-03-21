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

class ClocPerFile < Diggit::Analysis
	require_addons 'db', 'src_opt'

	def run
		commit_oid = src_opt[@source]["cloc-commit-id"] unless src_opt[@source].nil?
		commit_oid = 'HEAD' if commit_oid.nil?
		repo.checkout(commit_oid, { strategy: %i[force emove_untracked] })
		folder = File.expand_path(@source.folder)
		cloc = `cloc #{folder} --progress-rate=0 --quiet --by-file --yaml --script-lang=Python,python`
		return if cloc.empty?

		yaml = YAML.safe_load(cloc.lines[2..-1].join)
		yaml.delete('header')
		yaml.delete('SUM')
		cloc_a = []
		yaml.each do |key, value|
			# transform the hash so the filenames are not keys anymore (as they may contain a '.' it is incompatible with mongo)
			path = File.expand_path(key).gsub(folder, '').gsub(%r{^/}, '')
			cloc_a << value.merge({ path: path })
		end
		output = { source: @source.url, commit_oid: commit_oid.to_s, cloc: cloc_a }
		col = db.client['cloc-file']
		col.insert_one(output)
	end

	def clean
		db.client['cloc-file'].find({ source: @source.url }).delete_one
	end
end
