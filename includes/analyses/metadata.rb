# encoding: utf-8

class MetadataAnalysis < Diggit::Analysis

	def run
		# Importing tags
		tags = @addons[:db].db['tags']
		@repo.tags.each do |t|
			tag = { source: @source, name: t.name, target: t.target.oid }
			tags.insert(tag)
		end

		# Importing branches
		branches = @addons[:db].db['branches']
		@repo.branches.each do |b|
			branch = { source: @source, name: b.name, target: b.target.oid }
			branches.insert(branch)
		end

		# Importing commits
		commits = @addons[:db].db['commits']
		walker = Rugged::Walker.new(@repo)
		walker.sorting(Rugged::SORT_DATE)
		walker.push(@repo.last_commit)
		walker.each do |c|
			commit = {
				source: @source, oid: c.oid, message: c.message, author: c.author,
				committer: c.committer, parent_ids: c.parent_ids, time: c.time
			}
			commits.insert(commit)
		end
	end

	def clean
		@addons[:db].db['tags'].remove({source: @source})
		@addons[:db].db['branches'].remove({source: @source})
		@addons[:db].db['commits'].remove({source: @source})
	end

end
