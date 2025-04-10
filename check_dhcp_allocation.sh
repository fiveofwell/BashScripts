#!/bin/bash

temp_dir=$(mktemp -d)
 
seq -f "192.168.1.%g" 254 | xargs -P 100 -I {} bash -c \
'ping -c 1 {} | grep "ttl" | cut -d " " -f 4 | sed "s/://g" > '"$temp_dir"'/{}result.txt'

cat ${temp_dir}/*result.txt | sort -u
rm -r ${temp_dir}
