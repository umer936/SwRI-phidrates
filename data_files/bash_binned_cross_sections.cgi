#!/bin/bash

source /usr/local/var/www/SwRI-phidrates/data_files/common.bash
source /usr/local/var/www/SwRI-phidrates/data_files/vars.bash

# Globals
solar_activity=0.0
temp=1000.0          # default for Blackbody temperature in Kelvin
which_tab=""
use_semi_log="false"

# Convert variables to a value
# input="$QUERY_STRING"
input='which_tab=Sol?temp=1000.0?optical_depth=0.0?molecule=H2O?use_electron_volts=true?use_semi_log=false?solar_activity=0.0'
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val="$(echo -e "${val//%/\\x}" | sed 's/;//g')"
    declare "$key=$val"
done

if [[ "$which_tab" = "Int" ]]; then
    which_tab="IS "
fi

# If the option was not on the tab being processed, reset to the default value
# since it's being overridden by the previous parsing of QUERY_STRING.
if [[ "$solar_activity" = "undefined" ]]; then
    solar_activity=0.0
fi

print_results() {
    local molecule="$1"
    local temp_dir="$2"
    local use_semi_log="$3"
    local nice_name

    echo "<HTML><HEAD><TITLE>Binned Cross Sections of $molecule</TITLE></HEAD>"
    echo -e "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">"

    nice_name="$(get_input_name "$molecule")"
    if [[ -n "$nice_name" ]]; then
        echo "<H1>Binned Cross Sections of $nice_name</H1>"
    else
        echo "<H1>Binned Cross Sections of $molecule</H1>"
    fi

    echo -e "\n<P>"

    cd "$temp_dir"
    
    url_temp_dir="${temp_dir//$reg_exp_prefix/\/phidrates_images}"
    url_temp_dir="${url_temp_dir/tmp//}"

    local branches num_branches
    generate_branches

    for ((bnum=0 ; bnum < num_branches ; bnum++)); do
        if [[ "${branches[$bnum]}" = "Lambda" ]]; then
            branches[$bnum]="Total"
        fi
        gifname="$(generate_plot $temp_dir "${branches[$bnum+1]}" "$use_semi_log" "$bnum")"

        nice_name="$(get_output_name "${branches[$bnum+1]}")"
        if [[ -z "$nice_name" ]]; then
            echo "<H2>${branches[$bnum+1]}</H2>"
        else
            echo "<H2>$nice_name</H2>"
        fi

        echo -e "<IMG SRC = \"$gifname\" BORDER=4>"
        echo "<P><P>"
        rm "branch.$bnum"
    done

    echo -e "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/FotOut\"><span>Click here to view or shift-click to download the data file used to create this plot!</span></A>"
    echo -e "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}

generate_branches() {
    local line n input_file val0

    input_file="FotOut"
    
    n=0
    while read -r line; do
        if (( n == 0 )); then
            [[ "$line" =~ ^[[:space:]]*([0-9]+) ]]
            num_branches="${BASH_REMATCH[1]}"
        elif (( n == 1 )); then
            IFS=' ' read -ra branches <<< "$line"
        elif [[ ! "$line" =~ Rate ]]; then
            line="$(echo "$line" | awk '{$1=$1};1')"
            IFS=' ' read -ra values <<< "$line"

            val0="${values[0]}"

            for (( b=0 ; b < ${#values[@]} - 1 ; b++ )); do
                echo "$val0 ${values[$((b+1))]}" >> "branch.$b"
            done
        fi
        ((n++))
    done < "$input_file"

    echo "$num_branches"
}

generate_plot() {
    local tempdir="$1"
    local branch="$2"
    local use_semi_log="$3"
    local bnum="$4"
    local xlabel ylabel plotTitle set_mytics

    local gnuinfo="$tempdir/gnu_$bnum.info"
    
    # create plot parameters
    if ! touch "$gnuinfo"; then
        echo "Couldn't open branch.$bnum\n"
        exit 1
    fi

    # populate plot parameters
    xlabel='Wavelength [A]'
    ylabel='Cross Section [cm**2/A]'
    plotTitle="Southwest Research Institute\\nBranch: $branch"
    set_mytics="true"
    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics" "$gnuinfo"

    echo "plot \"branch.$bnum\" title \"\" with steps" >> "$gnuinfo"
    
    # create plot
    local gifname="$tempdir/gnu_$bnum.png"
    if ! touch "$gifname"; then
        echo "Couldn't open branch.$bnum\n"
        exit 1
    fi

    # populate plot
    /usr/local/bin/gnuplot "$gnuinfo" > "$gifname"
    #? consider numeric expansion
    if [[ $? -eq 127 ]]; then
        echo "failed to execute: $!"
    elif [[ $? -eq 0 ]]; then
        echo "child exited with value $?"
    fi

    if [[ -s "$gifname" ]]; then
        chmod 0644 "$gifname"
        plotname="/phidrates_images/$(basename $tempdir)/$(basename $gifname)"
    else
        plotname="img/baddata.gif"
    fi

    echo "$plotname"
}

echo -e "Content-type: text/html\n"

cd /usr/local/var/www/SwRI-phidrates
temp_dir="$(make_temp_directory)"

copy_necessary_files "$temp_dir"
copy_molecule "$molecule" "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"

exit 0