#!/bin/bash

# Include common functions and variables
source /usr/local/var/www/SwRI-phidrates/data_files/common.bash
source /usr/local/var/www/SwRI-phidrates/data_files/vars.bash

# Globals
solar_activity=0.0
temp=1000.0          # default for Blackbody temperature in Kelvin
which_tab=""
use_semi_log="false"

# Convert variables to a value
input="${QUERY_STRING}"
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

    echo "<HTML><HEAD><TITLE>Binned Rate Coefficients of $molecule</TITLE></HEAD>"
    echo "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">"

    nice_name="$(convert_canonical_input_name "$molecule")"
    if [[ -n "$nice_name" ]]; then
        echo "<H1>Binned Rate Coefficients of $nice_name</H1>"
    else
        echo "<H1>Binned Rate Coefficients of $molecule</H1>"
    fi

    echo -e "\n<P>"
    cd "$temp_dir"

    url_temp_dir="${temp_dir//$reg_exp_prefix/\/phidrates_images}"
    url_temp_dir="${url_temp_dir//tmp/}"

    num_branches="$(generate_branches)"
    bnum=1
    while [[ "$bnum" -le "$num_branches" ]]; do
        if [[ "${branches[$bnum]}" = "Lambda" ]]; then
            branches[$bnum]="Total"
        fi
        gifname="$(generate_plot "$temp_dir" "branch_r.$bnum" "${branches[$bnum+1]}" "$use_semi_log")"

        nice_name="$(convert_canonical_output_name "${branches[$bnum+1]}")"
        if [[ -n "$nice_name" ]]; then
            echo "<H2>$nice_name</H2>"
        else
            echo "<H2>${branches[$bnum+1]}</H2>"
        fi

        echo "<IMG SRC = \"$gifname\" BORDER=4>"
        echo -e "<P><P>"
        rm "branch_r.$bnum"
        ((bnum++))
    done

    echo "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/RatOut\"><span>Click here to view or shift-click to download the data wavelength-integrated over each bin!</span></A>"
    echo "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}

generate_branches() {
    local num_branches num_values line i bnum val

    if ! exec 3< "RatOut"; then
        echo "Could not open RatOut\n";
        exit 1
    fi
    
    read -r line <&3
    [[ "$line" =~ ^[[:space:]]*([0-9]+) ]]
    num_branches="${BASH_REMATCH[1]}"
    read -r header <&3
    branches=("$header")
    ref_count=0
    num_values=0

    while read -r line; do
        if [[ "$line" =~ Rate ]]; then
            continue
        else
            line="$(echo "$line" | awk '{$1=$1};1')"
            values=("$line")
            val0="${values[0]}"

            for (( b=0 ; b < ${#values[@]} - 1 ; b++ )); do
                echo "$val0 ${values[$((b+1))]}" >> "branch.$b"
            done
            num_values=$((num_values+1))
        fi
    done <3
    exec 3>&-

    echo "$num_branches"
}

generate_plot() {
    local tempdir="$1"
    local branch="$2"
    local use_semi_log="$3"
    local bnum="$4"
    local gifname xlabel ylabel plotTitle set_mytics

    gnuinfo="$tempdir/gnu_$bnum.info"
    exec 3> "$gnuinfo"

    xlabel="Wavelength [A]"
    ylabel="Rate Coefficient [A**-1 s**-1]"
    if [[ "$which_tab" = "Sol" ]]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch at SA = $solar_activity"
    elif [[ "$which_tab" = "IS " ]]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch"
    else
        plotTitle="Southwest Research Institute\\nBranch: $branch at T = ${temp}K"
    fi
    set_mytics="true"
    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics" "$gnuinfo"
    

    if [[ "$which_tab" = "IS " ]]; then
        echo "set xrange [100:100000]" >&3
    fi

    echo "plot \"$filename\" title \"\" with steps" >&3
    exec 3>&-

    gifname="$tempdir/gnu_$bnum.png"
    if ! touch "$gifname"; then
        echo "Cannot write gnu_$bnum.png"
        exit 1
    fi

    /usr/bin/gnuplot "$gnuinfo" > "$gifname"
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
copy_molecule "$molecule" "$temp_dir"
copy_necessary_files "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
time run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"
