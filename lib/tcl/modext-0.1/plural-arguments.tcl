

proc internal::regularise-plural-string-argument { args } {
	#puts stderr "regularise-plural-string-argument: [join $args]"
	upvar 1 [lindex $args 0] primary
	foreach arg [lrange $args 1 end] {
		upvar 1 $arg secondary
		#puts stderr "smushing $arg into [lindex $args 0]"
		#puts stderr "my locals: [info locals]"
		#puts stderr "parents locals: [uplevel 1 info locals]"
		#puts stderr "level 0: [info level 0]"
		#puts stderr "level 1: [info level 1]"
		#puts stderr "primary ([lindex $args 0]) = \"$primary\""
		#puts stderr "secondary ($arg) = \"$secondary\""
		if { ! [string equal "$secondary" ""] } {
			if { ! [string equal "$primary" ""] } {
				set primary "$primary $secondary"
			} else {
				set primary $secondary
			}
			#set secondary ""
			unset secondary
		}
	}
}

# names is the list of names (first one is the primary one).
# NOTE: returnscript MUST NOT have a trailing newline, unless you want to be tcl'd to death.
proc plural-string-argument { names {mainscript {}} {returnscript {}} } {
	#puts stderr "names = \"$names\""
	#puts stderr "mainscript = \"$mainscript\""
	#puts stderr "returnscript = \"$returnscript\""

	if { [llength $names] < 2 } {
		return -code error {plural-string-argument requires at least 2 names}
	}
	foreach name $names {
		if { [info exists ::modext::internal::${name}_flag] } {
			#return -code error "there is already a plural-string-argument called $name"
			return
		}
	}

	set primary [lindex $names 0]
	set ::modext::internal::${primary}_flag ""
	upvar 0 ::modext::internal::${primary}_flag primary_flag
	foreach name $names {
		set primary_flag "$primary_flag { [ list -${name} -string [list] ] }"
	}
	#puts stderr "${primary}_flag = $primary_flag"

	if { [string equal [info procs ::modext::internal::regularise-$primary] ""] } {
		set s "\n\tuplevel 1 \"::modext::internal::regularise-plural-string-argument $names\"\n\t"
		if { ! [string equal "$mainscript" ""] } {
			set s "${s}uplevel 1 {$mainscript}\n\t"
		}
		if { ! [string equal "$returnscript" ""] } {
			set s "${s}set f { $returnscript }\n\t"
			set s "${s}set f \"\${f} { \$script }\"\n\t"
			#set s "${s}puts stderr \"f = \\\"\$f\\\"\"\n\t"
			set s "${s}return \[uplevel 1 \$f\]\n\t"
		} else {
			set s "${s}return \[uplevel 1 \"\$script\"\]\n\t"
		}
		#puts stderr "proc regularise-$primary { {script {}} } = \"$s\""
		proc ::modext::internal::regularise-$primary { {script {}} } $s
	}
}


proc internal::regularise-multi-string-argument { args } {
	#puts stderr "regularise-multi-string-argument: [join $args]"
}

# names is the list of names (first one is the primary one).
# NOTE: returnscript MUST NOT have a trailing newline, unless you want to be tcl'd to death.
proc multi-string-argument { names {mainscript {}} {returnscript {}} } {
	#puts stderr "names = \"$names\""
	#puts stderr "mainscript = \"$mainscript\""
	#puts stderr "returnscript = \"$returnscript\""

	if { [llength $names] < 1 } {
		return -code error {multi-string-argument requires at least 1 name}
	}
	foreach name $names {
		if { [info exists ::modext::internal::${name}_flag] } {
			#return -code error "there is already a multi-string-argument called $name"
			return
		}
	}

	set primary [lindex $names 0]
	set ::modext::internal::${primary}_flag ""
	upvar 0 ::modext::internal::${primary}_flag primary_flag
	foreach name $names {
		set primary_flag "$primary_flag { [ list -${name} -string [list] ] }"
	}
	#puts stderr "${primary}_flag = $primary_flag"

	if { [string equal [info procs ::modext::internal::regularise-$primary] ""] } {
		set s "\n\t"
		#set s "${s}uplevel 1 \"::modext::internal::regularise-multi-string-argument $names\"\n\t"
		if { ! [string equal "$mainscript" ""] } {
			set s "${s}uplevel 1 {$mainscript}\n\t"
		}
		if { ! [string equal "$returnscript" ""] } {
			set s "${s}set f { $returnscript }\n\t"
			set s "${s}set f \"\${f} { \$script }\"\n\t"
			#set s "${s}puts stderr \"f = \\\"\$f\\\"\"\n\t"
			set s "${s}return \[uplevel 1 \$f\]\n\t"
		} else {
			set s "${s}return \[uplevel 1 \"\$script\"\]\n\t"
		}
		#puts stderr "proc regularise-$primary { {script {}} } = \"$s\""
		proc ::modext::internal::regularise-$primary { {script {}} } $s
	}
}

proc regularised-OptProc { name regularised_arguments arguments body } {
	set flags ""
	set pre ""
	set post ""
	foreach regularised_argument $regularised_arguments {
		upvar 0 ::modext::internal::${regularised_argument}_flag regularised_argument_flag
		set flags "$flags $regularised_argument_flag"
		set pre "${pre}::modext::internal::regularise-$regularised_argument {\n"
		set post "}${post}\n"
	}
	uplevel 1 [list OptProc $name [concat $flags $arguments] "
		$pre
		$body
		$post
	"]
}


proc ensure-at-least-1-in-list { name { fullname "" } } {
	if { [string equal "$fullname" ""] } {
		set fullname $name
	}
	uplevel 1 "
		if { \[llength \$$name\] == 0 } {
			return -code error \"\\\"\[info level 0\]\\\": no $fullname were specified (at least 1 is required)\"
		}
	"
}

proc ensure-at-least-1-arg { } {
	uplevel 1 {
		::modext::ensure-at-least-1-in-list args arguments
	}
}




