
# Based on stack_proc.tcl
# http://wiki.tcl.tk/4469
# Under the GPL


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


