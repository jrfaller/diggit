# encoding: utf-8

class MetadataAnalysis < Diggit::Analysis

	def run
		# Importing tags
		tags = @addons[:db].db['tags']
		@repo.tags.each do |t|
			tag = { source: @source, name: t.name, target: t.target.oid }
			tags.insert_one(tag)
		end

		# Importing branches
		branches = @addons[:db].db['branches']
		@repo.branches.each do |b|
			branch = { source: @source, name: b.name, target: b.target.oid }
			branches.insert_one(branch)
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
			commits.insert_one(commit)
		end
	end

	def clean
		@addons[:db].db['tags'].find({source: @source}).delete_many();
		@addons[:db].db['branches'].find({source: @source}).delete_many();
		@addons[:db].db['commits'].find({source: @source}).delete_many();
	end

end
