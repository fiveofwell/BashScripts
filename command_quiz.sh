#!/bin/bash

problems=(
	ls
	pwd
	cp
	mv
	rm
	mkdir
	rmdir
	touch
	cat
	less
	head
	tail
	find
	locate
	du
	df
	chmod
	chown
	ln
	grep
	awk
	sed
	sort
	uniq
	wc
	cut
	paste
	join
	tr
	ps
	top
	kill
	killall
	uptime
	uname
	free
	iostat
	lsof
	dmesg
	service
	systemctl
	ping
	traceroute
	ifconfig
	tar
	gzip
	scp
)

input=""
i=0

echo "Command quiz!"
echo "Type \"end\" to finish"

while [[ "${input}" != "end" && "${i}" -lt "${#problems[@]}" ]]
do
	cmd="${problems["${i}"]}"
	description="$(man "${cmd}" | col -b | sed -n '/^NAME/,/^SYNOPSIS/p' | grep '-' | cut -d '-' -f 2 | sed 's/^ //g' )"
	echo "\"${description}\""
	read input
	if [[ "${input}" == "${cmd}" ]];then
		echo "Correct!"
	elif [[ "${input}" != "end" ]]; then
		echo "Incorrect. The answer is ${cmd}"
	fi
	(( i++ ))
done
