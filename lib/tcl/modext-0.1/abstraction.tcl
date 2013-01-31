
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


# Various useful abstractions for the types of directories that
# modules frequently provide access to.

# kjp900, 2008-12-17




OptProc ::set-basedir {
	{ -root -string "" }
	{ -package -string "" }
	{ -version -string "" }
	{ ?dir? -string "" }
} {
	# FIXME: new params
	# and: make dir optional { ?dir? -any }
	if { [string equal "$root" ""] } {
		set root ${::default_basedir_root}
	}
	if { [string equal "$package" ""] } {
		set package $::package
	}
	if { [string equal "$version" ""] } {
		set version $::version
	}

	if { [string index $root 0] != "/" } {
		set root "/$root"
	}
	if { [string equal -nocase "$version" "none"] || [string equal -nocase "$version" "no"] } {
		set version ""
	}

	if { [string equal "$dir" ""] } {
		if { [string equal "$version" ""] } {
			set ::basedir "$root/$package"
		} else {
			set ::basedir "$root/$package/$version"
		}
	} elseif { [string index $dir 0] == "/" } {
		set ::basedir $dir
	} else {
		if { [string equal "$version" ""] } {
			set ::basedir "$root/$package/$dir"
		} else {
			set ::basedir "$root/$package/$version/$dir"
		}
	}
}

proc basedir-relative { dir } {
	if { [string index $dir 0] == "/" } {
		return $dir
	} else {
		return ${::basedir}/$dir
	}
}

# temporary-basedir set-basedir-args(sortof) ... --  command args
#intercepted single-OptProc temporary-basedir
#intercepted single-proc temporary-basedir
# temporary-foo cannot be interecepted
OptProc temporary-basedir {
	{ -root -string "" }
	{ -package -string "" }
	{ -version -string "" }
	{ -basedir -string "" }
	{ script }
} {
	#puts stderr "temporary-basedir args = $args"
	#puts stderr "temporary-basedir script = $script"

	if { ! [string equal "$root" ""] || ! [string equal "$package" ""] || ! [string equal "$version" ""] || ! [string equal "$basedir" ""] } {
		set save_basedir $::basedir
		#puts stderr "old basedir = $::basedir"

		#set-basedir $newbasedir
		set-basedir -root $root -package $package -version $version $basedir
		#puts stderr "munging to new basedir = $::basedir"
	}

	# catch errors, cleanup properly
	#set retval [eval $args]
	#set retval [uplevel 1 $script]
	set err [catch { uplevel 1 $script } retval]

	if { ! [string equal "$root" ""] || ! [string equal "$package" ""] || ! [string equal "$version" ""] || ! [string equal "$basedir" ""] } {
		set-basedir $save_basedir
		#puts stderr "restored basedir to = $::basedir"
	}

	#return $retval
	return -code $err -errorinfo $::errorInfo -errorcode $::errorCode $retval
}



# Compilers:
#   CC for C compiler
#   CPP for C pre-processor
#   CXX for C++ compiler
#   CXXCPP for C++ pre-processor (according to autoconf)
#   FC for Fortran (77/90) compiler
#   F77 for Fortran 77 compiler
#   F90 for Fortran 90 compiler
#   AS for assembler
#   AR for archiver
#   LD for linker

# Flags:
#   LDFLAGS for linker ($LD) flags
#   CPPFLAGS for C pre-processor ($CPP) flags
#   CFLAGS for C compiler ($CC) flags
#   CXXFLAGS for C++ compiler ($CXX) flags
#   CXXCPPFLAGS for C++ preprocessor ($CXXCPP) flags
#   FFLAGS for Fortran compiler ($FC) flags (when compiling either Fortran 77 or 90 code)
#   F77FLAGS for Fortran compiler ($FC) flags when compiling Fortran 77 code
#   F90FLAGS for Fortran compiler ($FC) flags when compiling Fortran 90 code
#   ASFLAGS for assembler ($AS) flags
#   ARFLAGS for archiver ($AR) flags

# Extra libs:
#   LIBS (for autoconf), LDLIBS (for make) for general libs, always applied
#   CLIBS (for users) for libs for C programs
#   CXXLIBS (for users) for libs for C++ programs
#   FLIBS (for users) for libs (for either Fortran 77 or 90 programs)
#   F77LIBS (for users) for libs for Fortran 77 programs
#   F90LIBS (for users) for libs for Fortran 90 programs



# Adds paths to the given variable.
# Either prepend-path or append-path is used subject to the append-paths option.
# The varname has PACKAGE_ prepended if the packaged-envvars option is enabled.
proc internal::add_dirs_to_var { varname args } {
	if { [::modext::option::is-option-enabled packaged-envvars] } {
		set varname "${::package_envvar_prefix}_$varname"
		#puts stderr "varname is now $varname due to packaged-envvars"
	}
	# FIXME: need to use conditional-load-always-remove, in case the user has set the option when the module is loaded.
	foreach dir $args {
		if { [::modext::option::is-option-enabled append-paths] } {
			append-path $varname $dir
		} else {
			prepend-path $varname $dir
		}
	}
}


proc internal::var_contains_flags { varname args } {
	return [expr [string first [join $args] [env $varname]] != -1]
}

