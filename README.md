# WordleSolver

WordleSolver is a bash script for solving Wordle-like games.

## Installation

Just clone this repo. `words.txt` file is important as well, as it provides dictionary of English 5-letter words.

You might need to make script executable first, using `chmod +x solver.sh`.  
Run script using `./solver.sh`.  

## Dependencies

- Bash version 4 or newer - must support arrays 
- `grep` or `GNU grep` that supports Perl regexes

## Usage

Just run the script and it provides the word to try:

```bash
$ ./solver.sh 
Try word: scald
Enter result. 
Use '-' if letter does not appear in word. 
Use '/' if letter appears, but is in wrong spot. 
Use '+' if letter appears and is in correct spot.

```

or run script with your own word as argument, like this:

```bash
$ ./solver.sh scald
Enter result. 
Use '-' if letter does not appear in word. 
Use '/' if letter appears, but is in wrong spot. 
Use '+' if letter appears and is in correct spot.

```

Then type word in your Wordle game and enter result in script, according to examples. Continue script with Enter key.

```bash
-/---
There are 223 words found: not giving list - too many
Try this one: choke, or enter 'other' to provide your own word

```
You can provide your own word by typing `other` in results. In that case script will ask for word in next step and its result in another one.

When script filters out words and discovers that there are at most 20 left, it will output a full list of matching words:

 ```bash
//---
There are 16 words found: 
birch
bitch
bunch
butch
fichu
finch
hitch
hunch
hutch
itchy
munch
pinch
pitch
punch
winch
witch
Try this one: pitch, or enter 'other' to provide your own word

```

Continue providing results until you solve your Wordle game.

## Important notes

- If script match more than 100 words it will not provide words with repeating letters, like `spoon` (double `o` letter) to exclude maximal amount of letters absent in winning word. First word will also not include repeating letters.
- Script operates in `hard mode` of Wordle, where "any revealed hints must be used in subsequent guesses". You can mitigate this behavior by providing your own word (sometimes you have lot of similar, potentially correct words, and might need to exclude more letters in single guess, as you have only 6 guesses overall) or enter `eliminate`, so script provides you with words that probably are not correct answers, but contains as much unused yet letters as possible.
- Other languages should theoretically work with this script too, if you replace `words.txt` with another language 5-letter word dictionary. This wasn't tested, and might have troubles with diacritic that doesn't appear in English alphabet, like `Ł`, `Ü`, `Ø`, and similar. If you have tested it, please tell me if it works or not.
- It is possible that `words.txt` dictionary contains words that Wordle treats as invalid. If that happen to you please open issue and I will delete that word from dictionary.

## License
GNU General Public License v3.0
