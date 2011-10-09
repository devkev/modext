


proc internal::split-when { when } {
	return [split $when " \t\n-_"]
}

proc internal::join-when { l } {
	return [join $l "-"]
}

proc internal::parse-when { when _poslist _neglist } {
	upvar ${_poslist} poslist
	upvar ${_neglist} neglist
	set negatenext 0
	foreach mode [::modext::internal::split-when $when] {
		if { [string equal $mode and] || [string equal $mode or] } {
			continue
		} elseif { [string equal $mode not] || [string equal $mode "!"] } {
			set negatenext 1
			continue
		}
		if { $negatenext } {
			set negatenext 0
			set target neglist
		} elseif { [string index $mode 0] == "!" } {
			set mode [string range $mode 1 end]
			set target neglist
		} else {
			set target poslist
		}
		lappend $target $mode
	}
}


proc internal::match-mode { l } {
	# return true if anything in l, when passed to module-info mode, matches (ie. it returns true).
	# return false if none of them do.
	foreach mode $l {
		if { [::module-info mode $mode] } {
			return 1
		}
	}
	return 0
}


proc only { when args } {
	set poslist [list]
	set neglist [list]

	::modext::internal::parse-when $when poslist neglist

	set succeed [::modext::internal::match-mode $poslist]
	set fail [::modext::internal::match-mode $neglist]

	if { $succeed && ! $fail } {
		uplevel [list set poslist $poslist]
		uplevel [list set neglist $neglist]
		uplevel ::modext::internal::upleveller $args
		uplevel [list unset poslist]
		uplevel [list unset neglist]
	}
}


proc not { when args } {
	set poslist [list]
	set neglist [list]

	::modext::internal::parse-when $when poslist neglist

	set succeed [::modext::internal::match-mode $poslist]
	set fail [::modext::internal::match-mode $neglist]

	if { ! ( $succeed && ! $fail ) } {
		uplevel ::modext::internal::upleveller $args
	}
}


# Deprecated.
# Only execute args if we are currently NOT in "module display"/"module show"
proc no-show { args } {
	uplevel ::modext::internal::upleveller ::modext::not show $args
}

# Deprecated.
# Only execute args if we are currently in "module load"
proc only-load { args } {
	uplevel ::modext::internal::upleveller ::modext::only load $args
}

# Deprecated.
# Only execute args if we are currently in "module show"
proc only-show { args } {
	uplevel ::modext::internal::upleveller ::modext::only show $args
}

# Deprecated.
# Only execute args if we are currently in "module load" or in "module show"
proc only-load-and-show { args } {
	uplevel ::modext::internal::upleveller ::modext::only load-show $args
}
# Deprecated.
proc only-load-or-show { args } {
	#eval only-load-and-show $args
	uplevel ::modext::internal::upleveller ::modext::only-load-and-show $args
}

# Deprecated.
# Only execute args if we are currently removing
proc only-remove { args } {
	uplevel ::modext::internal::upleveller ::modext::only remove $args
}

# Deprecated.
proc only-unload { args } {
	uplevel ::modext::internal::upleveller ::modext::only-remove $args
}

# Deprecated.
# Only execute args if we are currently truly removing (and not just swapping)
#intercepted single-proc ::only-remove-and-not-swap { script } {
proc only-remove-and-not-swap { args } {
	uplevel ::modext::internal::upleveller ::modext::only remove-!swap $args
}

# Deprecated.
proc only-unload-and-not-swap { args } {
	uplevel ::modext::internal::upleveller ::modext::only-remove-and-not-swap $args
}

# Deprecated.
# Only execute args if we are currently not removing
proc not-remove { args } {
	uplevel ::modext::internal::upleveller ::modext::not remove $args
}

# Deprecated.
proc not-unload { args } {
	uplevel ::modext::internal::upleveller ::modext::not-remove $args
}

# Deprecated.
# Only execute args if we are currently not removing or swapping
proc not-remove-or-swap { args } {
	uplevel ::modext::internal::upleveller ::modext::not remove-swap $args
}

# Deprecated.
proc not-unload-or-swap { args } {
	uplevel ::modext::internal::upleveller ::modext::not-remove-or-swap $args
}

proc ::cannot { when } {
	# FIXME: checkme

	# FIXME: only do this if $when doesn't include "[^!]?show".
	::modext::only show puts stderr "cannot $when"

	# things listed before "butallow" are positive, things after "butallow" get prefixed with "!" before handing off to the 'only' command.
	set swhen [list]
	set prefix {}
	foreach mode [::modext::internal::split-when $when] {
		if { [string equal $mode butallow] } {
			set prefix "!"
			continue
		}
		lappend swhen $prefix$mode
	}
	set when [::modext::internal::join-when $swhen]

	::modext::only $when {
		puts stderr "Error: module [::module-info name] is not able to: $poslist (instead try: $neglist)."
		break
	}
}


# Deprecated.
# Forbid module from being unloaded
# (should still allow it to be swapped)
proc ::cannot-remove { } {
	uplevel ::modext::internal::upleveller ::cannot remove-butallow-swap

	#::modext::only show puts stderr "cannot-remove"
	##only-remove-and-not-swap puts stderr "Error: module [module-info name] cannot be unloaded (try swapping instead)."
	##only-remove-and-not-swap break
	##only-remove-and-not-swap { puts stderr "Error: module [module-info name] cannot be unloaded." ; break }
	#::modext::only "remove ! swap" { puts stderr "Error: module [module-info name] cannot be unloaded." ; break }
	##only-remove-and-not-swap puts stderr "Error: module [module-info name] cannot be unloaded." "\;" break
}

# Deprecated.
proc ::cannot-unload { } {
	uplevel ::modext::internal::upleveller ::cannot-remove
}


proc ::message { when args } {
	# FIXME: checkme
	#::modext::only $when puts stderr $args
	::modext::only $when {
		foreach arg $args {
			puts stderr $arg
		}
	}
}

# Deprecated.
# Only display the given message (each arg is a possibly multiline string) during module load.
proc ::load-message { args } {
	::message load $args
}



# This will execute the given command(s) under the following conditions:
# - during module loads, only if the given condition is true
# - during module unloads, always
# It turns out that this is almost always what you want when fiddling with
# paths and stuff based on options.  This is because you only want to add to the
# path (or whatever) during load when an option is enabled (or whatever), but at unload time
# you have no idea whether the path was fiddled with at load time, so you have
# to do the fiddling anyway, just in case (and modules will reverse its meaning for you).
proc conditional-load-always-unload { loadcondition args } {
	set retval 0

	::modext::only load-show {
		if $loadcondition {
			#set retval [eval $args]
			set retval [uplevel 1 $args]
		}
	}

	::modext::only remove {
		#set retval [eval $args]
		set retval [uplevel 1 $args]
	}

	#if { [module-info mode load] || [module-info mode display] } {
	#	if $loadcondition {
	#		set retval [eval $args]
	#		#set retval [uplevel 1 $args]
	#	}
	#} elseif { [module-info mode remove] } {
	#	set retval [eval $args]
	#	#set retval [uplevel 1 $args]
	#}

	return $retval
}



