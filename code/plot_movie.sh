#!/bin/bash
export LANG=C LC_ALL=C

L=46

mkdir -p .pbc_frames
rm -f .pbc_frames/*

# Select numerical Fortran frames
mapfile -t frames < <(
    find . -maxdepth 1 -type f -regextype posix-extended \
    -regex './fort\.[0-9]+' -printf '%f\n' | sort -V
)

# Generate animated GIF
(
    echo "set term gif animate delay 10 size 1600,800"
    echo "set output 'simulation_movie.gif'"
    echo "set xrange [0:46]"
    echo "set yrange [0:46]"
    echo "set xtics 10"
    echo "set ytics 10"

    for data in "${frames[@]}"; do
        [ -s "$data" ] || continue

        tiled=".pbc_frames/${data}.dat"

        # Periodic copies across edges and corners
        awk -v L="$L" '
        NF >= 7 {
            for(i=-1;i<=1;i++)
                for(j=-1;j<=1;j++)
                    printf "%.12g %.12g %.12g %.12g\n", \
                    $1+i*L, $2+j*L, $3, $4
        }' "$data" > "$tiled"

        echo "set title 'Frame: $data'"

        printf "plot '%s' u 1:2:(\$3*0.5):(\$4*0.5) w vectors head filled lw 1 lc rgb 'red' notitle, " "$tiled"

        printf "'%s' u 1:2 w points pt 7 ps 1.0 lc rgb 'blue' notitle\n" "$tiled"
    done

    echo "unset output"

) | gnuplot
