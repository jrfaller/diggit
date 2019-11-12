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
# Copyright 2018 Jean-Rémy Falleri <jr.falleri@gmail.com>

class GitGraph < Diggit::Analysis
	require_addons 'out'

	def initialize(options)
		super(options)
	end

	def run
		FileUtils.mkdir_p(out.out_path_for_analysis(self))
		file = out.out_path_for_analysis(self, "graph.dot")
		File.open(file, 'w') do |f|
			f.puts "digraph repository {"
			f.puts "\tnode [shape=rect, color=lightblue2, style=filled];"
			append_dot_nodes(f)
			append_dot_links(f)
			f.puts "}"
		end
	end

	def append_dot_nodes(file)
		init_walker.each do |commit|
			file.puts "\tc_#{commit.oid} [label=\"#{commit.oid.to_s[0..6]}\"];"
		end
	end

	def append_dot_links(file)
		init_walker.each do |commit|
			commit.parents.each { |parent| file.puts "\tc_#{commit.oid} -> c_#{parent.oid};" }
		end
	end

	def init_walker
		walker = Rugged::Walker.new(repo)
		walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
		walker.push(repo.head.name)
		walker
	end

	def clean
		out.clean_analysis(self)
	end
end
