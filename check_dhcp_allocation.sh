#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/check_IP_format.sh"

temp_dir=$(mktemp -d)

scan_start_ip="192.168.1.%g"

if [[ $# -eq 1 ]];then
	check_IP_format "${1}"
	scan_start_ip=${1}
elif [[ $# -ne 0 ]];then
	echo "Too many arguments."
	exit 1
fi

scan_start_ip="$(echo "${scan_start_ip}" | cut -d . -f 1-3).0"
echo "Scan starts from: ${scan_start_ip}"
scan_start_ip="$(echo "${scan_start_ip}" | cut -d . -f 1-3).%g";

seq -f "${scan_start_ip}" 254 | xargs -P 100 -I {} bash -c \
	'ping -c 1 {} | grep "ttl" | cut -d " " -f 4 | sed "s/://g" > '"$temp_dir"'/{}result.txt'

cat ${temp_dir}/*result.txt | sort -u
rm -r ${temp_dir}
