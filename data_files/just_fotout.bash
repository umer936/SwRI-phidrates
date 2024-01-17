#!/bin/bash

source common.bash  # Assuming you have a common file for functions
source vars.bash    # Assuming you have a vars file for variables
source LUTInNew.txt # Assuming you have a LUTIn.txt file
source LUTOutNew.txt # Assuming you have a LUTOut.txt file

# Globals
solar_activity=0.0
temp=1000.0          # Default for Blackbody temperature in Kelvin
which_tab=""

molecule=Al
# Convert variables to a value
input="${QUERY_STRING}"
IFS='?' read -ra items <<< "${input}"
for item in "${items[@]}"; do
    IFS='=' read -ra key_val <<< "${item}"
    key=${key_val[0]}
    val=${key_val[1]}
    val=$(echo -e "${val//%/\\x}")
    val=$(echo -e "${val//;/}")
    declare "${key}=${val}"
done

# If option was not on the tab being processed, reset to default value
# since being overridden by previous parsing of QUERY_STRING.
if [ "${solar_activity}" == "undefined" ]; then
    solar_activity=0.0
fi

# Make a temporary directory
# Copy the "molecule".dat to our temporary directory
# Run photo on the temporary directory
temp_dir=$(make_temp_directory)
copy_molecule "${molecule}" "${temp_dir}"
copy_necessary_files "${temp_dir}"
write_input_file "${solar_activity}" "${temp}" "${which_tab}" "${temp_dir}"
run_photo_rat "${molecule}" "${temp_dir}"
print_results "${molecule}" "${temp_dir}"

print_results() {
    local molecule=$1
    local temp_dir=$2

    echo "Content-type: text/html" ; echo

    echo "<HTML><HEAD><TITLE>${molecule}</TITLE></HEAD>"
    echo "<BODY>"
    nice_name=$(convert_canonical_input_name "${molecule}")
    if [ -n "${nice_name}" ]; then
        echo "<H1>${nice_name}</H1>"
    else
        echo "<H1>${molecule}</H1>"
    fi

    echo "<P>"
    cd "${temp_dir}"
    awk 'NR==3{gsub(/Lambda/,"",$0); print;}' EEOut
    echo "<TABLE><TR><TH>Branch</TH>"
    echo "<TH>Rate Coeffs.<BR>[s<sup>-1</sup>]</TH><TH>Excess Energies<BR>[eV]</TH></TR><TR>"

    awk '/Rate Coeff/{flag=1;next}/Av\. Excess E =/{flag=0}flag' EEOut |
    awk '{gsub(/ Rate Coeffs. = /,"",$0); gsub(/^\s+/,"",$0); print $0;}' | {
        read -r line
        read -r line2
        read -ra sections <<< "${line}"
        read -ra rates_val <<< "${line}"
        read -ra energy_val <<< "${line2}"
        i=0
        for section in "${sections[@]}"; do
            nice_name=$(convert_canonical_output_name "${section}")
            if [ -n "${nice_name}" ]; then
                echo "<TD>${nice_name}</TD>"
            else
                echo "<TD>${section}</TD>"
            fi
            echo "<TD>${rates_val[i]}</TD>"
            echo "<TD>${energy_val[i]}</TD></TR>"
            ((i++))
        done
    }

    echo "</TABLE>"
    echo "<HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}