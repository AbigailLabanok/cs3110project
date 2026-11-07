open Schedule

(** [escape field] quotes a CSV field and doubles any embedded quotes. *)
let escape field =
  "\"" ^ String.concat "\"\"" (String.split_on_char '"' field) ^ "\""

(** [write_row channel fields] writes one escaped CSV row to [channel]. *)
let write_row channel fields =
  output_string channel (String.concat "," (List.map escape fields) ^ "\r\n")

(** [write_file filename schedule] writes one CSV row per meeting to
    [output/filename], creating the directory or replacing the file as needed.
    Empty days have no rows. Requires a valid, sorted weekly schedule.
    Raises [Invalid_argument] unless [filename] is a plain filename ending in
    [.csv], and [Sys_error] for file errors. *)
let write_file filename schedule =
  if
    Filename.basename filename <> filename
    || filename = ".csv"
    || not (Filename.check_suffix filename ".csv")
  then
    invalid_arg "Output must be a filename ending in .csv (without a directory)";
  if not (Sys.file_exists "output") then Sys.mkdir "output" 0o755;
  let path = Filename.concat "output" filename in
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      write_row channel
        [ "Day"; "Class"; "Meeting Type"; "Location"; "Start Time"; "End Time" ];
      List.iter
        (fun (day, meetings) ->
          List.iter
            (fun meeting ->
              write_row channel
                [
                  day_name day;
                  meeting.name;
                  meeting_type_name meeting.meeting_type;
                  meeting.location;
                  format_time meeting.start_time;
                  format_time meeting.end_time;
                ])
            meetings)
        schedule;
      flush channel)
