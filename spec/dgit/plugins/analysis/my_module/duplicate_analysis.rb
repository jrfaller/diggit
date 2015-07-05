# encoding: utf-8

module MyModule
	class DuplicateAnalysis < Diggit::Analysis
		def run
			@state = "runned"
		end

		def clean
			@state = "cleaned"
		end
	end
end
