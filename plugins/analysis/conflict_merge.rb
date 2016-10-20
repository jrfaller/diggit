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
# Copyright 2016 Floréal Morandat
# Copyright 2016 Benjamin Benni

require 'yaml'

class ConflictMerge < Diggit::Analysis
	#	require_addons 'out'

	RESULT_DIR = "result".freeze
	DIFF3 = "diff3".freeze

	def initialize(options)
		super(options)
	end

	def run
		walker = Rugged::Walker.new(repo)
		walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
		walker.push(repo.head.name)
		walker.each do |commit|
			parents = commit.parents
			next unless parents.size > 1
			left = parents[0]
			right = parents[1]
			next if repo.merge_base(left, right).nil?
			base = repo.lookup(repo.merge_base(left, right))
			dir = FileUtils.mkdir_p File.join(RESULT_DIR, commit.oid)
			%w(m b l r).each { |p| FileUtils.mkdir_p(File.join(dir, p)) }
			populate_merge_directory(dir, commit, base, left, right)
		end
	end

	def populate_merge_directory(dir, commit, base, left, right)
		btree = base.tree
		commit.tree.walk(:preorder) do |r, e|
			next if e[:type] == :tree
			next if btree.get_entry_by_oid(e[:oid])
			name = e[:name]
			components = r == "" ? [] : r.split(File::SEPARATOR)
			fname = flatten_name(r + name)

			write(e, fname, dir, "m")
			write(find_oid(btree, components, name), fname, dir, "b")
			write(find_oid(left.tree, components, name), fname, dir, "l")
			write(find_oid(right.tree, components, name), fname, dir, "r")
			diff_file = File.join(dir, "#{fname}.diff3")
			cmd = "#{DIFF3} -x" \
					" \"#{File.join(dir, 'l', fname)}\"" \
					" \"#{File.join(dir, 'b', fname)}\"" \
					" \"#{File.join(dir, 'r', fname)}\"" \
					" 2> /dev/null"
			res = `#{cmd}`
			system(
					DIFF3,
					"-m",
					File.join(dir, "l", fname),
					File.join(dir, "b", fname),
					File.join(dir, "r", fname),
					out: diff_file,
					err: File::NULL
			) unless res.empty?
		end
	end

	def find_oid(tree, components, name)
		components.each { |c| tree = repo.lookup(tree[c][:oid]) }
		tree[name]
	rescue
		nil # FIXME: what if a file has been renamed or is not there ???
	end

	def write(entry, name, *kind)
		return unless entry
		File.write(File.join(kind, name), repo.lookup(entry[:oid]).content)
	end

	def flatten_name(name)
		name.gsub(/_/, "__").gsub(%r{/}, "_")
	end

	def clean
		FileUtils.rm_rf RESULT_DIR
	end
end
