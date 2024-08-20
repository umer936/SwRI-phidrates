#!/bin/bash

source /usr/local/var/www/SwRI-phidrates/data_files/common.bash
source /usr/local/var/www/SwRI-phidrates/data_files/vars.bash

use_semi_log="false"
solar_activity="0.0"
temp="1000.0"
which_tab=""
ref_list=()

input="${QUERY_STRING}"
# input="which_tab=Sol?temp=1000.0?optical_depth=0?molecule=SO2?use_electron_volts=false?use_semi_log=false?solar_activity=0.1"
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val="$(echo -e "${val//%/\\x}" | sed 's/;//g')"
    declare "$key=$val"
done

if [[ "$solar_activity" == "undefined" ]]; then
    solar_activity="0.0"
fi

num_branches=0

print_results() {
    local molecule="$1"
    local temp_dir="$2"
    local use_semi_log="$3"
    local nice_name

    nice_name="$(get_input_name "$molecule")"
    if [[ ! -z "$nice_name" ]]; then
        echo "<H1>Cross Sections of $nice_name</H1>"
    else
        echo "<H1>Cross Sections of $molecule</H1>"
    fi

    echo -e "\n<P>"

    cd "$temp_dir"

    url_temp_dir="${temp_dir/$reg_exp_prefix/\/phidrates_images}"
    url_temp_dir="${url_temp_dir/tmp}"

    local branches num_branches
    generate_branches

    if [[ "${#branches[@]}" -gt 0 ]]; then
        for (( bnum=0 ; bnum <= num_branches ; bnum++ )); do
            if [[ "${branches[$bnum]}" = "Sigma" ]]; then
                branches[$bnum]="Total"
            fi

            data_file="$temp_dir/branch.$bnum"
            if ! touch "$data_file"; then
                echo "Couldn't open \"branch.$bnum\"."
                exit 1
            fi

            gifname="$(generate_plot "$temp_dir" "${branches[$bnum+1]}" "$use_semi_log" "$bnum")"

            nice_name="$(get_output_name "${branches[$bnum+1]}")"
            if [[ -z "$nice_name" ]]; then
                echo "<H2>${branches[$bnum+1]}</H2>"
            else
                echo "<H2>$nice_name</H2>"
            fi

            echo "<IMG SRC=\"$gifname\" BORDER=4>"
            echo "<P><P>"
            rm "$data_file"
        done
    else
        echo "<IMG SRC=\"img/baddata.gif\" BORDER=4>"
    fi

    echo "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/BrnOut\"><span>Click here to view or shift-click to download the data file used to create this plot!</span></A>"
    echo "<HR align=\"center\" width=\"50%\" size=\"1\">"
    echo "</BODY></HTML>"
}

function generate_branches() {
    local num_values line val0 is_header

    input_file="$temp_dir/BrnOut"
    if [[ ! -e "$input_file" ]]; then
        echo -e "Could not open BrnOut\n" >&2
        exit 1
    fi
    ref_count=0
    num_branches=0

    while read -r line; do
        if [[ $line =~ ^0.*References ]]; then
            if [[ "$ref_count" -ne 0 ]]; then
                ref_list[$((ref_count-1))]="${refs[@]}"
            fi
            ((ref_count++))
            refs=()
            read_refs=1
        elif [[ $line =~ ^0.*Branching.*[[:space:]]([0-9]+)[[:space:]]branches ]]; then
            read_refs=0
            num_branches="${BASH_REMATCH[1]}"
            is_header=1
        elif [[ $is_header -eq 1 ]]; then
            is_header=0
            IFS=' ' read -ra branches <<< "$line"
        elif [[ "$read_refs" -eq 1 ]]; then
            refs+=("$line")
        else
            # remove leading, trailing, and duplicate whitespaces
            line="$(echo "$line" | awk '{$1=$1};1')"
            IFS=' ' read -ra values <<< "$line"

            if [[ "${#values[@]}" -gt "$num_branches" ]]; then
                val0="${values[0]}"
                if [[ "$use_electron_volts" == "true" ]]; then
                    val0=$(bc -l <<< "12398.42 / $val0")
                fi

                for (( b=0 ; b < ${#values[@]} - 1; b++ )); do
                    echo "$val0 ${values[$((b+1))]}" >> "branch.$b"
                done
            fi
        fi
    done < "$input_file"

    echo "$num_branches"
}

function generate_plot() {
    local tempdir="$1"
    local branch="$2"
    local use_semi_log="$3"
    local bnum="$4"
    
    # Open gnuinfo file
    local gnuinfo
    gnuinfo="$temp_dir/gnu_$bnum.info"
    if ! touch "$gnuinfo"; then
        echo -e "Couldn't open $gnuinfo\n" >&2
        exit 1
    fi
    
    # Configure gnuinfo file
    local gifname xlabel ylabel plotTitle set_mytics

    if [[ "$use_electron_volts" == "true" ]]; then
        xlabel='Energy [eV]'
    else
        xlabel='Wavelength [A]'
    fi

    ylabel='Cross Section [cm**2]'
    plotTitle="Southwest Research Institute\\nBranch: $branch"
    set_mytics="true"

    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics" "$gnuinfo"
    echo -e "plot \"branch.$bnum\" title \"\" with lines" >> "$gnuinfo"

    # Create plot
    gifname="$temp_dir/gnu_$bnum.png"
    if ! touch "$gifname"; then
        echo -e "Couldn't open $gifname\n" >&2
        exit 1
    fi

    /usr/local/bin/gnuplot "$gnuinfo" > "$gifname"

    if [[ $? -eq -1 ]]; then
        echo "failed to execute: $!"
    elif [[ $? -ge 128 ]]; then
        echo "child died with signal $(( $? & 127 )), $(( $? & 128 )) coredump"
    fi

    if [[ -s "$gifname" ]]; then
        chmod 0644 "$gifname"
        plotname="/phidrates_images/${tempdir##*/}/${gifname##*/}"
    else
        plotname="img/baddata.gif"
    fi

    echo "$plotname"
}

echo -e "Content-type: text/html\n"

cd "/usr/local/var/www/SwRI-phidrates"
temp_dir="$(make_temp_directory)"
echo "$temp_dir"

copy_molecule "$molecule" "$temp_dir"
copy_necessary_files "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"
echo "$temp_dir"

exit 0