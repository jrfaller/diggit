# encoding: utf-8

class DiffSize < Diggit::Join

	SAMPLE_SIZE = 10

	def run
		@sources.map{ |s| sample(s) }
	end

	def sample(src)
    @addons[:R].src = src[:url]
    @addons[:R].size = SAMPLE_SIZE
    @addons[:R].dbname = @addons[:db].db.name
    @addons[:R].eval <<-EOS
			library(RMongo)

			srcQuery <- function(src) {
				paste0('{"source": "', src, '"}')
			}

			noZeros <- function(data) {
				subset(data,changes>0)
			}

			rubify <- function(data) {
				cbind(data$old_path, data$old_commit, data$new_path, data$new_commit)
			}

			db <- mongoDbConnect(dbname)
			d <- noZeros(dbGetQuery(db, 'diffstats', srcQuery(src), skip=0, limit=0))
			q <- quantile(d$changes)

			s <- subset(d,changes > 0 & changes <= q[3])
			m <- subset(d,changes > q[3] & changes <= q[4])
			b <- subset(d,changes > q[4])

			rs <- s[sample(nrow(s), size),]
			rm <- m[sample(nrow(m), size),]
			rb <- b[sample(nrow(b), size),]

			rs_ruby <- rubify(rs)
			rm_ruby <- rubify(rm)
			rb_ruby <- rubify(rb)
		EOS
		write_sample(src, @addons[:R].rs_ruby, 'small')
		write_sample(src, @addons[:R].rm_ruby, 'medium')
		write_sample(src, @addons[:R].rb_ruby, 'big')
	end

	def write_sample(src, sample, type)
		prefix = "#{@addons[:output].out}/#{src[:id]}/#{type}"
		n = 1
		sample.row_vectors.each do |row|
			FileUtils.mkdir_p("#{prefix}/#{n}")
			File.write("#{prefix}/#{n}/src_#{row[1]}_#{row[0].gsub(/\//,'_')}", `git -C #{src[:folder]} show #{row[1]}:#{row[0]}`)
			File.write("#{prefix}/#{n}/dst_#{row[3]}_#{row[2].gsub(/\//,'_')}", `git -C #{src[:folder]} show #{row[3]}:#{row[2]}`)
			n += 1
		end
	end

  def clean
		@sources.each{ |s| FileUtils.rm_rf("#{@addons[:output].out}/#{s[:id]}") }
  end

end