# Adds flags to the given variable.
# Either prepend-path or append-path is used subject to the prepend-flags option.
# The varname has PACKAGE_ prepended if the packaged-envvars option is enabled.
proc internal::add_flags_to_var { varname args } {
	set flags [join $args]

	# on module remove, switch to remove_flags_from_var
	if { [module-info mode remove] } {
		uplevel 1 ::modext::internal::remove_flags_from_var $varname $flags

	} else {

		if { [::modext::option::is-option-enabled packaged-envvars] } {
			set varname "${::package_envvar_prefix}_$varname"
			#puts stderr "varname is now $varname due to packaged-envvars"
		}

		# don't bother if [join $args] is already in the var somewhere
		if { ! [::modext::internal::var_contains_flags $varname $flags] } {
			set space " "
			if { [::modext::option::is-option-enabled prepend-flags] } {
				set value "$flags[env -prefix $space $varname]"
			} else {
				set value "[env -suffix $space $varname]$flags"
			}

			setenv $varname $value
		}

		# rubbish:
		#foreach flag $args {
		#	if { [is-option-enabled prepend-flags] } {
		#		prepend-path -d " " $varname $flag
		#	} else {
		#		append-path -d " " $varname $flag
		#	}
		#}

	}
}


# Removes flags from the given variable.
# Either prepend-path or append-path is used subject to the prepend-flags option.
# The varname has PACKAGE_ prepended if the packaged-envvars option is enabled.
proc internal::remove_flags_from_var { varname args } {
	if { [::modext::option::is-option-enabled packaged-envvars] } {
		set varname "${::package_envvar_prefix}_$varname"
		#puts stderr "varname is now $varname due to packaged-envvars"
	}

	set flags [join $args]

	# on module remove, do nothing
	if { ! [module-info mode remove] } {
		set i [string first $flags [env $varname]]
		if { $i != -1 } {
			setenv $varname [string replace [env $varname] $i [expr $i + [string length $flags]]]
		}
	}


	# rubbish:
	#remove-path -d " " $varname [join $args]
	##foreach flag $args {
	##	#puts stderr "removing from $varname: $flag"
	##	#remove-path -d " " $varname $flag
	##	#remove-path -d " " $varname "$flag"
	##	remove-path -d " " $varname "[join $flag]"
	##}
}


# Sets a variable to the given value.
# The varname has PACKAGE_ prepended if the packaged-envvars option is enabled.
# Yes, this could be done by intercepting setenv.
proc internal::set_var { varname args } {
	if { [::modext::option::is-option-enabled packaged-envvars] } {
		set varname "${::package_envvar_prefix}_$varname"
		#puts stderr "varname is now $varname due to packaged-envvars"
	}
	setenv $varname [join $args]
}



# bin-dir bin bin2 bin3:bin4:... ...
regularised-OptProc ::bin-dir { defaults force basedir } {
	{ args }
} {
	::modext::ensure-at-least-1-arg

	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {
			::modext::internal::add_dirs_to_var PATH [::modext::basedir-relative $dir]
		}
	}
}



# Remember the state of options at the time wrapper-dir is called, and
# restore that for each dir when bin-dir is later called inside
# process_wrapperdirs.

# Probably best done with some proc that will save the complete options state
# somewhere, and another to restore it again (temporarily).

# Actually (much) simpler will be to remember the (text) contents of the -force
# and -defaults args that are given to wrapper-dir and then pass them to
# bin-dir.



proc internal::init_wrapperdirs { } {
	# Use a list for this, since it's better to ensure that the ordering is correct
	# than to ensure that there are no duplicates.
	set ::modext::internal::wrapperdirs [list]
	set ::modext::internal::wrapperdirs_defaults [list]
	set ::modext::internal::wrapperdirs_force [list]
}

::modext::internal::init_wrapperdirs

proc internal::save_wrapperdir { dir defaults force } {
	lappend ::modext::internal::wrapperdirs $dir
	lappend ::modext::internal::wrapperdirs_defaults $defaults
	lappend ::modext::internal::wrapperdirs_force $force
}

proc process_wrapperdirs { } {
	foreach dir $::modext::internal::wrapperdirs defaults $::modext::internal::wrapperdirs_defaults force $::modext::internal::wrapperdirs_force {
		bin-dir -defaults $defaults -force $force $dir
	}
}


# wrapper-dir /apps/intel-fc/wrapper
# If -default is not specified, then the default will be whatever the default is
# for the "wrappers" option.  (Makes perfect sense, right?)
regularised-OptProc ::wrapper-dir { defaults force basedir } {
	{ args }
} {
	::modext::ensure-at-least-1-arg

	# Do not use basedir-relative here, since that will happen later when the underlying bin-dir is called.
	# Similarly, no need to peel out colon-separated paths.

	# NOOOOO - *DO* use basedir-relative here, since it will be influenced by the
	# presence of any basedir regular arguments.
	# When bin-dir is called later, basedir-relative will notice the leading / and not touch the path.
	# Similarly, we DO need to peel out colon-separated paths here.
	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {
			::modext::conditional-load-always-unload [::modext::option::is-option-enabled wrappers] ::modext::internal::save_wrapperdir [::modext::basedir-relative $dir] $defaults $force
		}
	}
}


