open Schedule

(** [split_once separator text] splits at the first [separator], or raises
    [Invalid_argument] if it is missing. *)
let split_once separator text =
  match String.index_opt text separator with
  | None -> invalid_arg ("Missing separator in: " ^ text)
  | Some index ->
      ( String.sub text 0 index,
        String.sub text (index + 1) (String.length text - index - 1) )

(** [read_lines channel] reads logical ICS lines, joining folded lines. Raises
    [Invalid_argument] for a continuation without a preceding line. *)
let read_lines channel =
  let rec loop lines =
    match input_line channel with
    | line ->
        let length = String.length line in
        let line =
          if length > 0 && line.[length - 1] = '\r' then
            String.sub line 0 (length - 1)
          else line
        in
        if line = "" then loop lines
        else if line.[0] = ' ' || line.[0] = '\t' then
          match lines with
          | previous :: rest ->
              loop
                ((previous ^ String.sub line 1 (String.length line - 1)) :: rest)
          | [] -> invalid_arg "Unexpected ICS continuation line"
        else loop (line :: lines)
    | exception End_of_file -> List.rev lines
  in
  loop []

(** [decode_text text] decodes ICS text escapes.
    Raises [Invalid_argument] for an invalid escape. *)
let decode_text text =
  let buffer = Buffer.create (String.length text) in
  let rec loop index =
    if index = String.length text then Buffer.contents buffer
    else if text.[index] = '\\' then (
      if index + 1 = String.length text then invalid_arg "Incomplete ICS escape";
      let character =
        match text.[index + 1] with
        | 'n' | 'N' -> '\n'
        | ('\\' | ',' | ';') as character -> character
        | _ -> invalid_arg "Unknown ICS escape"
      in
      Buffer.add_char buffer character;
      loop (index + 2))
    else (
      Buffer.add_char buffer text.[index];
      loop (index + 1))
  in
  loop 0

(** [parse_time value] reads a floating YYYYMMDDTHHMMSS timestamp. Returns
    minutes since midnight, rejects malformed times or nonzero seconds. *)
let parse_time value =
  if String.length value <> 15 || value.[8] <> 'T' then
    invalid_arg ("Expected a local YYYYMMDDTHHMMSS time: " ^ value);
  String.iteri
    (fun index character ->
      if index <> 8 && (character < '0' || character > '9') then
        invalid_arg ("Invalid timestamp: " ^ value))
    value;
  let hour = int_of_string (String.sub value 9 2) in
  let minute = int_of_string (String.sub value 11 2) in
  let second = int_of_string (String.sub value 13 2) in
  if hour > 23 || minute > 59 || second <> 0 then
    invalid_arg ("Expected a valid time with zero seconds: " ^ value);
  (hour * 60) + minute

(** [required key fields] finds a required property, or raises
    [Invalid_argument] if it is absent. *)
let required key fields =
  match List.assoc_opt key fields with
  | Some value -> value
  | None -> invalid_arg ("Missing ICS property: " ^ key)

(** [parse_event fields] returns recurring weekday codes and a class meeting.
    Supports weekly, same-day classes in floating local time. *)
let parse_event fields =
  let summary = decode_text (required "SUMMARY" fields) in
  let name, kind = split_once ',' summary in
  let meeting_type =
    match String.trim kind with
    | "Lecture" -> Lecture
    | "Discussion" -> Discussion
    | "Seminar" -> Seminar
    | other -> Other other
  in
  let start = required "DTSTART" fields in
  let finish = required "DTEND" fields in
  let start_time = parse_time start in
  let end_time = parse_time finish in
  if String.sub start 0 8 <> String.sub finish 0 8 || start_time >= end_time
  then invalid_arg "Classes must start and end on the same day, in time order";
  let rule =
    List.map (split_once '=')
      (String.split_on_char ';' (required "RRULE" fields))
  in
  if required "FREQ" rule <> "WEEKLY" then
    invalid_arg "Only weekly classes are supported";
  (match List.assoc_opt "INTERVAL" rule with
  | None | Some "1" -> ()
  | Some _ -> invalid_arg "Only classes repeating every week are supported");
  let days = String.split_on_char ',' (required "BYDAY" rule) in
  List.iter
    (fun day ->
      if not (List.mem day [ "MO"; "TU"; "WE"; "TH"; "FR"; "SA"; "SU" ]) then
        invalid_arg ("Unsupported weekday: " ^ day))
    days;
  ( days,
    {
      name = String.trim name;
      meeting_type;
      location = decode_text (required "LOCATION" fields);
      start_time;
      end_time;
    } )

(** [collect_events lines] parses events in file order, ignoring lines outside
    events. Raises [Invalid_argument] for malformed or unsupported events. *)
let collect_events lines =
  let rec collect current events = function
    | [] ->
        if current <> None then invalid_arg "Unclosed VEVENT";
        List.rev events
    | "BEGIN:VEVENT" :: rest ->
        if current <> None then invalid_arg "Nested VEVENT";
        collect (Some []) events rest
    | "END:VEVENT" :: rest -> (
        match current with
        | None -> invalid_arg "Unexpected END:VEVENT"
        | Some fields -> collect None (parse_event fields :: events) rest)
    | line :: rest -> (
        match current with
        | None -> collect None events rest
        | Some fields ->
            let property, value = split_once ':' line in
            let key = List.hd (String.split_on_char ';' property) in
            if (key = "DTSTART" || key = "DTEND") && key <> property then
              invalid_arg "Only floating local class times are supported";
            collect (Some ((key, value) :: fields)) events rest)
  in
  collect None [] lines

(** [build_schedule events] groups parsed events by day, Monday through Sunday,
    including empty days. Sorts meetings by start time, preserving input order
    for ties. Requires valid day codes and class meetings. *)
let build_schedule events =
  let days =
    [
      (Monday, "MO");
      (Tuesday, "TU");
      (Wednesday, "WE");
      (Thursday, "TH");
      (Friday, "FR");
      (Saturday, "SA");
      (Sunday, "SU");
    ]
  in
  List.map
    (fun (day, code) ->
      let meetings =
        List.filter_map
          (fun (codes, meeting) ->
            if List.mem code codes then Some meeting else None)
          events
      in
      ( day,
        List.stable_sort
          (fun first second -> compare first.start_time second.start_time)
          meetings ))
    days

(** [parse_lines lines] checks the calendar markers and returns a sorted
    seven-day schedule. Raises [Invalid_argument] for malformed or unsupported
    input. *)
let parse_lines lines =
  if not (List.mem "BEGIN:VCALENDAR" lines && List.mem "END:VCALENDAR" lines)
  then invalid_arg "Expected a VCALENDAR file";
  let events = collect_events lines in
  build_schedule events

(** [parse_file path] reads a Cornell ICS file into a typical Monday-Sunday
    timetable, with each day's classes sorted by start time. Raises [Sys_error]
    for file errors and [Invalid_argument] for malformed or unsupported input.
*)
let parse_file path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () -> parse_lines (read_lines channel))
