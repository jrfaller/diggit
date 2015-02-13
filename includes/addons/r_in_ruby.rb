# encoding: utf-8

R = nil # fixing SIGPIPE error in some cases. See http://hfeild-software.blogspot.fr/2013/01/rinruby-woes.html

require "rinruby"

class RWrapper < Diggit::Addon

	def initialize(*args)
		@r = RinRuby.new({:interactive=>false,:echo=>false})
	end

	def name
		:R
	end

	def method_missing(meth, *args, &block)
		@r.send meth, *args, &block
	end

end