# eg. man-dir man
# eg. man-dir share/man
regularised-OptProc ::man-dir { defaults force basedir } {
	{ args }
} {
	::modext::ensure-at-least-1-arg

	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {
			::modext::internal::add_dirs_to_var MANPATH [::modext::basedir-relative $dir]
		}
	}
}


# eg. info-dir info
# eg. info-dir share/info
regularised-OptProc ::info-dir { defaults force basedir } {
	{ args }
} {
	::modext::ensure-at-least-1-arg

	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {
			::modext::internal::add_dirs_to_var INFOPATH [::modext::basedir-relative $dir]
		}
	}
}


# eg. pkgconfig-dir pkgconfig
# eg. pkgconfig-dir lib/pkgconfig
regularised-OptProc ::pkgconfig-dir { defaults force basedir flavours } {
	{ args }
} {
	::modext::ensure-at-least-1-arg
	::modext::suffixes-from-flavours

	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {
			foreach suffix $suffixes {
				::modext::internal::add_dirs_to_var PKG_CONFIG_PATH$suffix [::modext::basedir-relative $dir]
			}
		}
	}
}
# FIXME: also proc pkg-config-dir
proc pkg-config-dir { args } {
	uplevel 1 "pkgconfig-dir $args"
}


# lib-dir [ -defaults <default options> ] [ -flavour < none | gnu | intel | pgi > ] lib1 [ lib2:lib3:... lib4 lib5 ... ]
regularised-OptProc ::lib-dir { defaults force basedir flavours } {
	{ args }
} {
	::modext::ensure-at-least-1-arg
	::modext::suffixes-from-flavours

	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {
			foreach suffix $suffixes {
				#::modext::conditional-load-always-unload [is-option-enabled library_path]    prepend-path LIBRARY_PATH$suffix    [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-option-enabled ld_library_path] prepend-path LD_LIBRARY_PATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-option-enabled ld_run_path]     prepend-path LD_RUN_PATH$suffix     [basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::option::is-option-enabled library_path]    ::modext::internal::add_dirs_to_var LIBRARY_PATH$suffix    [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::option::is-option-enabled ld_library_path] ::modext::internal::add_dirs_to_var LD_LIBRARY_PATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::option::is-option-enabled ld_run_path]     ::modext::internal::add_dirs_to_var LD_RUN_PATH$suffix     [::modext::basedir-relative $dir]
			}
		}
	}
}


# include-dir [ -language < all | c | cxx | cpp | c++ | f > ] [ -flavour < none | gnu | intel | pgi > ] $basedir/include
regularised-OptProc ::include-dir { defaults force basedir languages flavours } {
	{ args }
} {
	::modext::ensure-at-least-1-arg
	::modext::all-languages-by-default
	::modext::suffixes-from-flavours

	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {
			foreach suffix $suffixes {
				#::modext::conditional-load-always-unload [is-language c] prepend-path C_INCLUDE_PATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-language cxx]    prepend-path CPLUS_INCLUDE_PATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [expr {([is-language cpp] || [is-language cxxcpp] || ([is-language c] && [is-language cxx]))}] prepend-path CPATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [expr {([is-language f] || [is-language f77] || [is-language f90])}]      prepend-path FPATH$suffix [basedir-relative $dir]
				##::modext::conditional-load-always-unload {([is-language f] || [is-language f77] || [is-language f90])}      prepend-path FPATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-language ld] prepend-path LDPATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-language ar] prepend-path ARPATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-language as] prepend-path ASPATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-language py] prepend-path PYTHONPATH$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-language pl] prepend-path PERLLIB$suffix [basedir-relative $dir]
				#::modext::conditional-load-always-unload [is-language pl5] prepend-path PERL5LIB$suffix [basedir-relative $dir]

				::modext::conditional-load-always-unload [::modext::is-language c] ::modext::internal::add_dirs_to_var C_INCLUDE_PATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::is-language cxx]    ::modext::internal::add_dirs_to_var CPLUS_INCLUDE_PATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [expr {([::modext::is-language cpp] || [::modext::is-language cxxcpp] || ([::modext::is-language c] && [::modext::is-language cxx]))}] ::modext::internal::add_dirs_to_var CPATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [expr {([::modext::is-language f] || [::modext::is-language f77] || [::modext::is-language f90])}]      ::modext::internal::add_dirs_to_var FPATH$suffix [::modext::basedir-relative $dir]
				#::modext::conditional-load-always-unload {([::modext::is-language f] || [::modext::is-language f77] || [::modext::is-language f90])}      ::modext::internal::add_dirs_to_var FPATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::is-language ld] ::modext::internal::add_dirs_to_var LDPATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::is-language ar] ::modext::internal::add_dirs_to_var ARPATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::is-language as] ::modext::internal::add_dirs_to_var ASPATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::is-language py] ::modext::internal::add_dirs_to_var PYTHONPATH$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::is-language pl] ::modext::internal::add_dirs_to_var PERLLIB$suffix [::modext::basedir-relative $dir]
				::modext::conditional-load-always-unload [::modext::is-language pl5] ::modext::internal::add_dirs_to_var PERL5LIB$suffix [::modext::basedir-relative $dir]
			}
		}
	}
}

