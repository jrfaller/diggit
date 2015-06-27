# encoding: utf-8

require 'formatador'

class Formatador
	def self.info_i(str, indent = 1)
		info("#{'\t' * indent}#{str}")
	end

	def self.info(str)
		Formatador.display_line(str)
	end

	def self.ok_i(str, indent = 1)
		ok("#{'\t' * indent}#{str}")
	end

	def self.ok(str)
		Formatador.display_line("[green]#{str}[/]")
	end

	def self.error_i(str, indent = 1)
		error("#{'\t' * indent}#{str}")
	end

	def self.error(str)
		Formatador.display_line("[red]#{str}[/]")
	end
end

Log = Formatador
