#!/bin/bash

function usage () {
	echo "Usage: $0 <IP_address>"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/check_IP_format.sh"

if [[ "$#" -eq 0 ]]; then
	echo "Target IP address required."
	usage
	exit 1
elif [[ "$#" -ge 2 ]]; then
	echo "Too many arguments."
	usage
	exit 1
fi

address="$1"
max_hops=30

check_IP_format "${address}"

if ! ping -c3 -W3 "${address}" >/dev/null; then
	echo "Host ${address} is unreachable."
	exit 1
fi

echo "${max_hops} hops max."

reached=false

for ttl in $(seq 1 ${max_hops})
do
	result="$(LANG=C ping -c1 -t "${ttl}" "${address}")"
	if [[ "$?" -eq 0 ]]; then
		response_time="$(echo "$result" | grep 'time=' | sed -E 's/.*time=([0-9.]+) ms.*/\1/')"
		echo "${ttl} : ${address} (${response_time} ms)"
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
