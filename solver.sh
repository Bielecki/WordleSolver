#!/bin/bash

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
echo -e "Enter result. \nUse '-' if letter does not appear in word. \nUse '/' if letter appears, but is in wrong spot \nUse '+' if letter appears and is in correct spot"
read -r result

shuffle_word() {
	#remove repeating letters, only if there are too many words
	if [ "$full_search_amount" -gt 100 ]; then
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

declare -a legal_characters
declare -a illegal_characters

available_characters() {
	for ((i=0; $i<5; i++)); do
		if [[ "${result_array[$i]}" == "/" && ! "${legal_characters[*]}" =~ "${word_array[$i]}" ]]; then
			legal_characters+=( "${word_array[$i]}" )
		elif [[ "${result_array[$i]}" == "-" && ! "${illegal_characters[*]}" =~ "${word_array[$i]}" && ! "${legal_characters[*]}" =~ "${word_array[$i]}" ]]; then
			illegal_characters+=( "${word_array[$i]}" )
		fi
	done
}
available_characters

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
			if [ "${raw_results[$i]}" == "." ]; then
				regexes=( ["-"]="${raw_results[$i]}" ["/"]="[${raw_results[$i]}]" ["+"]="[${raw_results[$i]}]" )
			else
				regexes=( ["-"]="[${raw_results[$i]}]" ["/"]="[${raw_results[$i]}]" ["+"]="[${raw_results[$i]}]" )
			fi
			printf "${regexes[${result_array[$i]}]}"
		done
		printf ")")
	fi
}
create_prefix

create_search() {
	if [ "${#legal_characters[@]}" -eq 0 ]; then
		local legal_characters=( "a-z" )
	fi
	search="$(
	for ((i=0; $i<${#legal_characters[@]}; i++)); do
		printf %s '(?=.{0,4}[' ${legal_characters[$i]} '])'
	done
	)(?!.{0,4}[$(
	printf %s ${illegal_characters[@]} | tr -d ' ')])"
}
create_search

look_for_word() {
	full_search=$(grep -Pi "^${prefix}${search}.{5}" words.txt)
	full_search_amount=$(wc -l <<< "$full_search")
	printf "There are $full_search_amount words found: "
	if [ "$full_search_amount" -gt 20 ]; then
		printf "not giving list - too many\n"
	else
		printf "\n$full_search\n"
	fi
}
look_for_word
if [ "$full_search_amount" -eq 1 ]; then
	break
fi
shuffle_word

until [ "$full_search_amount" -eq 1 ]; do
	array_results
	available_characters
	create_raw_results
	create_prefix
	create_search
	look_for_word
	if [ "$full_search_amount" -eq 1 ]; then
		break
	fi
	shuffle_word
done
