
#package provide modext 1.0
#puts stderr "package provide modext 1.0"


# A collection of "extension" tcl procedures that are useful in modulefiles.
# All modulefiles should source this file as the first thing they do, ie:
#
# source /opt/Modules/extensions/extensions.tcl
#
# Maybe one day modules will be hacked so that it can automatically source
# this when modulefiles are interpreted.  Currently it's not possible.
# Including the source line in modulefiles isn't too onerous.
#
# Using $MODULESHOME/etc/rc doesn't seem to work.
#
# Using .modulerc or $MODULERCFILE does not work, because those files are
# interpreted "separately" from the interpretation of the main modulefile
# (ie. the tcl interpreter is reset or something, at any rate, vars and
# procs set in these module rc files DO NOT carry over to the main modulefile).

# kjp900, 2008-12-17


# This has now moved into ../extensions.tcl
## If the user has requested an alternate extensions file, then pass off to that
## straight away (ALWAYS).
#if { [array names ::env ALTERNATE_MODULE_EXTENSIONS] != "" &&
#     [info script] != "$::env(ALTERNATE_MODULE_EXTENSIONS)" } {
#	if { ! [file readable "$::env(ALTERNATE_MODULE_EXTENSIONS)"] } {
#		puts stderr "Warning: Unable to switch to alternate extensions: $::env(ALTERNATE_MODULE_EXTENSIONS)"
#	} else {
#		puts stderr "Notice: switching to alternate extensions: $::env(ALTERNATE_MODULE_EXTENSIONS)"
#		source "$::env(ALTERNATE_MODULE_EXTENSIONS)"
#		return
#	}
#}



# Make sure that this stuff is done only once per module invocation.
#puts stderr "extensions_loaded? [info exists ::extensions_loaded]"
# Need to redo all of this if the module file being executed changes (which happens on module swap, ugh).
if { [info exists ::extensions_loaded] && [string equal ${::extensions_loaded} $ModulesCurrentModulefile] } {
	return
}
variable ::extensions_loaded "$ModulesCurrentModulefile"



package require opt



if { ! [string equal [info procs proc-defined] proc-defined] } {
	proc proc-defined { procname } {
		return [string equal [info commands $procname] $procname]
	}
}

# single-proc is like proc, except that it will silently do nothing if the proc is already defined.
if { ! [proc-defined single-proc] } {
	proc single-proc { name args body } {
		if { ! [proc-defined $name] } {
			#proc $name $args $body
			uplevel 1 [list proc $name $args $body]
		}
	}
}

if { ! [proc-defined OptProc] } {
	proc OptProc { name args body } {
		#::tcl::OptProc $name $args $body
		uplevel 1 [list ::tcl::OptProc $name $args $body]
	}
}

if { ! [proc-defined single-OptProc] } {
	proc single-OptProc { name args body } {
		if { ! [proc-defined $name] } {
			#OptProc $name $args $body
			uplevel 1 [list OptProc $name $args $body]
		}
	}
}



# Very useful for debugging idio^H^H^H^Hesoteric TCL errors.
# Use it like this (replace "procname" with the proc to trace, after that proc has been defined):
#trace add execution procname enterstep dotrace
single-proc dotrace { args } {
	puts stderr "$args"
}


global extensions_home

#set extensions_home "/opt/Modules/default/extensions"
#set extensions_home "/home/900/kjp900/modulefiles/extensions"

# Automatic way of figuring out the location of the extensions
#puts stderr "info script = [info script]"
regsub "/\[^/\]*$" [info script] "" extensions_home
#puts stderr "extensions_home = $extensions_home"

source "$extensions_home/global_vars.tcl"


