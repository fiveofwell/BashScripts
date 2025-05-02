#!/bin/bash

function exit_with_error() {
echo "Invalid IP address : ${1}"
exit 1
}

function check_IP_format() {
local address
for address in "$@"
do
	local field_count=$(echo "${address}" | awk -F '.' '{print NF}')
	if [[ "${field_count}" -ne 4 ]]; then
		exit_with_error "${address}"
	fi

	for i in {1..4}
	do
		local field=$(echo "${address}" | cut -d . -f "${i}")
		if [[ -n $(echo "${field}" | sed 's/[0-9]//g') ]]; then
		exit_with_error "${address}"
		elif [[ -z "${field}" ]]; then
		exit_with_error "${address}"
		elif [[ "${field}" -lt 0 || "${field}" -gt 255 ]]; then
		exit_with_error "${address}"
		fi	       
	done
done
}
