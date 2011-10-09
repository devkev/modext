
# Based on stack_proc.tcl
# http://wiki.tcl.tk/4469
# Under the GPL

#namespace eval ::stacking {}
#namespace eval ::stacking::procs {}
#namespace eval ::stacking::num {}

#proc ::stacking::push { name arguments script } {
#	if { [string equal [info commands $name] ""] } {
#		proc $name $arguments $script
#	} else {
#		global ${name}_num
#		if { [info exists ${name}_num] } {
#			incr ${name}_num
#		} else {
#			set ${name}_num 0
#		}
#		puts stderr "initial: [info commands $name*]"
#		rename $name ${name}_[set ${name}_num]
#		puts stderr "stage1: [info commands $name*]"
#
#		#proc $name $arguments "
#		#	set _stacking_num [set ::stacking::num::$name]
#		#"$script
#
#		#proc $name $arguments {
#		#	set _stacking_num }[set ::stacking::num::$name]{
#		#}$script
#
#		set foo "
#			set _stacking_num [set ${name}_num]
#		"
#		append foo $script
#		proc $name $arguments $foo
#		puts stderr "stage2: [info commands $name*]"
#		puts stderr "stage2: [info commands testproc*]"
#	}
#}

namespace eval ::stupid {

proc ::stack-proc { name arguments script } {
	upvar #0 __stacking_${name}_num num

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

}


proc testproc { args } {
	puts stderr "This is a test proc ([llength $args] from [info level]): $args"
}
#puts stderr "my procs are: [info procs testproc*]"
testproc foo bar baz

stack-proc testproc { args } {
	puts stderr "cop this! $args"
	return [eval call-upper $args]
}
puts stderr "my procs are: [info procs testproc*]"
#puts stderr "my procs are: [info procs ::stacking::testproc*]"
testproc foo bar bang


stack-proc testproc { args } {
	puts stderr "KABOOMPOWBLAMMO"
	if { [string equal [lindex $args 0] safe] } {
		puts stderr "you're lucky..."
		set retval 0
	} else {
		set retval [eval call-upper $args]
	}
	puts stderr "YOU'RE EXPLODED NOW"
	return $retval
}
puts stderr "my procs are: [info procs testproc*]"
#puts stderr "my procs are: [info procs ::stacking::testproc*]"
testproc KA BOOM POW BLAMMMMOOOOOOO
testproc safe



#proc pullproc { name { newname "" }} {
#  upvar #0 $name stack
#  if [ info exists stack ] {
#    rename $name $newname
#    rename $name-$stack $name
#    incr stack -1
#    if { $stack == 0 } {
#      unset stack
#    }
#  }
# }

# proc getprev { } {
#  set name [lindex [ info level -1 ] 0]
#  if { "$name" == "callprev" } {
#    set name [lindex [ info level -2 ] 0]
#  }
#  set curproc ""
#  regexp {([^-]*)-([0-9]*)} $name -> procname curproc
#  if ![info exists procname] {
#    set procname $name
#  }
#  upvar #0 $procname stack
#  if { "$curproc" == "" } {
#    if [ info exists stack ] {
#      set curproc $stack
#    } else {
#      return ""
#    }
#  } else {
#    incr curproc -1
#  }
#  if { $curproc == 0 } {
#    return ""
#  }
#  return $procname-$curproc
# }
#
#proc stacking::callprev { args } {
#	set name [lindex [info level -1] 0]
#	if { ! [info exists stacking::num::$name] } {
#		# can't call up if nothing is stacked up there
#	} else {
#		set num [set stacking::num::$name] 
#		if { $num == 0 } {
#		}
#	}
#
#	set name [stacking::getprev]
#	if ![string equal $name "" ] {
#		return [ eval $name $args ]
#	}
#	return ""
#}



