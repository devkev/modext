
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


