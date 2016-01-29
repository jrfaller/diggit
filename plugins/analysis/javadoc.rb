# encoding: utf-8
#
# This file is part of Diggit.
#
# Diggit is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Diggit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Diggit.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2015 Jean-Rémy Falleri <jr.falleri@gmail.com>

require 'nokogiri'
require 'oj'

class Javadoc < Diggit::Analysis
	require_addons 'out'

	VALID_TYPES = [
			'root', 'CompilationUnit', 'TypeDeclaration', 'FieldDeclaration', 'MethodDeclaration',
			'SimpleName', 'QualifiedName', 'SimpleType', 'PrimitiveType', 'SingleVariableDeclaration',
			'VariableDeclarationFragment', 'Modifier', 'Javadoc', 'TagElement', 'TextElement', 'ArrayType'
	]

	def initialize(options)
		super(options)
	end

	def run
		files = Dir["#{@source.folder}/src/main/java/**/*.java"]
		puts "#{files.length} files to process"
		db = {}
		files.each do |f|
			puts "processing #{f}"
			xml = `gumtree parse -f XML "#{f}"`
			doc = Nokogiri::XML(xml)
			db[f] = index_methods(strip(doc))
		end
		Oj.to_file("#{out.out}/#{@source.id}.json", db)
	end

	def index_methods(doc)
		res = []
		doc.xpath("//MethodDeclaration").each do |m|
			id = method_id(m)
			javadoc = {}
			javadoc['main'] = m.xpath("Javadoc/TagElement[not(@label)]/TextElement/@label").to_s
			javadoc['params'] = {}
			m.xpath("Javadoc/TagElement[@label='@param']").each do |p|
				javadoc['params'][p.at_xpath("SimpleName/@label").to_s] = p.xpath("TextElement/@label").to_s
			end
			javadoc['return'] = m.xpath("Javadoc/TagElement[@label='@return']/TextElement/@label").to_s
			res << [id, javadoc]
		end
		res
	end

	def method_id(m)
		res = ""
		modifiers = m.xpath("Modifier/@label")
		res += "#{modifiers} " unless modifiers.empty?
		res += "#{type(m)} #{m.at_xpath('SimpleName/@label')}("
		params = m.xpath("SingleVariableDeclaration").map { |p| "#{type(p)} #{p.at_xpath('SimpleName/@label')}" }.join(',')
		res += "#{params})"
		res
	end

	def type(e)
		return e.at_xpath('SimpleType/@label').to_s unless e.at_xpath('SimpleType').nil?
		return e.at_xpath('PrimitiveType/@label').to_s unless e.at_xpath('PrimitiveType').nil?
		return e.at_xpath('ArrayType/@label').to_s unless e.at_xpath('ArrayType').nil?
		""
	end

	def strip(doc)
		active = []
		doc.children.each do |c|
			if VALID_TYPES.include?(c.name)
				active << c
			else
				c.unlink
			end
		end
		active.each { |a| strip(a) }
		doc
	end

	def clean
	end
end
