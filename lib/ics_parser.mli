val parse_file : string -> Schedule.weekly_schedule
(** [parse_file path] reads a Cornell ICS file into a typical Monday-Sunday
    timetable, with each day's classes sorted by start time. Raises [Sys_error]
    for file errors and [Invalid_argument] for malformed or unsupported input.
*)
