
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
		regsub "/\[^/\]*$" $module "" parent_module
		if { [is-loaded $parent_module] } {
			# great
		} else {
			module load $module
		}
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
		# FIXME: BUG: if no module is loaded, this will loop forever.
		# need to break out if $parent_module is empty or if the regsub
		# doesn't change it.
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


