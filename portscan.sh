#!/bin/bash

source check_IP_format.sh

function port_range_validation () {
	if [[ ${1} -gt 65535 ]]; then
		echo "Invalid port range."
		exit 1;
	fi
}

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

while getopts "sp:" OPT
do
	case $OPT in
		s)
			skip_ping=true ;;
		p)
			if [[ ! ${OPTARG} =~ ^[0-9]+\-[0-9]+$ ]]; then
				echo "Invaid port specification."
				exit 1
			fi

			port_start=$( echo "${OPTARG}" | cut -d '-' -f 1)
			port_end=$( echo "${OPTARG}" | cut -d '-' -f 2)
			
			port_range_validation "${port_start}"
			port_range_validation "${port_end}"

			if [[ ${port_start} -gt ${port_end} ]]; then
				echo "Invalid port specification."
				exit 1
			fi

			for i in $(seq ${port_start} ${port_end})
			do
				scan_ports+=("${i}")
			done ;;
		*)
			echo "Usage: $0 [-s] [-p ports] [address]"
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
