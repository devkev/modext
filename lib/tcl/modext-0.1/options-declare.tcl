


proc declare-option-actual { modoption } {
	#puts stderr "modoption = $modoption"
	set option [::modext::option::determine-option-name $modoption]
	#puts stderr "option = $option"
	set value [::modext::option::determine-option-value $modoption $option]
	#puts stderr "value = $value"

	# FIXME: re-enable this later
	#inhibit-self-conflict

	::modext::option::remove-option-other-modules $option $value

	# check for persistency:
	# - in module load, if persistent option is enabled then add this option to $optenv_persistent
	# - in module unload, always remove this option from $optenv_persistent (trust me :)
	::modext::conditional-load-always-unload [::modext::option::is-option-enabled persist] append-path $::optenv_persistent $option


	set optenv [::modext::option::get-optenv $option]
	setenv $optenv [::modext::option::option-value-to-string $value]

}


proc ::declare-option { } {
	#puts stderr "version = $version"
	#puts stderr "package = $package"
	set modoption "$::package"
	#puts stderr "modoption = $modoption"
	set option [::modext::option::determine-option-name $modoption]
	#puts stderr "option = $option"
	set value [::modext::option::determine-option-value $modoption $option]
	#puts stderr "value = $value"

	::modext::declare-option-actual $modoption


	# module-whatis and ModulesHelp

    set whatismsg "[string toupper [::modext::option::option-value-to-english $value]]S [::modext::option::get-option-description $option]."

	module-whatis "$whatismsg"

	# Do not be tempted to make helpmsg local, and then remove the { braces } from
	# the body of ModulesHelp below.  Trust me.
	# You will be nailed if any of the output contains unquoted $, which any that
	# talk about environment variables (eg. $LD_LIBRARY_PATH) will.
	global helpmsg
	set helpmsg "The [::module-info name] module option:
    $whatismsg

The current default is:
    [::modext::option::option-value-to-english [::modext::option::get-option-default $option]] [::modext::option::get-option-description $option].

Refer to \"module help o\" for information on using module options.
"

	proc ModulesHelp { } {
		puts stderr "$::helpmsg"
		if { "[info procs ModulesHelpSupplement]" != "" } {
			ModulesHelpSupplement
		}
	}

}



proc ::declare-options-help { } {

	module-whatis   "\"Module options\" are a way of passing options to modules"

	proc ModulesHelp { } "
		puts stderr \"\\\"Module options\\\" are a way of passing options to other modules.

The presence of an option module is used to indicate a particular
option to another module file.  Option modules are automatically
unloaded after they are used.

Typically, option modules are listed on a module load command line,
just prior to the module being loaded.  For example:

	module load o/wrapper intel-fc

will load the \\\"intel-fc\\\" module, enabling the \\\"o/wrapper\\\" option.
\"
	"

	#only-load-and-show module help o
	::modext::only load-show module help o

	break
}



