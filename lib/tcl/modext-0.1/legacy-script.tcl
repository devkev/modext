


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

