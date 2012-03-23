
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




OptProc ::legacy-script {
	{ mode -choice { load unload } }
	{ shelltype -choice { sh csh } }
	{ script -string }
} {
	if { [ module-info mode $mode ] && [string equal [module-info shelltype] $shelltype] } {
		if { [file readable $script] } {
			puts stdout "source $script ; "
			return 1
		} else {
			puts stderr "Warning: Unable to read legacy script $script"
			return 0
		}
	}
}

