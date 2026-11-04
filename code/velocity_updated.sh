#!/bin/bash
export LANG=C LC_ALL=C

(
# Adjusted resolution to 1024,1024 to match your square 50x50 box without stretching
echo "set term gif animate delay 10 size 1024,1024"
echo "set output 'simulation_movie.gif'"
echo "set size ratio -1"
echo "set xrange [0:50]"
echo "set yrange [0:50]"

# Set up the color palette (Blue = slow, Green = medium, Red = fast)
echo "set palette defined (0 'blue', 0.5 'green', 1 'red')"
echo "set cblabel 'Fluctuation Velocity Magnitude'"
echo "set cbrange [0:0.2]"
echo "unset key"

# Use ls -v to ensure files are sorted numerically
for data in $(ls -v fort.*) ; do
    [ -r "$data" ] || continue
    
    echo "set title 'Frame: $data'"
    
    # Vectors changed to gray so they don't clash with colors. Dots colored by column 7.
    echo "plot '$data' u 1:2:(\$3*0.5):(\$4*0.5) w vectors head filled lw 1 lc rgb 'gray50', \
               '$data' u 1:2:7 w p pt 7 ps 0.5 palette"
done
) | gnuplot
