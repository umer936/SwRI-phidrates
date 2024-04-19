#!/bin/bash

source /usr/local/var/www/SwRI-phidrates/data_files/vars.bash

# Creates a temporary directory in /var/tmp (/phidrates_images is this directory's alias)
make_temp_directory() {
    local temp_dir

    # Make a temporary directory
    if [[ ! -e "$prefix" ]]; then
        mkdir -p "$prefix"
    fi

    temp_dir=$(mktemp -d "$prefix/fileXXXXXX" || exit 1) 
    chmod 0755 "$temp_dir"

    echo "$temp_dir"
}

# Copies molecule data into the supplied temp directory
copy_molecule() {
    local molecule="$1"
    local temp_dir="$2"
    cp "$amop_cgi_bin_dir/photo/hrecs/$molecule.dat" "$temp_dir/Hrec"
}

# Copies standard data files into the supplied temp directory
copy_necessary_files() {
    local temp_dir="$1"

    cp "$amop_cgi_bin_dir/photo/NEW_CODE/BBGrid.dat" "$temp_dir/BBGrid.dat"
    cp "$amop_cgi_bin_dir/photo/NEW_CODE/PhFlux.dat" "$temp_dir/PhFlux.dat"
}

# Writes the input file
write_input_file() {
    local solar_activity="$1"
    local temp="$2"
    local which_tab="$3"
    local temp_dir="$4"
    
    local DummySA=0.0
    local newfile="$temp_dir/Input"
    
    # Create the file or exit with an error if unable to create
    if ! echo "$which_tab" > "$newfile"; then
        echo "Cannot create the file $newfile."
        exit 1
    fi

    # Blackbody Radiation Field
    if [[ "$which_tab" == "BB " ]]; then
        printf "%4.2f\n" "$DummySA" >> "$newfile"
        printf "%-8.0f\n" "$temp" >> "$newfile"
    # InterStellar Radiation Field - has not been completely implemented using the Input file.
    # For now, just put a placeholder for the 3rd line.
    elif [[ "$which_tab" == "Int" || "$which_tab" == "IS " ]]; then
        printf "%4.2f\n" "$DummySA" >> "$newfile"
        echo >> "$newfile"
    # Solar Radiation Field - the third line is ignored
    elif [[ "$which_tab" == "Sol" ]]; then
        printf "%4.2f\n" "$solar_activity" >> "$newfile"
        echo >> "$newfile"
    # Invalid value - nothing put into the file.
    else
        echo >> "$newfile"
    fi
}

# Runs the program to calculate various information (previously photo.exe)
run_photo_rat() {
    local molecule="$1"
    local temp_dir="$2"

    # "$amop_cgi_bin_dir/photo/NEW_CODE/photo.exe"
    cd "$temp_dir"
    /usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/photo.exe >&2

    if [[ $? -ne 0 ]]; then
        local code=$(( $? >> 8 ))
        echo -e "Content-type: text/html\n"
        echo "Error in subname, command = photo; code = $?/$code" 
        return $?
    fi
    return 0
}

