
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


# helper for accessing environment variables



# FIXME: if-envvar-contains


single-OptProc env {
	{ -default -any "" }
	{ -prefix -any "" }
	{ -suffix -any "" }
	{ var -any }
   	{ ?olddefault? "" }
} {
	if { ! [string equal $olddefault ""] && [string equal $default ""] } {
		set default $olddefault
	}

	# is [info exists ::env($var)] better?
	if { [array names ::env -exact $var] == $var } {
		if { [string equal $::env($var) ""] } {
			return ""
		} else {
			return "$prefix$::env($var)$suffix"
		}
	} else {
		return "$default"
	}
}

single-OptProc if-envvar-set {
   	{ args }
} {
	if { [llength $args] == 0 } {
		return
	}

	set var [lindex $args 0]
	if { [string equal $var "setenv"] } {
		set var [lindex $args 1]
		set subcmd $args
	} elseif { [llength $args] == 1 } {
		set splitted [split [string trim $var]]
		if { [string equal [lindex $splitted 0] "setenv" ] } {
			set var [lindex $splitted 1]
			set subcmd $args
		} else {
			return
		}
	} else {
		if { [llength $args] == 2 } {
			set subcmd [lindex $args 1]
		} else {
			set subcmd [lrange $args 1 end]
		}
	}

	# is [info exists ::env($var)] better?
	if { [array names ::env -exact $var] == $var } {
		if { [llength $subcmd] == 1 } {
			set subcmd [lindex $subcmd 0]
		}
		return [uplevel 1 $subcmd]
	}
}


single-OptProc if-envvar-unset {
   	{ args }
} {
	if { [llength $args] == 0 } {
		return
	}

	set var [lindex $args 0]
	if { [string equal $var "setenv"] } {
		set var [lindex $args 1]
		set subcmd $args
	} elseif { [llength $args] == 1 } {
		set splitted [split [string trim $var]]
		if { [string equal [lindex $splitted 0] "setenv" ] } {
			set var [lindex $splitted 1]
			set subcmd $args
		} else {
			return
		}
	} else {
		if { [llength $args] == 2 } {
			set subcmd [lindex $args 1]
		} else {
			set subcmd [lrange $args 1 end]
		}
	}

	# is [info exists ::env($var)] better?
	if { ! ( [array names ::env -exact $var] == $var ) } {
		if { [llength $subcmd] == 1 } {
			set subcmd [lindex $subcmd 0]
		}
		return [uplevel 1 $subcmd]
	}
}


