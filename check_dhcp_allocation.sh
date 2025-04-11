#!/bin/bash

function check_ip_format() {
	local field_count=$(echo "${1}" | awk -F '.' '{print NF}')
	if [[ ${field_count} -ne 4 ]]; then
		echo "Invalid IP address."
		exit 1
	fi

	for i in {1..4}
	do
		local field=$(echo "${1}" | cut -d . -f "${i}")

		if [[ -z ${field} ]]; then
			echo "Invalid IP address."
			exit 1
		fi

		if [[ ${field} -lt 0 || ${field} -gt 255 ]]; then
			echo "Invalid IP address."
			exit 1
		fi	       
	done
}

temp_dir=$(mktemp -d)

scan_start_ip="192.168.1.%g"

if [[ $# -eq 1 ]];then
	check_ip_format ${1}
elif [[ $# -eq 2 ]]; then
	check_ip_format ${1}
fi

seq -f "${scan_start_ip}" 254 | xargs -P 100 -I {} bash -c \
	'ping -c 1 {} | grep "ttl" | cut -d " " -f 4 | sed "s/://g" > '"$temp_dir"'/{}result.txt'

cat ${temp_dir}/*result.txt | sort -u
rm -r ${temp_dir}
