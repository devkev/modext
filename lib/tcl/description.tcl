
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


#puts stderr "get going"

proc description { script } {

	#puts stderr "this is the default"

	#package require modext
	set ::rc [catch { package require modext } ::errmsg]
	if { $::rc == 1 } {
		# FIXME: logging
		puts stderr ""
		puts -nonewline stderr "LOW-LEVEL MODEXT ERROR DETECTED"
		if { ! [string equal $::errorCode NONE] } {
			puts -nonewline stderr " (error code: $::errorCode)"
		}
		puts -nonewline stderr ": "
		puts stderr "$::errorInfo"
		error "$::errmsg" $::errorInfo $::errorCode
	}

	#puts stderr "got it"

	uplevel 1 [list description $script]

	#puts stderr "yikes"
}

