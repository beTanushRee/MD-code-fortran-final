#!/bin/bash
export LANG=C LC_ALL=C

(
# Set the terminal to animated gif, delay 10 = 0.1 seconds per frame
echo "set term gif animate delay 10 size 1024,512"
echo "set output 'simulation_movie.gif'"
echo "set xrange [0:20]"
echo "set yrange [0:20]"

# Use ls -v to ensure fort.1001 comes before fort.1002, not fort.1100
for data in $(ls -v fort.*) ; do
    [ -r "$data" ] || continue
    
    echo "set title 'Frame: $data'"
    echo "plot '$data' u 1:2:(\$3*0.5):(\$4*0.5) w vectors head filled lw 1 lc rgb 'red' title '', \
               '$data' u 1:2 w p pt 7 lc rgb 'blue' title ''"
done
) | gnuplot
