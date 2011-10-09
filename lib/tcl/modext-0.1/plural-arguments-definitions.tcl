




#############################
##                         ##
##   DEFAULTED OPTIONS     ##
##                         ##
#############################

#plural-string-argument {defaults default} {} { temporary-defaults $defaults }
plural-string-argument {defaults default} {} { ::modext::option::temporary-defaults $defaults }

# For testing many (4) plurals:
#plural-string-argument {defaults default defs def} {} { temporary-defaults $defaults }



#############################
##                         ##
##      FORCED OPTIONS     ##
##                         ##
#############################

#plural-string-argument {force forced} {} { temporary-forced-options $force }
plural-string-argument {force forced} {} { ::modext::option::temporary-forced-options $force }




#############################
##                         ##
##    BASEDIR OVERRIDES    ##
##                         ##
#############################

#multi-string-argument {basedir basedir-root basedir-package basedir-version} {} { temporary-basedir -root ${basedir-root} -package ${basedir-package} -version ${basedir-version} -basedir ${basedir} }
#multi-string-argument {basedir basedir-root basedir-package basedir-version} {} { temporary-basedir -root ${basedir-root} -package ${basedir-package} -version ${basedir-version} -basedir ${basedir} -- }
#multi-string-argument {basedir basedir-root basedir-package basedir-version} {} { temporary-basedir -root "${basedir-root}" -package "${basedir-package}" -version "${basedir-version}" -basedir "${basedir}" }
multi-string-argument {basedir basedir-root basedir-package basedir-version} {} { ::modext::temporary-basedir -root "${basedir-root}" -package "${basedir-package}" -version "${basedir-version}" -basedir "${basedir}" }






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



#############################
##                         ##
##        LANGUAGES        ##
##                         ##
#############################

# the language code names that are used are the same as the prefixes to $flags, eg. $cflags, $ldflags
set internal::languages [list c cxx cpp cxxcpp f f77 f90 ld ar as py pl pl5]
set internal::languagesep " \t\n,:;"

proc valid-language { lang } {
	if { [string equal -nocase "$lang" "all"] } {
		return $::modext::internal::languages
	} elseif { [string equal -nocase "$lang" "none"] || [string equal -nocase "$lang" ""] } {
		return [list]
	} elseif { [lsearchnocase $::modext::internal::languages $lang] >= 0 } {
		# direct language names
		return [list $lang]
	} else {
		# language synonyms
		if { [string equal -nocase "$lang" "c++"] } {
			return [list cxx]
		} elseif { [string equal -nocase "$lang" "c++cpp"] } {
			return [list cxxcpp]
		} elseif { [string equal -nocase "$lang" "cppcxx"] } {
			return [list cxxcpp]
		} elseif { [string equal -nocase "$lang" "cppc++"] } {
			return [list cxxcpp]
		} elseif { [string equal -nocase "$lang" "fortran"] } {
			return [list f]
		} elseif { [string equal -nocase "$lang" "fortran77"] } {
			return [list f77]
		} elseif { [string equal -nocase "$lang" "fortran90"] } {
			return [list f90]
		} elseif { [string equal -nocase "$lang" "link"] } {
			return [list ld]
		} elseif { [string equal -nocase "$lang" "linker"] } {
			return [list ld]
		} elseif { [string equal -nocase "$lang" "a"] } {
			return [list ar]
		} elseif { [string equal -nocase "$lang" "archive"] } {
			return [list ar]
		} elseif { [string equal -nocase "$lang" "archiver"] } {
			return [list ar]
		} elseif { [string equal -nocase "$lang" "s"] } {
			return [list as]
		} elseif { [string equal -nocase "$lang" "assembly"] } {
			return [list as]
		} elseif { [string equal -nocase "$lang" "assembler"] } {
			return [list as]
		} elseif { [string equal -nocase "$lang" "python"] } {
			return [list py]
		} elseif { [string equal -nocase "$lang" "perl"] } {
			return [list pl]
		} elseif { [string equal -nocase "$lang" "perl5"] } {
			return [list pl5]
		}
	}
	return -code error "\"[info level 0]\": the language \"$lang\" is not valid"
}

# test if any of the given langs are present in $languages.
# langs can be whitespace separated (ie. [llength $args] > 0), or
# separated by anything in $::languagesep.
proc is-language { args } {
	upvar 1 languages languages
	upvar 1 languagearray languagearray

	foreach arg $args {
		foreach lang [split $arg $::modext::internal::languagesep] {
			# everything in [valid-language $lang] must be $languages
			foreach l [::modext::valid-language $lang] {
				if { ! [info exists languagearray($l)] } {
					return 0
				}
			}
		}
	}
	return 1
}

