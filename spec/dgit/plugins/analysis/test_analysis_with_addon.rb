# encoding: utf-8

class TestAnalysisWithAddon < Diggit::Analysis
	require_addons "test_addon"

	attr_reader :foo

	def initialize(*args)
		super(args)
		@foo = nil
	end

	def run
		@foo = "foo"
	end

	def clean
		@foo = nil
	end
end
