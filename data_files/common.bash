#!/bin/bash

# Include variables from vars.bash if needed
source vars.bash

copy_molecule() {
    local molecule=$1
    local temp_dir=$2
    cp "$amop_cgi_bin_dir/photo/hrecs/$molecule.dat" "$temp_dir/Hrec"
}

make_temp_directory() {
    local temp_dir

    # Make a temporary directory
    if [ ! -e "$prefix" ]; then
        mkdir -p "$prefix"
    fi

    # removed -p arg... will it work?
    temp_dir=$(mktemp -d "$prefix" "fileXXXXXX")
    chmod 0755 "$temp_dir"
    echo "$temp_dir"
}


run_photo_rat() {
    local molecule=$1
    local temp_dir=$2

    cd "$temp_dir"
    "$amop_cgi_bin_dir/photo/NEW_CODE/photo.exe"
    # photo.exe will not execute

    if [ $? -ne 0 ]; then
        local code=$(( $? >> 8 ))
        echo "Content-type: text/html" ; echo
        echo "Error in subname, command = photo; code = $/?$code" # why is there a slash?
        return $?
    fi
    return 0
}

write_input_file() {
    local solar_activity="$1"
    local temp="$2"
    local which_tab="$3"
    local temp_dir="$4"
    local DummySA

    DummySA=0.0

    NEWFILE="$temp_dir/Input"

    # Create the file or exit with an error if unable to create
    if ! { echo "$which_tab" > "$NEWFILE"; }; then
        echo "Cannot create the file $NEWFILE."
        exit 1
    fi

    # Blackbody Radiation Field
    if [[ "$which_tab" == "BB " ]]; then
        printf "%4.2f\n" "$DummySA" >> "$NEWFILE"
        printf "%-8.0f\n" "$temp" >> "$NEWFILE"
    # InterStellar Radiation Field - has not been completely implemented using the Input file.
    # For now, just put a placeholder for the 3rd line.
    elif [[ "$which_tab" == "Int" || "$which_tab" == "IS " ]]; then
        printf "%4.2f\n" "$DummySA" >> "$NEWFILE"
        echo >> "$NEWFILE"
    # Solar Radiation Field - the third line is ignored
    elif [[ "$which_tab" == "Sol" ]]; then
        printf "%4.2f\n" "$solar_activity" >> "$NEWFILE"
        echo >> "$NEWFILE"
    # Invalid value - nothing put into the file.
    else
        echo >> "$NEWFILE"
    fi
}

copy_necessary_files() {
    local temp_dir=$1

    cp "$amop_cgi_bin_dir/photo/NEW_CODE/BBGrid.dat" "$temp_dir/BBGrid.dat"
    cp "$amop_cgi_bin_dir/photo/NEW_CODE/PhFlux.dat" "$temp_dir/PhFlux.dat"
}

set_common_output() {
    local use_semi_log=$1
    local xlabel=$2
    local ylabel=$3
    local title=$4
    local set_ytics=$5

    # Define your TMP_FILE or use stdout as appropriate
    # TMP_FILE="/path/to/output/file"

    # $TMP_FILE is not present
    echo "set terminal png size 800,600 font \"/usr/share/fonts/dejavu/DejaVuLGCSans.ttf\" 12" >> "$TMP_FILE"
    if [ "$use_semi_log" == "false" ]; then
        echo "set logscale x" >> "$TMP_FILE"
        echo "set logscale y 10" >> "$TMP_FILE"
        echo "set format y '%g'" >> "$TMP_FILE"
    else
        echo "set logscale y" >> "$TMP_FILE"
    fi

    # Rest of the output settings go here
    # Add to the TMP_FILE as needed
    # echo "set xlabel \"$xlabel\"" >> "$TMP_FILE"
    # echo "set ylabel \"$ylabel\"" >> "$TMP_FILE"
    # echo "set title \"$title\"" >> "$TMP_FILE"
    # ...

    if [ "$set_ytics" == "true" ]; then
        echo "set mytics 5" >> "$TMP_FILE"
    fi
}

convert_canonical_input_name() {
    local branch=$1
}

convert_canonical_output_name() {
    local branch=$1
}
# Usage examples:

# temp_dir=$(make_temp_directory)
# copy_molecule "Al" "/temp_dir" # CopyMolecule "molecule_name" "/temp_dir"
# run_photo_rat "molecule_name" "/temp_dir"
# write_input_file 1.0 300.0 "Sol" "/temp_dir"
# copy_necessary_files "/temp_dir"
# set_common_output "false" "X Label" "Y Label" "Title" "true"


# temp_dir=$(make_temp_directory)
# write_input_file 1.0 300.0 "Sol" "$temp_dir"