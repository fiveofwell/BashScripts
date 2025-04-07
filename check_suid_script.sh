#!/bin/bash

logfile="/var/log/check_suid"
temp_logfile="/tmp/check_suid_temp"

if [[ $(id -u) -ne 0 ]]; then
	echo "Please run as root."
	exit 1
fi

if [[ ! -f ${logfile} ]]; then
	echo "Logfile not found to compare. Try it next time."
	find / -perm -u+s -ls 1> ${logfile} 2>/dev/null
	if [[ -f ${logfile}  ]]; then
		echo "Logfile generated successfully."
		exit 0
	else
		echo "Logfile generation failed."
		exit 1
	fi
fi

find / -perm -u+s -ls 1> ${temp_logfile} 2>/dev/null

if ! diff ${logfile} ${temp_logfile} >/dev/null; then
	echo "There is a change in files with the SUID bit set. Check ${logfile} immediately."
	diff -u ${logfile} ${temp_logfile}
	mv ${temp_logfile} ${logfile}
else
	echo "No changes found since last check."
	rm -f ${temp_logfile}
fi

exit 0
