#!/bin/bash

################################################################
#  Parse QUERY_STRING -> filename; display file
################################################################

# Convert QUERY_STRING to a filename
input=$QUERY_STRING
IFS='&' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val=$(echo -e "${val//%/\\x}")
    val=${val//\;/}
    eval "$key=\"$val\""
done

# Now you can access the variables as needed, e.g., "$filename"

# Display the file or perform other actions here