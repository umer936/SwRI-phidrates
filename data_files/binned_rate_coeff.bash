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
input="$QUERY_STRING"
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

# Make a temporary directory
temp_dir=$(make_temp_directory)
copy_molecule "$molecule" "$temp_dir"
copy_necessary_files "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"

print_results() {
    local molecule="$1"
    local temp_dir="$2"
    local use_semi_log="$3"
    local nice_name

    echo -e "Content-type: text/html\n"
    echo "<HTML><HEAD><TITLE>Binned Rate Coefficients of $molecule</TITLE></HEAD>"
    echo "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">"

    nice_name=$(convert_canonical_input_name "$molecule")
    if [ -n "$nice_name" ]; then
        echo "<H1>Binned Rate Coefficients of $nice_name</H1>"
    else
        echo "<H1>Binned Rate Coefficients of $molecule</H1>"
    fi

    echo -e "\n<P>"
    cd "$temp_dir"

    url_temp_dir="$temp_dir"
    url_temp_dir="${url_temp_dir//$reg_exp_prefix/\/phidrates_images}"
    url_temp_dir="${url_temp_dir//tmp/}"

    num_branches=$(generate_branches)
    bnum=1
    while [ "$bnum" -le "$num_branches" ]; do
        if [ "${branches[$bnum]}" = "Lambda" ]; then
            branches[$bnum]="Total"
        fi
        gifname=$(generate_plot "$temp_dir" "branch_r.$bnum" "${branches[$bnum+1]}" "$use_semi_log")

        nice_name=$(convert_canonical_output_name "${branches[$bnum+1]}")
        if [ -n "$nice_name" ]; then
            echo "<H2>$nice_name</H2>"
        else
            echo "<H2>${branches[$bnum+1]}</H2>"
        fi

        echo "<IMG SRC = \"$gifname\" BORDER=4>"
        echo -e "<P><P>"
        rm "branch_r.$bnum"
        bnum=$((bnum+1))
    done

    echo "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/RatOut\"><span>Click here to view or shift-click to download the data wavelength-integrated over each bin!</span></A>"
    echo -e "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}

generate_branches() {
    local num_branches num_values line i bnum val

    exec 3< "RatOut"
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
            # use xargs
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
        exec 4> "branch_r.$bnum"
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
    ylabel="Rate Coefficient [A**-1 s**-1]"
    if [ "$which_tab" = "Sol" ]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch at SA = $solar_activity"
    elif [ "$which_tab" = "IS " ]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch"
    else
        plotTitle="Southwest Research Institute\\nBranch: $branch at T = ${temp}K"
    fi
    set_mytics="true"
    # set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics"
    
    # SET COMMON OUTPUT
    echo "set terminal png size 800,600 font \"/usr/share/fonts/dejavu/DejaVuLGCSans.ttf\" 12" >&3
    if [ "$use_semi_log" == "false" ]; then
        echo "set logscale x" >&3
        echo "set logscale y 10" >&3
        echo "set format y '%g'" >&3
    else
        echo "set logscale y" >&3
    fi

    # Rest of the output settings go here
    # Add to the TMP_FILE as needed
    # echo "set xlabel \"$xlabel\"" >> "$TMP_FILE"
    # echo "set ylabel \"$ylabel\"" >> "$TMP_FILE"
    # echo "set title \"$title\"" >> "$TMP_FILE"
    # ...

    if [ "$set_ytics" == "true" ]; then
        echo "set mytics 5" >&3
    fi
    # END SET COMMON OUTPUT

    if [ "$which_tab" = "IS " ]; then
        echo "set xrange [100:100000]" >&3
    fi

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
        # might need to be fixed
        plotname="$gifname"
        # might need to be fixed
        plotname="${plotname//$reg_exp_prefix/../phidrates_images}"
    else
        plotname="img/baddata.gif"
    fi

    echo "$plotname"
}

