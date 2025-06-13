#!/bin/bash

function exit_with_error() {
	local message="$1"
	local no_exit="$2"

	echo "Invalid IP address : ${message}"
	if [[ "${no_exit}" == true ]]; then
		return 1
	else
		exit 1
	fi
}

function check_IP_format() {
	local no_exit=false;

	while getopts "e" OPT
	do
		case $OPT in
			e)
				no_exit=true ;;
			*)
				exit 1 ;;
		esac
	done

	shift $((OPTIND -1))

	local address
	for address in "$@"
	do
		local field_count=$(echo "${address}" | awk -F '.' '{print NF}')
		if [[ "${field_count}" -ne 4 ]]; then
			exit_with_error "${address}" "${no_exit}" || return 1
		fi
		local i
		for i in {1..4}
		do
			local field=$(echo "${address}" | cut -d . -f "${i}")
			if [[ -n $(echo "${field}" | sed 's/[0-9]//g') ]]; then
				exit_with_error "${address}" "${no_exit}" || return 1
			elif [[ -z "${field}" ]]; then
				exit_with_error "${address}" "${no_exit}" || return 1
			elif [[ "${field}" -lt 0 || "${field}" -gt 255 ]]; then
				exit_with_error "${address}" "${no_exit}" || return 1
			fi
		done
	done
}
