# encoding: utf-8

class DiffStats < Diggit::Analysis

	ACCEPTED_EXTENSIONS = [".java", ".c", ".h", ".js", ".javascrip" ]

	def run
		col = @addons[:db].db['diffstats']

		walker = Rugged::Walker.new(@repo)
		ref = @repo.references["refs/heads/master"]
		walker.push(ref.target_id)
		walker.each do |commit|
			parent1 = commit.parents[0]
			if parent1
				diff1 = parent1.diff(commit)
				diff1.each_delta do |delta|
					old_path = delta.old_file[:path]
					new_path = delta.new_file[:path]
					old_ext = File.extname(old_path).downcase
					new_ext = File.extname(new_path).downcase
					if delta.status == :modified && old_ext.eql?(new_ext) && ACCEPTED_EXTENSIONS.include?(old_ext)
						sha_old = delta.old_file[:oid]
						sha_new = delta.new_file[:oid]
						patch = @repo.lookup(sha_new).diff(@repo.lookup(sha_old))
						changes = patch.changes
						edit = {source: @source, old_path: old_path, new_path: new_path, old_commit: commit.oid, new_commit: parent1.oid, changes: changes}
						col.insert(edit)
					end
				end
			end
		end
	end

  def clean
    @addons[:db].db['diffstats'].remove({source: @source})
  end

end
