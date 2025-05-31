#!/bin/bash

function usage () {
	echo "Usage: $0 [-d]"
	echo "-d	Delete log files"
}

logfile="/var/log/check_suid"
temp_logfile="/tmp/check_suid_temp"
last_check="/var/log/check_suid_date"

if [[ $(id -u) -ne 0 ]]; then
	echo "Please run as root."
	exit 1
fi

if [[ $# -ne 0 ]]; then
	if [[ $1 == "-d" ]]; then
		if rm -f ${logfile} ${temp_logfile} ${last_check}; then
			echo "Logfiles deleted successfully."
		else
			echo "Logfile deletion failed."
			exit 1
		fi
	else
		echo "Invalid option ${1}."
		usage
		exit 1;
	fi
fi

if [[ ! -f ${logfile} ]]; then
	echo "Generating logfiles for future use..."
	find / -perm -u+s -ls 1> ${logfile} 2>/dev/null
	date > ${last_check}
	if [[ -f ${logfile} && -f ${last_check} ]]; then
		echo "Logfile generated successfully."
		exit 0
	else
		echo "Logfile generation failed."
		exit 1
	fi
fi

find / -perm -u+s -ls 1> ${temp_logfile} 2>/dev/null

if [[ -f ${last_check} ]]; then
	echo -n "last check : "
	cat ${last_check}
fi

if ! diff ${logfile} ${temp_logfile} >/dev/null; then
	echo "There is a change in files with the SUID bit set. Check ${logfile} immediately."
	diff -u ${logfile} ${temp_logfile}
	mv ${temp_logfile} ${logfile}
else
	echo "No changes found since last check."
	rm -f ${temp_logfile}
fi

date > ${last_check}
exit 0
