# encoding: utf-8

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
