#!/bin/bash

# Define the array of filenames
filenames=("HRec1A.txt" "HRec2A.txt")

# Iterate over each filename
for file in "${filenames[@]}"; do
    echo "Working with $file"
    input_file="$file"
    output_file="hrecs/$(awk '{print $5}' "$file").dat"

    # Read and process the input file
    while IFS= read -r line; do
        # Check for end-of-file
        if [[ -z $line ]]; then
            continue
        fi

        # Write the line to the output file
        echo "$line" >> "$output_file"

        # Check for the ending condition
        if [[ $line == '***' ]]; then
            break
        fi
    done < "$input_file"
done