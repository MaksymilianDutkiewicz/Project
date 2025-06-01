#!/usr/bin/env bash

file="journal.csv"
time_period="$1"

if [[ -z "$time_period" ]]; then
  period="week"
fi


if [[ "$time_period" == "week" ]]; then
  since=$(date -d "last monday" +%F)
elif [[ "$time_period" == "month" ]]; then
  since=$(date +%Y-%m-01)
elif [[ "$time_period" == "all" ]]; then
  since="0000-00-00"
else
  echo "Użycie: report [week|month|all]" >&2
  exit 1
fi

awk -F"," -v s="$since" '$1 >= s' "$file" > tmp.csv

read study workout sleep < <(
  awk -F"," '{
    if ($2 == "study")        study += $4;
    else if ($2 == "workout") workout += $4;
    else if ($2 == "sleep")   sleep += $4 * 60;
  }
  END {
    print study+0, workout+0, sleep+0
  }' tmp.csv
)

awk -F"," '
{
  v = ($2 == "sleep") ? $4 * 60 : $4

  if      ($2 == "study")   study[$1]   += v
  else if ($2 == "workout") workout[$1] += v
  else if ($2 == "sleep")   sleep[$1]   += v
}
END {
  for (d in study)   all[d] = 1
  for (d in workout) all[d] = 1
  for (d in sleep)   all[d] = 1

  
  for (d in all) {
    printf "%s %d %d %d\n", d, study[d] + 0, workout[d] + 0, sleep[d] + 0
  }
}
' tmp.csv | sort > day.dat


gnuplot <<GP
set datafile separator whitespace
set term pdf size 14cm,11cm font "Times,12"
set output "panel.pdf"
set multiplot layout 3,1 title ""

  set style data histograms
  set style fill solid  
  set ylabel "min"
  set title "Study"
  plot "day.dat" using 2:xtic(1) lc rgb "blue" notitle

  set title "Workout"
  plot "day.dat" using 3:xtic(1) lc rgb "red" notitle

  set title "Sleep"
  plot "day.dat" using 4:xtic(1) lc rgb "green" notitle

unset multiplot
GP


range_txt="$since – $(date +%F)"
cat > report.tex <<TEX
\documentclass{article}
\usepackage{graphicx}
\usepackage{times}

\begin{document}
\LARGE Habit Report\\
\small $range_txt

\begin{itemize}
  \item Study:   {$study\,min}
  \item Workout: {$workout\,min}
  \item Sleep:   {$(( sleep / 60 ))\,h}
\end{itemize}

\includegraphics[width=\linewidth]{panel.pdf}
\end{document}
TEX

pdflatex report.tex >/dev/null 2>&1

rm -f panel.pdf report.tex report.log report.aux tmp.csv day.dat

echo "succesfully generated report.pdf"