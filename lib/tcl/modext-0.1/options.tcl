
# stuff for testing if options are set, etc


namespace eval option {


###########################################################################
#
# All options are "boolean".
# If prefixed with "no-", "not-", "disable-" or "without-" then the option is disabled.
# If prefixed with "yes-", "use-", "enable-" or "with-", or none of these prefixes, then the option is enabled.
#
# The default for an option can be enabled or disabled.
# Flags are just options that are disabled by default.
#
# Not every possible option name needs to be available in /opt/Modules/options/o,
# for example, flags will generally not have the disable module (eg. "no-foobar") available.
#
# Options must be registered in options-definitions.tcl before they can be used.
#
###########################################################################

set ::opt_enable_prefixes { yes use enable with }
set ::opt_disable_prefixes { no not disable without }
set ::opt_all_prefixes [concat $::opt_enable_prefixes $::opt_disable_prefixes]

set ::optenv_prefix MODULE_OPTION_
set ::optenv_persistent MODULE_PERSISTENT_OPTIONS
set ::opt_module_prefix o/

set ::opt_sep " \t\n,:;"

catch { unset ::options_defaults }
array set ::options_defaults { }
catch { unset ::options_descriptions }
array set ::options_descriptions { }
catch { unset ::options_forced }
array set ::options_forced { }

# Call this to register an option: what values it can take, and what its default is.
# If the default is omitted, then the default is y, ie. the option is enabled by default.
# Otherwise the default can be specified as n for disabled by default.
proc register { option desc {def y} } {
	#puts stderr "registering option $option $def"
	#::modext::show-debug "registering option $option $def"
	array set ::options_defaults [list "$option" "$def"]
	array set ::options_descriptions [list "$option" "$desc"]
}

proc register-option { option desc {def y} } {
	register $option $desc $def
}

# "Flags are just options that are disabled by default."
proc register-flag { option desc } {
	register-option "$option" "$desc" n
}


# Returns the env var used for the given option.
proc get-optenv { option } {
	#return "$::optenv_prefix$option"
	regsub -all "\[-\]" "$option" "_" adjoption
	return "$::optenv_prefix$adjoption"
}

proc option-string-to-value { value } {
	if { $value == y || $value == Y } {
		return 1
	} else {
		return 0
	}
}

proc option-value-to-string { value } {
	if { $value } {
		return y
	} else {
		return n
	}
}

proc option-value-to-english { value } {
	if { $value } {
		return Enable
	} else {
		return Disable
	}
}

proc get-option-default { option } {
	if { [array names ::options_defaults "$option"] != "" } {
		# known option
		return $::options_defaults($option)
	} else {
		# unknown option, assume it must be some flag, ie. default n
		return n
	}
}

proc get-option-description { option } {
	if { [array names ::options_descriptions "$option"] != "" } {
		# known option
		return $::options_descriptions($option)
	} else {
		# unknown option, assume it must be some flag, no description
		#return "<unknown option>"
		return "$option"
	}
}

proc option-exists { option } {
	return [info exists ::options_defaults($option)]
}

proc option-forced { option } {
	return [info exists ::options_forced($option)]
}

proc get-option-forced-value { option } {
	if { [array names ::options_forced "$option"] != "" } {
		# known option
		return $::options_forced($option)
	} else {
		# unforced option
		error "cannot get forced value of unforced option: $option"
	}
}

proc get-option-value { option } {
	if { [option-forced $option] } {
		set val [get-option-forced-value $option]
	} else {
		set optenv [get-optenv $option]
		if { [array names ::env $optenv] != "" } {
			set val $::env($optenv)
		} else {
			set val [get-option-default $option]
		}
	}
	return $val
}




proc determine-option-name { modoption } {
	foreach prefix $::opt_all_prefixes {
		regsub "^$prefix-" "$modoption" "" test_option
		if { "$test_option" != "$modoption" } {
			return "$test_option"
		}
	}
	return "$modoption"
}

proc determine-option-value { modoption option } {
	if { "$modoption" == "$option" } {
		return 1
	}
	regsub "${option}$$" "$modoption" "" pre
	foreach prefix $::opt_enable_prefixes {
		if { "$prefix-" == "$pre" } {
			return 1
		}
	}
	foreach prefix $::opt_disable_prefixes {
		if { "$prefix-" == "$pre" } {
			return 0
		}
	}
	# unknown prefix, assume some fancy prefix on a flag or something, still want it true (assuming false is no worse)
	return 1
}




proc is-option-persistent { option } {
	set realoption [determine-option-name $option]
	if { [array names ::env $::optenv_persistent] != "" } {
		foreach opt [split $::env($::optenv_persistent) ":"] {
			#puts stderr "testing $opt against $realoption"
			if { "$opt" == "$realoption" } {
				#puts stderr "$realoption is persistent, $option should not be removed"
				return 1
			}
		}
	}
	#puts stderr "$realoption is apparently not persistent, so $option may be removed"
	return 0
}


proc remove-option-basic { option } {
	# The inclusion of this in module show/display is debatable.
	#if { ! [is-option-persistent $option] } {
		# FIXME: uhhh, if we are in "module-info mode unload", then I think this should be a "module load", not "module unload"
		if { [module-info mode display] || [module-info name] != "${::opt_module_prefix}$option" } {
			#puts stderr "nuking ${::opt_module_prefix}$option"
			if { [module-info mode load] } {
				module unload "${::opt_module_prefix}$option"
			} elseif { [module-info mode unload] } {
				# the is-loaded prevents noise about "cannot find non-existant module"
				if { [is-loaded "${::opt_module_prefix}$option"] } {
					module load "${::opt_module_prefix}$option"
				}
				#module avail "${::opt_module_prefix}$option"
				#set foobunk [module avail "${::opt_module_prefix}$option"]

				# this is needed when swapping
				global ::remove-option-basic-reentrant
				if { ! [info exists ::remove-option-basic-reentrant] } {
					set ::remove-option-basic-reentrant 1
					::modext::declare-option-actual $option
					unset ::remove-option-basic-reentrant
				}
			}
		}
	#}
}

proc remove-option-enable-modules { option } {
	remove-option-basic "$option"
	foreach prefix $::opt_enable_prefixes {
		remove-option-basic "${prefix}-$option"
	}
}

proc remove-option-disable-modules { option } {
	foreach prefix $::opt_disable_prefixes {
		remove-option-basic "${prefix}-$option"
	}
}

proc remove-option { option } {
	remove-option-enable-modules "$option"
	remove-option-disable-modules "$option"
}

proc remove-option-other-modules { option value } {
	if { $value } {
		remove-option-disable-modules "$option"
	} else {
		remove-option-enable-modules "$option"
	}
}


catch { unset ::options_to_remove }
array set ::options_to_remove { }
catch { unset ::options_used }
array set ::options_used { }

# Call this to register that an option has been used, and should be removed
# at the end of the module (persistency permitting, of course).
proc add-option-to-remove { option } {
	array set ::options_used [list "$option" y]
	# FIXME: use the "only" proc
	if { [module-info mode load] || [module-info mode unload] } {
		array set ::options_to_remove [list "$option" y]
	}
}

# Run this at the end of the module to get rid of any non-persistent options
# that were used.
proc remove-used-options { } {
	# Take a copy of the list.  That way, anything that gets added
	# to the list during the course of doing these unloads won't
	# cause infinite recursion.
	array set my_options_to_remove [array get ::options_to_remove]
	foreach option [array names my_options_to_remove ] {
		#puts stderr "$option was used, considering removing it"
		if { ! [is-option-persistent $option] } {
			remove-option "$option"
		}
	}
}








# eg. temporary-defaults {temp-def1 temp-def2 ...} { command args... }
# temp-def are options of the form ((use|enable|no|disable|etc)-)?option
proc temporary-defaults { { defs {} } { script {} } } {
	foreach d $defs {
		foreach def [split $d $::opt_sep] {
			set option [determine-option-name $def]
			set val [option-value-to-string [determine-option-value $def $option]]
			set exists [option-exists $option]
			#puts stderr "exists = $exists"

			if { $exists } {
				#puts stderr "munging option $option to $val"
				#puts stderr "it is currently [get-option-default $option]"
				array set save_default [list $option [get-option-default $option]]
				array set ::options_defaults [list $option $val]
				#puts stderr "it is now [get-option-default $option]"
				#puts stderr "save_default($option) = $save_default($option)"
			}
		}
	}

	# catch errors, cleanup properly
	#set retval [eval $args]
	#set retval [uplevel 1 $script]
	set err [catch { uplevel 1 $script } retval]

	foreach option [array names save_default] {
		#puts stderr "unmunging option $option"
		#puts stderr "it is currently [get-option-default $option]"
		array set ::options_defaults [list "$option" "$save_default($option)"]
		#puts stderr "it is now [get-option-default $option]"
	}

	#return $retval
	return -code $err -errorinfo $::errorInfo -errorcode $::errorCode $retval
}
proc temporary-default { args } {
	return [uplevel 1 temporary-defaults $args]
}




# eg. temporary-forced-options {temp-def1 temp-def2 ...} { command args... }
# temp-def are options of the form ((use|enable|no|disable|etc)-)?option
proc temporary-forced-options { { defs {} } { script {} } } {
	foreach d $defs {
		foreach def [split $d $::opt_sep] {
			set option [determine-option-name $def]
			set val [option-value-to-string [determine-option-value $def $option]]
			set exists [option-exists $option]
			#puts stderr "exists = $exists"

			if { $exists } {
				#puts stderr "munging option $option to forced value $val"
				set isforced [option-forced $option]
				if { $isforced } {
					#puts stderr "it is already forced to [get-option-value $option]"
					array set save_forced [list $option [get-option-forced-value $option]]
				} else {
					#puts stderr "it is currently unforced as [get-option-value $option]"
				}
				array set ::options_forced [list $option $val]
				#puts stderr "it is now [get-option-value $option]"
				if { $isforced } {
					#puts stderr "save_forced($option) = $save_forced($option)"
				}
			}
		}
	}

	# catch errors, cleanup properly
	#set retval [eval $args]
	#set retval [uplevel 1 $script]
	set err [catch { uplevel 1 $script } retval]

	foreach d $defs {
		foreach def [split $d $::opt_sep] {
			set option [determine-option-name $def]
			#puts stderr "unmunging forced option $option"
			#puts stderr "it is currently [get-option-value $option]"
			if { [array names save_forced $option] != "" } {
				#puts stderr "it was previously forced to $save_forced($option)"
				array set ::options_forced [list $option $save_forced($option)]
			} else {
				#puts stderr "it was previously unforced"
				unset ::options_forced($option)
			}
			#puts stderr "it is now [get-option-value $option]"
		}
	}

	#return $retval
	return -code $err -errorinfo $::errorInfo -errorcode $::errorCode $retval
}
proc temporary-forced-option { args } {
	return [uplevel 1 temporary-forced-options $args]
}





# Just returns true or false if the given option is enabled or not.
proc is-option-enabled-basic { option } {
	return [option-string-to-value [get-option-value $option]]
}

# Returns true if the given option is enabled, false otherwise.
# Takes care of automatically unloading options, persist options, etc.
proc is-option-enabled { option } {
	# removing the option is conditional on the option value not being forced,
	# since if the value has been forced, then the option module (ie. the preference
	# indicated by the user) is not taken into account, and so should not disappear
	# on them...  i think.
	if { ! [option-forced $option] } {
		add-option-to-remove $option
	}
	return [is-option-enabled-basic $option]
}


}

