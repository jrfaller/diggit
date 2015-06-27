# encoding: utf-8

class TestAnalysisWithError < Diggit::Analysis
	def run
		raise "Error!"
	end

	def clean
	end
end
