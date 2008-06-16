plot "bin_spectrum.dat" with steps
set logscale xy
set xrange [1:100000]
set title "Southwest Research Institute\n\nSolar Activity"
set xlabel "Wavelength  (A)"
set ylabel "Solar Flux  (Photons cm**-2 s**-1 A**-1)"
set nokey
set mxtics 5
replot
set terminal gif
set output "spectrum.gif"
replot
