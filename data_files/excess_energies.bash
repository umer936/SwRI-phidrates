#!/bin/bash

# Include common functions
source common.bash  # Assuming you have a common file for functions
source vars.bash    # Assuming you have a vars file for variables
source LUTInNew.bash # Assuming you have a LUTIn.txt file
source LUTOutNew.bash # Assuming you have a LUTOut.txt file

# Globals
use_semi_log="false"
solar_activity=0.0
temp=1000.0
which_tab=""
molecule="Al"

# Extract QUERY_STRING
input="$QUERY_STRING"
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val=$(echo -e "${val//%/\\x}")
    val=${val//;/}
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

    echo "Content-type: text/html" ; echo

    echo "<HTML><HEAD><TITLE>Binned Excess Energies of $molecule</TITLE></HEAD>"
    echo "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">"
    
    # convert_canonical_input_name --> ConvertCanonicalBranchName || CopyMolecule
    nice_name=$(convert_canonical_input_name "$molecule")
    if [[ -n "$nice_name" ]]; then
        echo "<H1>Binned Excess Energies of $nice_name</H1>"
    else
        echo "<H1>Binned Excess Energies of $molecule</H1>"
    fi

    echo ; echo "<P>"
    cd "$temp_dir"

    url_temp_dir="${temp_dir//$reg_exp_prefix/\/phidrates_images}"
    url_temp_dir="${url_temp_dir//tmp}"

    num_branches=$(generate_branches)
    bnum=1
    while ((bnum <= num_branches)); do
        if [[ "${branches[bnum]}" == "Lambda" ]]; then
            branches[bnum]="Total"
        fi

        gifname=$(generate_plot "$temp_dir" "branch_r.$bnum" "${branches[bnum + 1]}" "$use_semi_log")
        nice_name=$(convert_canonical_output_name "${branches[bnum + 1]}")
        
        if [[ -n "$nice_name" ]]; then
            echo "<H2>$nice_name</H2>"
        else
            echo "<H2>${branches[bnum + 1]}</H2>"
        fi

        echo "<IMG SRC=\"$gifname\" BORDER=4>"
        echo "<P><P>"
        rm "branch_r.$bnum"
        ((bnum++))
    done

    echo "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/EEOut\"><span>Click here to view or shift-click to download the data wavelength-integrated over each bin!</span></A>"
    echo "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>"
    echo "</BODY></HTML>"
}

generate_branches() {
    local num_branches
    local num_values
    local line
    local i
    local bnum
    local val
    local header

    # Create EEOut
    exec 3< "EEOut"


    # Get the number of branches
    read -r line <&3
    [[ "$line" =~ ^\s*(\d+) ]]
    num_branches="${BASH_REMATCH[1]}"

    read -r header <&3
    # populate array with elements from header, delimited by spaces
    IFS=' ' read -ra branches <<< "$header"

    num_values=0

    while read -r line <&3; do
        if [[ "$line" =~ Rate ]] || [[ "$line" =~ Av ]]; then
            continue
        fi

        #line=${line# }
        #line=${line% }
        #line=${line//+([[:space:]])/ }*/
        # line=$(echo "$line" | tr -s ' ' | sed 's/^ //;s/ $//')
        line=$(tr -s ' ' <<< "$line" | sed 's/^ //;s/ $//')

        # Delimit by spaces
        IFS=' ' read -ra values <<< "$line"
        i=0
        for val in "${values[@]}"; do
            items["$i,$num_values"]="$val"
            ((i++))
        done

        ((num_values++))
    done

    bnum=1
    while ((bnum <= num_branches)); do
        exec 4> "branch_r.$bnum"
        i=1
        last_x=${items[0,0]}
        last_y=${items[$bnum,0]}

        while ((i < num_values)); do
            new_y=$(bc -l <<< "scale=10; ($last_y / (${items[0,$i]} - $last_x))")
            echo "$last_x $new_y" >&4
            last_x=${items[0,$i]}
            last_y=${items[$bnum,$i]}
            ((i++))
        done

        exec 4>&-
        ((bnum++))
    done

    echo "$num_branches"
}

generate_plot() {
    local tempdir="$1"
    local filename="$2"
    local branch="$3"
    local use_semi_log="$4"
    local gifname
    local xlabel
    local ylabel
    local plotTitle
    local set_mytics

    # Retain TMP_FILE
    TMP_FILE="$(mktemp --tmpdir="${tempdir}" gnu_XXXXXX.info)"

    xlabel="Wavelength [A]"
    ylabel="Binned Excess Energies [eV A**-1 s**-1]"

    if [ "$which_tab" == "Sol" ]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch at SA = ${solar_activity}"
    elif [ "$which_tab" == "IS " ]; then
        plotTitle="Southwest Research Institute\\nBranch: $branch"
    else
        plotTitle="Southwest Research Institute\\nBranch: $branch at T = ${temp}K"
    fi

    set_mytics="true"

    echo "set terminal png size 800,600 font \"/usr/share/fonts/dejavu/DejaVuLGCSans.ttf\" 12" >> "$TMP_FILE"

    if [ "$use_semi_log" == "false" ]; then
        echo "set logscale x" >> "$TMP_FILE"
        echo "set logscale y 10" >> "$TMP_FILE"
        echo "set format y '%g'" >> "$TMP_FILE"
    else
        echo "set logscale y" >> "$TMP_FILE"
    fi

    cat << EOF >> "$TMP_FILE"
set style line 80 lt 0
set style line 81 lt 3  # dashed
set style line 81 lw 0.5  # grey
set mxtics 10
set style line 1 lt 1
set style line 2 lt 1
set style line 3 lt 1
set style line 4 lt 1
set style line 1 lt 1 lw 6 pt 7
set style line 2 lt 2 lw 6 pt 9
set style line 3 lt 3 lw 6 pt 5
set style line 4 lt 4 lw 6 pt 13
set origin 0, 0.01
set xlabel "$xlabel"
set ylabel "$ylabel"
set title "$title"
EOF

    if [ "$set_ytics" == "true" ]; then
        echo "set mytics 5" >> "$TMP_FILE"
    fi

    if [ "$which_tab" == "IS " ]; then
        echo "set xrange [100:100000]" >> "$TMP_FILE"
    fi

    echo "plot \"$filename\" title \"\" with steps" >> "$TMP_FILE"
    gifname=$(mktemp --tmpdir="${tempdir}" XXXXXX.png)
    gnuplot "$TMP_FILE" > "$gifname"

    if [ $? -eq -1 ]; then
        echo "failed to execute: $!"
    elif [ $? -eq 0 ]; then
        echo "Child exited successfully"
    else
        echo "child died with status $?"
    fi

    if [ -s "$gifname" ]; then
        chmod 0644 "$gifname"
        plotname="$gifname"
        plotname="${plotname//$reg_exp_prefix/..\/phidrates_images}"
    else
        plotname="img/baddata.gif"
    fi

    echo "$plotname"
}

# Make a temporary directory

temp_dir=$(make_temp_directory)
copy_molecule "$molecule" "$temp_dir"
copy_necessary_files "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
#run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"