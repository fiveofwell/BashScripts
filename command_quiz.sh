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

echo "Command quiz!"
echo "Type \"end\" to finish"

correct_cnt=0
problem_cnt=0

for cmd in $(shuf -e "${problems[@]}")
do
	if ! manpage="$(man 1 "${cmd}" 2>/dev/null)"; then
		continue
	fi

	description="$(\
		echo "${manpage}" |\
		col -b |\
		grep -m 1 -A 1 "NAME" |\
		tail -n 1 |\
		sed 'y/-—–−/----/' |\
		tr -s '-' |\
		cut -d '-' -f 2- |\
		sed 's/^ //'\
		)"

	if [[ -z "${description}" ]]; then
		continue
	fi

	echo ""
	echo "\"${description}\""
	read -p "Enter your answer: " input
	if [[ "${input}" = "${cmd}" ]];then
		echo "Correct!"
		(( correct_cnt++ ))
	elif [[ "${input}" != "end" ]]; then
		echo "Incorrect. The answer is ${cmd}"
	else
		break
	fi
	(( problem_cnt++ ))
done


if [[ "${problem_cnt}" -ne 0 ]]; then
	echo ""
	echo "==RESULT=="
	if [[ "${correct_cnt}" -eq "${problem_cnt}" ]]; then
		echo "${correct_cnt}/${problem_cnt} PERFECT!"
	else
		echo "${correct_cnt}/${problem_cnt}"
	fi

	accuracy="$(( correct_cnt * 100 / problem_cnt ))"
	echo "Accuracy: ${accuracy}%"
fi
