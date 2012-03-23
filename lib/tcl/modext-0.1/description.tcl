
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



package provide modext 0.1


namespace eval modext {

	namespace eval internal {
		# Automatic way of figuring out the location of the modext files.
		# Better would probably be to use [file split] and [file join].
		#puts stderr "info script = [info script]"
		#regsub "/\[^/\]*$" [info script] "" homedir
		set homedir [file dirname [info script]]
		#puts stderr "homedir = $homedir"
	}
	#puts stderr "homedir = $internal::homedir"

	#source "$internal::homedir/global_vars.tcl"

	set ::rc [catch {

		namespace eval config {
			source [file join [set [namespace parent]::internal::homedir] site-config.tcl]
		}

		# at this stage, only definitions of stuff
		set definitions_files [list]

		lappend definitions_files basic
		lappend definitions_files stacking
		lappend definitions_files env

		lappend definitions_files options
		lappend definitions_files options-definitions

		lappend definitions_files show-debug

		lappend definitions_files cluestick

		# Deprecated.
		#lappend definitions_files intercept

		lappend definitions_files restrict

		lappend definitions_files options-declare

		lappend definitions_files autohelp


		# Sets up default variables and stuff.
		lappend definitions_files default_version

		lappend definitions_files plural-arguments
		lappend definitions_files plural-arguments-definitions

		# Stuff that defines procs.
		lappend definitions_files legacy-script
		lappend definitions_files abstraction
		lappend definitions_files self-conflict
		lappend definitions_files prereqs
		# FIXME: software-url

		foreach f $definitions_files {
			source [file join $internal::homedir $f.tcl]
		}

	} ::errmsg]

	if { $::rc == 1 } {
		if { [info exists ::errorInfo] && [info exists ::errorCode] } {
			#set show_backtrace [expr [modext::check-envvar-enabled MODULES_ERROR_BACKTRACE] || [modext::check-envvar-enabled MODULE_ERROR_BACKTRACE]]
			set show_backtrace 1
			if { $show_backtrace } {
				puts stderr ""
			}
			puts -nonewline stderr "MODULE ERROR DETECTED"
			if { ! [string equal $::errorCode NONE] } {
				puts -nonewline stderr " (error code: $::errorCode)"
			}
			puts -nonewline stderr ": "
			if { $show_backtrace } {
				puts stderr "$::errorInfo"
			} else {
				puts stderr "[firstline $::errorInfo]"
				puts stderr "(Detailed error information and backtrace has been suppressed, set \$MODULES_ERROR_BACKTRACE to unsuppress.)"
			}
			unset show_backtrace
			error "$::errmsg" $::errorInfo $::errorCode
		}
	}


	namespace eval internal {

		proc description { script } {

			# pre stuff
			# ...

			# now comes the per-module specific stuff (eg. $version, $package, etc)

			# remember to reset any global stuff, eg. wrapperdir lists, options_to_remove, etc etc.
			# actually, deliberately DO NOT clear options_to_remove.  better to make sure that all
			# the used options (in any of the 3 stages) end up getting cleared.

			::modext::internal::init-default_version
			::modext::internal::init_wrapperdirs
			::modext::internal::init-package-envvar-prefix
			::modext::internal::init-inhibit_base_envvar
			::modext::internal::init-inhibit_version_envvar
			package-short-name
			package-full-name
			package-short-desc
			package-long-desc
			::modext::internal::init-package-extra-help
			::modext::internal::init_package_compilers
			::modext::internal::init_package_interpreters
			::modext::internal::init_package_cmds
			::modext::internal::init_package_libs
			::modext::internal::init_package_see_also
			::modext::internal::init_package_group
			::modext::internal::init-inhibit_self_conflict


			uplevel 1 $script

			# post stuff
			# ...

			# wrapperdirs must be done at the end, so that they are always done after bindirs
			::modext::process_wrapperdirs

			# self-conflict (unless requested not to)
			::modext::perform-self-conflict-if-necessary

			# base-envvar (unless requested not to)
			::modext::perform-base-envvar-if-necessary
			::modext::perform-version-envvar-if-necessary 

			::modext::set-whatis-if-necessary
			::modext::set-help-if-necessary

			::modext::only-load ::modext::check-group-access

			# Remove any options that need to be removed.
			::modext::show-debug "options used: [array names ::options_used]"
			::modext::show-debug "options to remove: [array names ::options_to_remove]"
			::modext::option::remove-used-options

			return
		}

	}

}


proc description { script } {

	set ::rc [catch { uplevel 1 [list ::modext::internal::description $script] } ::errmsg]

	if { $::rc == 1 } {
		# FIXME: logging
		# be silent if the error is 'invoked "break" outside of a loop', which is valid module syntax
		# yes this regexp is a silly way to do this, but i don't know any better way...
		if { [info exists ::errorInfo] && [info exists ::errorCode] } {
			if { [regexp {^invoked \"(break|continue)\" outside of a loop} $::errorInfo] } {
				# shoosh!
			} elseif { [regexp {^EXIT [0-9]+\n} $::errorInfo] } {
				# shoosh!
			} elseif { [regexp -lineanchor {while executing.^\"conflict .*\"$} $::errorInfo] } {
				# shoosh!
			} elseif { [regexp -lineanchor {while executing.^\"prereq .*\"$} $::errorInfo] } {
				# shoosh!
			} else {
				set show_backtrace [expr [::modext::check-envvar-enabled MODULES_ERROR_BACKTRACE] || [::modext::check-envvar-enabled MODULE_ERROR_BACKTRACE]]
				if { $show_backtrace } {
					puts stderr ""
				}
				puts -nonewline stderr "MODULE ERROR DETECTED"
				if { ! [string equal $::errorCode NONE] } {
					puts -nonewline stderr " (error code: $::errorCode)"
				}
				puts -nonewline stderr ": "
				if { $show_backtrace } {
					puts stderr "$::errorInfo"
				} else {
					puts stderr "[firstline $::errorInfo]"
					puts stderr "(Detailed error information and backtrace has been suppressed, set \$MODULES_ERROR_BACKTRACE to unsuppress.)"
				}
				unset show_backtrace
			}
			error "$::errmsg" $::errorInfo $::errorCode
		}
	}

	#if { $::rc == 1 } {
	#	# FIXME: logging
	#	if { [info exists ::errorInfo] && [info exists ::errorCode] } {
	#		set show_backtrace [expr [::modext::check-envvar-enabled MODULES_ERROR_BACKTRACE] || [::modext::check-envvar-enabled MODULE_ERROR_BACKTRACE]]
	#		if { $show_backtrace } {
	#			puts stderr ""
	#		}
	#		puts -nonewline stderr "MODULE ERROR DETECTED"
	#		if { ! [string equal $::errorCode NONE] } {
	#			puts -nonewline stderr " (error code: $::errorCode)"
	#		}
	#		puts -nonewline stderr ": "
	#		if { $show_backtrace } {
	#			puts stderr "$::errorInfo"
	#		} else {
	#			puts stderr "[firstline $::errorInfo]"
	#			puts stderr "(Detailed error information and backtrace has been suppressed, set \$MODULES_ERROR_BACKTRACE to unsuppress.)"
	#		}
	#		unset show_backtrace
	#		error "$::errmsg" $::errorInfo $::errorCode
	#	}
	#}

	return
}


