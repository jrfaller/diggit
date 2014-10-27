# encoding: utf-8

class PomAnalysis < Diggit::Analysis

	def run
		pom_files = Dir['**/pom.xml']
		pom_files.each do |file|
			puts file
			git = `git --no-pager log --pretty=%H%n%an --name-status #{file}`.lines
			history = []
			git.each_slice(4) { |slice| history << [slice[0].strip, slice[1].strip, slice[3].split("\t")[0].strip] }
			puts history.inspect
		end
	end

end
