
# Copyright (C) 2012 Kevin Pulo and the Australian National University.
#
# This file is part of modext.
# 
# modext is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# modext is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with modext.  If not, see <http://www.gnu.org/licenses/>.


# debug stuff


if { ! [info exists show-debug-count] } {
	set show-debug-count 0
}

proc show-debug { msg } {
	set check-function ::modext::option::is-option-enabled
	if { ${::modext::show-debug-count} > 0 } {
		# reentry, use the basic option check
		set check-function ::modext::option::is-option-enabled-basic
	}
	incr ::modext::show-debug-count 1

	# We check that this isn't the o/show-debug module itself to stop stupid
	# extraneous tracing info being spat out during (for example) module show
	# o/show-debug and module whatis o/show-debug.  Modules is very dumb, and
	# it modifies $::env when setenv is called, even in module show/whatis (and
	# probably other non-load ones as well).
	if { [${check-function} show-debug] && [::module-info name] != "o/show-debug" } {
		puts stderr "DEBUG: $msg"
	}

	incr ::modext::show-debug-count -1
}


