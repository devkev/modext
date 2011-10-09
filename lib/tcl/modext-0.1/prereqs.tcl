
# Various useful abstractions for prerequisite conditions.

# kjp900, 2009-01-06



# hard-prereq someothermodule
proc ::hard-prereq { args } {
	uplevel 1 prereq $args
}

# soft-prereq someothermodule
# FIXME: correct behaviour with multiple modules specified (ie. boolean or)
proc ::soft-prereq { module } {
	# FIXME: correct behaviour if the specified module contains a version
	if { [is-loaded $module] } {
		# great
	} else {
		module load $module
	}
}

# force-prereq someothermodule/someversion
# FIXME: correct behaviour with multiple modules specified (ie. boolean or)
proc ::force-prereq { module } {
	if { [is-loaded $module] } {
		# nothing to do
	} else {
		# check if some other version is loaded, remove if necessary before loading
		# FIXME: infinite loop bug
		regsub "/\[^/\]*$" $module "" parent_module
		while { "$parent_module" != "$module" } {
			if { [is-loaded $parent_module] } {
				module unload $parent_module
				break
			}
			regsub "/\[^/\]*$" $parent_module "" parent_module
		}
		module load $module
	}
}


