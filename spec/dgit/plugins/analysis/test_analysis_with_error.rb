# encoding: utf-8

class TestAnalysisWithError < Diggit::Analysis
	def run
		fail "Error!"
	end

	def clean
	end
end
