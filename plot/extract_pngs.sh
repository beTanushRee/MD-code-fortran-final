#!/bin/bash
export LANG=C LC_ALL=C

# Identify the first and last fort.* files numerically
first_frame=$(ls -v fort.* | head -n 1)
last_frame=$(ls -v fort.* | tail -n 1)

for data in "$first_frame" "$last_frame"; do
    # Skip if file is not readable
    [ -r "$data" ] || continue
    
    png="${data}.png"
    
    gnuplot <<-EOF
        set term pngcairo enhanced size 1024,512
        set output "$png"
        set xrange [0:20]
        set yrange [0:20]
        set title "Frame: $data"
        
        plot "$data" u 1:2:(\$3*0.5):(\$4*0.5) w vectors head filled lw 1 lc rgb "red" title "", \
             "$data" u 1:2 w p pt 7 lc rgb "blue" title ""
EOF
    echo "Generated $png"
done