single-proc do_everything { } {

	global extensions_home
	source "$extensions_home/global_vars.tcl"


	# The order of these files matters, so think carefully when
	# adding to it.

	source "$extensions_home/site-config.tcl"

	source "$extensions_home/basic.tcl"
	source "$extensions_home/env.tcl"

	source "$extensions_home/options.tcl"
	source "$extensions_home/options-definitions.tcl"

	source "$extensions_home/show-debug.tcl"

	source "$extensions_home/cluestick.tcl"

	# Intercept must come before any interceptable procs are defined.
	source "$extensions_home/intercept.tcl"

	source "$extensions_home/restrict.tcl"

	source "$extensions_home/options-declare.tcl"

	source "$extensions_home/autohelp.tcl"


	# Sets up default variables and stuff.
	source "$extensions_home/default_version.tcl"

	source "$extensions_home/plural-arguments.tcl"
	source "$extensions_home/plural-arguments-definitions.tcl"

	# Stuff that defines procs.
	source "$extensions_home/legacy-script.tcl"
	source "$extensions_home/abstraction.tcl"
	source "$extensions_home/self-conflict.tcl"
	source "$extensions_home/prereqs.tcl"
	source "$extensions_home/software-url.tcl"
	source "$extensions_home/docommon.tcl"



	# Go back inside again, so that we know when we come out.
	#puts stderr "going back inside $ModulesCurrentModulefile"
	show-debug "START: source $ModulesCurrentModulefile"
	source "$ModulesCurrentModulefile"
	show-debug "END: source $ModulesCurrentModulefile"


	# Now we know that the module file has finished doing its stuff.


	# So, any special stuff that has to be run at the end (ie. ala atexit())
	# can now be done here.

	# wrapperdirs must be done at the end, so that they are always done after bindirs
	process_wrapperdirs

	# self-conflict (unless requested not to)
	perform-self-conflict-if-necessary

	# base-envvar (unless requested not to)
	perform-base-envvar-if-necessary
	perform-version-envvar-if-necessary 

	set-whatis-if-necessary
	set-help-if-necessary

	only-load check-group-access

	# Remove any options that need to be removed.
	#show-debug [array names ::options_used]
	remove-used-options


	# Soon extensions.tcl will return, and the module file will continue running.
	# Left to its own devices, it will go through and rerun everything again.
	# This would be a problem.
	# So, we set the intercept mode to inhibit.  This causes all the module commands
	# from this point onwards to be no-ops.  Hooray!
	#puts stderr "INHIBITING"
	# continue bombs the whole module swap, not just each stage.
	#continue
	set-intercept-mode inhibit

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
	trace add execution do_everything enterstep dotrace
	# FIXME: Would be nice if this worked...
	#trace add execution ModulesHelp enterstep dotrace
}

set ::rc [catch { do_everything } ::errmsg]
if { $rc == 1 } {
	# FIXME: logging
	# be silent if the error is 'invoked "break" outside of a loop', which is valid module syntax
	# yes this regexp is a silly way to do this, but i don't know any better way...
	if { [regexp {^invoked \"(break|continue)\" outside of a loop} $::errorInfo] } {
		# shoosh!
	} elseif { [regexp {^EXIT [0-9]+\n} $::errorInfo] } {
		# shoosh!
	} elseif { [regexp -lineanchor {while executing.^\"conflict .*\"$} $::errorInfo] } {
		# shoosh!
	} elseif { [regexp -lineanchor {while executing.^\"prereq .*\"$} $::errorInfo] } {
		# shoosh!
	} else {
		set show_backtrace [expr [check-envvar-enabled MODULES_ERROR_BACKTRACE] || [check-envvar-enabled MODULE_ERROR_BACKTRACE]]
		if { $show_backtrace } {
			puts stderr ""
		}
		puts -nonewline stderr "MODULE ERROR DETECTED"
		if { ! [string equal $::errorCode NONE] } {
			puts -nonewline stderr " (error code: $::errorCode)"
		}
		puts -nonewline stderr ": "
		if { $show_backtrace } {
			puts stderr "$::errorInfo"
		} else {
			puts stderr "[firstline $::errorInfo]"
			puts stderr "(Detailed error information and backtrace has been suppressed, set \$MODULES_ERROR_BACKTRACE to unsuppress.)"
		}
		unset show_backtrace
	}
	error "$::errmsg" $::errorInfo $::errorCode
}