run_photo_rat_jl() {
    local molecule="$1"
    local temp_dir="$2"

    # "$amop_cgi_bin_dir/photo/NEW_CODE/photo.exe"
    cd "$temp_dir"
    julia --project=/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/Phidrates.jl "/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/Phidrates.jl" >&2
    # /home/user/.juliaup/bin --project[={/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE|@.}] "/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/Phidrates.jl" >&2

    if [[ $? -ne 0 ]]; then
        local code=$(( $? >> 8 ))
        echo -e "Content-type: text/html\n"
        echo "Error in subname, command = photo; code = $?/$code" 
        return $?
    fi
    return 0
}
# Writes output for gnuinfo files
function set_common_output() {
    local use_semi_log="$1"
    local xlabel="$2"
    local ylabel="$3"
    local title="$4"
    local set_ytics="$5"
    local filename="$6"

    echo "set terminal png size 800,600 font \"/usr/share/fonts/dejavu/DejaVuLGCSans.ttf\" 12" >> "$filename"
    if [[ "$use_semi_log" == "false" ]]; then
        echo "set logscale x" >> "$filename"
        echo "set logscale y 10" >> "$filename"
        echo "set format y '%g'" >> "$filename"
    else
        echo "set logscale y" >> "$filename"
    fi


    echo "# Line style for axes
set style line 80 lt 0

# Line style for grid
set style line 81 lt 3  # dashed
set style line 81 lw 0.5  # grey

# set grid back linestyle 81
# set xtics nomirror
# set ytics nomirror

#set log x
set mxtics 10    # Makes logscale look good.

# Line styles: try to pick pleasing colors, rather
# than strictly primary colors or hard-to-see colors
# like gnuplot's default yellow.  Make the lines thick
# so they're easy to see in small plots in papers.
set style line 1 lt 1
set style line 2 lt 1
set style line 3 lt 1
set style line 4 lt 1
set style line 1 lt 1 lw 6 pt 7
set style line 2 lt 2 lw 6 pt 9
set style line 3 lt 3 lw 6 pt 5
set style line 4 lt 4 lw 6 pt 13
set origin 0, 0.01" >> "$filename"

    echo "set xlabel \"$xlabel\"" >> "$filename"
    echo "set ylabel \"$ylabel\"" >> "$filename"
    echo "set title \"$title\"" >> "$filename"

    # Rest of the output settings go here
    # Add to the TMP_FILE as needed
    # echo "set xlabel \"$xlabel\"" >> "$TMP_FILE"
    # echo "set ylabel \"$ylabel\"" >> "$TMP_FILE"
    # echo "set title \"$title\"" >> "$TMP_FILE"
    # ...

    if [[ "$set_ytics" == "true" ]]; then
        echo "set mytics 5" >> "$filename"
    fi
}

function set_common_output_2() {
    local use_semi_log="$1"
    local xlabel="$2"
    local ylabel="$3"
    local title="$4"
    local set_ytics="$5"
    
    echo "set terminal png size 800,600 font \"/usr/share/fonts/dejavu/DejaVuLGCSans.ttf\" 12"
    if [[ "$use_semi_log" == "false" ]]; then
        echo "set logscale x"
        echo "set logscale y 10"
        echo "set format y '%g'"
    else
        echo "set logscale y"
    fi

    cat << EOF
# Line style for axes
set style line 80 lt 0

# Line style for grid
set style line 81 lt 3  # dashed
set style line 81 lw 0.5  # grey

# set grid back linestyle 81
# set xtics nomirror
# set ytics nomirror

#set log x
set mxtics 10    # Makes logscale look good.

# Line styles: try to pick pleasing colors, rather
# than strictly primary colors or hard-to-see colors
# like gnuplot's default yellow.  Make the lines thick
# so they're easy to see in small plots in papers.
set style line 1 lt 1
set style line 2 lt 1
set style line 3 lt 1
set style line 4 lt 1
set style line 1 lt 1 lw 6 pt 7
set style line 2 lt 2 lw 6 pt 9
set style line 3 lt 3 lw 6 pt 5
set style line 4 lt 4 lw 6 pt 13
set origin 0, 0.01
EOF

    echo "set xlabel \"$xlabel\""
    echo "set ylabel \"$ylabel\""
    echo "set title \"$title\""

    if [ "$set_ytics" == "true" ]; then
        echo "set mytics 5"
    fi
}

function get_input_name() {
    local branch=$1
    echo "$(grep -m 1 "$branch=" /usr/local/var/www/SwRI-phidrates/data_files/LUTInOnly.txt)" | cut -f 2 -d "="
}

function get_output_name() {
    local branch=$1
    echo "$(grep -m 1 "$branch=" /usr/local/var/www/SwRI-phidrates/data_files/LUTOutOnly.txt)" | cut -f 2 -d "="
}

throw2web() {
    while getopts ":n" opt; do
        echo $opt
        case $opt in
            n) 
                echo -e "Content-type: text/html\n" ;;
            \?)
                echo "Unknown option: $opt" ; exit 1 ;;
        esac
        shift 1
    done
    
    local message="$1"
    local code=${2:-'1'}
    
    echo "$message"
    exit $code
}

throw() {
    local message="$1"
    local code=${2:-'1'}
    
    echo "$message" >&2
    exit $code
}