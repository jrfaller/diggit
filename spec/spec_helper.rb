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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Diggit.	If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2015 Jean-Rémy Falleri <jr.falleri@gmail.com>

require 'coveralls'
Coveralls.wear!

require_relative('../lib/dgit')

TEST_URL = 'https://github.com/jrfaller/test-git.git'

RSpec.configure do |config|
	config.before(:all) do
		FileUtils.rm_rf('spec/dgit/.dgit')
		FileUtils.rm_rf('spec/dgit/sources')
	end
end
