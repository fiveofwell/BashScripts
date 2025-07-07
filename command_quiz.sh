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
	lsof
	dmesg
	service
	systemctl
	ping
	ifconfig
	tar
	scp
)

input=""
i=0

echo "Command quiz!"
echo "Type \"end\" to finish"

correct_cnt=0
problem_cnt=0

while [[ "${input}" != "end" && "${i}" -lt "${#problems[@]}" ]]
do
	all="${#problems[@]}"
	rand="$(( RANDOM % all ))"
	cmd="${problems["${rand}"]}"
	description="$(man "${cmd}" | col -b | sed -n '/^NAME/,/^SYNOPSIS/p' | grep '-' | cut -d '-' -f 2 | sed 's/^ //g' )"
	echo ""
	echo "\"${description}\""
	read input
	if [[ "${input}" == "${cmd}" ]];then
		echo "Correct!"
		(( correct_cnt++ ))
	elif [[ "${input}" != "end" ]]; then
		echo "Incorrect. The answer is ${cmd}"
	else
		(( problem_cnt-- ))
	fi
	(( i++ ))
	(( problem_cnt++ ))
done

echo ""
echo "==RESULT=="
if [[ "${correct_cnt}" -eq "${problem_cnt}" ]]; then
	echo "${correct_cnt}/${problem_cnt} PERFECT!"
else
	echo "${correct_cnt}/${problem_cnt}"
fi

accuracy="$(( correct_cnt * 100 / problem_cnt ))"
echo "Accuracy: ${accuracy}%"