#intercepted single-OptProc include-dir-old {
#	{ args }
#} {
#	if { "$flavour" == "gnu" } {
#		set suffix "_GNU"
#	} elseif { "$flavour" == "intel" } {
#		set suffix "_INTEL"
#	} elseif { "$flavour" == "pgi" } {
#		set suffix "_PGI"
#	} else {
#		set suffix ""
#	}
#
#	if { "$language" == "cxx" } {
#		set language c++
#	} elseif { "$language" == "cpp" } {
#		set language c++
#	}
#
#	foreach dirlist [reverse $args] {
#		foreach dir [reverse [split $dirlist ":"]] {
#			#::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language all]" ] prepend-path CPATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language c] || [string equal $language all]" ] prepend-path CPATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language c-only] || [string equal $language all]" ] prepend-path C_INCLUDE_PATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language c++] || [string equal $language all]" ] prepend-path CPLUS_INCLUDE_PATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language f] || [string equal $language all]" ] prepend-path FPATH$suffix [basedir-relative $dir]
#		}
#	}
#}


# FIXME: Also: $PYTHONPATH
# FIXME: Also: $PERL5LIB and/or $PERLLIB

#intercepted regularised-OptProc python-lib-dir { defaults force basedir } {
#	{ args }
#} {
#	ensure-at-least-1-arg
#	uplevel 1 "include-dir -language python $args"
#}
#
#intercepted regularised-OptProc perl-lib-dir { defaults force basedir } {
#	{ args }
#} {
#	ensure-at-least-1-arg
#	uplevel 1 "include-dir -language perl $args"
#}
#
#intercepted regularised-OptProc perl5-lib-dir { defaults force basedir } {
#	{ args }
#} {
#	ensure-at-least-1-arg
#	uplevel 1 "include-dir -language perl5 $args"
#}

proc ::python-lib-dir { args } {
	uplevel 1 "include-dir -language python $args"
}

proc ::perl-lib-dir { args } {
	uplevel 1 "include-dir -language perl $args"
}

proc ::perl5-lib-dir { args } {
	uplevel 1 "include-dir -language perl5 $args"
}


proc internal::init_activate_modules { } {
	# Might not support options properly.  But then they are a hack anyway.
	set ::modext::internal::activatemodules [list]
}

::modext::internal::init_activate_modules

proc internal::save_activatemodule { mod } {
	lappend ::modext::internal::activatemodules $mod
}

proc process_activatemodules { } {
	foreach mod $::modext::internal::activatemodules {
		module load $mod
	}
}


# modules-dir modulefiles modulefiles2 modulefiles3:modulefiles4:... ...
regularised-OptProc ::modules-dir { defaults force basedir } {
	{ args }
} {
	::modext::ensure-at-least-1-arg

	foreach dirlist [reverse $args] {
		foreach dir [reverse [split $dirlist ":"]] {

			set fulldir [::modext::basedir-relative $dir]
			#puts stderr "fulldir = $fulldir"

			if { [module-info mode remove] } {
				foreach modfile [split [::modext::env _LMFILES_] ":"] {
					#puts stderr "checking $fulldir against $modfile"
					if { [string equal -length [string length $fulldir] $fulldir/ $modfile] } {
						# ding!
						#puts stderr "ding! $fulldir $modfile"
						# mark this one as inactive
						set modname [string range $modfile [string length $fulldir/] end]
						#puts stderr "modname $modname"
						# cannot use prepend-path because we are unloading, BAH
						#prepend-path INACTIVEMODULES $modname
						#puts stderr "unsetenv INACTIVEMODULES $modname[env -prefix : INACTIVEMODULES]"
						unsetenv INACTIVEMODULES $modname[::modext::env -prefix : INACTIVEMODULES]
						# remember we are already unloading, so must "load" the module to unload it.
						module load $modname

						# junk like this isn't going to fly; modules has too many checks in "module list"
						#unsetenv LOADEDMODULES [env -suffix : LOADEDMODULES]($modname)
						#unsetenv _LMFILES_ [env -suffix : _LMFILES_]$fulldir/$modname
					}
				}
			}

			#prepend-path MODULEPATH $fulldir
			::modext::internal::add_dirs_to_var MODULEPATH $fulldir

			if { [module-info mode load] } {
				foreach modname [split [::modext::env INACTIVEMODULES] ":"] {
					set modfile $fulldir/$modname
					# if exists then remove from INACTIVEMODULES and load it
					# perhaps better to try to check the output of module avail $modname ?
					#set testing [module avail -t $modname]
					#puts stderr "testing: $testing"
					# no, that doesn't work.
					if { [file readable $modfile] } {
						#module load $modname
						::modext::internal::save_activatemodule $modname
						remove-path INACTIVEMODULES $modname
					}
				}
			}

		}
	}
}

proc ::module-dir { args } {
	uplevel 1 "modules-dir $args"
}

proc ::modulefile-dir { args } {
	uplevel 1 "modules-dir $args"
}

proc ::modulefiles-dir { args } {
	uplevel 1 "modules-dir $args"
}




# preload-lib [ -defaults <default options> ] lib
regularised-OptProc ::preload-lib { defaults force basedir } {
	{ args }
} {
	::modext::ensure-at-least-1-arg

	foreach liblist [reverse $args] {
		foreach lib [reverse [split $liblist ":"]] {
			::modext::internal::add_dirs_to_var LD_PRELOAD [::modext::basedir-relative $lib]
		}
	}
}



