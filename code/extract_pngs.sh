#!/bin/bash
export LANG=C LC_ALL=C

L=46

frames=($(find . -maxdepth 1 -type f -regextype posix-extended \
    -regex './fort\.[0-9]+' -printf '%f\n' | sort -V))

for data in "${frames[0]}" "${frames[-1]}"; do
    [ -s "$data" ] || continue

    awk -v L="$L" 'NF>=7 {
        for(i=-1;i<=1;i++) for(j=-1;j<=1;j++)
            print $1+i*L, $2+j*L, $3, $4
    }' "$data" > temp.dat

    gnuplot <<-EOF
        set term pngcairo size 1600,800 enhanced
        set output "$data.png"
        set xrange [0:$L]
        set yrange [0:$L]
        set title "Frame: $data"

        plot 'temp.dat' u 1:2:(\$3*0.5):(\$4*0.5) \
             w vectors head filled lw 1 lc rgb "red" notitle, \
             'temp.dat' u 1:2 \
             w p pt 7 ps 1.0 lc rgb "blue" notitle

        unset output
EOF
done

rm -f temp.dat
