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

	def clean(source)
		@addons[:db].db['cloc'].remove({source: source})
	end

end


class ClocPerFileAnalysis < Diggit::Analysis

	def run
		commit_oid = @repo.head
		commit_oid = @options[:cloc][:commit_oid] if options.has_key?(:cloc) && @options[:cloc].has_key?(:commit_oid)
		@repo.checkout(commit_oid, {:strategy=>[:force,:remove_untracked]})
		commit_oid.tree.walk_blobs do |root, entry|
			unless @repo.lookup(entry[:oid]).binary?
				cloc = `cloc #{root}#{entry[:name]} --progress-rate=0 --quiet --yaml --script-lang=Python,python`
				unless cloc.empty?
					yaml = YAML.load(cloc.lines[2..-1].join)
					yaml.delete('header')
					output = { source: @source, file: "#{root}#{entry[:name]}", commit_oid: commit_oid, cloc: yaml }
					col = @addons[:db].db['cloc-file']
					col.insert(output)
				end
			end
		end
	end

	def clean(source)
		@addons[:db].db['cloc'].remove({source: source})
	end
end