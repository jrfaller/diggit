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
# Copyright 2015 Matthieu Foucault <foucaultmatthieu@gmail.com>
#

R = nil # fixing SIGPIPE error in some cases. See http://hfeild-software.blogspot.fr/2013/01/rinruby-woes.html

require "rinruby"

class R < Diggit::Addon
	def initialize(*args)
		super(args)
		@r = RinRuby.new({ interactive: false, echo: true })
	end

	def method_missing(meth, *args, &block)
		@r.send meth, *args, &block
	end
end