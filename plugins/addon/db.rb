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

require 'mongo'

# A MongoDB addon for Diggit. The name of this addon is :db.
# This addon might use an :mongo hash in the global options. In this
# hash, the :database key allows to configure the name of the database.
# @!attribute [r] db
# 	@return [Mongo::DB] the mongo database object.
class Db < Diggit::Addon
	DEFAULT_URL = 'mongodb://127.0.0.1:27017/diggit'

	attr_reader :client

	def initialize(*args)
		super
		url = DEFAULT_URL
		url = @options[:mongo][:url] if @options.key?(:mongo) && @options[:mongo].key?(:url)
		@client = Mongo::Client.new(url)
	end
end