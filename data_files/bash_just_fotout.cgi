#!/bin/bash

source /usr/local/var/www/SwRI-phidrates/data_files/common.bash
source /usr/local/var/www/SwRI-phidrates/data_files/vars.bash

# Globals
solar_activity=0.0
temp=1000.0          # Default for Blackbody temperature in Kelvin
which_tab=""

# input="${QUERY_STRING}"
input='which_tab=Sol?temp=1000.0?optical_depth=0.0?molecule=H2O?use_electron_volts=true?use_semi_log=false?solar_activity=0.0'
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val="$(echo -e "${val//%/\\x}" | sed 's/;//g')"
    declare "$key=$val"
done

if [[ "$solar_activity" == "undefined" ]]; then
    solar_activity=0.0
fi

print_results() {
    local molecule="$1"
    local temp_dir="$2"

    echo "<HTML><HEAD><TITLE>$molecule</TITLE></HEAD>"
    echo "<BODY>"

    nice_name="$(get_input_name "$molecule")"
    if [[ -n "$nice_name" ]]; then
        echo "<H1>$nice_name</H1>"
    else
        echo "<H1>$molecule</H1>"
    fi

    echo "<P>"
    cd "$temp_dir"

    input_file="EEOut"
    
    local branches rate_vals energy_vals
    while read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([0-9]+)[[:space:]]*.+ ]]; then
            num_branches="${BASH_REMATCH[0]}"
        elif [[ "$line" =~ Lambda ]]; then
            IFS=' ' read -ra branches <<< "$line"
        elif [[ "$line" =~ Excess ]]; then
            IFS=' ' read -ra energy_vals <<< "$(echo "$line" | cut -d "=" -f 2)"
        elif [[ "$line" =~ Rate ]]; then
            IFS=' ' read -ra rate_vals <<< "$(echo "$line" | cut -d "=" -f 2)"
        fi
    done < "$input_file"


    echo "<TABLE><TR><TH>Branch</TH>"
    echo "<TH>Rate Coeffs.<BR>[s<sup>-1</sup>]</TH><TH>Excess Energies<BR>[eV]</TH></TR><TR>"
    
    for (( i=0 ; i < ${#branches[@]} - 1 ; i++ )); do
        echo "<TR>"
        nice_name="$(get_output_name "${branches[i+1]}")"
        if [[ -n "$nice_name" ]]; then
            echo "<TD>$nice_name</TD>"
        else
            echo "<TD>${branches[i+1]}</TD>"
        fi
        echo "<TD>${rate_vals[i]}</TD><TD>${energy_vals[i]}</TD></TR>"
    done
    
    echo "</TABLE>"
    echo "<HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}

echo -e "Content-type: text/html\n"

cd /usr/local/var/www/SwRI-phidrates
temp_dir="$(make_temp_directory)"

copy_molecule "$molecule" "$temp_dir"
copy_necessary_files "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir"