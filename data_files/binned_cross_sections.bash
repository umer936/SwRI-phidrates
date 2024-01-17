#!/bin/bash

# Include common functions and variables
source common.bash
source vars.bash
source LUTInNew.txt
source LUTOutNew.txt

# Parse QUERY_STRING -> filename; display file

# Globals
solar_activity=0.0
temp=1000.0          # default for Blackbody temperature in Kelvin
which_tab=""
use_semi_log="false"

# Convert variables to a value
# input="$QUERY_STRING"
input='cross_sections.cgi?which_tab=IS ?temp=1000.0?optical_depth=0.0?molecule=Al?use_electron_volts=true?use_semi_log=false?solar_activity=0.0'
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val=$(echo -e "${val//%/\\x}")
    val="${val//;}"
    declare "$key=$val"
done

if [ "$which_tab" = "Int" ]; then
    which_tab="IS "
fi

# If the option was not on the tab being processed, reset to the default value
# since it's being overridden by the previous parsing of QUERY_STRING.
if [ "$solar_activity" = "undefined" ]; then
    solar_activity=0.0
fi

print_results() {
    local molecule="$1"
    local temp_dir="$2"
    local use_semi_log="$3"
    local nice_name

    echo -e "Content-type: text/html\n"
    echo "<HTML><HEAD><TITLE>Binned Cross Sections of $molecule</TITLE></HEAD>"
    echo "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">"

    nice_name=$(convert_canonical_input_name "$molecule")
    if [ -n "$nice_name" ]; then
        echo "<H1>Binned Cross Sections of $nice_name</H1>"
    else
        echo "<H1>Binned Cross Sections of $molecule</H1>"
    fi

    echo -e "\n<P>"
    cd "$temp_dir"

    url_temp_dir="$temp_dir"
    url_temp_dir="${url_temp_dir//$reg_exp_prefix/\/phidrates_images}"
    url_temp_dir="${url_temp_dir/tmp//}"

    num_branches=$(generate_branches)
    bnum=1
    while [ "$bnum" -le "$num_branches" ]; do
        if [ "${branches[$bnum]}" = "Lambda" ]; then
            branches[$bnum]="Total"
        fi
        gifname=$(generate_plot "$temp_dir" "branch.$bnum" "${branches[$bnum+1]}" "$use_semi_log")

        nice_name=$(convert_canonical_output_name "${branches[$bnum+1]}")
        if [ -n "$nice_name" ]; then
            echo "<H2>$nice_name</H2>"
        else
            echo "<H2>${branches[$bnum+1]}</H2>"
        fi

        echo "<IMG SRC = \"$gifname\" BORDER=4>"
        echo -e "<P><P>"
        rm "branch.$bnum"
        bnum=$((bnum+1))
    done

    echo "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/FotOut\"><span>Click here to view or shift-click to download the data file used to create this plot!</span></A>"
    echo -e "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}

generate_branches() {
    local num_branches num_values line i bnum val

    exec 3< "FotOut"
    read -r line <&3
    [[ $line =~ ^\s*(\d+) ]]
    num_branches=${BASH_REMATCH[1]}
    read -r header <&3
    branches=($header)
    ref_count=0
    num_values=0

    while read -r line <&3; do
        if [[ $line =~ Rate ]]; then
            continue
        else
            line=${line%% }
            line=${line%% }
            line=${line// / }
            # line=$(echo $line | xargs)
            values=($line)
            i=0
            for val in "${values[@]}"; do
                items[$i,$num_values]="$val"
                i=$((i+1))
            done
            num_values=$((num_values+1))
        fi
    done

    bnum=1
    while [ "$bnum" -le "$num_branches" ]; do
        exec 4> "branch.$bnum"
        i=1
        last_x=${items[0,0]}
        last_y=${items[$bnum,0]}
        while [ "$i" -lt "$num_values" ]; do
            new_y="$last_y"
            echo "$last_x $new_y" >&4
            last_x=${items[0,$i]}
            last_y=${items[$bnum,$i]}
            i=$((i+1))
        done
        exec 4>&-
        bnum=$((bnum+1))
    done
    echo "$num_branches"
}

generate_plot() {
    local tempdir="$1"
    local filename="$2"
    local branch="$3"
    local use_semi_log="$4"
    local gifname xlabel ylabel plotTitle set_mytics

    gnuinfo=$(tempfile -d "$tempdir" -p 'gnu_' -s '.info')
    exec 3> "$gnuinfo"

    xlabel="Wavelength [A]"
    ylabel="Cross Section [cm**2/A]"
    plotTitle="Southwest Research Institute\\nBranch: $branch"
    set_mytics="true"
    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics"

    echo "plot \"$filename\" title \"\" with steps" >&3
    exec 3>&-

    gifname=$(tempfile -d "$tempdir" -s '.png')
    /usr/bin/gnuplot "$gnuinfo" > "$gifname"
    if [ $? -eq 127 ]; then
        echo "failed to execute: $!"
    elif [ $? -eq 0 ]; then
        echo "child exited with value $?"
    fi

    if [ -s "$gifname" ]; then
        chmod 0644 "$gifname"
        plotname="$gifname"
        plotname="${plotname//$reg_exp_prefix/../phidrates_images}"
    else
        plotname="img/baddata.gif"
    fi

    echo "$plotname"
}

# Make a temporary directory
temp_dir=$(make_temp_directory)
copy_necessary_files "$temp_dir"
copy_molecule "$molecule" "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"