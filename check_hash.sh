#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE_DIR="${SCRIPT_DIR}/data"
FILENAME="${SCRIPT_DIR}/data/file_hashes.txt"

usage () {
	echo "Usage: $0 [-p] [-a file [-y | -n]] [-r file]"
	echo "-p             print the hash record file"
	echo "-a file        append the hash of file"
	echo "  -y           If the file already exists in the record, automatically replace its hash"
	echo "  -n           If the file already exists in the record, automatically skip without updating"
	echo "-r file        remove the hash of file"
}

pluralize_file_count () {
	if [[ "$1" -eq 1 ]]; then
		echo -n "$1 file"
	else
		echo -n "$1 files"
	fi
	return 0
}

add_hash () {
	local file="$(realpath "$1")"
	local hash="$(sha256sum "${append_file}" | cut -d ' ' -f1)"
	local timestamp="$(date '+%Y/%m/%d %H:%M:%S')"

	if echo -e "${hash}\t${file}\t${timestamp}" >>"${FILENAME}"; then
		echo "The hash of ${file} was successfully recorded."
		return 0
	else
		echo "Hash recording failed."
		return 1
	fi
}

interactive_add_hash () {
	local file="$(realpath "$1")"
	local auto_yes="$2"
	local auto_no="$3"

	local skip="false"

	if [[ ! -f "${file}" ]]; then
		echo "File ${file} does not exist."
		return 1
	elif check_hash_entry "${file}" ; then
		if [[ "${auto_yes}" = "true" ]]; then
			echo "The hash of ${file} will be replaced."
			if ! remove_hash "${file}"; then
				return 1
			fi
		elif [[ "${auto_no}" = "true" ]]; then
			echo "The hash of ${file} was already recorded. Process skipped."
			skip="true"
		else	
			echo "The hash of ${file} was already recorded."
			while true 
			do
				echo -n "Would you like to replace the hash? (yes/no): "
				read -r input
				if [[ "${input,,}" = "yes" ]]; then
					if ! remove_hash "${file}"; then
						return 1
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
		if add_hash "${file}"; then
			return 0
		else
			return 1
		fi
	fi
	return 0
}

remove_hash () {
	local remove_file="$(realpath $1)"

	if [[ ! -f "${remove_file}" ]]; then
		echo "File ${remove_file} does not exist."
		return 1
	elif ! check_hash_entry "${remove_file}"; then
		echo "The hash of ${remove_file} is not recorded."
		return 1
	fi

	local line_number="$(awk -F '\t' -v name="${remove_file}" '$2 == name {print NR; exit}' "${FILENAME}")"

	if [[ -n "${line_number}" ]]; then
		sed -i "${line_number}d" "${FILENAME}"
	fi

	if ! check_hash_entry "${remove_file}"; then
		echo "The hash of ${remove_file} was successfully deleted."
		return 0
	else
		echo "Failed to delete the hash of ${remove_file}"
		return 1
	fi
}

#return 0 if the hash of "$1" exists
function check_hash_entry () {
	local filename="$1"
	if [[ -n "$(awk -F '\t' -v name="${filename}" '$2 == name {print}' "${FILENAME}")" ]]; then
		return 0
	else
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
			if [[ "${auto_no}" = "true" ]]; then
				echo "The -y and -n options are mutually exclusive."
				exit 1
			fi
			auto_yes="true"
			;;

		n)
			if [[ "${auto_yes}" = "true" ]]; then
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
	if interactive_add_hash "${append_file}" "${auto_yes}" "${auto_no}"; then
		exit 0
	else
		exit 1
	fi
fi

record_count="$(wc -l < "${FILENAME}")"

if [[ "${record_count}" -eq 0 ]]; then
	echo "No files to check."
	exit 0
else
	echo "$(pluralize_file_count "${record_count}") will be checked."
fi

progress=1

unknown_file=0
changed_file=0
unchanged_file=0

GREEN="\033[32m"
RED="\033[31m"
NC="\033[0m"

while IFS=$'\t' read -r hash file timestamp 
do
	echo -n "${progress}/${record_count}: "
	if [[ ! -f "${file}" ]]; then
		(( unknown_file++ ))
		echo -e "${RED}${file} does not exist.${NC}"
	elif [[ "$(sha256sum "${file}" | cut -d ' ' -f1)" != "${hash}" ]]; then
		(( changed_file++ ))
		echo -e "${RED}${file} may have been modified${NC} since ${timestamp}"
	else
		(( unchanged_file++ ))
		echo -e "${GREEN}No changes found on ${file}${NC} since ${timestamp}"
	fi
	(( progress++ ))
done < "${FILENAME}"

if [[ "${unknown_file}" -ne 0 ]]; then
	echo -e "${RED}$(pluralize_file_count "${unknown_file}") does not exist.${NC}"
fi

if [[ "${changed_file}" -ne 0 ]]; then
	echo -e "${RED}$(pluralize_file_count "${changed_file}") modified.${NC}"
fi

if [[ "${unchanged_file}" -ne 0 ]]; then
	echo -e "${GREEN}$(pluralize_file_count "${unchanged_file}") unchanged.${NC}"
fi

exit 0
