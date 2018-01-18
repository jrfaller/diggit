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
# Copyright 2016 Jean-Rémy Falleri <jr.falleri@gmail.com>
# Copyright 2016 Floréal Morandat
# Copyright 2016 Benjamin Benni

require 'yaml'

class ConflictMerge < Diggit::Analysis
	require_addons 'out'

	DIFF3 = 'diff3'.freeze

	def initialize(options)
		super(options)
	end

	def run
		walker = Rugged::Walker.new(repo)
		walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
		walker.push(repo.head.name)
		walker.each do |commit|
			out_dir = out.out_path(source.id, commit.oid)
			parents = commit.parents
			next unless parents.size > 1
			left = parents[0]
			right = parents[1]
			next if repo.merge_base(left, right).nil?
			base = repo.lookup(repo.merge_base(left, right))
			%w[m b l r].each { |p| FileUtils.mkdir_p(File.join(out_dir, p)) }
			populate_merge_directory(out_dir, commit, base, left, right)
		end
	end

	def populate_merge_directory(out_dir, commit, base, left, right)
		commit.tree.walk(:preorder) do |r, e|
			next if e[:type] == :tree
			next if base.tree.get_entry_by_oid(e[:oid])
			oids = find_oids(r, e[:name], base, left, right)
			next if oids[:left].nil? || oids[:right].nil? # This would result in a trivial merge

			fname = flatten_name(r + e[:name])
			write(e[:oid], fname, out_dir, 'm')
			if oids[:base].nil?
				write_file("", fname, out_dir, 'b') # Create a fake file in base
			else
				write(oids[:base], fname, out_dir, 'b')
			end
			write(oids[:left], fname, out_dir, 'l')
			write(oids[:right], fname, out_dir, 'r')

			write_commit_log(out_dir, commit, base, left, right)

			diff_file = File.join(out_dir, "#{fname}.diff3")
			File.unlink diff_file unless system(
					DIFF3,
					"-m",
					File.join(out_dir, 'l', fname),
					File.join(out_dir, 'b', fname),
					File.join(out_dir, 'r', fname),
					out: diff_file
			) == false
		end
	end

	def find_oids(root, name, base, left, right)
		components = root == "" ? [] : root.split(File::SEPARATOR)
		{
		  base: find_oid(base.tree, components, name),
		  left: find_oid(left.tree, components, name),
		  right: find_oid(right.tree, components, name)
		}
	end

	def find_oid(tree, components, name)
		components.each { |c| tree = repo.lookup(tree[c][:oid]) }
		tree[name][:oid]
	rescue StandardError => e
		# TODO: better error handling
		puts e
	end

	def write(oid, name, *kind)
		write_file repo.lookup(oid).content, name, *kind
	end

	def write_file(data, name, *kind)
		File.write(File.join(kind, name), data)
	end

	def write_commit_log(out_dir, *commits)
		File.open(File.join(out_dir, "commits.txt"), "w") do |file|
			commits.each { |c| file.write("#{c.oid}\n") }
		end
	end

	def flatten_name(name)
		name.gsub(/_/, '__').gsub(%r{/}, '_')
	end

	def clean
		out.clean
	end
end
