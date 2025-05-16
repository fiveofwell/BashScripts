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

if [[ $# -eq 0 ]]; then
	address="192.168.1.1"
	check_IP_format "${address}"
elif [[ $# -eq 1 ]]; then
	address="$1"
	check_IP_format "${address}"
else
	echo "Too many arguments."
	exit 1
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
