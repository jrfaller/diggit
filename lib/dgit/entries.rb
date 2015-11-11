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

module Diggit
	module EntryWithError
		attr_reader :error

		def error=(e)
			if e.nil?
				@error = nil
			else
				@error = ErrorEntry.new(e)
			end
		end
	end

	class EntryWithRunnables
		attr_reader :performed, :canceled

		def initialize
			@performed = []
			@canceled = []
		end

		def error?
			@canceled.size > 0
		end

		def has?(runnable_or_string, state = :all)
			name = retrieve_name(runnable_or_string)
			if state == :performed
				return @performed.count { |e| e.name == name } > 0
			elsif state == :canceled
				return @canceled.count { |e| e.name == name } > 0
			elsif state == :all
				return (@performed + @canceled).count { |e| e.name == name } > 0
			end
		end

		def clean(runnable_or_string)
			name = retrieve_name(runnable_or_string)
			@performed.delete_if { |e| e.name == name }
			@canceled.delete_if { |e| e.name == name }
		end

			private

		def retrieve_name(runnable_or_string)
			if runnable_or_string.is_a? String
				return runnable_or_string
			else
				return runnable_or_string.name
			end
		end
	end

	class ErrorEntry
		attr_reader :name, :message, :backtrace

		def initialize(error)
			@name = error.class.name
			@message = error.to_s
			@backtrace = error.backtrace
		end
	end

	class RunnableEntry
		include EntryWithError
		attr_accessor :start, :end, :name

		def initialize(runnable)
			@start = nil
			@end = nil
			@name = runnable.name
		end

		def error?
			!@error.nil?
		end

		def tic
			@start = Time.now
		end

		def toc
			@end = Time.now
		end
	end

	class SourceEntry < EntryWithRunnables
		include EntryWithError
		attr_accessor :state

		def initialize
			super
			@state = :new
		end

		def error?
			super || !@error.nil?
		end

		def new?
			@state == :new
		end

		def cloned?
			@state == :cloned
		end
	end

	class WorkspaceEntry < EntryWithRunnables
		def initialize
			super
		end
	end
end
