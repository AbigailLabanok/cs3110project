# Big Red Meal Planner

The first part of the project is implemented: importing a Cornell Scheduler
`.ics` file and exporting the student's class schedule as a CSV.

- `Schedule` defines the days, meeting types, and class records. Times are stored
  as minutes since midnight.
- `Ics_parser` extracts course names, meeting types, locations, and times into a
  Monday–Sunday schedule, with each day's classes sorted by start time.
- `Schedule_csv` writes one row per class meeting, with readable `HH:MM` times.
- The command-line program connects the parser and writer and reports input or
  file errors.

The schedule represents a typical teaching week. It does not account for
holidays, cancellations, or semester date ranges. Meal planning, dining data,
strategies, and budget summaries are still to come. The test suite currently
contains only a placeholder test.

## Running the program

With OCaml, Dune, and OUnit installed, run these commands
from the project root:

```sh
dune build
dune exec BigRedMealPlanner -- data/2026FA_Schedule_DT.ics 2026FA_Schedule_DT.csv
```

Replace the input path with your Cornell Scheduler export. The output argument
must be a filename ending in `.csv`, without a directory. The program creates
`output/` if needed and writes `output/<filename>.csv`.

The CSV columns are **Day, Class, Meeting Type, Location, Start Time, End Time**.
Days without classes are included in the parsed schedule but have no CSV rows.
