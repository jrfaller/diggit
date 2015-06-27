# encoding: utf-8

class TestAnalysis < Diggit::Analysis
	def run
		@state = "runned"
	end

	def clean
		@state = "cleaned"
	end
end
