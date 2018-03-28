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

	VALID_TYPES = %w[
			root CompilationUnit TypeDeclaration FieldDeclaration MethodDeclaration SimpleName QualifiedName
			QualifiedName SimpleType PrimitiveType ArrayType SingleVariableDeclaration VariableDeclarationFragment
			Modifier Javadoc TagElement TextElement MarkerAnnotation MethodRef
	].freeze

	def initialize(options)
		super(options)
	end

	def run
		FileUtils.mkdir_p(out.out_path_for_analysis(self))
		files = Dir["#{@source.folder}/src/main/java/**/*.java"]
		puts "#{files.length} files to process"
		db = {}

		files.each do |f|
			puts "processing #{f}"
			xml = `gumtree parse -f XML "#{f}"`
			doc = strip(Nokogiri::XML(xml))
			db[f] = index_methods(doc)
		end

		Oj.to_file(file, db)
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

			javadoc["params"] = get_params(m)
			javadoc["see"] = get_see(m)
			javadoc["throws"] = get_throws(m)
			javadoc["links"] = get_links(m)
			javadoc['return'] = m.xpath("Javadoc/TagElement[@label='@return']/TextElement/@label").to_s

			res["methods"] << [id, javadoc]
			res["metrics"]["nb_method_override"] = override_count
			res["metrics"]["nb_method_override_inheritdoc"] = override_inherit_count
		end

		res
	end

	def method_id(method)
		res = ""
		modifiers = method.xpath("Modifier/@label")
		res += "#{modifiers} " unless modifiers.empty?
		res += "#{type(method)} #{method.at_xpath('SimpleName/@label')}("
		param_list = method.xpath("SingleVariableDeclaration").map do |p|
			"#{type(p)} #{p.at_xpath('SimpleName/@label')}"
		end
		params = param_list.join(',')
		res += "#{params})"
		res
	end

	def type(element)
		return element.at_xpath('SimpleType/@label').to_s unless element.at_xpath('SimpleType').nil?
		return element.at_xpath('PrimitiveType/@label').to_s unless element.at_xpath('PrimitiveType').nil?
		return element.at_xpath('ArrayType/@label').to_s unless element.at_xpath('ArrayType').nil?
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

	def get_params(method)
		data = {}
		method.xpath("Javadoc/TagElement[@label='@param']").each do |p|
			data[p.at_xpath("SimpleName/@label").to_s] = [] if data[p.at_xpath("SimpleName/@label").to_s].nil?

			data[p.at_xpath("SimpleName/@label").to_s].push(p.xpath("TextElement/@label").to_s)
		end
		data
	end

	def get_links(method)
		method.xpath("Javadoc/TagElement/TagElement[@label='@link']").map { |p| p.xpath('QualifiedName/@label').to_s }
	end

	def get_throws(method)
		throws = {}
		method.xpath("Javadoc/TagElement[@label='@throws']").each do |p|
			throws[p.at_xpath("SimpleName/@label").to_s] = p.xpath("TextElement/@label").to_s
		end
		throws
	end

	def get_see(method)
		method.xpath("Javadoc/TagElement[@label='@see']/MethodRef").map { |p| p.xpath('SimpleName/@label').to_s }
	end

	def count_classes(doc)
		doc.xpath("//TypeDeclaration").count
	end

	def count_methods(doc)
		doc.xpath("//MethodDeclaration").count
	end

	def count_commented_classes(doc)
		doc.xpath("//TypeDeclaration/Javadoc").count
	end

	def count_commented_methods(doc)
		doc.xpath("//MethodDeclaration/Javadoc").count
	end

	def class_comment(doc)
		doc.xpath("//MethodDeclaration/Javadoc").to_s
	end

	def clean
		out.clean_analysis(self)
	end

	def file
		out.out_path_for_analysis(self, "javadoc.json")
	end
end
