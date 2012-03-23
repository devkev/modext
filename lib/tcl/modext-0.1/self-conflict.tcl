
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


# conflict with self, unless requested not to



set internal::inhibit_self_conflict 0
proc internal::init-inhibit_self_conflict { } {
	set ::modext::internal::inhibit_self_conflict 0
}
::modext::internal::init-inhibit_self_conflict

proc ::inhibit-self-conflict { } {
	set ::modext::internal::inhibit_self_conflict 1
}

proc perform-self-conflict-if-necessary { } {
	if { ! $::modext::internal::inhibit_self_conflict } {
		if { ! [string equal $::package ""] } {
			conflict $::package
		}
	}
}

stack-proc ::conflict { args } {
	# User usage of the conflict command implicitly inhibits
	# the automatic self conflict.
	inhibit-self-conflict

	return [eval call-upper $args]
}


