
# An easy way of running a "common" module file, where the module files for a
# package can be parametrised in terms of (only) the version number.

# Usage:
#   docommon [-version <version>] [-common-file <commonfile>]
#
# Both arguments are optional.
# <version> defaults to the final part of the module filename,
# eg. if the module "intel-fc/10.1.018" calls "docommon", then
# <version> will default to "10.1.018".
# <commonfile> defaults to "common".
#
# eg:
#   docommon
#   docommon -version 10.1.018
#   docommon -common-file common-test
#   docommon -version 10.1.018 -common-file common-test

# kjp900, 2008-12-17



intercepted single-OptProc docommon {
	{ -version -string "none" }
	{ -common-file -string "common" }
} {
	upvar 0 version myversion
	unset version

	global extensions_home
	source "$extensions_home/global_vars.tcl"

	#puts stderr "docommon: ModulesCurrentModulefile = $ModulesCurrentModulefile"
	if { $myversion == "none" } {
		set version $default_version
	} else {
		set version $myversion
	}
	#puts stderr "docommon: version = $version"

	#puts stderr "docommon: modulefiledir = $modulefiledir"
	#puts stderr "docommon: source $modulefiledir/$common"
	source $modulefiledir/${common-file}
}

#trace add execution docommon enterstep dotrace


