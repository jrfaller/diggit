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
# Copyright 2016 Jean-Rémy Falleri <jr.falleri@gmail.com>
# Copyright 2016 Mohamed A. OUMAZIZ <med@oumaziz.com>

require 'nokogiri'
require 'oj'

class Javadoc < Diggit::Analysis
	require_addons 'out'

	VALID_TYPES = %w(
			root CompilationUnit TypeDeclaration FieldDeclaration MethodDeclaration SimpleName QualifiedName
			QualifiedName SimpleType PrimitiveType ArrayType SingleVariableDeclaration VariableDeclarationFragment
			Modifier Javadoc TagElement TextElement MarkerAnnotation MethodRef MethodRefParameter MemberRef TypeParameter
			PackageDeclaration
	).freeze

	def initialize(options)
		super(options)
	end

	def run

		files = Dir["#{@source.folder}/src/main/**/*.java"]
		puts "#{files.length} files to process"
		db = {}

		files.each do |f|
			puts "processing #{f}"
			xml = `gumtree parse -f XML "#{f}"`
			doc = strip(Nokogiri::XML(xml))
			db[f] = index_methods(doc)
		end

		Oj.to_file("#{out.out}/#{@source.id}.json", db)
	end

	def index_methods(doc)
		res = {}

		# Class Part
		res["class"] = {}
		res["class"]["main"] = 	class_comment(doc)
		res["class"]["tags"] = class_tags(doc)

		# Class Fields Part
		res["fields"] = get_fields(doc)

		# Metrics Part
		data = {}
		data["nb_class"] = count_classes(doc)
		data["nb_method"] = count_methods(doc)
		data["nb_class_commented"] = count_commented_classes(doc)
		data["nb_method_commented"] = count_commented_methods(doc)
		data["nb_throws"] = count_throws(doc)
		data["nb_exception"] = count_exceptions(doc)

		res["metrics"] = data

		override_count = 0
		override_inherit_count = 0

		# Method Part
		res["methods"] = []

		package = doc.xpath("root/CompilationUnit/PackageDeclaration/QualifiedName/@label").to_s

		doc.xpath("root/CompilationUnit/TypeDeclaration").each do |c|
			parentFullName = package + "." + c.at_xpath("SimpleName/@label").to_s
			
			getMethodsRecursively(c, res, override_count, override_inherit_count, parentFullName)
		end

		res
	end

	def getMethodsRecursively(c, res, override_count, override_inherit_count, parentFullName)
		className = get_class_name(c) 

		if(c.xpath("MethodDeclaration").count > 0)
			c.xpath("MethodDeclaration").each do |m|
				id = method_id(m)

				javadoc = {}

				javadoc["method_name"] = m.at_xpath("SimpleName/@label").to_s
				javadoc["class_name"] = className
				javadoc["full_class_name"] = parentFullName
				javadoc['main'] = get_method_comment(m)
				javadoc['params'] = {}

				javadoc['override'] = false
				javadoc['inheritDoc'] = false
				m.xpath("MarkerAnnotation/SimpleName/@label").each do |k|

					next unless k.to_s.casecmp("override") == 0
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
				javadoc["exceptions"] = get_exceptions(m)
				javadoc["links"] = get_links(m)

				javadoc["since"] = m.xpath("Javadoc/TagElement[@label='@since']/TextElement/@label").to_s

				javadoc['return'] = get_return(m)

				res["methods"] << [id, javadoc]
				res["metrics"]["nb_method_override"] = override_count
				res["metrics"]["nb_method_override_inheritdoc"] = override_inherit_count
			end
		end

		if(c.xpath("TypeDeclaration").count > 0)
			c.xpath("TypeDeclaration").each do |t|
				getMethodsRecursively(t, res, override_count, override_inherit_count, parentFullName + "." + t.at_xpath("SimpleName/@label").to_s)
			end
		end

	end

	def method_id(m)
		res = ""
		modifiers = m.xpath("Modifier").map{ |q| q.xpath("@label")}.join(" ")
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

	def get_params(m)
		data = {}
		m.xpath("Javadoc/TagElement[@label='@param']").each do |p|
			if data[p.at_xpath("SimpleName/@label").to_s].nil?
				data[p.at_xpath("SimpleName/@label").to_s] = []
			end

			param = ""
			p.xpath("./*").each do |q|
				if q.name == "TextElement"
					param += q.xpath("@label").to_s
				end

				if q.name == "TagElement"
					param += get_link(q)
				end
			end

			data[p.at_xpath("SimpleName/@label").to_s].push(param)
		end
		data
	end

	def get_links(m)
		m.xpath("Javadoc/TagElement/TagElement[@label='@link']").map { |p| 
			if p.at_xpath("SimpleName").nil? 
				p.xpath('QualifiedName/@label').to_s 
			else
				p.xpath('SimpleName/@label').to_s 
			end
		}
	end

	def get_throws(m)
		throws = {}
		m.xpath("Javadoc/TagElement[@label='@throws']").each do |p|
			id = ""
			p.xpath("./*").each do |q|
				if q.name == "QualifiedName"
					id = p.at_xpath("QualifiedName/@label").to_s
					throws[id] = ""
				end

				if q.name == "SimpleName"
					id = p.at_xpath("SimpleName/@label").to_s
					throws[id] = ""
				end

				if q.xpath("@label").to_s == "@link" || q.xpath("@label").to_s == "@code"
					throws[id] += get_link(q)
				end

				if q.name == "TextElement"
					throws[id] += q.xpath("@label").to_s
				end
			end
		end

		throws
	end

	def get_exceptions(m)
		exceptions = {}
		m.xpath("Javadoc/TagElement[@label='@exception']").each do |p|
			id = ""
			p.xpath("./*").each do |q|
				if q.name == "QualifiedName"
					id = p.at_xpath("QualifiedName/@label").to_s
					exceptions[id] = ""
				end

				if q.name == "SimpleName"
					id = p.at_xpath("SimpleName/@label").to_s
					exceptions[id] = ""
				end

				if q.xpath("@label").to_s == "@link" || q.xpath("@label").to_s == "@code"
					exceptions[id] += get_link(q)
				end

				if q.name == "TextElement"
					exceptions[id] += q.xpath("@label").to_s
				end
			end
		end

		exceptions
	end

	def get_return(m)
		res = ""
		m.xpath("Javadoc/TagElement[@label='@return']/*").each do |p|
			if p.name == "TextElement"
				res += p.xpath("@label").to_s
			else
				res += get_link(p)
			end
		end
		res
	end

	def get_see(m)
		m.xpath("Javadoc/TagElement[@label='@see']/MethodRef").map { |p| p.xpath('SimpleName').map{ |q| q.xpath("@label")}.join("#") }
	end

	def get_method_comment(m)
		main = ""
		m.xpath("Javadoc/TagElement[not(@label)]/*").each do |p|
			if p.at_xpath("QualifiedName/@label").nil? && p.at_xpath("SimpleName/@label").nil? && (p.xpath("MethodRef").count == 0) && (p.xpath("TextElement").count == 0) && p.name != "TagElement"
				main += p.at_xpath("@label").to_s
			else
				main += get_link(p)
			end
		end
		main
	end

	def get_link(p)
		link = ""

		if p.xpath("SimpleName").count > 0
			link += "{@link " + p.at_xpath("SimpleName/@label").to_s + "}"
		end

		if p.xpath("QualifiedName").count > 0
			link += "{@link " + p.at_xpath("QualifiedName/@label").to_s  + "}"
		end

		if p.xpath("TextElement").count > 0
			if p.xpath("@label").to_s == "@code"
				link += "{@code " + p.at_xpath("TextElement/@label").to_s.lstrip.rstrip  + "}"
			else
				link += "{@link #" + p.at_xpath("TextElement/@label").to_s.lstrip.rstrip  + "}"
			end
		end

		if p.xpath("MemberRef").count > 0
			link += "{@link " + p.xpath("MemberRef").map{ |q| q.xpath("SimpleName/@label")}.join("#") + "}"
		end
			
		methodref = ""

		if p.xpath("MethodRef").count > 0 
			if p.xpath("MethodRef/SimpleName").count > 1
				methodref += "{@link " + p.xpath("MethodRef").map { |s| s.xpath('SimpleName').map{ |q| q.xpath("@label")}.join("#") }.join("#").to_s + '('
			else
				methodref += "{@link #" + p.xpath("MethodRef/SimpleName/@label").to_s + '('
			end

			if p.xpath("MethodRef/MethodRefParameter/SimpleName").count > 0
				methodref += p.xpath("MethodRef/*/*/@label").each_slice(2).map { |q| "#{q.first} #{q.last}" }.join(", ")
			else
				methodref += p.xpath("MethodRef/*/*/@label").map { |q| q }.join(", ")
			end
		end
			
		if methodref != ""
			methodref += ')' + p.xpath("TextElement/@label").to_s + '}'
			link += methodref
		end
		link
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

	def count_throws(doc)
		doc.xpath("//Javadoc/TagElement[@label='@throws']").count
	end

	def count_exceptions(doc)
		doc.xpath("//Javadoc/TagElement[@label='@exception']").count
	end

	def class_comment(doc)
		main = ""
		doc.xpath("//TypeDeclaration/Javadoc/TagElement[not(@label)]/*").each do |p|
			if p.name == "TagElement"
				main += get_link(p)
			else
				main += p.at_xpath("@label").to_s
			end
		end
		main
	end

	def class_tags(doc) 
		tags = {}
		doc.xpath("//TypeDeclaration/Javadoc/TagElement[@label]").each do |p|
			if tags[p.xpath("@label").to_s].nil?
				tags[p.xpath("@label").to_s] = []
			end

			tags[p.xpath("@label").to_s].push(p.xpath("TextElement/@label").to_s)
		end
		tags
	end

	def get_fields(doc)
		fields = {}

		doc.xpath("//FieldDeclaration").each do |f|
			modifiers = ""
			res = ""

			modifiers = f.xpath("Modifier").map{ |q| q.xpath("@label")}.join(" ")
			res += "#{modifiers} " unless modifiers.empty?
			res += "#{type(f)} #{f.at_xpath('SimpleName/@label')}"
			res += f.xpath("VariableDeclarationFragment/SimpleName/@label").to_s

			desc = ""
			f.xpath("Javadoc/TagElement[not(@label)]/*").each do |p|
				if p.name == "TextElement"
					desc += p.xpath("@label").to_s
				else
					desc += get_link(p)
				end
			end
			
			fields[res] = desc
		end
		fields
	end

	def get_class_name(doc)
		name = doc.at_xpath("SimpleName/@label").to_s
		if doc.xpath("TypeParameter").count > 0
			name += "<"
			name += doc.xpath("TypeParameter/SimpleName/@label").map{|q| q}.join(",")
			name += ">"
		end

		name
	end

	def clean
	end
end
