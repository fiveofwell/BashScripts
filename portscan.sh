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

if [[ $# -eq 0 ]]; then
	address="192.168.1.1"
	check_IP_format "${address}"
elif [[ $# -eq 1 ]]; then
	if [[ "$1" == "-s" ]]; then
		skip_ping=true
		address="192.168.1.1"
		check_IP_format "${address}"
	else
		address="$1"
		check_IP_format "${address}"
	fi
elif [[ $# -eq 2 ]]; then
	option="$1"
	if [[ "${option}" == "-s" ]]; then
		skip_ping=true
	else
		echo "Invalid option."
		echo "Usage: $0 [-s] [IP address]"
		exit 1
	fi
	address="$2"
	check_IP_format "${address}"
else
	echo "Too many arguments."
	exit 1
fi

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
