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
#

require 'formatador'

class Formatador
	def self.info_i(str, indent = 1)
		info("#{'\t' * indent}#{str}")
	end

	def self.info(str)
		Formatador.display_line(str)
	end

	def self.ok_i(str, indent = 1)
		ok("#{'\t' * indent}#{str}")
	end

	def self.ok(str)
		Formatador.display_line("[green]#{str}[/]")
	end

	def self.error_i(str, indent = 1)
		error("#{'\t' * indent}#{str}")
	end

	def self.error(str)
		Formatador.display_line("[red]#{str}[/]")
	end
end

Log = Formatador