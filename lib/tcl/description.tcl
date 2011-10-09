

#puts stderr "get going"

proc description { script } {

	#puts stderr "this is the default"

	#package require modext
	set ::rc [catch { package require modext } ::errmsg]
	if { $::rc == 1 } {
		# FIXME: logging
		puts stderr ""
		puts -nonewline stderr "LOW-LEVEL MODEXT ERROR DETECTED"
		if { ! [string equal $::errorCode NONE] } {
			puts -nonewline stderr " (error code: $::errorCode)"
		}
		puts -nonewline stderr ": "
		puts stderr "$::errorInfo"
		error "$::errmsg" $::errorInfo $::errorCode
	}

	#puts stderr "got it"

	uplevel 1 [list description $script]

	#puts stderr "yikes"
}

