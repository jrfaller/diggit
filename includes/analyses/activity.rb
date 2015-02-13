# encoding: utf-8

class Activity < Diggit::Analysis

	def run
		walker = Rugged::Walker.new(@repo)
		walker.sorting(Rugged::SORT_DATE)
		walker.push(@repo.last_commit)
		col = @addons[:db].db['activity']
		output = { source: @source, commits: []}
		walker.each do |c| c.author[:name]
			output[:commits] << {author: c.author[:name], time: c.time }
		end
		col.insert(output)
	end

	def clean
		@addons[:db].db['activity'].remove({source: @source})
	end

end
