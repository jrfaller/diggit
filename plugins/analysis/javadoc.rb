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

	VALID_TYPES = %w(
			root CompilationUnit TypeDeclaration FieldDeclaration MethodDeclaration SimpleName QualifiedName
			QualifiedName SimpleType PrimitiveType ArrayType SingleVariableDeclaration VariableDeclarationFragment
			Modifier Javadoc TagElement TextElement MarkerAnnotation
	).freeze

	def initialize(options)
		super(options)
	end

	def run
		files = Dir["#{@source.folder}/src/main/java/**/*.java"]
		puts "#{files.length} files to process"
		db = {}

		classes_count = 0
		methods_count = 0
		commented_classes = 0
		commented_methods = 0

		files.each do |f|
			puts "processing #{f}"
			xml = `gumtree parse -f XML "#{f}"`
			doc = strip(Nokogiri::XML(xml))
			db[f] = index_methods(doc)

			classes_count += count_classes(doc)
			methods_count += count_methods(doc)
			commented_methods += count_commented_methods(doc)
			commented_classes += count_commented_classes(doc)
		end

		Oj.to_file("#{out.out}/#{@source.id}.json", db)
	end

	def index_methods(doc)
		res = {}

		override_count = 0
		override_inherit_count = 0

		# Partie Metrics

		data = {}
		data["nb_class"] = count_classes(doc)
		data["nb_method"] = count_methods(doc)
		data["nb_class_commented"] = count_commented_classes(doc)
		data["nb_method_commented"] = count_commented_methods(doc)

		res["metrics"] = data

		# Partie methodes
		res["methods"] = []

		doc.xpath("//MethodDeclaration").each do |m|
			id = method_id(m)
			javadoc = {}
			javadoc['main'] = m.xpath("Javadoc/TagElement[not(@label)]/TextElement/@label").to_s
			javadoc['params'] = {}

			javadoc['override'] = false
			javadoc['inheritDoc'] = false
			m.xpath("MarkerAnnotation/SimpleName/@label").each do |k|
				next unless k.to_s.casecmp("override")
				javadoc['override'] = true
				override_count += 1

				if m.xpath("Javadoc/TagElement/TagElement[@label='@inheritDoc']").count > 0
					javadoc['inheritDoc'] = true
					override_inherit_count += 1
				end
			end

			m.xpath("Javadoc/TagElement[@label='@param']").each do |p|
				if javadoc['params'][p.at_xpath("SimpleName/@label").to_s].nil?
					javadoc['params'][p.at_xpath("SimpleName/@label").to_s] = []
				end

				javadoc['params'][p.at_xpath("SimpleName/@label").to_s].push(p.xpath("TextElement/@label").to_s)
			end

			javadoc['return'] = m.xpath("Javadoc/TagElement[@label='@return']/TextElement/@label").to_s
			res["methods"] << [id, javadoc]
			res["metrics"]["nb_method_override"] = override_count
			res["metrics"]["nb_method_override_inheritdoc"] = override_inherit_count
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

	def count_classes(doc)
		res = doc.xpath("//TypeDeclaration").count
		res
	end

	def count_methods(doc)
		res = doc.xpath("//MethodDeclaration").count
		res
	end

	def count_commented_classes(doc)
		res = doc.xpath("//TypeDeclaration/Javadoc").count
		res
	end

	def count_commented_methods(doc)
		res = doc.xpath("//MethodDeclaration/Javadoc").count
		res
	end

	def class_comment(doc)
		res = doc.xpath("//MethodDeclaration/Javadoc").to_s
		res
	end

	def clean
	end
end
