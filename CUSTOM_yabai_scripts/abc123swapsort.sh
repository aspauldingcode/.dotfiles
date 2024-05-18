#!/bin/bash

# Function to generate random numbers
generate_random_numbers() {
    local num_nodes=$1
    for ((i=1; i<=num_nodes; i++)); do
        echo -n "$((RANDOM % 10)) "  # Generating random numbers between 0 to 9
    done
}

# Function to get numbers for a specific letter
get_numbers_for_letter() {
    local letter=$1
    echo "Enter numbers for letter $letter (space-delimited):"
    read numbers
    echo "$numbers"
}

# Prompt user to enter the number of unique letters
num_letters=""
while [[ -z $num_letters || $num_letters -lt 1 ]]; do
    echo "How many unique letters?"
    read num_letters
done

# Get unique letters based on the number provided
unique_letters=($(printf '%s\n' {A..Z} | head -n $num_letters))

# Generate random numbers for each letter
random_numbers=$(generate_random_numbers "${#unique_letters[@]}")

# Store output to a file
output_file="swapsortresult"

echo "Nodes sorted alphabetically with random subnode numbers:" > "$output_file"
for ((i=0; i<${#unique_letters[@]}; i++)); do
    letter="${unique_letters[i]}"
    numbers=$(get_numbers_for_letter "$letter")
    echo "$letter ${random_numbers[i]} $numbers" >> "$output_file"
done

echo "Output saved to $output_file"
