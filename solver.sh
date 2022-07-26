#!/bin/bash

#set -x

bold=$(tput bold setaf 6) #bold text and set to cyan
normal=$(tput sgr0) #clear text attributes

if [ -z "$1" ]; then
	#shuffle first word, but not with repeating letters
	#double and repeating letters are permitted in wordle,
	#but we wont use them as a first word, to maximise letters tried
	word=$(shuf -n 1 <<< $(grep -Ev '^.*(.).*\1.*$' words.txt))
	echo "Try word: ${bold}${word}${normal}"
else
	word="$1"
fi

#read user input
echo -e "Enter result. \nUse '-' if letter does not appear in word. \nUse '/' if letter appears, but is in wrong spot. \nUse '+' if letter appears and is in correct spot."
read -r result

shuffle_word() {
	#remove repeating letters, only if there are too many words
	if [ "$full_search_amount" -gt 100 ]; then
		word=$(shuf -n 1 <<< $(grep -Ev '^.*(.).*\1.*$' <<< "$full_search"))
	else
		word=$(shuf -n 1 <<< "$full_search")
	fi
	echo "Try this one: ${bold}${word}${normal}, or enter 'other' to provide your own word"
	read -r result

	if [ "$result" == "other" ]; then
		echo "Please provide word then:"
		read -r word
		echo "Now please enter its result:"
		read -r result
	elif [ "$result" == "eliminate" ]; then
		eliminate_words
	fi
}

eliminate_words() {
	alphabet=( $(printf "%s " {a..z}) )
	unused_characters=$(echo "${certain_characters[@]} ${legal_characters[@]} ${illegal_characters[@]} ${alphabet[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')
	eliminated=$(grep -E "[$unused_characters]{5}" words.txt)
	#check if we can provide word without repeating letters
	if [[ $(grep -oEv '^.*(.).*\1.*$' <<< "$eliminated" | wc -l) -gt 0 ]]; then
		#if words with all unique letter are found, save only these
		eliminated=$(grep -oEv '^.*(.).*\1.*$' <<< "$eliminated")
	fi
	eliminated_amount=$(wc -l <<< "$eliminated")
	if [[ "$eliminated_amount" -gt 0 && -n "$eliminated" ]]; then
		word=$(shuf -n1 <<< "$eliminated")
	else
		unused_characters=$(echo "${legal_characters[@]} ${illegal_characters[@]} ${alphabet[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')
		eliminated=$(grep -E "[$unused_characters]{5}" words.txt)
		if [[ "$eliminated_amount" -gt 0 && -n "$eliminated" ]]; then
			echo "Warning! Found only words matching already-correct and unused characters"
			word=$(shuf -n1 <<< "$eliminated")
		else
			unused_characters=$(echo "${illegal_characters[@]} ${alphabet[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')
			eliminated=$(grep -E "[$unused_characters]{5}" words.txt)
			if [[ "$eliminated_amount" -gt 0 && -n "$eliminated" ]]; then
				echo "Warning! Found only words matching already-correct, wrong-spot and unused characters"
				word=$(shuf -n1 <<< "$eliminated")
			else
				echo "Cannot create word with characters left"
				shuffle_word
			fi
		fi
	fi

	printf "Found $(wc -l <<< $eliminated) words, that could help you eliminate characters: "
	if [ "$(wc -l <<< $eliminated)" -gt 20 ]; then
		printf "not giving list - too many\n"
	else
		printf "\n$eliminated\n"
	fi
	echo "Try this one: ${bold}${word}${normal}, or enter 'other' to provide your own word"
	read -r result

	if [ "$result" == "other" ]; then
		echo "Please provide word then:"
		read -r word
		echo "Now please enter its result:"
		read -r result
	fi
}

array_results() {
	word_array=( $(echo "$word" | grep -o .) )
	result_array=( $(echo "$result" | grep -o .) )
}
array_results

declare -a certain_characters
declare -a legal_characters
declare -a illegal_characters

available_characters() {
	for ((i=0; $i<5; i++)); do
		if [[ "${result_array[$i]}" == "+" && ! "${certain_characters[*]}" =~ "${word_array[$i]}" ]]; then
			certain_characters+=( "${word_array[$i]}" )
		elif [[ "${result_array[$i]}" == "/" && ! "${legal_characters[*]}" =~ "${word_array[$i]}" ]]; then
			legal_characters+=( "${word_array[$i]}" )
		elif [[ "${result_array[$i]}" == "-" && ! "${illegal_characters[*]}" =~ "${word_array[$i]}" && ! "${legal_characters[*]}" =~ "${word_array[$i]}" && ! "${certain_characters[*]}" =~ "${word_array[$i]}" ]]; then
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
	exit 0
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

set +x
