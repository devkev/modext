
# Various basic TCL procs.


package require opt


if { ! [string equal [info procs ::proc-defined] ::proc-defined] } {
	proc ::proc-defined { procname } {
		return [string equal [info commands $procname] $procname]
	}
}

# single-proc is like proc, except that it will silently do nothing if the proc is already defined.
if { ! [proc-defined ::single-proc] } {
	proc ::single-proc { name args body } {
		if { ! [proc-defined $name] } {
			#proc $name $args $body
			uplevel 1 [list proc $name $args $body]
		}
	}
}

if { ! [proc-defined ::OptProc] } {
	proc ::OptProc { name args body } {
		#::tcl::OptProc $name $args $body
		uplevel 1 [list ::tcl::OptProc $name $args $body]
	}
}

if { ! [proc-defined ::single-OptProc] } {
	proc ::single-OptProc { name args body } {
		if { ! [proc-defined $name] } {
			#OptProc $name $args $body
			uplevel 1 [list OptProc $name $args $body]
		}
	}
}


# feeling now that this is misguided...
#proc user-facing { proctype name args body } {
#	# FIXME: should confirm that $name doesn't contain ::
#	uplevel 1 [list $proctype ::$name $args $body]
#}



# Very useful for debugging idio^H^H^H^Hesoteric TCL errors.
# Use it like this (replace "procname" with the proc to trace, after that proc has been defined):
#trace add execution procname enterstep dotrace
single-proc dotrace { args } {
	puts stderr "$args"
}



# Reverse a list, pinched from somewhere on the net.
single-proc ::reverse { list } {
	for {set i [ expr [ llength $list ] - 1 ] } {$i >= 0} {incr i -1} {
		lappend _temp [ lindex $list $i ]
	}
	return  $_temp
}


# Center a line.
single-OptProc ::center {
	{ -width -int 80 }
	{ -pad -string " " }
	{ s }
} {
	set padnum [expr ( $width - [string length $s] ) / 2]
	set padding [string repeat $pad $padnum]
	#return "${padding}${s}${padding}"
	return "${padding}${s}"
}

# stopgap until tcl 8.6 which has lsearch -nocase, and in the absence
# of being able to get lsearch -regexp working properly
single-proc ::lsearchnocase { list pattern } {
	set i 0
	foreach element $list {
		if { [string equal -nocase $element $pattern] } {
			return $i
		}
		set i [expr $i + 1]
	}
	return -1
}


single-proc ::map { procname args } {
	foreach i $args {
		$procname $i
	}
}


single-proc check-envvar-enabled { name } {
	if { [array names ::env $name] != "" && ( $::env($name) == y || $::env($name) == Y ) } {
		return 1
	} else {
		return 0
	}
}

single-proc firstline { s } {
	set i [string first "\n" $s]
	if { $i < 0 } {
		return $s
	} else {
		return [string range $s 0 [expr "$i - 1"]]
	}
}

if { [check-envvar-enabled MODULES_TRACE] || [check-envvar-enabled TRACE_MODULES] } {
	#trace add execution do_everything enterstep dotrace

	#trace add execution ::description enterstep dotrace
	trace add execution internal::description enterstep dotrace

	# FIXME: Would be nice if this worked...
	#trace add execution ModulesHelp enterstep dotrace
}


single-proc internal::upleveller { args } {
	if { [llength $args] == 1 } {
		set args [lindex $args 0]
		if { [llength $args] == 1 } {
			#::uplevel 2 [lindex $args 0]
			#::uplevel 1 [lindex $args 0]
			::uplevel [lindex $args 0]
		} else {
			#::uplevel 2 $args
			#::uplevel 1 $args
			::uplevel $args
		}
	} else {
		#::uplevel 2 $args
		#::uplevel 1 $args
		::uplevel $args
	}
}


OptProc ::file_absolutify {
	{ -base -string "" }
	{ f }
} {
	if { [string index $f 0] != "/" } {
		if { [string equal $base ""] } {
			set base [pwd]
		}
		set f $base/$f
	}
	set new [list]
	set skip 0
	foreach seg [reverse [file split $f]] {
		if { [string equal $seg .] } {
			# skip
		} elseif { [string equal $seg ..] } {
			incr skip
		} elseif { $skip > 0 } {
			incr skip -1
		} else {
			lappend new $seg
		}
	}
	if { $skip > 0 } {
		lappend new /
	}
	return [file join {*}[reverse $new]]
}

