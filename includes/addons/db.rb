# encoding: utf-8
require 'mongo'

# A MongoDB addon for Diggit. The name of this addon is :db. This addon might use an :mongo hash in the global options. In this
# hash, the :database key allows to configure the name of the database.
# @!attribute [r] db
# 	@return [Mongo::DB] the mongo database object.
class Db < Diggit::Addon

	DEFAULT_DB = 'diggit'

	attr_reader :db

	def initialize(*args)
		super
		database = DEFAULT_DB
		database = @options[:mongo][:database] if @options.has_key?(:mongo) && @options[:mongo].has_key?(:database)
		@db = Mongo::Client.new(['127.0.0.1:27017'], :database => database);
	end

	def name
		:db
	end

end
