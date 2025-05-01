#!/bin/bash

function check_IP_format() {
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

