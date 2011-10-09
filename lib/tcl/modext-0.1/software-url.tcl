
# An abstraction for generating URLs that reference the software web site.
# Returns a string.

# kjp900, 2009-01-05


set ::default_software_url_site "ANU"

set ::default_software_url_host "xe"
set nodename [uname nodename]
if { [string match "x*" $nodename] } {
	set ::default_software_url_host "xe"
} elseif { [string match "ac*" $nodename] } {
	set ::default_software_url_host "ac"
}

set ::default_software_url_software "$::package"

set ::default_software_url_version "$::version"

set ::default_software_url_subversion ""

set ::default_software_url_revision ""



set ::software_url_site "${::default_software_url_site}"

intercepted single-proc software-url-site { { site none } } {
	if { "$site" == "none" } {
		set ::software_url_site "${::default_software_url_site}"
	} else {
		set ::software_url_site "$site"
	}
}


set ::software_url_host "${::default_software_url_host}"

intercepted single-proc software-url-host { { host none } } {
	if { "$host" == "none" } {
		set ::software_url_host "${::default_software_url_host}"
	} else {
		set ::software_url_host "$host"
	}
}


set ::software_url_software "${::default_software_url_software}"

intercepted single-proc software-url-software-name { { name none } } {
	if { "$name" == "none" } {
		set ::software_url_software "${::default_software_url_software}"
	} else {
		set ::software_url_software "$name"
	}
}


set ::software_url_version "${::default_software_url_version}"

intercepted single-proc software-url-version { { v none } } {
	if { "$v" == "none" } {
		set ::software_url_version "${::default_software_url_version}"
	} else {
		set ::software_url_version "$v"
	}
}


set ::software_url_subversion "${::default_software_url_subversion}"

intercepted single-proc software-url-subversion { v } {
	set ::software_url_subversion "$v"
}


set ::software_url_revision "${::default_software_url_revision}"

intercepted single-proc software-url-revision { v } {
	set ::software_url_revision "$v"
}



# Tcl has no out-of-band "null"/"nil"/"None"... :(

# This is the new function.
single-OptProc software-url {
	{ -site -string "DEFAULT" }
	{ -host -string "DEFAULT" }
	{ -software -string "DEFAULT" }
	{ -version -string "DEFAULT" }
	{ -subversion -string "DEFAULT" }
	{ -revision -string "DEFAULT" }
	{ -section -string "" }
	{ -full -boolflag }
} {
	if { "$site" == "DEFAULT" } {
		set site ${::software_url_site}
	}
	if { "$host" == "DEFAULT" } {
		set host ${::software_url_host}
	}
	if { "$software" == "DEFAULT" } {
		set software ${::software_url_software}
	}
	if { "$version" == "DEFAULT" } {
		set version ${::software_url_version}
	}
	if { "$subversion" == "DEFAULT" } {
		set subversion ${::software_url_subversion}
	}
	if { "$revision" == "DEFAULT" } {
		set revision ${::software_url_revision}
	}

	# Until such time as the apache rewrite rules are in place.
	#set full 1

	if { $full } { 
		# "man n http" gives info on the TCL "http" package, and its "formatQuery" function for url-encoding strings
		show-debug "http versions: [package versions http]"
		if { [ catch {package require http 2.0} ] } {
			# Couldn't find 2.0, try 1.0
			if { [ catch {package require http 1.0} ] } {
				# Couldn't find 1.0 either
				show-debug "No http 2.* or 1.* packages available!"
				return "\[Unable to generate software URL: site=\"$site\", host=\"$host\", software=\"$software\", version=\"$version\", subversion=\"$subversion\", revision=\"$revision\", section=\"$section\"\]"
			} else {
				set formatQuery http_formatQuery
			}
		} else {
			set formatQuery ::http::formatQuery
		}

		return "http://nf.nci.org.au/facilities/software/software_host.php?[$formatQuery site $site host $host software $software version $version sub_version $subversion revision $revision show_section $section]"
	} else {
		return "http://nf.nci.org.au/sw/$site/$host/$software/$version/$subversion/$revision/$section"
	}
}


# This is the old and deprecated way to get urls to the software map.
single-proc software_url { software version host { site "ANU" } } {
	show-debug "http versions: [package versions http]"
	if { [ catch {package require http 2.0} ] } {
		# Couldn't find 2.0, try 1.0
		if { [ catch {package require http 1.0} ] } {
			# Couldn't find 1.0 either
			show-debug "No http 2.* or 1.* packages available!"
			return "\[Unable to generate software map URL: software=\"$software\", host=\"$host\", site=\"$site\", version=\"$version\"\]"
		} else {
			set formatQuery http_formatQuery
		}
	} else {
		set formatQuery ::http::formatQuery
	}

	# "man n http" gives info on the TCL "http" package, and its "formatQuery" function for url-encoding strings
	return "http://nf.nci.org.au/facilities/software/software_host.php?[$formatQuery site $site host $host software $software version $version]"
	#return "http://nf.nci.org.au/sw?[$formatQuery site $site host $host software $software version $version]"
}


