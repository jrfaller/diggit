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
# Copyright 2019 Jean-Rémy Falleri <jr.falleri@gmail.com>

require 'yaml'

# List all diffs from a repository.
class DiffExtractor < Diggit::Analysis
	require_addons 'out'

	ALLOWED_EXTENSIONS = ['.java', '.rb'].freeze

	def initialize(options)
		super(options)
	end

	def run
		walker = Rugged::Walker.new(repo)
		walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
		walker.push(repo.head.name)
		walker.each do |commit|
			out_dir = out.out_path_for_analysis(self, commit.oid)
			parents = commit.parents
			next unless parents.size == 1

			parent = parents[0]
			populate_diff_directory(out_dir, commit, parent)
		end
	end

	def populate_diff_directory(out_dir, commit, parent)
		directories_created = false
		diff = parent.diff(commit)
		diff.each_delta do |delta_entry|
			next unless delta_entry.status == :modified
			next unless ALLOWED_EXTENSIONS.include?(File.extname(delta_entry.new_file[:path]))

			unless directories_created
				FileUtils.mkdir_p(File.join(out_dir, 'src'))
				FileUtils.mkdir_p(File.join(out_dir, 'dst'))
				directories_created = true
			end
			flat_name = flatten_name(delta_entry.new_file[:path])
			write(delta_entry.new_file[:oid], flat_name, File.join(out_dir, 'src'))
			write(delta_entry.old_file[:oid], flat_name, File.join(out_dir, 'dst'))
		end
	end

	def write(oid, name, out_dir)
		write_file repo.lookup(oid).content, name, out_dir
	end

	def write_file(data, name, out_dir)
		File.write(File.join(out_dir, name), data)
	end

	def flatten_name(name)
		name.gsub(/_/, '__').gsub(%r{/}, '_')
	end

	def clean
		out.clean_analysis(self)
	end
end
