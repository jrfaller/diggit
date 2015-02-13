# encoding: utf-8

require 'yaml'

class ClocAnalysis < Diggit::Analysis

	def run
		cloc = `cloc . --progress-rate=0 --quiet --yaml`
		unless cloc.empty?
			yaml = YAML.load(cloc.lines[2..-1].join)
			yaml.delete('header')
			output = { source: @source, cloc: yaml }
			col = @addons[:db].db['cloc']
			col.insert(output)
		end
	end

	def clean
		@addons[:db].db['cloc'].remove({source: @source})
	end

end


class ClocPerFileAnalysis < Diggit::Analysis

	def run
		commit_oid = "HEAD"
		commit_oid = @addons[:sources_options][@source]["cloc-commit-id"] if @addons.has_key?(:sources_options) && @addons[:sources_options].has_key?(@source) && @addons[:sources_options][@source].has_key?("cloc-commit-id")
		@repo.checkout(commit_oid, {:strategy=>[:force,:remove_untracked]})
		cloc = `cloc . --progress-rate=0 --quiet --by-file --yaml --script-lang=Python,python`
		unless cloc.empty?
			yaml = YAML.load(cloc.lines[2..-1].join)
			yaml.delete('header')
			yaml.delete('SUM')
			cloc_a = []
			yaml.each do |key, value|
				# transform the hash so the filenames are not keys anymore (as they may contain a '.' it is incompatible with mongo)
				path = key.gsub(/^\.\//, '') # remove the './' at the start of filenames
				cloc_a << value.merge({:path => path})
			end
			output = { source: @source, commit_oid: commit_oid.to_s, cloc: cloc_a }
			col = @addons[:db].db['cloc-file']
			col.insert(output)
		end
	end

	def clean
		@addons[:db].db['cloc-file'].remove({source: @source})
	end
end
