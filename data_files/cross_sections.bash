#!/bin/bash

# Include common functions and variables
source common.bash
source vars.bash
source LUTInNew.bash
source LUTOutNew.bash

# Parse QUERY_STRING -> filename; display file
use_semi_log="false"
solar_activity="0.0"
temp="1000.0"
which_tab=""
ref_list=()

# Convert variables to a value
input="${QUERY_STRING}"
input='which_tab=IS ?temp=1000.0?optical_depth=0.0?molecule=Al?use_electron_volts=true?use_semi_log=false?solar_activity=0.0'
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -ra keyValue <<< "$item"
    key="${keyValue[0]}"
    val="${keyValue[1]}"
    val="$(echo -e "${val//%/\\x}" | sed 's/;//g')"
    declare "$key=$val"
done

# If the solar_activity is "undefined," reset it to 0.0
if [ "$solar_activity" == "undefined" ]; then
    solar_activity="0.0"
fi


print_results() {
    local molecule="$1"
    local temp_dir="$2"
    local use_semi_log="$3"
    local nice_name

    echo "Content-type: text/html"
    echo

    nice_name="$(convert_canonical_input_name "$molecule")"
    if [ ! -z "$nice_name" ]; then
        echo "<H1>Cross Sections of $nice_name</H1>"
    else
        echo "<H1>Cross Sections of $molecule</H1>"
    fi

    echo
    echo "<P>"
    cd "$temp_dir"
    # might need fixing
    url_temp_dir="${temp_dir/$reg_exp_prefix/\/phidrates_images}"
    # might need fixing
    url_temp_dir="${url_temp_dir/tmp}"

    num_branches="$(generate_branches)"
    bnum=0

    if [ ${#branches[@]} -gt 0 ]; then
        while [ "$bnum" -le "$num_branches" ]; do
            if [ "${branches[$bnum+2]}" == "Sigma" ]; then
                branches[$bnum+2]="Total"
            fi
            gifname="$(generate_plot "$temp_dir" "branch.$bnum" "${branches[$bnum+2]}" "$use_semi_log")"
            nice_name="$(convert_canonical_output_name "${branches[$bnum+2]}")"
            if [ ! -z "$nice_name" ]; then
                echo "<H2>${branches[$bnum+2]}</H2>"
            else
                echo "<H2>$nice_name</H2>"
            fi
            echo "<IMG SRC=\"$gifname\" BORDER=4>"
            echo "<P><P>"
            rm "branch.$bnum"
            bnum=$((bnum+1))
        done
    else
        echo "<IMG SRC=\"img/baddata.gif\" BORDER=4>"
    fi

    echo "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/BrnOut\"><span>Click here to view or shift-click to download the data file used to create this plot!</span></A>"
    echo "<HR align=\"center\" width=\"50%\" size=\"1\">"
    echo "</BODY></HTML>"
}

generate_branches() {
    local num_branches num_values line i bnum val

    input_file="BrnOut"

    ref_count=0
    num_branches=0
    num_values=0

    while read -r line; do
        if [[ "$line" =~ ^0.*References ]]; then
            if [ "$ref_count" -ne 0 ]; then
                ref_list[$((ref_count-1))]="${refs[@]}"
            fi
            ref_count=$((ref_count+1))
            refs=()
            read_refs=1
        elif [[ "$line" =~ ^0.*Branching.*[[:space:]](\d+)[[:space:]]branches ]]; then
            read_refs=0
            num_branches="${BASH_REMATCH[1]}"
            header=$(head -n 1 "$input_file")
            IFS=' ' read -ra branches <<< "$header"
        else
            if [ "$read_refs" -eq 1 ]; then
                refs+=("$line")
            else
                # might need fixing
                line="${line#"${line%%[![:space:]]*}"}"
                line="${line%"${line##*[![:space:]]}"}"
                line=$(echo "$line" | sed 's/\s+/ /g')
                read -ra values <<< "$line"
                if [ "${#values[@]}" -gt "$num_branches" ]; then
                    i=0
                    for val in "${values[@]}"; do
                        if [ "$i" -eq 0 ] && [ "$use_electron_volts" == "true" ]; then
                            items[0,num_values]=$(bc -l <<< "12398.42 / $val")
                        else
                            items[$i,num_values]="$val"
                        fi
                        i=$((i+1))
                    done
                    num_values=$((num_values+1))
                fi
            fi
        fi
    done < "$input_file"

    bnum=0
    while [ "$bnum" -le "$num_branches" ]; do
        output_file="branch.$bnum"
        i=0
        while [ "$i" -lt "$num_values" ]; do
            echo "${items[0,$i]} ${items[$((bnum + 1)),$i]}" > "$output_file"
            i=$((i+1))
        done
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

    gnuinfo=$(tempfile -p 'gnu_' -d "$tempdir" -s '.info')
    echo -e "plot \"$filename\" title \"\" with lines" > "$gnuinfo"

    if [ "$use_electron_volts" == "true" ]; then
        xlabel="Energy [eV]"
    else
        xlabel="Wavelength [A]"
    fi

    ylabel="Cross Section [cm**2]"
    plotTitle="Southwest Research Institute\\nBranch: $branch"
    set_mytics="true"

    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics"

    gifname=$(tempfile -d "$tempdir" -s '.png')
    /usr/bin/gnuplot "$gnuinfo" > "$gifname"

    if [ $? -eq -1 ]; then
        echo "failed to execute: $!"
    elif [ $? -ge 128 ]; then
        echo "child died with signal $(( $? & 127 )), $(( $? & 128 )) coredump"
    fi

    if [ -s "$gifname" ]; then
        chmod 0644 "$gifname"
        plotname="$gifname"
        # might need fixing
        plotname="${plotname/$reg_exp_prefix/\/phidrates_images}"
    else
        plotname="img/baddata.gif"
    fi
    echo "$plotname"
}

# Make a temporary directory
temp_dir="$(make_temp_directory)"
copy_molecule "$molecule" "$temp_dir"
copy_necessary_files "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"