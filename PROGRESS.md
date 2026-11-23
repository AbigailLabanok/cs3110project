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
strategies, and budget summaries are still to come.

## Schedule representation for the meal planner

The planner should work directly with the `Schedule.weekly_schedule` returned
by `Ics_parser.parse_file`; there is no need to read the exported CSV back in.
The types are defined in `lib/schedule.mli`:

```ocaml
type time = int
(** Minutes since midnight, from 0 through 1439. *)

type class_meeting = {
  name : string;
  meeting_type : meeting_type;
  location : string;
  start_time : time;
  end_time : time;
}

type weekly_schedule = (weekday * class_meeting list) list
```

A `class_meeting` represents one class session. For example, a CS 4820 lecture
in Ives Hall 305 from 09:05 to 09:55 has `name = "CS 4820"`,
`meeting_type = Lecture`, `location = "Ives Hall 305"`, `start_time = 545`,
and `end_time = 595`. Times are minutes since midnight, so subtraction gives
a duration in minutes. Meeting types are `Lecture`, `Discussion`, `Seminar`,
or `Other "..."`. Locations are plain strings that have not yet been mapped
to campus regions.

A `weekly_schedule` is a list of pairs: each weekday is paired with its list
of class meetings. The parser returns Monday through Sunday, each exactly
once, with an empty list `[]` for days without classes. Each day's meetings
are sorted by start time, and recurring classes appear on each listed day.

## Running the program

With OCaml, Dune, and OUnit installed, run these commands
from the project root:

```sh
dune build
dune exec BigRedMealPlanner -- data/2026FA_Schedule_example.ics 2026FA_Schedule_example.csv
```

Replace the input path with your Cornell Scheduler export. The output argument
must be a filename ending in `.csv`, without a directory. The program creates
`output/` if needed and writes `output/<filename>.csv`.

The CSV columns are **Day, Class, Meeting Type, Location, Start Time, End Time**.
Days without classes are included in the parsed schedule but have no CSV rows.

## Testing

Run everything from the project root:

    dune build
    dune test

`dune test` runs two kinds of tests and should finish with `Ran: X tests ...
OK`:

- **OUnit/QCheck** (`test/test_BigRedMealPlanner.ml` and `test/test_planner.ml`): unit tests and property
  tests (QCheck) of `Schedule`, `Navigation`, `Eateries`, `Strategy`, `Ics_parser` and
  `Schedule_csv`.
- **Cram** (`test/cli.t`): runs `bin/main.exe` on the sample schedule and
  checks the CSV and the error messages.

To test coverage, run the following commands:

    rm -f bisect*.coverage
    dune test --instrument-with bisect_ppx --force
    bisect-ppx-report html

