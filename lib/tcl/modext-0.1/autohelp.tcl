
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




proc help-heading { s } {
	return "[string toupper ${s}]\n[string repeat "-" [expr [string length ${s}] + 1]]\n\n"
}

proc set-help-if-necessary { } {
	if { ! [proc-defined ::ModulesHelp] } {
		# Modulefile has not provided its own help, we will do so here.
		::modext::show-debug "providing auto help"

		set heading "${::modext::internal::package_full_name}"
		if { ! [string equal "${::version}" ""] } {
			set heading "$heading, version ${::version}"
		}
		set heading "[string toupper $heading]"

		set ruler "[string repeat "*" [expr [string length $heading] + 6]]"

		# FIXME: use append
		set ::autohelp_str ""
		set ::autohelp_str "${::autohelp_str}[center "$ruler"]\n"
		set ::autohelp_str "${::autohelp_str}[center "*  $heading  *"]\n"
		set ::autohelp_str "${::autohelp_str}[center "$ruler"]\n"
		set ::autohelp_str "${::autohelp_str}\n"

		# descriptions
		if { ! [string equal "${::modext::internal::package_short_desc}" ""] || ! [string equal "${::modext::internal::package_long_desc}" ""] } {
			set ::autohelp_str "${::autohelp_str}[::modext::help-heading "Description"]"

			# short description
			if { ! [string equal "${::modext::internal::package_short_desc}" ""] } {
				set ::autohelp_str "${::autohelp_str}${::modext::internal::package_short_desc}\n"
				set ::autohelp_str "${::autohelp_str}\n"
			}

			# long description
			if { ! [string equal "${::modext::internal::package_long_desc}" ""] } {
				set ::autohelp_str "${::autohelp_str}${::modext::internal::package_long_desc}\n"
				set ::autohelp_str "${::autohelp_str}\n"
			}

			set ::autohelp_str "${::autohelp_str}\n"
		}

		# access (group) requirements
		if { ! [string equal "${::modext::internal::package_group}" ""] } {
			set ::autohelp_str "${::autohelp_str}[::modext::help-heading "Access Prerequisites"]"
			set ::autohelp_str "${::autohelp_str}* Membership of the '${::modext::internal::package_group}' group.\n"
			# FIXME: output eligibility
			set result [in_group ${::modext::internal::package_group}]
			if { $result == 0 } {
				set ::autohelp_str "${::autohelp_str}  * This requirement is satisfied.\n"
				set ::autohelp_str "${::autohelp_str}    You have access to ${::modext::internal::package_full_name}.\n"
			} elseif { $result == 1 } {
				set ::autohelp_str "${::autohelp_str}  * This requirement is NOT satisfied.\n"
				set ::autohelp_str "${::autohelp_str}    You DO NOT have access to ${::modext::internal::package_full_name}.\n"
			} elseif { $result == 2 } {
				set ::autohelp_str "${::autohelp_str}  * Unable to check if this requirement is satisfied or not.\n"
			}
			set ::autohelp_str "${::autohelp_str}\n"
			set ::autohelp_str "${::autohelp_str}\n"
		}

		# commands provided
		if { [llength ${::modext::internal::package_cmds}] > 0 } {
			set ::autohelp_str "${::autohelp_str}[::modext::help-heading "Commands Provided"]"
			foreach cmd ${::modext::internal::package_cmds} {
				set ::autohelp_str "${::autohelp_str}  $cmd\n"
			}
			set ::autohelp_str "${::autohelp_str}\n"
			set ::autohelp_str "${::autohelp_str}\n"
		}

		# libraries provided
		if { [llength ${::modext::internal::package_libs}] > 0 } {
			set ::autohelp_str "${::autohelp_str}[::modext::help-heading "Libraries Provided"]"
			foreach lib ${::modext::internal::package_libs} {
				set ::autohelp_str "${::autohelp_str}  $lib\n"
			}
			set ::autohelp_str "${::autohelp_str}\n"
			set ::autohelp_str "${::autohelp_str}\n"
		}

		# see also
		if { [llength ${::modext::internal::package_see_also}] > 0 } {
			set ::autohelp_str "${::autohelp_str}[::modext::help-heading "See Also"]"
			foreach ref ${::modext::internal::package_see_also} {
				set ::autohelp_str "${::autohelp_str}  $ref\n"
			}
			set ::autohelp_str "${::autohelp_str}\n"
			set ::autohelp_str "${::autohelp_str}\n"
		}

		# options used
		if { [array size ::options_used] > 0 } {
			set ::autohelp_str "${::autohelp_str}[::modext::help-heading "Options Recognised"]"
			foreach option [array names ::options_used] {
				set ::autohelp_str "${::autohelp_str}$option:\n"
				set ::autohelp_str "${::autohelp_str}  * [::modext::option::get-option-description $option]\n"
				set ::autohelp_str "${::autohelp_str}  * currently: [string tolower [::modext::option::option-value-to-english [::modext::option::is-option-enabled $option]]]d (default: [string tolower [::modext::option::option-value-to-english [::modext::option::get-option-default $option]]]d)\n"
				set ::autohelp_str "${::autohelp_str}\n"
			}
		}

		# any extra help messages
		if { [llength ${::modext::internal::package_extra_help}] > 0 } {
			set ::autohelp_str "${::autohelp_str}\n"
			foreach msg ${::modext::internal::package_extra_help} {
				foreach msg2 $msg {
					set ::autohelp_str "${::autohelp_str}$msg2\n"
				}
			}
			set ::autohelp_str "${::autohelp_str}\n"
		}

		# define the help proc
		#proc ::ModulesHelp { } "
		#	puts stderr \${::autohelp_str}
		#	break
		#"
		#proc ::ModulesHelp { } "
		#	puts stderr \${::autohelp_str}
		#"
		proc ::ModulesHelp { } {
			puts stderr ${::autohelp_str}
			#proc ::break { } { }
			#break
		}
	}
}


set ::whatis_provided 0

proc module-whatis_replace { args } {
	# Notice when the user runs module-whatis, so that we don't have to
	# provide our own automatic one.
	set ::whatis_provided 1
	eval module-whatis_runreal $args
	#uplevel 1 module-whatis_runreal $args
}

proc ::inhibit-auto-whatis { } {
	set ::whatis_provided 1
}

proc set-whatis-if-necessary { } {
	if { ! ${::whatis_provided} } {
		# Modulefile has not provided its own whatis, we will do so here.
		::modext::show-debug "providing auto whatis"
		set str "${::modext::internal::package_full_name}"
		if { ! [string equal "${::version}" ""] } {
			set str "$str, version ${::version}"
		}
		if { ! [string equal "${::modext::internal::package_short_desc}" ""] } {
			set str "$str: ${::modext::internal::package_short_desc}"
		}
		module-whatis "$str"
	}
}


if { [string equal module-info [info commands module-info]] && [module-info mode help] } {
	# standard modules commands aren't defined in help mode.
	# or rather, they're defined, but calling them is diabolical.
	# it makes stuff fail.
	# which inhibits showing the help.
	# ARGH!  dickheads!
	# not sure which commands are affected and which aren't.

	proc ::prereq { args } {
		# FIXME: save the list and display it in autohelp
	}

	#proc ::conflict { args } {
	#	# FIXME: save the list and display it in autohelp
	#}

	# unresolved...
	# appears impossible - modules is a piece of shit
	#proc ::break { args } {
	#	uplevel 1 ::tcl::break $args
	#}

	# unresolved...
	#proc ::continue { args } {
	#}

	proc ::exit { args } {
	}
}

