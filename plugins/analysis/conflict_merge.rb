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

# List all conflicts from a repository.
# Useful alias to explore the results :
#   alias fconflicts "find . -iname '*.diff3' | sed -e 's/\.\///g' | sed -e 's/\/.*/\//g' | uniq -u"
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
			base_oid = repo.merge_base(left, right)
			next if base_oid.nil?
			base = repo.lookup(base_oid)
			%w[m b l r].each { |p| FileUtils.mkdir_p(File.join(out_dir, p)) }
			populate_merge_directory(out_dir, commit, base, left, right)
		end
	end

	def populate_merge_directory(out_dir, commit, base, left, right)
		commit.tree.walk_blobs(:preorder) do |r, e|
			next if base.tree.get_entry_by_oid(e[:oid])
			oids = find_oids(r, e[:name], base, left, right)
			next if oids[:left].nil? || oids[:right].nil? # This would result in a trivial merge

			flat_name = flatten_name(r + e[:name])
			write(e[:oid], flat_name, out_dir, 'm')
			if oids[:base].nil?
				write_file("", flat_name, out_dir, 'b') # Create a fake file in base
			else
				write(oids[:base], flat_name, out_dir, 'b')
			end
			write(oids[:left], flat_name, out_dir, 'l')
			write(oids[:right], flat_name, out_dir, 'r')

			write_commit_log(out_dir, commit, base, left, right)

			diff_file = File.join(out_dir, "#{flat_name}.diff3")
			system(
					DIFF3,
					'-x',
					'-T',
					'--strip-trailing-cr',
					'-a',
					File.join(out_dir, 'l', flat_name),
					File.join(out_dir, 'b', flat_name),
					File.join(out_dir, 'r', flat_name),
					out: diff_file
			)
			File.unlink diff_file if File.zero?(diff_file)
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
		components.each { |c| tree = repo.lookup(tree[c][:oid]) unless tree.nil? || tree[c].nil? }
		return nil if tree.nil? || tree[name].nil?
		tree[name][:oid]
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