proc update-languages-from-list { } {
	uplevel 1 {
		set languagelist $languages
		unset languagearray
		array set languagearray [list]
		foreach reallang $languagelist {
			array set languagearray [list $reallang y]
		}
		if { [info exists reallang] } { unset reallang }
		set numlanguages [array size languagearray]
	}
}

proc update-languages-from-array { } {
	uplevel 1 {
		set languagelist [lsort [array names languagearray]]
		set languages $languagelist
		set numlanguages [array size languagearray]
	}
}

proc ensure-at-least-1-language { } {
	uplevel 1 {
		::modext::ensure-at-least-1-in-list languages
	}
}

proc all-languages-by-default { } {
	uplevel 1 {
		if { [string equal $origlanguagelist ""] } {
			set languages [valid-language all]
			::modext::update-languages-from-list
		}
	}
}

plural-string-argument {languages language langs lang} {
	if { ! [array exists languagearray] } {
		set origlanguagelist $languages
		unset languages
		array set languagearray [list]
		foreach lang [split "$origlanguagelist" $::modext::internal::languagesep] {
			foreach reallang [::modext::valid-language $lang] {
				array set languagearray [list $reallang y]
			}
		}
		if { [info exists lang] } { unset lang }
		if { [info exists reallang] } { unset reallang }
		::modext::update-languages-from-array
	}
}




#############################
##                         ##
##        FLAVOURS         ##
##                         ##
#############################

# similarly flavour.
# regularise-flavour should also set ${flavour_suffix} accordingly.

set internal::flavours [list gnu intel pgi]
set internal::flavoursep " \t\n,:;"

proc valid-flavour { flavour } {
	if { [string equal -nocase "$flavour" "all"] } {
		return $::modext::internal::flavours
	} elseif { [string equal -nocase "$flavour" "none"] || [string equal -nocase "$flavour" ""] } {
		return [list]
	} elseif { [lsearchnocase $::modext::internal::flavours $flavour] >= 0 } {
		# direct language names
		return [list $flavour]
	} else {
		# language synonyms
		if { [string equal -nocase "$flavour" "portland"] } {
			return [list pgi]
		}
	}
	return -code error "\"[info level 0]\": the flavour \"$flavour\" is not valid"
}

# test if any of the given flavours are present in $flavours.
# flavours can be whitespace separated (ie. [llength $args] > 0), or
# separated by anything in $::flavoursep.
proc is-flavour { args } {
	upvar 1 flavours flavours
	upvar 1 flavourarray flavourarray

	foreach arg $args {
		foreach flav [split $arg $::modext::internal::flavoursep] {
			# everything in [valid-flavour $flav] must be $flavours
			foreach l [::modext::valid-flavour $flav] {
				if { ! [info exists flavourarray($l)] } {
					return 0
				}
			}
		}
	}
	return 1
}

proc update-flavours-from-list { } {
	uplevel 1 {
		set flavourlist $flavours
		unset flavourarray
		array set flavourarray [list]
		foreach realflav $flavourlist {
			array set flavourarray [list $realflav y]
		}
		if { [info exists realflav] } { unset realflav }
		set numflavours [array size flavourarray]
	}
}

proc update-flavours-from-array { } {
	uplevel 1 {
		set flavourlist [lsort [array names flavourarray]]
		set flavours $flavourlist
		set numflavours [array size flavourarray]
	}
}

proc ensure-at-least-1-flavour { } {
	uplevel 1 {
		::modext::ensure-at-least-1-in-list flavours
	}
}

proc all-flavours-by-default { } {
	uplevel 1 {
		if { [string equal $origflavourlist ""] } {
			set flavours [::modext::valid-flavour all]
			::modext::update-flavours-from-list
		}
	}
}

proc suffixes-from-flavours { } {
	uplevel 1 {
		if { [info exists suffixes] } {
			# only add to it
			foreach flavour $flavours {
				lappend suffixes _[string toupper $flavour]
			}
		} else {
			# doesn't exist yet, so create if necc
			if { $numflavours == 0 } {
				set suffixes [list ""]
			} else {
				set suffixes [list]
				foreach flavour $flavours {
					lappend suffixes _[string toupper $flavour]
				}
			}
		}
	}
}

plural-string-argument {flavours flavour flavs flav} {
	if { ! [array exists flavourarray] } {
		set origflavourlist $flavours
		unset flavours
		array set flavourarray [list]
		foreach flav [split "$origflavourlist" $::modext::internal::flavoursep] {
			foreach realflav [::modext::valid-flavour $flav] {
				array set flavourarray [list $realflav y]
			}
		}
		if { [info exists flav] } { unset flav }
		if { [info exists realflav] } { unset realflav }
		::modext::update-flavours-from-array
	}
}



