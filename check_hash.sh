#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE_DIR="${SCRIPT_DIR}/data"
FILENAME="${SCRIPT_DIR}/data/file_hashes.txt"

usage () {
	echo "Usage: $0 -a <file_to_append>"
}

mkdir -p "${FILE_DIR}"
touch "${FILENAME}"

while getopts "a:" OPT
do
	case "${OPT}" in
	a)
		append_file="${OPTARG}"
		if [[ ! -f "${OPTARG}" ]]; then
			echo "File ${append_file} does not exist."
			exit 1
		fi

		hash="$(sha256sum "${append_file}" | cut -d ' ' -f1)"
		append_file_realpath="$(realpath "${append_file}")"
		if echo "${hash} ${append_file_realpath} $(date '+%Y/%m/%d %H:%M:%S')" >>"${FILENAME}"; then
			echo "The hash of ${append_file_realpath} was successfully recorded."
			exit 0
		else
			echo "Hash recording failed."
			exit 1
		fi
		;;
	*)
		usage
		exit 1
		;;
	esac
done

while read line
do
	hash="$(echo "${line}" | cut -d ' ' -f1)"
	file="$(echo "${line}" | cut -d ' ' -f2)"
	recorded_time="$(echo "${line}" | cut -d ' ' -f3,4)"
	if [[ ! -f "${file}" ]]; then
		echo "${file} does not exist."
		exit 1
	elif [[ "$(sha256sum "${file}" | cut -d ' ' -f1)" != "${hash}" ]]; then
		echo "${file} may have been modified since ${recorded_time}."
	fi
done < "${FILENAME}"
exit 0
