# encoding: utf-8

class DiffSize < Diggit::Join

	ACCEPTED_EXTENSIONS = [".java", ".c", ".h", ".js", ".javascrip" ]

	def run
		col = @addons[:db].db['diffstats']
    @sources.each do |source|
      diffs = col.count({:query => {"source" => source}})
      puts "#{source}: #{diffs}"
    end
	end

  def clean
  end

end
