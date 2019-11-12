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

require 'yaml'

class Cloc < Diggit::Analysis
	require_addons 'db'

	def initialize(options)
		super(options)
	end

	def run
		walker = Rugged::Walker.new(repo)
		walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
		walker.push(repo.head.name)
		walker.each do |c|
			repo.checkout(c.oid, { strategy: %i[force remove_untracked] })
			cloc = `cloc #{@source.folder} --progress-rate=0 --quiet --yaml`
			next if cloc.empty?

			yaml = YAML.safe_load(cloc.lines[2..-1].join)
			yaml.delete('header')
			output = { source: @source.url, commit: c.oid, cloc: yaml }
			db.client['cloc'].insert_one(output)
		end
	end

	def clean
		db.client['cloc'].find({ source: @source.url }).delete_many
	end
end
