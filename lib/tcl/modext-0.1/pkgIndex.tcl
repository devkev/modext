
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


# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

# This dumb junk.  Hand-created, since extensions.tcl uses variables that are only defined inside modules.

#puts stderr "ticket to freedom?"
#puts stderr "modulefilename is $ModulesCurrentModulefile"
#puts stderr "modulefilename is $::ModulesCurrentModulefile"

#package ifneeded modext 1.0 [list]
#source [file join $dir extensions.tcl]

#package ifneeded modext 1.0 [list source [file join $dir extensions.tcl]]
#package ifneeded modext 1.0 [list set extensions_home $dir \; source [file join $dir description.tcl]]
package ifneeded modext 0.1 [list source [file join $dir description.tcl]]
