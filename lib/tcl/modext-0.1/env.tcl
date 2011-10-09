
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


