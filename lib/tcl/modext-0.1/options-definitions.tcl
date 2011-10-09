

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
# Options must be registered HERE before they can be used.
#
# You will probably also want to create the actual options modulefiles in
# /opt/Modules/options/o, as appropriate.  Each one should just have:
#
##%Module1.0
#source /opt/Modules/extensions/extensions.tcl
#declare-option
#
# and that's enough.
#
###########################################################################


##############################################################################
##############################################################################
##############################################################################


# To create a new option, register it here, then create appropriate
# modules inside /opt/Modules/options/o/ as desired.

# Options are ENABLED by default.
# Flags are options that are DISABLED by default.
# Therefore call "register-option" vs "register-flag" accordingly.

#option::register wrappers "wrapper scripts" n
option::register wrappers "wrapper scripts"

option::register ld_library_path "the \$LD_LIBRARY_PATH environment variable (for dynamic library linking)"
option::register ld_run_path "the \$LD_RUN_PATH environment variable (for dynamic library linking)"
option::register library_path "the \$LIBRARY_PATH environment variable (for finding libraries at link time)"

option::register-flag show-debug "verbose debugging info"

option::register-flag persist "persistent options"

# Paths are generally prepended, unless overridden with this.
option::register-flag append-paths "appending paths to environment variables"

# Flags are generally appended, unless overridden with this.
option::register-flag prepend-flags "prepending flags to environment variables"

option::register-flag packaged-envvars "using \$PACKAGE_FOO instead of \$FOO"



##############################################################################
##############################################################################
##############################################################################


