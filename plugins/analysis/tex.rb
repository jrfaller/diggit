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

require 'fileutils'

class Tex < Diggit::Analysis
	require_addons 'out'

	def initialize(options)
		super(options)
	end

	def run
		walker = Rugged::Walker.new(repo)
		walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
		walker.push(repo.head.name)
		walker.each do |c|
			repo.checkout(c.oid, { strategy: %i[force remove_untracked] })
			words = Dir["**/*.tex"].reduce(0) { |acc, elem| acc + `cat "#{elem}" | wc -w`.to_i }
			File.open(file, 'a') { |f| f.puts("#{source.url};#{c.oid};#{words}\n") }
		end
	end

	def clean
		out.clean
	end

	def file
		"#{out.out}/words.csv"
	end
end
