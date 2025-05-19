#!/bin/bash

source check_IP_format.sh

scan_ports=(
	20
	21
	22
	23
	25
	53
	80
	123
	143
	161
	162
	443
	587
	8080
)

skip_ping=false

while getopts "s" OPT
do
	case $OPT in
		s)
			skip_ping=true ;;
		*)
			echo "Usage: $0 [-s] [address]"
			exit 1 ;;
	esac
done

shift $((OPTIND -1))

if [[ $# -eq 1 ]]; then
	address="$1"
else
	address="192.168.1.1"
fi

check_IP_format "${address}"

if ! ${skip_ping}; then
	if ! ping -c 1 -W 3 "${address}" >/dev/null 2>&1; then
		echo "Cannot access to ${address}"
		exit 1
	fi
fi

echo "The port scan is performed on ${address}."

for port in "${scan_ports[@]}"
do
	if nc -z -w1 "${address}" "${port}" 2>/dev/null; then
		echo "${port} is open."
	else
		echo "${port} is closed."
	fi
done
