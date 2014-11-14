require 'spec_helper'
require 'fileutils'
require 'oj'

FileUtils.rm_rf('tmp')
FileUtils.mkdir('tmp')
FileUtils.cd('tmp')

TEST_URL = "https://github.com/jrfaller/test-git"
TEST_FOLDER = "https_github_com_jrfaller_test-git"
WRONG_URL = "foo"

RSpec.describe Diggit::Cli::DiggitCli do

	it "should init a diggit folder" do
		result = capture(:stdout) { Diggit::Cli::DiggitCli.start(["init"]) }
		expect(result).to include("folder successfully initialized")
		expect(sources).to be_empty
		expect(log).to be_empty
		expect(config).to eq({analyses: [], addons: [], joins: [],  options: {}})
	end

	it "should add an url" do
		Diggit::Cli::DiggitCli.start(["sources", "add", TEST_URL])
		expect(sources).to include(TEST_URL)
	end

	it "should add another url" do
		Diggit::Cli::DiggitCli.start(["sources", "add", WRONG_URL])
		expect(sources).to include(WRONG_URL)
	end

	it "should list the sources" do
		result = capture(:stdout) { Diggit::Cli::DiggitCli.start(["sources", "list"]) }
		expect(result).to include(TEST_URL)
		expect(result).to include(WRONG_URL)
	end

	it "should display the status" do
		result = capture(:stdout) { Diggit::Cli::DiggitCli.start(["status"]) }
		expect(result).to include("2 new (0 errors)")
	end

	it "should add an analysis" do
		Diggit::Cli::DiggitCli.start(["analyses", "add", "TestAnalysis"])
		expect(config[:analyses]).to eq(["TestAnalysis"])
	end

	it "should add an addon" do
		Diggit::Cli::DiggitCli.start(["addons", "add", "TestAddon"])
		expect(config[:addons]).to eq(["TestAddon"])
	end

	it "should add a join" do
		Diggit::Cli::DiggitCli.start(["joins", "add", "TestJoin"])
		expect(config[:joins]).to eq(["TestJoin"])
	end

	it "should perform clones on all urls, handling errors" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["perform", "clones"]) }
		expect(results).to include("#{TEST_URL} cloned")
		expect(log[TEST_URL]).to include(state: :cloned, error: {})
		expect(File.exist?(File.expand_path(TEST_FOLDER,Diggit::SOURCES_FOLDER))).to be true
		expect(results).to include("error cloning foo")
		expect(log[WRONG_URL][:state]).to eq(:new)
		expect(log[WRONG_URL][:error]).to include(name: "Rugged::NetworkError")
	end

	it "should display info on a regular url" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["sources", "info", TEST_URL]) }
		expect(results).to include("cloned")
		expect(results).to include(TEST_URL)
	end

	it "should display info and error on an url in error" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["sources", "info", WRONG_URL]) }
		expect(results).to include("new")
		expect(results).to include(WRONG_URL)
		expect(results).to include("error")
		expect(results).to include("Rugged::NetworkError")
	end

	it "should display all errors" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["sources", "errors"]) }
		expect(results).to include("new")
		expect(results).to include(WRONG_URL)
		expect(results).to include("error")
		expect(results).to include("Rugged::NetworkError")
	end

	it "should remove urls" do
		Diggit::Cli::DiggitCli.start(["sources", "rem", WRONG_URL])
		expect(sources).to_not include(WRONG_URL)
	end

	it "should perform analyses" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["perform", "analyses"]) }
		expect(results).to include("TestAnalysis performed")
		expect(results).to include("source #{TEST_URL} analyzed")
		expect(log[TEST_URL][:state]).to eq(:finished)
	end

	it "should perform joins" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["perform", "joins"]) }
		expect(results).to include("TestJoin performed")
		expect(results).to include("joins performed")
	end

	it "should clean joins" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["clean", "joins"]) }
		expect(results).to include("TestJoin cleaned")
	end

	it "should clean analyses" do
		results = capture(:stdout) { Diggit::Cli::DiggitCli.start(["clean", "analyses"]) }
		expect(results).to include("TestAnalysis cleaned on #{TEST_URL}")
		expect(log[TEST_URL][:state]).to eq(:cloned)
	end

	it "should remove a join" do
		Diggit::Cli::DiggitCli.start(["joins", "rem", "TestJoin"])
		expect(config[:addons]).not_to include("TestJoin")
	end

	it "should remove an analysis" do
		Diggit::Cli::DiggitCli.start(["analyses", "rem", "TestAnalysis"])
		expect(config[:analyses]).not_to include("TestAnalysis")
	end

	it "should remove an addon" do
		Diggit::Cli::DiggitCli.start(["addons", "rem", "TestAddon"])
		expect(config[:addons]).not_to include("TestAddon")
	end

end