# FIXME: LDFLAGS, CPPFLAGS, {,F,F90,C,CXX}{LIBS,LDADD,FLAGS} (anything else?)

regularised-OptProc ::ensure-flags { defaults force languages flavours } {
	{ args }
} {
	::modext::ensure-at-least-1-language
	::modext::ensure-at-least-1-arg
	::modext::suffixes-from-flavours

	foreach language $languages {
		foreach suffix $suffixes {
			#append-path -d " " [string toupper $language]FLAGS$suffix "[join $args]"
			#add_flags_to_var [string toupper $language]FLAGS$suffix "[join $args]"
			# Not sure about this:
			::modext::internal::add_flags_to_var [string toupper $language]FLAGS$suffix $args
		}
	}
}


regularised-OptProc ::set-flags { defaults force languages flavours } {
	{ args }
} {
	::modext::ensure-at-least-1-language
	::modext::suffixes-from-flavours

	foreach language $languages {
		foreach suffix $suffixes {
			::modext::internal::set_var [string toupper $language]FLAGS$suffix $args
		}
	}
}


regularised-OptProc ::avoid-flags { defaults force languages flavours } {
	{ args }
} {
	::modext::ensure-at-least-1-language
	::modext::ensure-at-least-1-arg
	::modext::suffixes-from-flavours

	# FIXME: CHECKME
	# make sure that the given flags are NOT present in the $FOOFLAGS var
	# (ie. ala remove-path)
	foreach language $languages {
		foreach suffix $suffixes {
			#remove-path -d " " [string toupper $language]FLAGS$suffix "[join $args]"
			#remove_flags_from_var [string toupper $language]FLAGS$suffix "[join $args]"
			# Not sure about this:
			::modext::internal::remove_flags_from_var [string toupper $language]FLAGS$suffix $args
		}
	}
}



# provides pkg1/ver /loc/of/modulefile/pkg1/ver pkg2 /loc/of/modulefile/pkg2/ver ...
regularised-OptProc ::provides { defaults force } {
	{ args }
} {
	::modext::ensure-at-least-1-arg

	foreach { mod modfile } $args {
		append-path PROVIDEDMODULES $mod
		append-path _PMFILES_ $modfile
	}
}







