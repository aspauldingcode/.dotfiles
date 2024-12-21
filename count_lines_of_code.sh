#!/bin/bash

# Get current directory if no argument provided
root_dir=${1:-.}

# Count initialization
total_lines=0

# Check if current directory is a git repo
if [ -d "$root_dir/.git" ]; then
    # Get all tracked files, excluding binary files
    lines_in_repo=$(git ls-files | grep -vE '\.(webp|ttf|png|jpg|jpeg)$' | sed 's/.*/"&"/' | xargs wc -l | grep -o "[0-9]* total" | awk '{SUM += $1} END {print SUM}')
    
    # Get current branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Print results
    printf "%-80s -> %s lines\n" "$(basename "$root_dir") ($current_branch)" "$lines_in_repo"
    total_lines=$lines_in_repo

    # Update README.md with new line count
    formatted_lines=$(printf "%'d" $lines_in_repo)
    DATE=$(date)
    # Use perl instead of sed for better cross-platform compatibility
    perl -i -pe "s/There are [0-9,]* lines of code in this repo.*/There are $formatted_lines lines of code in this repo. Last updated: $DATE/" README.md
    echo "Updated line count in README.md to $formatted_lines"
else
    echo "Error: Not a git repository"
    exit 1
fi

# Show total lines
echo "Total: $(printf "%'d" $total_lines) lines"
