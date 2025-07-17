#!/bin/bash

function usage () {
	echo "Usage: $0 [-m] [-h] <destination>"
	echo "-m     Specify max hops (default:30)"
	echo "-h     Help"
}

max_hops=30

while getopts "hm:" OPT
do
	case "${OPT}" in
	h)
		usage
		exit 0 ;;
	m)
		if [[ "${OPTARG}" =~ ^[1-9][0-9]*$ || "${OPTARG}" -eq 0 ]]; then
			max_hops="${OPTARG}"
		else
			echo "Invalid hop specification: ${OPTARG}"
			exit 1
		fi ;;
	*)
		exit 1 ;;
	esac
done

shift $((OPTIND -1))

if [[ "$#" -eq 0 ]]; then
	echo "Destination required."
	usage
	exit 1
elif [[ "$#" -ge 2 ]]; then
	echo "Too many arguments."
	usage
	exit 1
fi

destination="$1"

if ! ping -c3 -W3 "${destination}" >/dev/null; then
	echo "Host ${destination} is unreachable."
	exit 1
fi

if [[ "${max_hops}" -eq 1 ]]; then
	echo "${max_hops} hop max."
else
	echo "${max_hops} hops max."
fi

reached=false

for ttl in $(seq 1 ${max_hops})
do
	result="$(LANG=C ping -c1 -t "${ttl}" "${destination}")"
	if [[ "$?" -eq 0 ]]; then
		response_time="$(echo "${result}" | grep 'time=' | sed -E 's/.*time=([0-9.]+) ms.*/\1/')"
		echo "${ttl} : ${destination} (${response_time} ms)"
		reached=true
		break
	elif [[ -n "$(echo "${result}" | grep exceeded)" ]]; then
		reply_address="$(echo "${result}" | grep 'From' | cut -d ' ' -f 2)"
		echo "${ttl} : ${reply_address}"
	else
		echo "${ttl} : *"
	fi
done

if ! $reached; then
	echo "Reached max hops."
fi
