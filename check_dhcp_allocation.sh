#!/bin/bash

function check_ip_format() {
	local field_count=$(echo "${1}" | awk -F '.' '{print NF}')
	if [[ "${field_count}" -ne 4 ]]; then
		echo "Invalid IP address."
		exit 1
	fi

	for i in {1..4}
	do
		local field=$(echo "${1}" | cut -d . -f "${i}")
		if [[ -n $(echo "${field}" | sed 's/[0-9]//g') ]]; then
			echo "Invalid IP address."
			exit 1
		elif [[ -z "${field}" ]]; then
			echo "Invalid IP address."
			exit 1
		elif [[ "${field}" -lt 0 || "${field}" -gt 255 ]]; then
			echo "Invalid IP address."
			exit 1
		fi	       
	done
}

temp_dir=$(mktemp -d)

scan_start_ip="192.168.1.%g"

if [[ $# -eq 1 ]];then
	check_ip_format "${1}"
	scan_start_ip=${1}
elif [[ $# -ne 0 ]];then
	echo "Too many arguments."
	exit 1
fi

scan_start_ip="$(echo "${scan_start_ip}" | cut -d . -f 1-3).0"
echo "Scan starts from: ${scan_start_ip}"
scan_start_ip="$(echo "${scan_start_ip}" | cut -d . -f 1-3).%g";

seq -f "${scan_start_ip}" 254 | xargs -P 100 -I {} bash -c \
	'ping -c 1 {} | grep "ttl" | cut -d " " -f 4 | sed "s/://g" > '"$temp_dir"'/{}result.txt'

cat ${temp_dir}/*result.txt | sort -u
rm -r ${temp_dir}
