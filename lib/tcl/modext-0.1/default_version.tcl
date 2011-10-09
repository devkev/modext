
# Sets the value of $version (TCL variable) to be the final part of the module
# filename.  Also sets $default_version identically.  Also sets $modulefiledir
# to the directory containing the modulefile.
#
# eg. if the module is "intel-fc/10.1.018" from /apps/Modules/modulefiles, then
# $default_version and $version will be set to "10.1.018" and $modulefiledir
# will be set to "/apps/Modules/modulefiles/intel-fc".
#
# Modulefiles are of course free to override $version, but should do so as
# early as possible after sourcing extensions.tcl.  Nothing's stopping them
# from overriding $default_version and $modulefiledir, except that it's a dumb
# thing to do.

# kjp900, 2008-12-17

proc internal::init-default_version { } {

	#global extensions_home
	#source "$extensions_home/global_vars.tcl"
	global ModulesCurrentModulefile

	# FIXME: use [file]
	#regsub "^/.*/" "$ModulesCurrentModulefile" "" default_version
	#regsub "^.*/" "$ModulesCurrentModulefile" "" default_version
	regsub "^.*/" "[module-info name]" "" ::default_version

	#regsub "^/.*/\(\[^/\]*\)/\[^/\]*$" "$ModulesCurrentModulefile" "\\1" ::default_package
	#regsub "^(.*/)?\(\[^/\]*\)/\[^/\]*$" "[module-info name]" "\\1" ::default_package
	regsub "/.*$" "[module-info name]" "" ::default_package

	# For finding common files.
	regsub "/\[^/\]*$" "$ModulesCurrentModulefile" "" ::modulefiledir


	# FIXME: [file tail] ftw
	proc ::string_endswith { s suffix } {
		#puts stderr "[string length $suffix] $suffix"
		#puts stderr "[string range $s end-[string length $suffix] end]"
		return [string equal $suffix [string range $s end-[expr [string length $suffix] - 1] end]]
	}


	if { [string equal $::default_version $::default_package] } {
		# This is an unversioned module/package.
		set ::default_version ""
	}
	if { [string equal $::default_package "o"] } {
		# This is an option module.
		set ::default_package $::default_version
		set ::default_version ""
		set ::default_basedir ""
		set ::default_basedir_root ""
	} else {
		# If the module file ($ModulesCurrentModulefile) is a symlink, and it has a basename
		# of "modulefile", then the directory of the "modulefile" file that it points to,
		# is the $default_basedir.  Also if this ends in $default_package or
		# $default_package/$default_version (as appropriate), then strip that off and set
		# $default_basedir_root to the resulting string, so that set-basedir will work as
		# expected later on.
		# 
		# Otherwise, if the modulefile full path ends in "Modules/modulefiles", then strip
		# that off, and that's the default_basedir_root, ie. append $default_package or
		# $default_package/$default_version to that, and that's your $default_basedir (though
		# probably best to just set $default_basedir_root, so that set-basedir will work as
		# expected later on.
		#
		# Otherwise, strip the package/version, then search backwards for the first "mf" element.
		# If found, then substitute "sw" for "mf", and that's the $basedir.
		#
		# Failing all that, just use the $default_basedir_root which will have been set in
		# site-config.tcl.
		#
		# Also figure out arch and repo, if possible, to set $PACKAGE_ARCH and $PACKAGE_REPO.

		if { [string equal $::default_version ""] } {
			set endbit "$::default_package"
		} else {
			set endbit "$::default_package/$::default_version"
		}

		regsub "/$endbit$" "$ModulesCurrentModulefile" "" modulebasis

		#set symlinkmatch "/modulefile"
		set symlinkmatch [list "modulefile" "syzfile"]
		set traditional_match "/Modules/modulefiles"
		# testing
		#set traditional_match "/noarch"

		set ::default_basedir ""
		set ::default_basedir_root ""
		#puts stderr "endbit $endbit"
		#puts stderr [file type $ModulesCurrentModulefile]
		#puts stderr [file readlink $ModulesCurrentModulefile]
		#puts stderr $modulebasis
		#if { [string equal link [file type $ModulesCurrentModulefile]] && [string_endswith [file readlink $ModulesCurrentModulefile] $symlinkmatch] } {}
		if { [string equal link [file type $ModulesCurrentModulefile]] && [lsearch -exact $symlinkmatch [file tail [file readlink $ModulesCurrentModulefile]]] != -1 } {
			#puts stderr "foobar"
			# FIXME: relative symlinks must be resolved!
			#set ::default_basedir [string range [file readlink $ModulesCurrentModulefile] 0 end-[string length $symlinkmatch]]
			#set ::default_basedir [file dirname [file readlink $ModulesCurrentModulefile]]
			set ::default_basedir [file_absolutify -base [file dirname $ModulesCurrentModulefile] [file dirname [file readlink $ModulesCurrentModulefile]]]
			#set pointsto 
			#if { [string index $pointsto 0] == "/" } {
			#	set ::default_basedir $pointsto
			#} else {
			#	# FIXME: [file normalize] is too heavy-handed.
			#	# I just want to remove the "../" segments, but still allow symlinks.
			#	# eg. consider that /sw -> /mnt/bigdisk/sw.
			#	# using [file normalize] like this will make the basedir be "/mnt/bigdisk/sw/...",
			#	# when i still just want it to be "/sw/...".
			#	#set ::default_basedir [file normalize [file dirname $ModulesCurrentModulefile]/$pointsto]
			#	#set ::default_basedir [file_regularise [file dirname $ModulesCurrentModulefile]/$pointsto]
			#	set ::default_basedir [file_absolutify [file dirname $ModulesCurrentModulefile]/$pointsto]
			#}

			#puts stderr "$::default_basedir"
			if { [string_endswith $::default_basedir "/$endbit"] } {
				set ::default_basedir_root [string range $::default_basedir 0 end-[string length "/$endbit"]]
			}
		} elseif { [string_endswith $modulebasis $traditional_match] } {
			#puts stderr "bunk"
			set ::default_basedir_root [string range $modulebasis 0 end-[string length $traditional_match]]
		} else {
		}

		if { [string equal $::default_basedir ""] && [string equal ::default_basedir_root [info exists ::default_basedir_root]] } {
			if { ! [string equal $::default_basedir_root ""] } {
				#puts stderr "bing"
				set ::default_basedir "$::default_basedir_root/$endbit"
			}
		}
	}

	::modext::show-debug "default_version = $::default_version"
	::modext::show-debug "default_package = $::default_package"
	::modext::show-debug "default_basedir = $::default_basedir"
	::modext::show-debug "default_basedir_root = $::default_basedir_root"


	set ::version "$::default_version"
	set ::package "$::default_package"
	set ::basedir "$::default_basedir"

}

::modext::internal::init-default_version