## bin-dir bin bin2 bin3:bin4:... ...
#intercepted single-OptProc bin-dir {
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	foreach dirlist [reverse $args] {
#		foreach dir [reverse [split $dirlist ":"]] {
#			prepend-path PATH [basedir-relative $dir]
#		}
#	}
#}
#
#
## Use a list for this, since it's better to ensure that the ordering is correct
## than to ensure that there are no duplicates.
#set ::wrapperdirs [list]
#
#single-proc save_wrapperdir { dir } {
#	lappend ::wrapperdirs $dir
#}
#
#single-proc process_wrapperdirs { } {
#	foreach dir $::wrapperdirs {
#		bin-dir $dir
#	}
#}
#
#
## wrapper-dir /apps/intel-fc/wrapper
## If -default is not specified, then the default will be whatever the default is
## for the "wrappers" option.  (Makes perfect sense, right?)
#intercepted single-OptProc wrapper-dir {
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ dir -any }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	# Do not use basedir-relative here, since that will happen later when the underlying bin-dir is called.
#	# Similarly, no need to peel out colon-separated paths.
#	::modext::conditional-load-always-unload [temporary-defaults $defaults -- is-option-enabled wrappers] save_wrapperdir $dir
#	#temporary-defaults $defaults {
#	#	::modext::conditional-load-always-unload [is-option-enabled wrappers] save_wrapperdir $dir
#	#}
#}
#
#
## eg. man-dir man
## eg. man-dir share/man
#intercepted single-OptProc man-dir {
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	foreach dirlist [reverse $args] {
#		foreach dir [reverse [split $dirlist ":"]] {
#			prepend-path MANPATH [basedir-relative $dir]
#		}
#	}
#}
#
#
## eg. info-dir info
## eg. info-dir share/info
#intercepted single-OptProc info-dir {
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	foreach dirlist [reverse $args] {
#		foreach dir [reverse [split $dirlist ":"]] {
#			prepend-path INFOPATH [basedir-relative $dir]
#		}
#	}
#}
#
#
## eg. pkgconfig-dir pkgconfig
## eg. pkgconfig-dir lib/pkgconfig
#intercepted single-OptProc pkgconfig-dir {
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	foreach dirlist [reverse $args] {
#		foreach dir [reverse [split $dirlist ":"]] {
#			prepend-path PKG_CONFIG_PATH [basedir-relative $dir]
#		}
#	}
#}
#
#
## lib-dir [ -defaults <default options> ] [ -flavour < none | gnu | intel | pgi > ] lib1 [ lib2:lib3:... lib4 lib5 ... ]
#intercepted single-OptProc lib-dir {
#	{ -flavour -choice { none gnu intel pgi } }
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	if { "$flavour" == "gnu" } {
#		set suffix "_GNU"
#	} elseif { "$flavour" == "intel" } {
#		set suffix "_INTEL"
#	} elseif { "$flavour" == "pgi" } {
#		set suffix "_PGI"
#	} else {
#		set suffix ""
#	}
#
#	foreach dirlist [reverse $args] {
#		foreach dir [reverse [split $dirlist ":"]] {
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- is-option-enabled library_path] prepend-path LIBRARY_PATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- is-option-enabled ld_library_path] prepend-path LD_LIBRARY_PATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- is-option-enabled ld_run_path] prepend-path LD_RUN_PATH$suffix [basedir-relative $dir]
#		}
#	}
#}
#
#
## include-dir [ -language < all | c | cxx | cpp | c++ | f > ] [ -flavour < none | gnu | intel | pgi > ] $basedir/include
## To change the default, change which option is listed first in the "-choice"
## arguments below.
#intercepted single-OptProc include-dir {
#	{ -language -choice { all c c-only c++ cxx cpp f } }
#	{ -flavour -choice { none gnu intel pgi } }
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	if { "$flavour" == "gnu" } {
#		set suffix "_GNU"
#	} elseif { "$flavour" == "intel" } {
#		set suffix "_INTEL"
#	} elseif { "$flavour" == "pgi" } {
#		set suffix "_PGI"
#	} else {
#		set suffix ""
#	}
#
#	if { "$language" == "cxx" } {
#		set language c++
#	} elseif { "$language" == "cpp" } {
#		set language c++
#	}
#
#	foreach dirlist [reverse $args] {
#		foreach dir [reverse [split $dirlist ":"]] {
#			#::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language all]" ] prepend-path CPATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language c] || [string equal $language all]" ] prepend-path CPATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language c-only] || [string equal $language all]" ] prepend-path C_INCLUDE_PATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language c++] || [string equal $language all]" ] prepend-path CPLUS_INCLUDE_PATH$suffix [basedir-relative $dir]
#			::modext::conditional-load-always-unload [temporary-defaults $defaults -- expr "[string equal $language f] || [string equal $language all]" ] prepend-path FPATH$suffix [basedir-relative $dir]
#		}
#	}
#}
#
#
## FIXME: Also: $PYTHONPATH
## FIXME: Also: $PERL5LIB and/or $PERLLIB
#
#
## preload-lib [ -defaults <default options> ] lib
#intercepted single-OptProc preload-lib {
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#} {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	foreach liblist [reverse $args] {
#		foreach lib [reverse [split $liblist ":"]] {
#			prepend-path LD_PRELOAD [basedir-relative $lib]
#		}
#	}
#}



#intercepted regularised-OptProc ensure-flags { defaults force languages flavours } {
#	{ args }
#} {
#
#	puts stderr "This is definitely ensure-flags running..."
#
#	if { [is-option-enabled persist] } {
#		puts stderr "PERSISTENCE"
#	} else {
#		puts stderr "no persistence"
#	}
#
#	puts stderr "here's a test for ya: [is-option-enabled persist]"
#
#	if { [is-option-enabled ld_library_path] } {
#		puts stderr "LD_LIBRARY_PATH"
#	} else {
#		puts stderr "no ld_library_path"
#	}
#	if { [is-option-enabled ld_run_path] } {
#		puts stderr "LD_RUN_PATH"
#	} else {
#		puts stderr "no ld_run_path"
#	}
#	if { [is-option-enabled library_path] } {
#		puts stderr "LIBRARY_PATH"
#	} else {
#		puts stderr "no library_path"
#	}
#
#
#	#puts stderr "defaults: $defaults"
#	#puts stderr "languages ([array size langarr]): [array names langarr]"
#
#	if { [array size langarr] == 0 } {
#		return -code error {no languages specified}
#	}
#
#	if { [llength args] == 0 } {
#		return -code error {no arguments specified}
#	}
#
#	foreach lang [lsort [array names langarr]] {
#		append-path -d " " [string toupper $lang]FLAGS "[join $args]"
#	}
#
#}

#intercepted single-OptProc ensure-flags [concat ${::defaults_flag} ${::force_flag} ${::languages_flag} {
#	{ args }
#} ] {
#
#	set something "happy"
#
#	regularise-force {
#		puts stderr "just force: $something"
#	}
#	regularise-force {
#		regularise-force {
#			puts stderr "double force: $something"
#		}
#	}
#	regularise-force {
#		regularise-force {
#			regularise-force {
#				puts stderr "triple force: $something"
#			}
#		}
#	}
#
#	#puts stderr [info body regularise-defaults]
#	regularise-defaults {
#		puts stderr "just defaults: $something"
#	}
#	regularise-defaults {
#		regularise-defaults {
#			puts stderr "double defaults: $something"
#		}
#	}
#	regularise-defaults {
#		regularise-defaults {
#			regularise-defaults {
#				puts stderr "triple defaults: $something"
#			}
#		}
#	}
#
#	regularise-defaults {
#		regularise-force {
#			puts stderr "defaults then force: $something"
#		}
#	}
#
#	regularise-force {
#		regularise-defaults {
#			puts stderr "force then defaults: $something"
#		}
#	}
#
#	regularise-defaults {
#		regularise-force {
#			if { [is-option-enabled persist] } {
#				puts stderr "PERSISTENCE"
#			} else {
#				puts stderr "no persistence"
#			}
#		}
#	}
#
#	regularise-defaults {
#		regularise-force {
#			puts stderr "here's a test for ya: [is-option-enabled persist]"
#		}
#	}
#
#	regularise-defaults {
#		puts stderr "here's a test for ya: [is-option-enabled persist]"
#	}
#
#	regularise-defaults {
#		regularise-force {
#			regularise-languages {
#			regularise-languages {
#
#				#puts stderr "defaults: $defaults"
#				#puts stderr "languages ([array size langarr]): [array names langarr]"
#
#				if { [array size langarr] == 0 } {
#					return -code error {no languages specified}
#				}
#
#				if { [llength args] == 0 } {
#					return -code error {no arguments specified}
#				}
#
#				foreach lang [lsort [array names langarr]] {
#					append-path -d " " [string toupper $lang]FLAGS "[join $args]"
#				}
#
#			}
#			}
#		}
#	}
#}

#intercepted single-OptProc set-flags [concat ${::languages_flag} ${::defaults_flag} {
#	{ args }
#} ] {
#	regularise-defaults {
#	regularise-languages {
#
#	if { [array size langarr] == 0 } {
#		return -code error {no languages specified}
#	}
#
#	foreach lang [lsort [array names langarr]] {
#		setenv [string toupper $lang]FLAGS "[join $args]"
#	}
#	}
#	}
#}

#intercepted single-OptProc ensure-flags [concat ${::language_flag} ${::defaults_flag} {
#	{ -replace }
#	{ args }
#} ] {
#	regularise-defaults
#	regularise-languages
#
#	if { [array size languages] == 0 } {
#		return -code error {no languages specified}
#	}
#
#	if { [is-language c c++ fortran,fortran77,fortran90] } {
#		puts stderr "yay, it's one or more of: c, c++, f, f77, f90"
#	} else {
#		puts stderr "no go"
#	}
#
#	if { $replace } {
#		set cmd "setenv"
#	} else {
#		set cmd "append-path -d ' '"
#	}
#	foreach lang [lsort [array names languages]] {
#		eval "$cmd [string toupper $lang]FLAGS [join $args]"
#	}
#}

#intercepted single-OptProc ensure-flags "
#	\"-language -choice $::languages\"
#	{ -defaults -string "" }
#	{ -default -string "" }
#	{ args }
#" {
#	if { "$default" != "" } {
#		if { "$defaults" != "" } {
#			set defaults "$defaults $default"
#		} else {
#			set defaults "$default"
#		}
#	}
#
#	foreach flaglist $args {
#		foreach flag [split $flaglist] {
#			append-path -d ' ' LDFLAGS $flag
#		}
#	}
#}

#intercepted-OptProc avoid-flags {
#} {
#}






# FIXME: move the underscore here...
proc ::package-envvar-prefix { { prefix "DEFAULT" } } {
	if { [string equal $prefix "DEFAULT"] } {
		regsub -all "\[-\]" "$::package" "_" ::modext::internal::package_envvar_prefix
		set ::modext::internal::package_envvar_prefix [string toupper ${::modext::internal::package_envvar_prefix}]
	} else {
		set ::modext::internal::package_envvar_prefix $prefix
	}
}

proc internal::init-package-envvar-prefix { } {
	set ::modext::internal::package_envvar_prefix ""
	package-envvar-prefix
}

::modext::internal::init-package-envvar-prefix


proc ::set-package { package } {
	set ::package $package
	package-envvar-prefix
}

proc ::set-version { version } {
	set ::version $version
}


# FIXME: temporary-package-envvar-prefix, and associated regularised option(s) to
# temporarily change the envvar prefix on certain commands.





#
# setenv PACKAGE_BASE to $::basedir, unless requested not to
#

proc internal::init-inhibit_base_envvar { } {
	set ::modext::internal::inhibit_base_envvar 0
}

::modext::internal::init-inhibit_base_envvar

proc ::inhibit-base-envvar { } {
	set ::modext::internal::inhibit_base_envvar 1
}

proc ::allow-base-envvar { } {
	set ::modext::internal::inhibit_base_envvar 0
}

proc perform-base-envvar-if-necessary { } {
	if { ! [string equal "$::basedir" ""] } {
		::modext::conditional-load-always-unload [expr ! $::modext::internal::inhibit_base_envvar] setenv ${::modext::internal::package_envvar_prefix}_BASE $::basedir
		::modext::conditional-load-always-unload [expr ! $::modext::internal::inhibit_base_envvar] setenv ${::modext::internal::package_envvar_prefix}_ROOT $::basedir
	}
}



#
# setenv PACKAGE_VERSION to $::version, unless requested not to
#

proc internal::init-inhibit_version_envvar { } {
	set ::modext::internal::inhibit_version_envvar 0
}

::modext::internal::init-inhibit_version_envvar


proc ::inhibit-version-envvar { } {
	set ::modext::internal::inhibit_version_envvar 1
}

proc ::allow-version-envvar { } {
	set ::modext::internal::inhibit_version_envvar 0
}

proc perform-version-envvar-if-necessary { } {
	if { ! [string equal "$::version" ""] } {
		::modext::conditional-load-always-unload [expr ! $::modext::internal::inhibit_version_envvar] setenv ${::modext::internal::package_envvar_prefix}_VERSION $::version
	}
}




# FIXME: these should be in the "::modext::info" namespace, not "::modext::internal", which feels a bit wierd when they're used in autohelp.

#set internal::package_short_name "$::package"

proc ::package-short-name { { name none } } {
	if { "$name" == "none" } {
		set ::modext::internal::package_short_name "${::package}"
	} else {
		set ::modext::internal::package_short_name "$name"
	}
}

package-short-name



#set internal::package_full_name "$::package"

proc ::package-full-name { { name none } } {
	if { "$name" == "none" } {
		set ::modext::internal::package_full_name "${::modext::internal::package_short_name}"
	} else {
		set ::modext::internal::package_full_name "$name"
	}
}

package-full-name



#set internal::package_short_desc ""

proc ::package-short-desc { { desc "" } } {
	set ::modext::internal::package_short_desc "$desc"
}
proc ::package-short-description { args } {
	eval package-short-desc $args
}

package-short-desc



#set internal::package_long_desc ""

proc ::package-long-desc { { desc "" } } {
	set ::modext::internal::package_long_desc "$desc"
}
proc ::package-long-description { args } {
	eval package-long-desc $args
}

package-long-desc



proc internal::init-package-extra-help { } {
	set ::modext::internal::package_extra_help [list]
}

::modext::internal::init-package-extra-help

proc ::package-extra-help { args } {
	foreach msg $args {
		lappend ::modext::internal::package_extra_help "$msg"
	}
}




proc internal::init_package_compilers { } {
	set ::modext::internal::package_compilers [list]
}

::modext::internal::init_package_compilers

# FIXME: language and flavour
regularised-OptProc ::provides-compilers { defaults force languages flavours } {
	{ args }
} {
	#ensure-at-least-1-language
	#ensure-at-least-1-arg
	#suffixes-from-flavours

	foreach compiler $args {
		#foreach language $languages {
		#	foreach suffix $suffixes {
		#		#append-path -d " " [string toupper $language]FLAGS$suffix "[join $args]"
		#		#add_flags_to_var [string toupper $language]FLAGS$suffix "[join $args]"
		#		# Not sure about this:
		#		set_var [string toupper $language]C$suffix $compiler
		#	}
		#}

		# FIXME
		lappend ::modext::internal::package_compilers $compiler
	}
}
proc ::provides-compiler { args } {
	eval provides-compilers $args
}



proc internal::init_package_interpreters { } {
	set ::modext::internal::package_interpreters [list]
}

::modext::internal::init_package_interpreters

# FIXME: language and flavour
proc ::provides-interpreters { args } {
	foreach interpreter $args {
		lappend ::modext::internal::package_interpreters $interpreter
	}
}
proc ::provides-interpreter { args } {
	eval provides-interpreters $args
}



proc internal::init_package_cmds { } {
	set ::modext::internal::package_cmds [list]
}

::modext::internal::init_package_cmds

proc ::provides-commands { args } {
	foreach cmd $args {
		lappend ::modext::internal::package_cmds $cmd
	}
}
proc ::provides-command { args } {
	eval provides-commands $args
}
proc ::provides-cmds { args } {
	eval provides-commands $args
}
proc ::provides-cmd { args } {
	eval provides-commands $args
}




proc internal::init_package_libs { } {
	set ::modext::internal::package_libs [list]
}

::modext::internal::init_package_libs

proc ::provides-libraries { args } {
	foreach lib $args {
		lappend ::modext::internal::package_libs $lib
	}
}
proc ::provides-library { args } {
	eval provides-libraries $args
}
proc ::provides-libs { args } {
	eval provides-libraries $args
}
proc ::provides-lib { args } {
	eval provides-libraries $args
}




proc internal::init_package_see_also { } {
	set ::modext::internal::package_see_also [list]
}

::modext::internal::init_package_see_also

proc ::see-also { desc } {
	lappend ::modext::internal::package_see_also $desc
}






# check this at load time, refuse to load if not a member.
# add to autohelp output (including eligibility).

proc internal::init_package_group { } {
	set ::modext::internal::package_group ""
}

::modext::internal::init_package_group

proc ::package-access-group { group } {
	set ::modext::internal::package_group $group
}

# returns 0 if the user is in the group, 1 if not.
# if unable to check the user's groups, returns 2.
proc in_group { group } {
	set groups_program [auto_execok groups]
	if { [string equal "${groups_program}" "" ] } {
		# Unable to check groups
		return 2
	} else {
		foreach g [split [exec "${groups_program}"]] {
			if { [string equal "$g" "$group"] } {
				return 0
			}
		}
		return 1
	}
}

proc check-group-access { } {
	if { ! [string equal "${::modext::internal::package_group}" ""] } {
		# check that the user is a member of the group, if not, abort (break)
		set result [::modext::in_group ${::modext::internal::package_group}]
		if { $result == 0 } {
			# Okay
			show-debug "you are a member of ${::modext::internal::package_group}, no problem"
		} elseif { $result == 1 } {
			puts stderr ""
			puts stderr "ERROR: You must be a member of the '${::modext::internal::package_group}' group to access ${::modext::internal::package_full_name}"
			puts stderr ""
			# FIXME: output a URL
			puts stderr "For more information:"
			puts stderr "  * Refer to the \"Access Prerequisites\" listed for this software in the Software Registry"
			puts stderr "    [software-url -section license]"
			puts stderr "  * Contact the NCI NF helpdesk at: help@nf.nci.org.au"
			puts stderr ""
			break
		} elseif { $result == 2 } {
			# Unable to check groups - warn the user
			puts stderr "WARNING: Unable to check your groups - you may not have access to this software"
		}
	}
}


