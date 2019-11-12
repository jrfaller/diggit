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

require_relative 'lib/dgit/version'

Gem::Specification.new do |spec|
	spec.name = 'diggit'
	spec.version = Diggit::VERSION
	spec.summary = "A Git repository analysis tool."
	spec.authors = ["Jean-Rémy Falleri", "Floréal Morandat", "Matthieu Foucault", "Mohamed Oumaziz"]
	spec.email = 'jr.falleri@gmail.com'
	spec.homepage = 'https://github.com/jrfaller/diggit'
	spec.licenses = 'LGPL-3.0'
	spec.description = 'Diggit is an agile tool that allows you to'\
			' analyze git repositories.'
	spec.require_paths = ['lib']
	spec.files = ['CHANGELOG.md', 'README.md', 'LICENSE', 'bin/dgit'] +
			Dir['lib/**/*.rb'] + Dir['spec/**/*.rb'] + Dir['plugins/**/*.rb']
	spec.executables << 'dgit'
	spec.bindir = 'bin'
	spec.required_ruby_version = '~> 2.4'
	spec.add_runtime_dependency 'formatador', '~> 0'
	spec.add_runtime_dependency 'gli', '~> 2'
	spec.add_runtime_dependency 'oj', '~> 3', ' >= 3.4.0'
	spec.add_runtime_dependency 'rugged', '~> 0'
	spec.add_development_dependency 'coveralls', '~> 0'
	spec.add_development_dependency 'pry', '~> 0'
	spec.add_development_dependency 'rake', '~> 13'
	spec.add_development_dependency 'redcarpet', '~> 3'
	spec.add_development_dependency 'rspec', '~> 3'
	spec.add_development_dependency 'rubocop', '~> 0', '>= 0.49.0'
	spec.add_development_dependency 'simplecov' , '~> 0', '>= 0.16.0'
	spec.add_development_dependency 'yard', '~> 0', '>= 0.9.20'
end
