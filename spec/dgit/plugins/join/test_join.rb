# encoding: utf-8

class TestJoin < Diggit::Join
	require_analyses 'test_analysis'

	class << self
		attr_accessor :sources
	end

	@sources = nil

	def run
		self.class.sources = @sources
	end
end
