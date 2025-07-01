#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/check_IP_format.sh"

function usage () {
	echo "Usage: $0 [-s] [-d] [-p port-port] [-h] [address]"
	echo "-s              Skip ping check"
	echo "-d              Disable displaying service name"
	echo "-p port-port    Specify port range"
	echo "-h              Help"
	echo "address         Target IP address (default:192.168.1.1)"	
}

function port_range_validation () {
	if [[ "$1" -gt 65535 || "$1" -lt 0 ]]; then
		echo "Invalid port range."
		exit 1
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

declare -A unique_ports

for port in "${scan_ports[@]}"
do
	unique_ports["${port}"]=1
done

skip_ping=false
show_service_name=true

while getopts "sdp:h" OPT
do
	case "${OPT}" in
		s)
			skip_ping=true ;;
		d)
			show_service_name=false ;;
		p)
			if [[ ! "${OPTARG}" =~ ^[0-9]+\-[0-9]+$ ]]; then
				echo "Invalid port specification."
				exit 1
			fi

			port_start=$(echo "${OPTARG}" | cut -d '-' -f 1)
			port_end=$(echo "${OPTARG}" | cut -d '-' -f 2)

			port_range_validation "${port_start}"
			port_range_validation "${port_end}"

			if [[ "${port_start}" -gt "${port_end}" ]]; then
				echo "Invalid port specification."
				exit 1
			fi

			for i in $(seq "${port_start}" "${port_end}")
			do
				unique_ports["${i}"]=1
			done ;;
		h)
			usage
			exit 0 ;;
		*)
			usage
			exit 1 ;;
	esac
done

shift $((OPTIND -1))

if [[ "$#" -eq 0 ]]; then
	address="192.168.1.1"
elif [[ "$#" -eq 1 ]]; then
	address="$1"
else
	echo "Too many arguments."
	exit 1
fi

check_IP_format "${address}"

if [[ "${skip_ping}" != true ]]; then
	if ! ping -c 1 -W 3 "${address}" >/dev/null 2>&1; then
		echo "Cannot ping ${address}. It might be offline or ICMP is blocked."
		echo "You can skip the ping check by using the -s option."
		exit 1
	fi
fi

echo "The port scan is performed on ${address}."

for port in $(printf "%s\n" "${!unique_ports[@]}" | sort -n)
do
	if [[ "${show_service_name}" == true ]]; then
		service_name="$(grep -m1 -E "${port}/(tcp|udp)" /etc/services | cut -f 1)"
		if [[ -z "${service_name}" ]]; then
			service_name="unknown"
		fi
		if nc -z -w1 "${address}" "${port}" 2>/dev/null; then
			echo "${port}(${service_name}) is open."
		else
			echo "${port}(${service_name}) is closed."
		fi
	else
		if nc -z -w1 "${address}" "${port}" 2>/dev/null; then
			echo "${port} is open."
		else
			echo "${port} is closed."
		fi
	fi
done
