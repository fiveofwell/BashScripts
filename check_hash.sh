#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE_DIR="${SCRIPT_DIR}/data"
FILENAME="${SCRIPT_DIR}/data/file_hashes.txt"

usage () {
	echo "Usage: $0 [-a file_to_append] [-r file_to_remove]"
	echo "-a        append the hash of file"
	echo "-r        remove the hash of file"
}

add_hash () {
	local append_file="$1"
	local hash="$(sha256sum "${append_file}" | cut -d ' ' -f1)"
	local append_file_realpath="$(realpath "${append_file}")"
	if echo "${hash} ${append_file_realpath} $(date '+%Y/%m/%d %H:%M:%S')" >>"${FILENAME}"; then
		echo "The hash of ${append_file_realpath} was successfully recorded."
		exit 0
	else
		echo "Hash recording failed."
		exit 1
	fi

}

interactive_add_hash () {
	local append_file="$1"
	local auto_yes="$2"
	local auto_no="$3"

	skip="false"
	if [[ ! -f "${append_file}" ]]; then
		echo "File ${append_file} does not exist."
		exit 1
	elif grep -Fq "${append_file}" "${FILENAME}"; then
		if [[ "${auto_yes}" = "true" ]]; then
			echo "The hash of ${append_file} will be replaced."
			if ! remove_hash "${append_file}"; then
				exit 1
			fi
		elif [[ "${auto_no}" = "true" ]]; then
			echo "The hash of ${append_file} was already recorded. Process skipped."
			skip="true"
		else	
			echo "The hash of ${append_file} was already recorded."
			while true 
			do
				echo -n "Would you like to replace the hash? (yes/no): "
				read -r input
				if [[ "${input,,}" = "yes" ]]; then
					if ! remove_hash "${append_file}"; then
						exit 1
					fi
					break
				elif [[ "${input,,}" = "no" ]]; then
					skip="true"
					break
				else
					echo "Invalid input: ${input}"
				fi
			done
		fi
	fi

	if [[ "${skip}" = "false" ]]; then
		add_hash "${append_file}"
	fi
}

remove_hash () {
	local remove_file="$1"
	if [[ ! -f "${remove_file}" ]]; then
		echo "File ${remove_file} does not exist."
		return 1
	elif ! grep -Fq "${remove_file}" "${FILENAME}"; then
		echo "The hash of ${remove_file} is not recorded."
		return 1
	fi

	sed -i "\|${remove_file}|d" "${FILENAME}"
	if ! grep -Fq "${remove_file}" "${FILENAME}"; then
		echo "The hash of ${remove_file} was successfully deleted."
		return 0
	else
		echo "Failed to delete the hash of ${remove_file}"
		return 1
	fi
}

mkdir -p "${FILE_DIR}"
touch "${FILENAME}"

flag_a="false"
flag_p="false"
auto_yes="false"
auto_no="false"

while getopts "a:r:pyn" OPT
do
	case "${OPT}" in
		a)
			append_file="${OPTARG}"
			flag_a="true"
			;;
		r)
			if remove_hash "${OPTARG}"; then
				exit 0
			else
				exit 1
			fi
			;;
		p)
			flag_p="true"
			;;
		y)
			if [[ "${auto_no}" == "true" ]]; then
				echo "The -y and -n options are mutually exclusive."
				exit 1
			fi
			auto_yes="true"
			;;
		n)
			if [[ "${auto_yes}" == "true" ]]; then
				echo "The -y and -n options are mutually exclusive."
				exit 1
			fi
			auto_no="true"
			;;
		*)
			usage
			exit 1
			;;
	esac
done

shift $((OPTIND -1))

if [[ "$#" -ne 0 ]]; then
	echo "Unexpected arguments: $@"
	usage
	exit 1
fi

if [[ "${flag_p}" = "true" ]]; then
	cat "${FILENAME}"
	exit 0
fi

if [[ "${flag_a}" = "false" && ("${auto_yes}" = "true" || "${auto_no}" = "true") ]]; then
	echo "The -y or -n option must be used with the -a option."
	exit 1
fi

if [[ "${flag_a}" = "true" ]]; then
	interactive_add_hash "${append_file}" "${auto_yes}" "${auto_no}"
	exit 0
fi

while read line
do
	hash="$(echo "${line}" | cut -d ' ' -f1)"
	file="$(echo "${line}" | cut -d ' ' -f2)"
	recorded_time="$(echo "${line}" | cut -d ' ' -f3,4)"
	if [[ ! -f "${file}" ]]; then
		echo "${file} does not exist."
	elif [[ "$(sha256sum "${file}" | cut -d ' ' -f1)" != "${hash}" ]]; then
		echo "${file} may have been modified since ${recorded_time}."
	else
		echo "No changes found on ${file} since ${recorded_time}"
	fi
done < "${FILENAME}"
exit 0
