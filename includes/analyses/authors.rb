# encoding: utf-8

class AuthorAnalysis < Diggit::Analysis

	def run
		walker = Rugged::Walker.new(@repo)
		walker.sorting(Rugged::SORT_DATE)
		walker.push(@repo.last_commit)
		authors = walker.collect{ |c| c.author[:name] }.uniq
		puts "Authors : #{authors}"
	end
end
