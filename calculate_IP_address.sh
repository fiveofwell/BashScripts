#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/check_IP_format.sh"

function usage () {
	echo "Usage: $0 <IP address> <subnet mask>"
	echo "       $0 <IP address>/<prefix length>"
	echo ""
	echo "Example: $0 192.168.1.10 255.255.255.0"
	echo "         $0 192.168.1.10/24"
}

address=""
subnet_mask=""

#CIDR notation
if [[ -n $(echo "${1}" | grep '/') ]]; then
	if [[ $# -ne 1 ]]; then
		echo "Too many arguments."
		usage
		exit 1
	fi

	address=$(echo "${1}" | cut -d '/' -f 1)
	prefix=$(echo "${1}" | cut -d '/' -f 2)
	if ! [[ ${prefix} =~ ^[0-9]+$ ]] || ((prefix < 0 || prefix > 32)); then
		echo "Invalid CIDR prefix: ${prefix}"
		exit 1
	fi

	for i in {1..4}
	do
		subnet_bit=""
		for j in {1..8}
		do
			if (((i - 1) * 8 + j <= prefix)); then
				subnet_bit="${subnet_bit}1"
			else
				subnet_bit="${subnet_bit}0"
			fi
		done

		subnet_mask=${subnet_mask}$(echo "ibase=2; ${subnet_bit}" | bc)
		if [[ ${i} -ne 4 ]]; then
			subnet_mask="${subnet_mask}."
		fi
	done
else

	if [[ $# -le 1 ]]; then
		echo "Arguments required."
		usage
		exit 1
	elif [[ $# -ge 3 ]]; then
		echo "Too many arguments."
		usage
		exit 1
	fi
	address="${1}"
	subnet_mask="${2}"
fi

check_IP_format "${address}"

if ! check_IP_format -e "${subnet_mask}" >/dev/null; then
	echo "Invalid subnet mask: ${subnet_mask}"
	exit 1;
fi

bin=""
for i in {1..4}
do
	field=$(echo "${subnet_mask}" | cut -d "." -f "${i}")
	binary_field=$(printf "%08d" "$(echo "ibase=10; obase=2; ${field}" | bc)")
	bin="${bin}${binary_field}"
done

if ! [[ ${bin} =~ ^1*0*$ ]]; then
	echo "Invalid subnet mask: ${subnet_mask}"
	exit 1
fi

network_address=""
broadcast_address=""

for i in {1..4}
do
	field=$(echo "${address}" | cut -d "." -f "${i}")
	subnet_field=$(echo "${subnet_mask}" | cut -d "." -f "${i}")
	network_address="${network_address}$((${field} & ${subnet_field}))"
	broadcast_address="${broadcast_address}$((${field} | (255 ^ ${subnet_field})))"

	if [[ ${i} -ne 4 ]]; then
		network_address="${network_address}."
		broadcast_address="${broadcast_address}."
	fi

done

echo "Network address is ${network_address}"
echo "Broadcast address is ${broadcast_address}"
