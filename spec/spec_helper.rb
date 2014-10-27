require 'oj'

require_relative('../lib/diggit_cli')

$0 = "grit"
ARGV.clear

def config
	return Oj.load_file(Diggit::DIGGIT_RC)
end

def log
	return Oj.load_file(Diggit::DIGGIT_LOG)
end

def sources
	return IO.readlines(Diggit::DIGGIT_SOURCES).map{ |line| line.strip }
end

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end
