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

require 'spec_helper'
require 'fileutils'

RSpec.describe Diggit::Dig do
	it "should refuse to be launched outside a dgit folder" do
		expect { Diggit::Dig.init("spec/dgit") }.to raise_error(/is not a diggit folder/)
	end

	it "should initialize a dgit folder" do
		expect { Diggit::Dig.init("spec/dgit") }.to raise_error(/is not a diggit folder/)
		Diggit::Dig.init_dir("spec/dgit")
		diggit = Diggit::Dig.init("spec/dgit")
		expect(diggit.config.to_hash).to eq(Diggit::Config.empty_config)
	end

	it "should not load a plugin with bad type" do
		expect { Diggit::Dig.it.plugin_loader.load_plugin("test_addon", :foo) }.to raise_error(/Unknown plugin type/)
		expect { Diggit::Dig.it.plugin_loader.load_plugin("test_addon", :analysis) }.to raise_error(/not found./)
	end

	it "should load an addon" do
		addon = Diggit::Dig.it.plugin_loader.load_plugin("test_addon", :addon)
		expect(addon.to_s).to eq("TestAddon")
		addon2 = Diggit::Dig.it.plugin_loader.load_plugin("test_addon", :addon)
		expect(addon2.to_s).to eq("TestAddon")
	end

	it "should load an analysis" do
		analysis = Diggit::Dig.it.plugin_loader.load_plugin("test_analysis", :analysis)
		expect(analysis.to_s).to eq('TestAnalysis')
		analysis = Diggit::Dig.it.plugin_loader.load_plugin("test_analysis_with_addon", :analysis)
		expect(analysis.to_s).to eq('TestAnalysisWithAddon')
		analysis_instance = analysis.new({})
		expect(analysis_instance.test_addon.foo).to eq("Foo.")
	end

	it "should load an analysis enlosed in a module" do
		analysis = Diggit::Dig.it.plugin_loader.load_plugin("other_analysis", :analysis)
		expect(analysis.to_s).to eq('MyModule::OtherAnalysis')
	end

	it "should emit a warning in case of ambiguous analysis name" do
		expect(Diggit::Dig.it.plugin_loader).to receive(:warn).with(/Ambiguous plugin name/)
		Diggit::Dig.it.plugin_loader.load_plugin("duplicate_analysis", :analysis)
	end

	it "should load a join" do
		join = Diggit::Dig.it.plugin_loader.load_plugin("test_join", :join)
		expect(join.to_s).to eq('TestJoin')
	end

	it "should load a join with addons" do
		join = Diggit::Dig.it.plugin_loader.load_plugin("test_join_with_addon", :join)
		expect(join.to_s).to eq('TestJoinWithAddon')
		join_instance = join.new({})
		expect(join_instance.test_addon.foo).to eq("Foo.")
	end

	it "should store analyses and joins" do
		Diggit::Dig.it.config.add_analysis("test_analysis")
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.config.to_hash).to eq({ analyses: ['test_analysis'], joins: [] })
		Diggit::Dig.it.config.del_analysis("test_analysis")
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.config.to_hash).to eq({ analyses: [], joins: [] })
		Diggit::Dig.it.config.add_join("test_join")
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.config.to_hash).to eq({ analyses: [], joins: ['test_join'] })
		Diggit::Dig.it.config.del_join("test_join")
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.config.to_hash).to eq({ analyses: [], joins: [] })
	end

	it "should store sources" do
		Diggit::Dig.it.journal.add_source(TEST_URL)
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.journal.sources_by_ids.first.url).to eq TEST_URL
	end

	it "should clone sources" do
		Diggit::Dig.it.clone
		expect(File.exist?("spec/dgit/sources/#{TEST_URL.id}/.git")).to be true
		src = Diggit::Dig.it.journal.sources_by_ids.first
		expect(src.url).to eq TEST_URL
		src.entry.state = :new
		Diggit::Dig.it.clone
		expect(src.url).to eq TEST_URL
		Diggit::Dig.init("spec/dgit")
		src = Diggit::Dig.it.journal.sources_by_ids.first
		expect(src.url).to eq TEST_URL
	end

	it "should perform analyses in order" do
		Diggit::Dig.it.config.add_analysis("test_analysis")
		expect_any_instance_of(TestAnalysis).to receive(:run)
		Diggit::Dig.it.config.add_analysis("test_analysis_with_addon")
		expect_any_instance_of(TestAnalysisWithAddon).to receive(:run)
		Diggit::Dig.it.analyze
		src = Diggit::Dig.it.journal.sources_by_ids.first
		expect(src.entry.has?("test_analysis", :performed)).to be true
		expect(src.entry.has?("test_analysis_with_addon", :performed)).to be true
		Diggit::Dig.init("spec/dgit")
		src = Diggit::Dig.it.journal.sources_by_ids.first
		expect(src.entry.has?("test_analysis", :performed)).to be true
		expect(src.entry.has?("test_analysis_with_addon", :performed)).to be true
	end

	it "should handle analyses with error" do
		Diggit::Dig.it.config.add_analysis("test_analysis_with_error")
		Diggit::Dig.it.analyze
		src = Diggit::Dig.it.journal.sources_by_ids.first
		expect(src.entry.has?("test_analysis_with_error", :performed)).to be false
		expect(src.entry.has?("test_analysis_with_error", :canceled)).to be true
		expect(src.entry.error?).to be true
		expect(src.entry.canceled.first.error.message).to eq("Error!")
	end

	it "should perform joins" do
		Diggit::Dig.it.config.add_join("test_join")
		Diggit::Dig.it.config.add_join("test_join_with_addon")
		expect_any_instance_of(TestJoin).to receive(:run)
		expect_any_instance_of(TestJoinWithAddon).not_to receive(:run)
		Diggit::Dig.it.join
		expect(Diggit::Dig.it.journal.workspace.has?("test_join", :performed)).to be true
		expect(Diggit::Dig.it.journal.workspace.has?("test_join_with_addon", :performed)).to be false
	end

	it "should handle joins with error" do
		Diggit::Dig.it.config.add_join("test_join_with_error")
		Diggit::Dig.it.join
		expect(Diggit::Dig.it.journal.workspace.has?("test_join_with_error", :performed)).to be false
		expect(Diggit::Dig.it.journal.workspace.has?("test_join_with_error", :canceled)).to be true
		expect(Diggit::Dig.it.journal.workspace.error?).to be true
		expect(Diggit::Dig.it.journal.workspace.canceled.first.error.message).to eq("Error!")
	end

	it "should clean joins" do
		expect_any_instance_of(TestJoin).to receive(:clean)
		expect_any_instance_of(TestJoinWithAddon).not_to receive(:clean)
		Diggit::Dig.it.join([], [], :clean)
		expect(Diggit::Dig.it.journal.workspace.has?("test_join")).to be false
		expect(Diggit::Dig.it.journal.workspace.has?("test_join_with_addon")).to be false
		Diggit::Dig.it.config.del_all_joins
	end

	it "should handle joins with clean errors" do
		Diggit::Dig.it.config.add_join("test_join_with_clean_error")
		Diggit::Dig.it.join
		expect(Diggit::Dig.it.journal.workspace.has?("test_join_with_clean_error", :performed)).to be true
		Diggit::Dig.it.join([], [], :clean)
		expect(Diggit::Dig.it.journal.workspace.has?("test_join_with_clean_error", :performed)).to be false
		expect(Diggit::Dig.it.journal.workspace.has?("test_join_with_clean_error", :canceled)).to be true
	end

	it "should clean analyses" do
		expect_any_instance_of(TestAnalysis).to receive(:clean)
		expect_any_instance_of(TestAnalysisWithAddon).to receive(:clean)
		Diggit::Dig.it.analyze([], [], :clean)
		src = Diggit::Dig.it.journal.sources_by_ids.first
		expect(src.entry.has?("test_analysis")).to be false
		expect(src.entry.has?("test_analysis_with_addon")).to be false
		Diggit::Dig.it.config.del_all_analyses
	end

	it "should handle analyses with clean errors" do
		Diggit::Dig.it.config.add_analysis("test_analysis_with_clean_error")
		Diggit::Dig.it.analyze([], ["test_analysis_with_clean_error"])
		src = Diggit::Dig.it.journal.sources_by_ids.first
		expect(src.entry.has?("test_analysis_with_clean_error", :performed)).to be true
		Diggit::Dig.it.analyze([], [], :clean)
		expect(src.entry.has?("test_analysis_with_clean_error", :performed)).to be false
		expect(src.entry.has?("test_analysis_with_clean_error", :canceled)).to be true
	end

	it "should read source options" do
		File.open("spec/dgit/.dgit/sources_options", "w") do |f|
			f.write('{
								"https://github.com/jrfaller/test-git.git":{
									"myOption":"myValue"
								}
							}')
		end

		Diggit::Dig.it.config.add_analysis("test_analysis_with_sources_options")
		expect { Diggit::Dig.it.analyze }.to output(/myValue/).to_stdout
		Diggit::Dig.it.config.del_all_analyses
	end
end
