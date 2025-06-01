#!/usr/bin/env bash
file="journal.csv"

activity="$1"      
subject="$2"       
amount="$3"        
chosen_date="$4"  

if [[ -z "$activity" || -z "$amount" ]]; then
  echo "Correct use: log [activity] [subject] [amount] [YYYY-MM-DD]" >&2
  exit 1
fi

if [[ -n "$chosen_date" ]]; then
  if [[ $chosen_date = [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]]; then
    date="$chosen_date"
  else
    echo "Incorrect date format: (YYYY-MM-DD)" >&2
    exit 1
  fi
else
  date=$(date +%F)
fi

printf '%s,%s,%s,%s\n' "$date" "$activity" "$subject" "$amount" >> "$file"

echo "logged: $date, $activity, $subject, $amount"