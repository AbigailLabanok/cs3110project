End-to-end Cram tests for the command-line program: .ics file in, CSV file out.
Expected output is worked out by hand from data/2026FA_Schedule_example.ics.

The sample file has 13 weekly class meetings, so the CSV has a header plus 13
rows, listed Monday through Friday. Saturday and Sunday have no classes.

  $ ../bin/main.exe ../data/2026FA_Schedule_example.ics week.csv
  Wrote schedule to output/week.csv
  $ tr -d '\r' < output/week.csv
  "Day","Class","Meeting Type","Location","Start Time","End Time"
  "Monday","CS 4820","Lecture","Ives Hall 305","09:05","09:55"
  "Monday","CS 4820","Discussion","Upson Hall 142","10:10","11:25"
  "Monday","SPAN 1210","Seminar","Rockefeller Hall 103","12:20","13:10"
  "Monday","MUSIC 3111","Studio","Lincoln Hall 124","14:55","16:10"
  "Tuesday","SPAN 1210","Seminar","Rockefeller Hall 103","12:20","13:10"
  "Tuesday","ECON 3120","Lecture","Goldwin Smith Hall 132-HEC Aud","13:25","14:40"
  "Wednesday","CS 4820","Lecture","Ives Hall 305","09:05","09:55"
  "Wednesday","SPAN 1210","Seminar","Rockefeller Hall 103","12:20","13:10"
  "Wednesday","MUSIC 3111","Studio","Lincoln Hall 124","14:55","16:10"
  "Thursday","ECON 3120","Lecture","Goldwin Smith Hall 132-HEC Aud","13:25","14:40"
  "Friday","CS 4820","Lecture","Ives Hall 305","09:05","09:55"
  "Friday","ECON 3120","Discussion","Ives Hall 115","10:10","11:00"
  "Friday","SPAN 1210","Seminar","Rockefeller Hall 103","12:20","13:10"

Running again with the same output name replaces the file rather than
appending to it: the line count stays at 14 (header plus 13 rows).

  $ ../bin/main.exe ../data/2026FA_Schedule_example.ics week.csv
  Wrote schedule to output/week.csv
  $ wc -l < output/week.csv | tr -d ' '
  14

A calendar with no events is valid and gives a header-only CSV.

  $ printf 'BEGIN:VCALENDAR\nEND:VCALENDAR\n' > empty.ics
  $ ../bin/main.exe empty.ics empty.csv
  Wrote schedule to output/empty.csv
  $ tr -d '\r' < output/empty.csv
  "Day","Class","Meeting Type","Location","Start Time","End Time"

Errors. Each prints one message on standard error and exits with status 1,
and no CSV is written for the failed input.

Wrong number of arguments:

  $ ../bin/main.exe
  Usage: BigRedMealPlanner <input.ics> <output.csv>
  [1]
  $ ../bin/main.exe ../data/2026FA_Schedule_example.ics
  Usage: BigRedMealPlanner <input.ics> <output.csv>
  [1]

Input file that does not exist:

  $ ../bin/main.exe no_such_file.ics out.csv
  Error: no_such_file.ics: No such file or directory
  [1]

Input that is not a calendar:

  $ printf 'hello\n' > notacalendar.ics
  $ ../bin/main.exe notacalendar.ics out.csv
  Error: Expected a VCALENDAR file
  [1]
  $ ls output
  empty.csv
  week.csv

An event with no LOCATION line is rejected:

  $ printf 'BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:CS 1110\\, Lecture\nDTSTART:20260824T090500\nDTEND:20260824T095500\nRRULE:FREQ=WEEKLY;BYDAY=MO\nEND:VEVENT\nEND:VCALENDAR\n' > noloc.ics
  $ ../bin/main.exe noloc.ics out.csv
  Error: Missing ICS property: LOCATION
  [1]

Output names must be a plain filename ending in .csv:

  $ ../bin/main.exe ../data/2026FA_Schedule_example.ics week.txt
  Error: Output must be a filename ending in .csv (without a directory)
  [1]
  $ ../bin/main.exe ../data/2026FA_Schedule_example.ics sub/week.csv
  Error: Output must be a filename ending in .csv (without a directory)
  [1]
