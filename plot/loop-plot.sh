#!/bin/bash
export LANG=C LC_ALL=C

for data in fort.* ; do
    [ -r "$data" ] || continue
    png="${data%"*"}.png"

    gnuplot <<END-OF-PLOT
        set term png enhanced size 1024,512
        set output "$png"
        set xrange [0:20]
        set yrange [0:20]

        #set title "$data"
        
        plot "$data" u 1:2:(\$3*0.5):(\$4*0.5) w vectors head filled lw 1 lc rgb "red" title "","$data" u 1:2 w p pt 7 lc rgb "blue" title ""
                     
END-OF-PLOT
done
