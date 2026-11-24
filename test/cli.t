End-to-end Cram tests for the command-line program. The program is
interactive: it prints a welcome message, asks for the path of an .ics file on
standard input, saves the parsed schedule to output/schedule.csv, and prints
the meal plan. Each test below types the path by piping it in with echo.

Expected values are worked out by hand from data/2026FA_Schedule_example.ics.
Its 13 weekly class meetings give a CSV with a header plus 13 rows.

The welcome message and the question are printed first:

  $ echo ../data/2026FA_Schedule_example.ics | ../bin/main.exe | grep -v '^$' | head -n 7
  CORNELL MEAL PLANNER
  This program helps Cornell students plan meals by using class schedules.
  Instructions:
  1. Input your scheduler as an .ics file path.
  2. Enter some of your dining hall preferences.
  3. Receive your personalized meal plan.
  Enter your .ics file path: Schedule saved to output/schedule.csv

The saved CSV lists the 13 meetings from Monday through Friday:

  $ tr -d '\r' < output/schedule.csv
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

Meal slots. A gap between two classes is a meal slot when it is at least 60
minutes long. By hand from the table above: Monday 13:10-14:55 (105 minutes);
Wednesday 09:55-12:20 (145) and 13:10-14:55 (105); Friday 11:00-12:20 (80).
Monday 11:25-12:20 is only 55 minutes and the other gaps are 15 minutes, so
they are not slots. We check the times, lengths and neighbouring classes, not
the eatery names, which depend on the stored data.

  $ echo ../data/2026FA_Schedule_example.ics | ../bin/main.exe | grep -E 'Available time|Break length|Previous class|Next class'
  Available time: 13:10 - 14:55
  Break length: 105 minutes
  Previous class: SPAN 1210 (Rockefeller Hall 103)
  Next class: MUSIC 3111 (Lincoln Hall 124)
  Available time: 09:55 - 12:20
  Break length: 145 minutes
  Previous class: CS 4820 (Ives Hall 305)
  Next class: SPAN 1210 (Rockefeller Hall 103)
  Available time: 13:10 - 14:55
  Break length: 105 minutes
  Previous class: SPAN 1210 (Rockefeller Hall 103)
  Next class: MUSIC 3111 (Lincoln Hall 124)
  Available time: 11:00 - 12:20
  Break length: 80 minutes
  Previous class: ECON 3120 (Ives Hall 115)
  Next class: SPAN 1210 (Rockefeller Hall 103)

Every slot lists suggested eateries:

  $ echo ../data/2026FA_Schedule_example.ics | ../bin/main.exe | grep -c 'Suggested eateries:'
  4

Running again replaces the CSV rather than appending to it: the line count
stays at 14 (header plus 13 rows).

  $ echo ../data/2026FA_Schedule_example.ics | ../bin/main.exe > /dev/null
  $ wc -l < output/schedule.csv | tr -d ' '
  14

A calendar with no events is valid. There are no classes, so no meal slots:

  $ printf 'BEGIN:VCALENDAR\nEND:VCALENDAR\n' > empty.ics
  $ echo empty.ics | ../bin/main.exe | grep -v '^$' | tail -n 2
  Your Suggested Meal Plan:
  No meal times found.

Errors. Each prints one message on standard error and exits with status 1.
The welcome text goes to standard output, so we discard it here.

Input file that does not exist:

  $ echo no_such_file.ics | ../bin/main.exe > /dev/null
  Error: no_such_file.ics: No such file or directory
  [1]

Input that is not a calendar:

  $ printf 'hello\n' > notacalendar.ics
  $ echo notacalendar.ics | ../bin/main.exe > /dev/null
  Error: Expected a VCALENDAR file
  [1]

An event with no LOCATION line is rejected:

  $ printf 'BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:CS 1110\\, Lecture\nDTSTART:20260824T090500\nDTEND:20260824T095500\nRRULE:FREQ=WEEKLY;BYDAY=MO\nEND:VEVENT\nEND:VCALENDAR\n' > noloc.ics
  $ echo noloc.ics | ../bin/main.exe > /dev/null
  Error: Missing ICS property: LOCATION
  [1]
