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

require 'mongo'

# A MongoDB addon for Diggit. This addon might use a `:mongo` hash in the global options. In this
# hash, the `:database` key allows to configure the name of the database.
# @!attribute [r] client
# 	@return [Mongo::Client] the mongodb client object.
class Db < Diggit::Addon
	DEFAULT_SERVER = '127.0.0.1:27017'
	DEFAULT_DB = 'diggit'

	attr_reader :client

	def initialize(*args)
		super
		Mongo::Logger.logger.level = ::Logger::FATAL
		server = read_option(:mongo, :server, DEFAULT_SERVER)
		db = read_option(:mongo, :db, DEFAULT_DB)
		@client = Mongo::Client.new([server], database: db)
	end

	def insert(collection, data)
		client[collection].bulk_write(data.map { |d| { insert_one: d } }, ordered: true) unless data.empty?
	end
end
