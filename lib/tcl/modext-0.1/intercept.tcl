
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




# Interception is now largely unnecessary.
# So these just reduce to simple passthroughs.

proc intercepted { proctype name args } {
	uplevel 1 [list $proctype $name] $args
	#add_intercepted_procs $name
}

# For backwards-compatibility only, remove eventually.
proc intercepted-proc { name args body } {
	#uplevel 1 [list intercepted ::proc $name $args $body]
	uplevel 1 [list intercepted single-proc $name $args $body]
}
proc intercepted-OptProc { name args body } {
	#uplevel 1 [list intercepted ::tcl::OptProc $name $args $body]
	uplevel 1 [list intercepted single-OptProc $name $args $body]
}



## INTERCEPT MODE CAN BE:
##   intercept: standard interception, real function is eventually called
##   inhibit: noop, real function is not called
#
#single-OptProc set-intercept-mode {
#	{ ?mode? -choice { intercept inhibit } }
#} {
#	set ::intercept_mode $mode
#}
#
#set-intercept-mode
#
#
#
#
#array set ::intercepted_procs { }
#
#single-proc map { procname args } {
#	foreach i $args {
#		$procname $i
#	}
#}
#
#single-proc add_intercepted_proc { p } {
#	if { [array names ::intercepted_procs "$p"] == "" } {
#		array set ::intercepted_procs [list "$p" y]
#	}
#}
#
#single-proc add_intercepted_procs { args } {
#	eval map add_intercepted_proc $args
#	eval map intercept $args
#}
#
## FIXME: doing this by using "args" to just catch all the args break the
## temporary-... procs, if they are interecepted (which they probably shouldn't be).
#
#single-proc intercept { procname } {
#	show-debug "intercept $procname"
#
#	if { [info commands "${procname}_real"] != "" } {
#		# already defined
#		return
#	}
#
#	rename ${procname} "${procname}_real"
#
#	#puts stderr "proc ${procname}_inhibit { args } \"show-debug \\\"INHIBITED: ${procname} \\\$args\\\"\""
#	proc ${procname}_inhibit { args } "
#		show-debug \"INHIBITED: ${procname} \$args\"
#	"
#
#	#puts stderr "proc $procname { args } \"eval ${procname}_\$::intercept_mode \$args\""
#	proc ${procname} { args } "
#		eval ${procname}_\$::intercept_mode \$args
#	"
#
#	# Jiggery-pokery with proc names is necessary so that "module show" output is correct.
#	# FIXME: probably want "uplevel 1" instead of "eval"
#	proc ${procname}_runreal { args } "
#		show-debug \"RUNREAL: ${procname} \$args\";
#		rename ${procname} ${procname}_save
#		rename ${procname}_real ${procname}
#		set err \[catch { uplevel 1 ${procname} \$args } retval\]
#		rename ${procname} ${procname}_real
#		rename ${procname}_save ${procname}
#		return -code \$err -errorinfo \$::errorInfo -errorcode \$::errorCode \$retval
#	"
#
#	# If foobar_replace is defined, it is its responsibility to eventually call
#	# foobar_runreal (or not).  This allows foobar_replace to choose when foobar_runreal
#	# is called (eg. at the start, at the end, or in the middle, of the replacement
#	# behaviour).
#	proc ${procname}_intercept { args } "
#		show-debug \"INTERCEPT: ${procname} \$args\";
#		if { \[info procs ${procname}_replace\] == \"\" } {
#			eval ${procname}_runreal \$args
#		} else {
#			eval ${procname}_replace \$args
#		}
#	"
#
#}
#
##trace add execution intercept enterstep dotrace
#
#
## Tcl scares me sometimes.
##proc intercepted-proc { name args body } {
##	#::proc $name $args $body
##	uplevel 1 [list ::proc $name $args $body]
##	add_intercepted_procs $name
##}
##
##proc intercepted-OptProc { name args body } {
##	#::tcl::OptProc $name $args $body
##	uplevel 1 [list ::tcl::OptProc $name $args $body]
##	add_intercepted_procs $name
##}
#
## Hah.
#single-proc intercepted { proctype name args } {
#	uplevel 1 [list $proctype $name] $args
#	add_intercepted_procs $name
#}
#
## For backwards-compatibility only, remove eventually.
#single-proc intercepted-proc { name args body } {
#	#uplevel 1 [list intercepted ::proc $name $args $body]
#	uplevel 1 [list intercepted single-proc $name $args $body]
#}
#single-proc intercepted-OptProc { name args body } {
#	#uplevel 1 [list intercepted ::tcl::OptProc $name $args $body]
#	uplevel 1 [list intercepted single-OptProc $name $args $body]
#}
#
#
#
##
## INTERCEPT USER-FACING COMMANDS SUPPLIED BY NATIVE MODULES.
##
## IT IS IMPORTANT TO ALSO CALL add_intercepted_procs FOR EACH PROC
## THAT IS SUPPLIED BY EXTENSIONS.
##
## THE BEST WAY TO DO THAT IS TO DEFINE THEM USING THE intercepted-proc COMMAND
## INSTEAD OF THE REGULAR proc COMMAND.
##
#
## Prevent noise from the 2nd pass.
##add_intercepted_procs puts
#
## dunno why this fails *shrug*
##add_intercepted_procs break
#
#add_intercepted_procs setenv unsetenv
#add_intercepted_procs append-path prepend-path
#add_intercepted_procs remove-path
#add_intercepted_procs prereq conflict
#
## not necessary, i think
##add_intercepted_procs is-loaded
#
#add_intercepted_procs module
#
## not necessary, i think
##add_intercepted_procs module-info
#
## Cannot fool the builtin "module" command with this.
## (eg. for forcibly unloading a module during a module show)
##proc module-info_replace { args } {
##	set cmd [lindex $args 0]
##	puts stderr "cmd = $cmd"
##	eval module-info_runreal $args
##}
#
## FIXME: would be nice, though, to intercept module-info and make it convert
## "module-info mode show" to "module-info mode display" and similarly
## "module-info mode unload" to "module-info mode remove", etc.
#
#add_intercepted_procs module-version
#add_intercepted_procs module-alias
#add_intercepted_procs module-trace
#add_intercepted_procs module-user
#add_intercepted_procs module-verbosity
#add_intercepted_procs module-log
#add_intercepted_procs module-whatis
#add_intercepted_procs set-alias unset-alias
#add_intercepted_procs system
#add_intercepted_procs uname
#add_intercepted_procs x-resource
#
##add_intercepted_procs package
##proc package_replace { args } {
##	puts stderr "package $args"
##	eval package_real $args
##}
#


