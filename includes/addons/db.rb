# encoding: utf-8
require 'mongo'

class Db < Diggit::Addon

	DEFAULT_DB = 'diggit'

	attr_reader :db

	def initialize(*args)
		super
		client = Mongo::MongoClient.new
		database = DEFAULT_DB
		database = @options[:mongo][:database] if @options.has_key?(:mongo) && @options[:mongo].has_key?(:database)
		@db = client[database]
	end

	def name
		:db
	end

end
