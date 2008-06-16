{
    if (NR == 1) {
       last_x = $1
       last_y = $2
    } else {
       print last_x,last_y/($1 - last_x)
       last_x = $1
       last_y = $2
    }
}
