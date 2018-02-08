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
# Copyright 2018 Jean-Rémy Falleri <jr.falleri@gmail.com>

require 'yaml'
require 'yard'
require 'levenshtein'
require 'gruff'

# List all yardoc duplications
class YardDup < Diggit::Analysis
	require_addons 'out'

	def initialize(options)
		super(options)
	end

	def run
		Log.info "processing yardoc of #{@source.id}"
		out_dir = out.out_path_for_analysis(self)
		FileUtils.mkdir_p(out_dir)
		doc_hash = {}
		YARD::Registry.clear
		YARD::Registry.load(Dir["#{source.folder}/**/*.rb"], true)
		objects = YARD::Registry.all(:method)
		Log.info "processing #{objects.size} documented methods"
		objects.each do |obj|
			insert_to_map("@main #{obj.docstring}", doc_hash, obj) unless obj.docstring.empty?
			obj.tags.each do |tag|
				next if tag.nil?
				tag_tokens = []
				tag_tokens << "@#{tag.tag_name}" unless tag.tag_name.nil?
				tag_tokens << tag.types.join(',') unless tag.types.nil? || tag.types.empty?
				tag_tokens << tag.text unless tag.text.nil?
				insert_to_map(tag_tokens.join(' '), doc_hash, obj)
			end
		end
		write_duplications(File.join(out_dir, "duplications.txt"), doc_hash)
		puts_duplicated_methods(doc_hash)
		plot_duplications(File.join(out_dir, "duplications.png"), doc_hash)
		write_near_miss(File.join(out_dir, "near-miss.txt"), doc_hash)
	end

	def similarity(s1, s2)
		d_norm = Levenshtein.distance(s1, s2).to_f / [s1.size.to_f, s2.size.to_f].max
		1 - d_norm
	end

	def puts_duplicated_methods(doc_hash)
		obj_hash = {}
		doc_hash.each_value do |value|
			value.each { |obj| obj_hash[obj] = true } if value.size > 2
		end
		Log.info "#{obj_hash.each_key.to_a.size} method involved in duplications"
	end

	def write_duplications(file, doc_hash)
		File.open(file, 'w') do |f|
			doc_hash.each { |key, value| f.write "#{key} (#{value.size}) #{value}\n" if value.size > 1 }
		end
	end

	def plot_duplications(file, doc_hash)
		dup_hash = {}
		doc_hash.each_value do |value|
			dup_hash[value.size] = if dup_hash.key?(value.size)
																											dup_hash[value.size] + 1
																										else
																											1
																										end
		end
		g = Gruff::Bar.new
		g.hide_legend = true
		dup_numbers = 2..dup_hash.each_key.to_a.max
		dup_numbers.each do |dup|
			if dup_hash.key?(dup)
				g.data(dup, dup_hash[dup])
			else
				g.data(dup, 0)
			end
		end
		g.write(file)
	end

	def write_near_miss(file, doc_hash)
		keys = doc_hash.each_key.to_a
		return if keys.size < 2
		File.open(file, 'w') do |f|
			(0..(keys.size - 2)).each do |i|
				key1 = keys[i]
				key2 = keys[i + 1]
				sim = similarity(key1, key2)
				f.write "(#{sim}) #{key1} || #{key2}\n" if sim > 0.8
			end
		end
	end

	def insert_to_map(key, hash, obj)
		hash[key] = [] unless hash.key?(key)
		hash[key] << "#{obj.file} #{obj.path}"
	end

	def clean
		out.clean_analysis(self)
	end
end
