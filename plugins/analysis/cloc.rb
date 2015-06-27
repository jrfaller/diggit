# encoding: utf-8

require 'yaml'

class Cloc < Diggit::Analysis
	require_addons 'db'

	def initialize(options)
		super(options)
	end

	def run
		cloc = `cloc . --progress-rate=0 --quiet --yaml`
		return if cloc.empty?
		yaml = YAML.load(cloc.lines[2..-1].join)
		yaml.delete('header')
		output = { source: @source.url, cloc: yaml }
		db.client['cloc'].insert_one(output)
	end

	def clean
		db.client['cloc'].find({ source: @source.url }).delete_one
	end
end
