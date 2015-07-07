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

FileUtils.rm_rf('spec/dgit/.dgit')
FileUtils.rm_rf('spec/dgit/sources')

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
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].url).to eq TEST_URL
	end

	it "should clone sources" do
		Diggit::Dig.it.clone
		expect(File.exist?("spec/dgit/sources/#{TEST_URL.id}/.git")).to be true
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].url).to eq TEST_URL
		Diggit::Dig.it.journal.sources_by_ids(0)[0].state = :new
		Diggit::Dig.it.clone
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].url).to eq TEST_URL
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].url).to eq TEST_URL
	end

	it "should perform analyses in order" do
		Diggit::Dig.it.config.add_analysis("test_analysis")
		expect_any_instance_of(TestAnalysis).to receive(:run)
		Diggit::Dig.it.config.add_analysis("test_analysis_with_addon")
		expect_any_instance_of(TestAnalysisWithAddon).to receive(:run)
		Diggit::Dig.it.analyze
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].all_analyses).to eq(%w(test_analysis test_analysis_with_addon))
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].all_analyses).to eq(%w(test_analysis test_analysis_with_addon))
	end

	it "should handle analyses with error" do
		Diggit::Dig.it.config.add_analysis("test_analysis_with_error")
		Diggit::Dig.it.analyze
		src = Diggit::Dig.it.journal.sources_by_ids(0)[0]
		expect(src.all_analyses).to include("test_analysis")
		expect(src.error?).to be true
		expect(src.error[:message]).to eq("Error!")
	end

	it "should perform joins" do
		Diggit::Dig.it.config.add_join("test_join")
		Diggit::Dig.it.config.add_join("test_join_with_addon")
		expect_any_instance_of(TestJoin).to receive(:run)
		expect_any_instance_of(TestJoinWithAddon).not_to receive(:run)
		Diggit::Dig.it.join
		expect(Diggit::Dig.it.journal.join?("test_join")).to be true
		expect(Diggit::Dig.it.journal.join?("test_join_with_addon")).to be false
	end

	it "should clean joins" do
		expect_any_instance_of(TestJoin).to receive(:clean)
		expect_any_instance_of(TestJoinWithAddon).to receive(:clean)
		Diggit::Dig.it.join([], [], :clean)
	end

	it "should clean analyses" do
		expect_any_instance_of(TestAnalysis).to receive(:clean)
		expect_any_instance_of(TestAnalysisWithAddon).to receive(:clean)
		Diggit::Dig.it.analyze([], [], :clean)
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].all_analyses).to eq([])
	end
end
