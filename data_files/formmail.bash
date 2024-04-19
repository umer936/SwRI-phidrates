#!/bin/bash

# Define variables
mailprog="/usr/sbin/sendmail"
date=$(date)
recipient="joey@swri.edu"
subject="Questionnaire answers!"

# Print the initial output heading
echo "Location: ${QUERY_STRING}"
echo -e "\n"

# Get the input
read -r -d '' buffer -n "$CONTENT_LENGTH" 

# Split the name-value pairs
IFS='&' read -ra pairs <<< "$buffer"

for pair in "${pairs[@]}"; do
    IFS='=' read -r name value <<< "$pair"

    # Un-Webify plus signs and %-encoding
    value="${value//+/ }"
    value=$(printf '%b' "${value//%/\\x}")
    name="${name//+/ }"
    name=$(printf '%b' "${name//%/\\x}")

    # Uncomment for debugging purposes
    # echo "Setting $name to $value<P>"

    FORM["$name"]="$value"
done

# Print return HTML
echo -e "<html><head><title>Thank You</title></head>\n"
echo -e "<body><h1>Thank You For Filling Out This Form</h1>\n"
echo -e "Thank you for taking the time to fill out our feedback form. ${QUERY_STRING}\n"

# Open the mail
MAIL="${mailprog} ${recipient}"
(echo "From: ${FORM['username']} (${FORM['realname']})";
echo "Reply-To: ${FORM['username']} (${FORM['realname']})";
echo "To: ${recipient}";
echo "Subject: ${subject}";
echo -e "\n";
echo -e "Below is the result of your feedback form. It was submitted by ${FORM['realname']} ${FORM['username']} on ${date}";
echo -e "--------------------------------------------------------------";

for pair in "${pairs[@]}"; do
    IFS='=' read -r name value <<< "$pair"

    # Un-Webify plus signs and %-encoding
    value="${value//+/ }"
    value=$(printf '%b' "${value//%/\\x}")
    name="${name//+/ }"
    name=$(printf '%b' "${name//%/\\x}")

    # Print the mail for each name-value pair
    echo -e "${name}: ${value}";
    echo -e "____________________________________________\n\n";
done) | $MAIL

echo -e "</body></html>"
