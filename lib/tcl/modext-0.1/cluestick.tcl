
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



# Correct the behaviour of various module command stupidities.




if { ! [string equal module-info [info commands module-info]] } {
	# Provide some fake rubbish if this is being run as "package require modext" in a plain tclsh
	# (probably to test if modext is in $TCLLIBPATH or not).
	proc ::module-info { args } { return 0 }
	set ::ModulesCurrentModulefile "/"
} else {


# adjust module-info mode to accept unload, show, etc

# module-info mode does not recognise that "unload" is a synonym for "remove",
# or that "show" is a synonym for "display",
# or that "rm" is a synonym for "remove",
# or that "add" is a synonym for "load".

# also if you ask "module-info mode load" during stage2 of a swap (ie. "module-info mode switch2" returns true),
# then modules erroneously returns 0.  this contradicts the fact that "module-info mode remove" is true during
# switch1 and switch3.  so we correct this too.
stack-proc ::module-info { args } {
	if { [llength $args] == 2 && [string equal [lindex $args 0] "mode"] } {
		switch -exact -- [lindex $args 1] {
			unload {
				lset args 1 remove
			}
			rm {
				lset args 1 remove
			}
			show {
				lset args 1 display
			}
			add {
				lset args 1 load
			}
			swap {
				lset args 1 switch
			}
		}
	}

	if { [llength $args] == 2 && [string equal [lindex $args 0] mode] && [string equal [lindex $args 1] load] && [call-upper mode switch2] } {
		return 1
	} else {
		return [eval call-upper $args]
	}
}

}




# is-loaded returns an empty string during module whatis, which means
# that any statements along the lines of "if { [is-loaded somejunk] }" inside
# module files, cause module whatis to fail.
stack-proc ::is-loaded { args } {
	if { [module-info mode whatis] } {
		return 0
	} else {
		return [eval call-upper $args]
	}
}




# Doing "module list" inside a module causes $LOADEDMODULES (but not $_LMFILES_)
# to be truncated to just the first entry.  Yeah, tell me about it.
stack-proc ::module { args } {
	if { [llength $args] == 1 && [string equal [lindex $args 0] "list"] } {
		set realloadedmodules $::env(LOADEDMODULES)
	}

	set retval [eval call-upper $args]

	if { [info exists realloadedmodules] } {
		set ::env(LOADEDMODULES) $realloadedmodules
	}

	return $retval
}



# setenvs that are done in module files cause $::env to be updated.
# Pity that unsetenvs done in module files don't.  FFS.
stack-proc ::unsetenv { args } {
	set retval [eval call-upper $args]

	foreach var $args {
		if { [info exists ::env($var)] } {
			unset ::env($var)
		}
	}

	return $retval
}




