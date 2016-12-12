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

RSpec.describe Diggit do
	it "should init a dgit folder" do
		out = `bin/dgit -f spec/dgit init`
		expect(out).to match(/Diggit folder initialized/)
	end

	it "should display status" do
		out = `bin/dgit -f spec/dgit status`
		expect(out).to match(/Config/)
	end

	it "should add a source" do
		`bin/dgit -f spec/dgit sources add "#{TEST_URL}"`
		out = `bin/dgit -f spec/dgit sources list`
		expect(out).to match(/#{TEST_URL_INFO1}/)
		expect(out).to match(/new/)
	end

	it "should del a source" do
		`bin/dgit -f spec/dgit sources add http://foo`
		out = `bin/dgit -f spec/dgit sources list`
		expect(out).to match(/foo/)
		out = `bin/dgit -f spec/dgit sources del 1`
		expect(out).to_not match(/foo/)
	end

	it "should perform clones" do
		`bin/dgit -f spec/dgit clones perform`
		out = `bin/dgit -f spec/dgit sources list`
		expect(out).to match(/cloned/)
	end

	it "should add an analysis" do
		`bin/dgit -f spec/dgit analyses add test_analysis`
		out = `bin/dgit -f spec/dgit status`
		expect(out).to match(/test_analysis/)
	end

	it "should perform the analyses" do
		`bin/dgit -f spec/dgit analyses perform`
		out = `bin/dgit -f spec/dgit sources info 0`
		expect(out).to match(/test_analysis/)
		expect(out).to match(/Performed/)
		expect(out).to_not match(/Canceled/)
	end

	it "should handle analyses with errors" do
		`bin/dgit -f spec/dgit analyses add test_analysis_with_error`
		`bin/dgit -f spec/dgit analyses perform`
		out = `bin/dgit -f spec/dgit sources info 0`
		expect(out).to match(/test_analysis_with_error/)
		expect(out).to match(/Canceled/)
		expect(out).to match(/Error!/)
	end

	it "should add joins" do
		`bin/dgit -f spec/dgit joins add test_join`
		out = `bin/dgit -f spec/dgit status`
		expect(out).to match(/test_join/)
		expect(out).to_not match(/Performed joins/)
	end

	it "should perform joins" do
		`bin/dgit -f spec/dgit joins perform`
		out = `bin/dgit -f spec/dgit status`
		expect(out).to match(/test_join/)
		expect(out).to match(/Performed joins/)
	end

	it "should handle joins with errors" do
		`bin/dgit -f spec/dgit joins add test_join_with_error`
		`bin/dgit -f spec/dgit joins perform`
		out = `bin/dgit -f spec/dgit status`
		expect(out).to match(/test_join_with_error/)
		expect(out).to match(/Canceled/)
		expect(out).to match(/Error!/)
	end

	it "should clean joins" do
		`bin/dgit -f spec/dgit joins perform -m clean`
		out = `bin/dgit -f spec/dgit status`
		expect(out).to_not match(/Canceled/)
		expect(out).to_not match(/Performed/)
	end

	it "should clean anlyses" do
		`bin/dgit -f spec/dgit analyses perform -m clean`
		out = `bin/dgit -f spec/dgit sources info 0`
		expect(out).to_not match(/Canceled/)
		expect(out).to_not match(/Performed/)
	end
end
