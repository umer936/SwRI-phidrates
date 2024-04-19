#!/bin/bash

# Include common functions
source /usr/local/var/www/SwRI-phidrates/data_files/common.bash
source /usr/local/var/www/SwRI-phidrates/data_files/vars.bash

# Globals
use_semi_log="false"
solar_activity=0.0
temp=1000.0
which_tab=""

# Extract QUERY_STRING
input="$QUERY_STRING"
input='which_tab=Sol?temp=1000.0?optical_depth=0.0?molecule=H2O?use_electron_volts=true?use_semi_log=false?solar_activity=0.0'
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val="$(echo -e "${val//%/\\x}" | sed 's/;//g')"
    declare "$key=$val"
done

if [[ "$which_tab" == "Int" ]]; then
    which_tab="IS "
fi

if [[ "$solar_activity" == "undefined" ]]; then
    solar_activity=0.0
fi

print_results() {
    local molecule="$1"
    local temp_dir="$2"
    local use_semi_log="$3"
    local nice_name

    echo "<HTML><HEAD><TITLE>Binned Excess Energies of $molecule</TITLE></HEAD>"
    echo "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">"
    
    nice_name="$(get_input_name "$molecule")"
    if [[ -n "$nice_name" ]]; then
        echo "<H1>Binned Excess Energies of $nice_name</H1>"
    else
        echo "<H1>Binned Excess Energies of $molecule</H1>"
    fi

    echo -e "\n<P>"

    cd "$temp_dir"

    url_temp_dir="${temp_dir//$reg_exp_prefix/\/phidrates_images}"
    url_temp_dir="${url_temp_dir//tmp}"

    local branches num_branches
    generate_branches
    
    for (( bnum=0 ; bnum < num_branches ; bnum++ )); do
        if [[ "${branches[$bnum]}" == "Lambda" ]]; then
            branches[$bnum]="Total"
        fi

        data_file="$temp_dir/branch_r.$bnum"
        if ! touch "$data_file"; then
            echo "Couldn't open branch_r.$bnum." >&2
            exit 1
        fi

        gifname="$(generate_plot "$temp_dir" "$bnum" "${branches[bnum + 1]}" "$use_semi_log")"
        nice_name="$(get_output_name "${branches[bnum + 1]}")"

        if [[ -n "$nice_name" ]]; then
            echo "<H2>$nice_name</H2>"
        else
            echo "<H2>${branches[bnum + 1]}</H2>"
        fi

        #? single quotes?
        echo "<IMG SRC=\"$gifname\" BORDER=4>"
        echo "<P><P>" #? what does this do?
        rm "$data_file"
    done

    echo "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/EEOut\"><span>Click here to view or shift-click to download the data wavelength-integrated over each bin!</span></A>"
    echo "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}

generate_branches() {
    local line n input_file val0

    input_file="$temp_dir/EEOut"
    if [[ ! -e "$input_file" ]]; then
        echo "Couldn't open EEOut\n" >&2
        exit 1
    fi 

    n=0
    while read -r line; do
        if [[ $n -eq 0 ]]; then
            [[ "$line" =~ ^[[:space:]]*([0-9]+) ]]
            num_branches="${BASH_REMATCH[1]}"
        elif [[ $n -eq 1 ]]; then
            IFS=' ' read -ra branches <<< $line
        elif [[ ! "$line" =~ Rate || ! "$line" =~ Av ]]; then
            line="$(echo "${line[$i]}" | awk '{$1=$1};1')"
            IFS=' ' read -ra values <<< $line

            val0="${values[0]}"

            for (( b=0 ; b < ${#values[@]} - 1 ; b++ )); do
                echo "$val0 ${values[$((b+1))]}" >> "branch_r.$b"
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
    
    #? can I consolidate this?
    local gnuinfo="$tempdir/gnu_$bnum.info"
    if ! touch "$gnuinfo"; then
        echo "Couldn't open $gnuinfo" >&2
        exit 1
    fi

    local xlabel ylabel plotTitle set_mytics
    xlabel='Wavelength [A]'
    ylabel='Binned Excess Energies [eV A**-1 s**-1]'

    if [[ "$which_tab" == "Sol" ]]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch at SA = ${solar_activity}"
    elif [[ "$which_tab" == "IS " ]]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch"
    else
        plotTitle="Southwest Research Institute\\nBranch: $branch at T = ${temp}K"
    fi

    set_mytics="true"
    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics" $gnuinfo
    echo "plot \"branch.$bnum\" title \"\" with steps" >> $gnuinfo

    if [[ "$which_tab" = "IS " ]]; then
        echo "set xrange [100:100000]" >> $gnuinfo
    fi

    local gifname="$tempdir/gnu_$bnum.png"
    if ! touch "$gifname"; then
        echo "Could not open $gifname"
        exit 1
    fi

    /usr/local/bin/gnuplot "$gnuinfo" > "$gifname"

    if [[ $? -eq -1 ]]; then
        echo "failed to execute: $!"
    elif [[ $? -eq 0 ]]; then
        echo "Child exited successfully"
    else
        echo "child died with status $?"
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
#run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"