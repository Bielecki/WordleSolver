#!/bin/bash

# grep -Pi '(?=[^m][l][^a][^l][m])(?=.{0,4}m)(?=.{0,4}a)(?!.{0,4}n)(?=.{0,4}l)(?!.{0,4}y)(?!.{0,4}c)(?!.{0,4}i).{5}' words.txt | sort

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

array_results() {
	word_array=( $(echo "$word" | grep -o .) )
	result_array=( $(echo "$result" | grep -o .) )
}
array_results

create_prefix() {
	declare -A regexes
	prefix=$(printf "(?="
	for ((i=0; $i<5; i++)); do
		regexes=( ["-"]="." ["/"]="[^${word_array[$i]}]" ["+"]="[${word_array[$i]}]" )
		printf "${regexes[${result_array[$i]}]}"
	done
	printf ")")
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
	full_search=$(grep -Pi "^${search}.{5}" words.txt)
	full_search_amount=$(wc -l <<< "$full_search")
	echo "There are $full_search_amount words found"
	if [ "$full_search_amount" -gt 20 ]; then
		echo "Too many words found, not giving list"
	else
		echo "$full_search"
	fi
}
look_for_word
###############################################
#exit 1
###############################################

#once again removing repeating letters, only if there are too many words
if [ "$full_search_amount" -gt 200 ]; then
	word=$(shuf -n 1 <<< $(grep -Ev '^.*(.).*\1.*$' <<< "$full_search"))
else
	word=$(shuf -n 1 <<< "$full_search")
fi
echo "Try this one: $word"
read -r result

array_results

#word_array=( $(echo "$word" | grep -o .) )
#result_array=( $(echo "$result" | grep -o .) )

search="${search}$(
for ((i=0; $i<5; i++)); do
	printf "%s" "(" "${regexes[${result_array[$i]}]}" "${word_array[$i]}" ")"
done)"
echo ""

full_search=$(grep -Pi "^${search}.{5}" words.txt)
echo "There are $(wc -l <<< $full_search) words found"

word=$(shuf -n 1 <<< "$full_search")
echo "Try this one: $word"

#	combined+=(  )
