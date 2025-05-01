#!/bin/bash

source check_IP_format.sh

if [[ $# -le 1 ]]; then
echo "Two agrguments required."
exit 1
elif [[ $# -ge 3 ]]; then
echo "Too many arguments."
exit 1
fi

check_IP_format $1
check_IP_format $2

for i in {1..4}
do

field=$(echo "${2}" | cut -d "." -f "${i}")
if [[ ${field} -eq 255 || ${field} -eq 0 ]]; then
continue
fi

binary=$(echo "ibase=10; obase=2; ${field}" | bc)
if [[ -z $(echo "${binary}" | grep '^1*0*$') ]]; then
echo "Invalid subnet mask."
exit 1
elif [[ ${#binary} -lt 8 && "${binary}" == 1* ]]; then
echo "Invalid subnet mask."
exit 1
fi

done

network_address="";
for i in {1..4}
do
field=$(echo "${1}" | cut -d "." -f "${i}")
subnet_field=$(echo "${2}" | cut -d "." -f "${i}")
network_address="${network_address}$((${field}&${subnet_field}))"

if [[ ${i} -ne 4 ]]; then
network_address="${network_address}."
fi

done

echo "Network address is ${network_address}"
