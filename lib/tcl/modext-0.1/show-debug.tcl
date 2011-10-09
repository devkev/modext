
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


