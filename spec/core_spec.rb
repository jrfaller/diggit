# encoding: utf-8

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

	it "should perform analyses" do
		Diggit::Dig.it.config.add_analysis("test_analysis")
		Diggit::Dig.it.analyze
		# expect(TestAnalysis.state).to eq("runned")
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].all_analyses).to include("test_analysis")
		Diggit::Dig.init("spec/dgit")
		expect(Diggit::Dig.it.journal.sources_by_ids(0)[0].all_analyses).to include("test_analysis")
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
		Diggit::Dig.it.join
		expect(Diggit::Dig.it.journal.join?("test_join")).to be true
		expect(TestJoin.sources.size).to eq 1
		expect(TestJoin.sources[0].url).to eq TEST_URL
		expect(Diggit::Dig.it.journal.join?("test_join_with_addon")).to be false
	end
end
