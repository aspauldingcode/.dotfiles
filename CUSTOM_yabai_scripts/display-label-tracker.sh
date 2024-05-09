#!/bin/bash

# Define an array with the numerical words
numerical_words=("one" "two" "three" "four" "five" "six" "seven" "eight")

# Function to get the numerical integer associated with a word
get_numerical_integer() {
    local word="$1"
    for i in "${!numerical_words[@]}"; do
        if [ "${numerical_words[$i]}" = "$word" ]; then
            echo "$((i + 1))"
            return
        fi
    done
    echo "0" # Return 0 if the word is not found
}

# Main script logic
labels=$(yabai -m query --displays | jq -r '.[].label')
for label in $labels; do
    numerical_integer=$(get_numerical_integer "$label")
    echo "Display '$label' is associated with the numerical integer '$numerical_integer'"
done

