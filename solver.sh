#!/bin/bash

# grep -Pi '(?=[^m][l][^a][^l][m])(?=.{0,4}m)(?=.{0,4}a)(?!.{0,4}n)(?=.{0,4}l)(?!.{0,4}y)(?!.{0,4}c)(?!.{0,4}i).{5}' words.txt | sort

if [ "$1" == "-v" ]; then
	debug=true
	shift
	set -x
fi

if [ -z "$1" ]; then
	#shuffle first word, but not with repeating letters
	#double and repeating letters are permitted in wordle,
	#but we wont use them as a first word, to maximise letters tried
	word=$(shuf -n 1 <<< $(grep -Ev '^.*(.).*\1.*$' words.txt))
	echo "Try word: $word"
else
	word="$1"
fi

#read user input
echo -e "Enter result. Use '-' if letter does not appear in word. \nUse '/' if letter appears, but is in wrong spot \nUse '+' if letter appears and is in correct spot"
read -r result

shuffle_word() {
	#shuffle words
	#remove repeating letters, only if there are too many words
	if [ "$full_search_amount" -gt 200 ]; then
		word=$(shuf -n 1 <<< $(grep -Ev '^.*(.).*\1.*$' <<< "$full_search"))
	else
		word=$(shuf -n 1 <<< "$full_search")
	fi
	echo "Try this one: $word"
	read -r result
}

array_results() {
	word_array=( $(echo "$word" | grep -o .) )
	result_array=( $(echo "$result" | grep -o .) )
}
array_results

declare -A raw_results
create_raw_results() {
	declare -A regexes
	if [ -z "$raw_results" ]; then
		for ((i=0; $i<5; i++)); do
			regexes=( ["-"]="." ["/"]="^${word_array[$i]}" ["+"]="${word_array[$i]}" )
			raw_results[$i]="${regexes[${result_array[$i]}]}"
		done
	else
		for ((i=0; $i<5; i++)); do
			if [[ "${raw_results[$i]}" == "[a-z]{1}" ]]; then continue
			elif [ "${result_array[$i]}" == "+" ]; then
				#replace no matter what
				raw_results[$i]="${word_array[$i]}"
			elif [ "${raw_results[$i]::1}" == "^" -a "${result_array[$i]}" == "-" ]; then continue
			elif [ "${raw_results[$i]::1}" == "^" -a "${result_array[$i]}" == "/" ]; then
				#add letter
				raw_results[$i]="${raw_results[$i]}${word_array[$i]}"
			elif [ "${raw_results[$i]}" == "." -a "${result_array[$i]}" == "-" ]; then continue
			elif [ "${raw_results[$i]}" == "." -a "${result_array[$i]}" == "/" ]; then
				#replace
				raw_results[$i]="^${word_array[$i]}"
			fi
	#		regexes=( ["-"]="." ["/"]="^${word_array[$i]}" ["+"]="${word_array[$i]}" )
	#		printf "${regexes[${result_array[$i]}]}"
		done
	fi
}
create_raw_results

create_prefix() {
	declare -A regexes
	if [ -z "$prefix" ]; then
		prefix=$(printf "(?="
		for ((i=0; $i<5; i++)); do
			regexes=( ["-"]="." ["/"]="[^${word_array[$i]}]" ["+"]="[${word_array[$i]}]" )
			printf "${regexes[${result_array[$i]}]}"
		done
		printf ")")
	else
		prefix=$(printf "(?="
		for ((i=0; $i<5; i++)); do
			regexes=( ["-"]="${raw_results[$i]}" ["/"]="[${raw_results[$i]}]" ["+"]="[${raw_results[$i]}]" )
			printf "${regexes[${result_array[$i]}]}"
		done
		printf ")")
	fi
}
create_prefix

create_search() {
	declare -A regexes
	regexes=( ["-"]="?!.{0,4}" ["/"]="?=.{0,4}" ["+"]="" )
	search="${prefix}$(
	for ((i=0; $i<5; i++)); do
		if [ "${result_array[$i]}" == "+" ]; then continue; fi
		printf "%s" "(" "${regexes[${result_array[$i]}]}" "${word_array[$i]}" ")"
	done)"
}
create_search
echo ""

look_for_word() {
if $debug ; then set +x ; fi
	full_search=$(grep -Pi "^${search}.{5}" words.txt)
if $debug ; then set -x ; fi
	full_search_amount=$(wc -l <<< "$full_search")
	echo "There are $full_search_amount words found"
	if [ "$full_search_amount" -gt 20 ]; then
		echo "Too many words found, not giving list"
	else
		echo "$full_search"
	fi
}
look_for_word

until [ "$full_search_amount" -eq 1 ]; do
	array_results
	create_raw_results
	create_prefix
	create_search
	look_for_word
	shuffle_word
done

if $debug ; then
	set +x
fi
#	combined+=(  )
