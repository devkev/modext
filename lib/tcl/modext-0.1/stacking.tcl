
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


# Based on stack_proc.tcl by Larry Smith.
# http://wiki.tcl.tk/4469
# Under the GPL (any version)


proc ::stack-proc { name arguments script } {
	if { ! [string equal $name [info commands $name]] } {
		return
	}

	upvar #0 ${name}__stacking_num num

	if { [info exists num] } {
		incr num
	} else {
		set num 0
	}

	rename $name ${name}__stacking_$num

	set fullscript "set __stacking_num $num ;"
	append fullscript $script
	proc $name $arguments $fullscript

	return
}


proc ::call-upper { args } {
	set name [lindex [info level -1] 0]
	upvar 1 __stacking_num num

	if { ! [info exists num] } {
		# can't call up if this is the top level.
		# (this should not happen.)
		# only happens when call-upper is called from a routine
		# that hasn't been stacked, which is clearly a stupid thing to do.
		error "call-upper called from outside a stack-proc"
	} else {
		rename ${name} ${name}__stacking_${num}_save
		rename ${name}__stacking_${num} ${name}
		set retval [uplevel 2 $name $args]
		rename ${name} ${name}__stacking_${num}
		rename ${name}__stacking_${num}_save ${name}
		return $retval
	}
}


