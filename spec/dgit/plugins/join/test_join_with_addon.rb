# encoding: utf-8

class TestJoinWithAddon < Diggit::Join
	require_addons 'test_addon'
	require_analyses 'test_analysis_with_error'
end
