#set key opaque
set key top left
set logscale x
set logscale y
set grid y2
set ylabel "runtime[s]"
set y2label "speedup"
set y2range [0:550]
set ytics nomirror
set y2tics nomirror
set y2tics 100
set grid noxtics noytics noztics front
set xlabel "rays per sample"
set format x "%.0te%+03T";
set xrange [10000:10000000]

#set style fill solid 1 noborder
set style fill transparent solid 0.15

plot \
"runtime.dat" u 1:5 w boxes axes x1y2 t "4 x GPU speedup" ,\
"runtime.dat" u 1:6 w boxes axes x1y2 t "1 x GPU speedup" ,\
"runtime.dat" u 1:2 w linespoints axes x1y1 t "1 x CPU runtime ",\
"runtime.dat" u 1:3 w linespoints axes x1y1 t "4 x GPU runtime " lt rgb "red",\
"runtime.dat" u 1:4 w linespoints axes x1y1 t "1 x GPU runtime " lt rgb "green" 

# Output
set term png
set output "runtime.png"
replot
set term postscript
set output "runtime.ps"
replot
set term x11