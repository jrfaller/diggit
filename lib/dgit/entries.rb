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
	# Journal entry for elements that can have error.
	#
	# @!attribute [r] error
	# 	@return [ErrorEntry, nil] the error entry.
	module EntryWithError
		attr_reader :error

		# Set the error of the entry.
		# @param e [Exception, nil] the error, to indicate an absence of error, pass +nil+.
		# @return [void]
		def error=(e)
			@error = e.nil? ? nil : ErrorEntry.new(e)
		end
	end

	# Journal entry for elements that can launch runnables.
	#
	# @!attribute [r] performed
	# 	@return [Array<RunnableEntry>] the list of performed runnables.
	# @!attribute [r] canceled
	# 	@return [Array<RunnableEntry>] the list of canceled runnables.
	class EntryWithRunnables
		attr_reader :performed, :canceled

		def initialize
			@performed = []
			@canceled = []
		end

		# Error status of the element.
		# @return [Boolean]
		def error?
			!@canceled.empty?
		end

		# Check if a runnable has been performed or canceled.
		# @param runnable_or_string [Runnable, String] the runnable or the name of the runnable.
		# @param state [Symbol] the status of the runnable: `:performed`, `:canceled` or `:all`.
		# @return [Boolean]
		def has?(runnable_or_string, state = :all)
			name = retrieve_name(runnable_or_string)
			return @performed.count { |e| e.name == name } > 0 if state == :performed
			return @canceled.count { |e| e.name == name } > 0 if state == :canceled
			return (@performed + @canceled).count { |e| e.name == name } > 0 if state == :all
		end

		# Remove a runnable from all the entries.
		# @param runnable_or_string [Runnable, String] the runnable or the name of the runnable
		# @return [void]
		def clean(runnable_or_string)
			name = retrieve_name(runnable_or_string)
			@performed.delete_if { |e| e.name == name }
			@canceled.delete_if { |e| e.name == name }
		end

			private

		def retrieve_name(runnable_or_string)
			return runnable_or_string if runnable_or_string.is_a? String
			runnable_or_string.name
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
			@name = runnable.name
			@end = nil
			tic
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

		def duration
			@end - @start
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
