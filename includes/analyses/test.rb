# encoding: utf-8

class TestAnalysis < Diggit::Analysis

	def run
		puts "TestAnalysis performed"
	end

	def clean
		puts "TestAnalysis cleaned on #{@source}"
	end

end
