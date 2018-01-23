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

require 'formatador'

class Formatador
	@level = :normal

	class << self
		attr_accessor :level
	end

	def self.fine(str)
		Formatador.display_line("[blue]#{str}[/]") if visible(__method__)
	end

	def self.info(str)
		Formatador.display_line("[purple]#{str}[/]") if visible(__method__)
	end

	def self.ok(str)
		Formatador.display_line("[green]#{str}[/]") if visible(__method__)
	end

	def self.debug(str)
		Formatador.display_line("[yellow]#{str}[/]") if visible(__method__)
	end

	def self.warn(str)
		Formatador.display_line("[orange]#{str}[/]") if visible(__method__)
	end

	def self.error(str)
		Formatador.display_line("[red]#{str}[/]") if visible(__method__)
	end

	def self.visible(method)
		target = method.to_sym
		if %i[ok error info].include?(target)
			true
		elsif %i[warn debug fine].include?(target) && level == :fine
			true
		else
			false
		end
	end
end

Log = Formatador
