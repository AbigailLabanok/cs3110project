val write_file : string -> Schedule.weekly_schedule -> unit
(** [write_file filename schedule] writes one CSV row per meeting to
    [output/filename], creating the directory or replacing the file as needed.
    Empty days have no rows. Requires a valid, sorted weekly schedule.
    Raises [Invalid_argument] unless [filename] is a plain filename ending in
    [.csv], and [Sys_error] for file errors. *)
