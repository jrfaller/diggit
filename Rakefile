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

require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'
require 'bundler/gem_tasks'

RuboCop::RakeTask.new(:rubocop)
RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new(:yard)

task default: %i[rubocop yard spec]
