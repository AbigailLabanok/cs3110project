(* Test suite for the modules: Schedule, Navigation, Eateries, Strategy,
   Ics_parser, Schedule_csv. *)

open OUnit2
open BigRedMealPlanner
module G = QCheck2.Gen

(* Helpers *)

(** [string_of_region_option r] is a printable form of [r] for failure messages.
*)
let string_of_region_option = function
  | None -> "None"
  | Some r -> "Some " ^ Navigation.region_name r

(** [string_of_string_list lst] is [lst] printed as an OCaml-style list. *)
let string_of_string_list lst = "[" ^ String.concat "; " lst ^ "]"

(** [with_temp_file contents f] writes [contents] to a fresh temporary file,
    applies [f] to the file's path, and deletes the file afterward, even if [f]
    raises. *)
let with_temp_file contents f =
  let path = Filename.temp_file "mealplanner" ".ics" in
  let channel = open_out_bin path in
  output_string channel contents;
  close_out channel;
  Fun.protect ~finally:(fun () -> Sys.remove path) (fun () -> f path)

(** [parse_string contents] is [Ics_parser.parse_file] applied to a temporary
    file containing [contents]. *)
let parse_string contents = with_temp_file contents Ics_parser.parse_file

(** [read_file path] is the entire contents of the file at [path]. *)
let read_file path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () -> really_input_string channel (in_channel_length channel))

(** [expect_invalid_argument f] passes if [f ()] raises [Invalid_argument] and
    fails otherwise. *)
let expect_invalid_argument f =
  match f () with
  | _ -> assert_failure "expected Invalid_argument, but no exception was raised"
  | exception Invalid_argument _ -> ()

(** [meeting name kind location start finish] is a class meeting. *)
let meeting name meeting_type location start_time end_time =
  { Schedule.name; meeting_type; location; start_time; end_time }

(** [schedule_of_assoc assoc] is a full Monday-through-Sunday schedule whose
    days are taken from [assoc]; days not in [assoc] are empty. *)
let schedule_of_assoc assoc =
  List.map
    (fun day -> (day, try List.assoc day assoc with Not_found -> []))
    Schedule.weekdays

(* Schedule Tests*)

let schedule_tests =
  [
    ( "format_time pads and covers the day's range" >:: fun _ ->
      assert_equal
        [ "00:00"; "01:00"; "09:05"; "14:55"; "23:59" ]
        (List.map Schedule.format_time [ 0; 60; 545; 895; 1439 ])
        ~printer:string_of_string_list );
    ( "day_name of every day" >:: fun _ ->
      assert_equal
        [
          "Monday";
          "Tuesday";
          "Wednesday";
          "Thursday";
          "Friday";
          "Saturday";
          "Sunday";
        ]
        (List.map Schedule.day_name Schedule.weekdays)
        ~printer:string_of_string_list );
  ]

(* Navigation Tests*)

let region_cases =
  [
    ( "known building with a room number",
      "Ives Hall 305",
      Some Navigation.Central );
    ( "ignores case and surrounding spaces",
      "  UPSON hall 142 ",
      Some Navigation.Central );
    ("building name with no room number", "Ives Hall", Some Navigation.Central);
    ("unknown building", "Atlantis Hall 1", None);
    ("online class", "Online", None);
    ("a longer word that starts with a building name", "Ives Hallway 3", None);
  ]

(** [make_region_test (label, location, expected)] is a test that
    [Navigation.region_of_location location] is [expected]. *)
let make_region_test (label, location, expected) =
  "region_of_location: " ^ label >:: fun _ ->
  assert_equal expected
    (Navigation.region_of_location location)
    ~printer:string_of_region_option

let navigation_tests = List.map make_region_test region_cases

(** [gen_location] generates a mix of real-looking locations and random strings.
*)
let gen_location =
  G.oneof
    [
      G.oneof_list (List.map (fun (_, loc, _) -> loc) region_cases);
      G.string_size ~gen:G.printable (G.int_range 0 20);
    ]

let navigation_properties =
  [
    QCheck2.Test.make
      ~name:"region_of_location ignores letter case and surrounding spaces"
      ~count:500 ~print:Fun.id gen_location (fun loc ->
        Navigation.region_of_location (" " ^ String.uppercase_ascii loc ^ " ")
        = Navigation.region_of_location (String.lowercase_ascii loc));
  ]

(* Eateries Tests*)

(** [sample_eatery hours] is an eatery with the given opening hours. *)
let sample_eatery hours =
  {
    Eateries.name = "Test Eatery";
    region = Navigation.Central;
    kind = Eateries.Cafe;
    hours;
  }

let weekdays_only = Schedule.[ Monday; Tuesday; Wednesday; Thursday; Friday ]

(** [make_open_test (label, eatery, day, time, expected)] is a test that
    [Eateries.is_open eatery day time] is [expected]. *)
let make_open_test (label, eatery, day, time, expected) =
  "is_open: " ^ label >:: fun _ ->
  assert_equal expected
    (Eateries.is_open eatery day time)
    ~printer:string_of_bool

let weekday_eatery = sample_eatery [ (weekdays_only, 480, 1260) ]

let two_windows =
  sample_eatery
    [ ([ Schedule.Monday ], 420, 600); ([ Schedule.Monday ], 660, 840) ]

(* Boundary cases: 480 = 08:00 opens, 1260 = 21:00 closes (exclusive). *)
let open_cases =
  Schedule.
    [
      ("open at the opening minute", weekday_eatery, Monday, 480, true);
      ("closed at the closing minute", weekday_eatery, Monday, 1260, false);
      ("closed on a day not listed", weekday_eatery, Saturday, 720, false);
      ("closed in the gap between two windows", two_windows, Monday, 630, false);
      ("no hours means never open", sample_eatery [], Monday, 720, false);
    ]

let eateries_tests = List.map make_open_test open_cases

(** [day_index d] is the position of [d] in Monday-through-Sunday order. *)
let day_index = function
  | Schedule.Monday -> 0
  | Schedule.Tuesday -> 1
  | Schedule.Wednesday -> 2
  | Schedule.Thursday -> 3
  | Schedule.Friday -> 4
  | Schedule.Saturday -> 5
  | Schedule.Sunday -> 6

(** [gen_windows] generates a list of opening-hours entries, each with
    [opens < closes <= 1440]. *)
let gen_windows =
  G.list_size (G.int_range 0 4)
    G.(
      let* days = list_size (int_range 1 7) (oneof_list Schedule.weekdays) in
      let* opens = int_range 0 1438 in
      let+ closes = int_range (opens + 1) 1440 in
      (days, opens, closes))

(** [open_minutes windows] is a 7 x 1440 table whose entry [d][t] is true
    exactly when some window covers minute [t] of day [d]. It is built minute by
    minute, independently of [Eateries.is_open]. *)
let open_minutes windows =
  let table = Array.make_matrix 7 1440 false in
  List.iter
    (fun (days, opens, closes) ->
      List.iter
        (fun day ->
          for t = opens to closes - 1 do
            table.(day_index day).(t) <- true
          done)
        days)
    windows;
  table

let eateries_properties =
  [
    QCheck2.Test.make ~name:"is_open agrees with a minute-by-minute model"
      ~count:500
      ~print:(fun (ws, (d, t)) ->
        Printf.sprintf "%d windows; %s at %d" (List.length ws)
          (Schedule.day_name d) t)
      G.(
        pair gen_windows
          (pair (oneof_list Schedule.weekdays) (int_range 0 1439)))
      (fun (windows, (day, time)) ->
        Eateries.is_open (sample_eatery windows) day time
        = (open_minutes windows).(day_index day).(time));
  ]

(* Strategy Tests*)

(** [eatery_named name region kind] is an eatery with no opening hours. *)
let eatery_named name region kind = { Eateries.name; region; kind; hours = [] }

let sample_eateries =
  Eateries.
    [
      eatery_named "A" Navigation.North Dining_hall;
      eatery_named "B" Navigation.Central Cafe;
      eatery_named "C" Navigation.Collegetown Off_campus;
      eatery_named "D" Navigation.West Dining_hall;
      eatery_named "E" Navigation.Central Cafe;
    ]

(** [names_of eateries] is the names of [eateries], in order. *)
let names_of eateries = List.map (fun e -> e.Eateries.name) eateries

(* Expected results are worked out by hand from [sample_eateries] and the
   "Valid:" lines in strategy.mli: save_brbs allows dining halls and off campus
   (A, C, D); save_brbs_and_cash allows only dining halls (A, D);
   save_cash_and_swipes allows only cafes (B, E). *)
let strategy_filter_cases =
  [
    ("save_brbs", Strategy.save_brbs, [ "A"; "C"; "D" ]);
    ("save_brbs_and_cash", Strategy.save_brbs_and_cash, [ "A"; "D" ]);
    ("save_cash_and_swipes", Strategy.save_cash_and_swipes, [ "B"; "E" ]);
  ]

(** [make_filter_test (label, s, expected)] is a test that filtering
    [sample_eateries] with [s] leaves exactly the eateries named [expected], in
    order. *)
let make_filter_test (label, s, expected) =
  "filter with " ^ label >:: fun _ ->
  assert_equal expected
    (names_of (Strategy.filter s sample_eateries))
    ~printer:string_of_string_list

let strategy_tests =
  List.map make_filter_test strategy_filter_cases
  @ [
      ( "of_name finds every strategy by name, ignoring case and spaces"
      >:: fun _ ->
        List.iter
          (fun s ->
            assert_equal (Some s)
              (Strategy.of_name ("  " ^ String.uppercase_ascii s.Strategy.name))
              ~msg:s.Strategy.name)
          Strategy.all );
      ( "of_name rejects unknown names and prefixes of names" >:: fun _ ->
        assert_equal None (Strategy.of_name "save-everything");
        assert_equal None (Strategy.of_name "save-brbs-and") );
      ( "every strategy leaves at least one real eatery" >:: fun _ ->
        List.iter
          (fun s ->
            assert_bool
              (s.Strategy.name ^ " leaves no eatery in Eateries.eateries")
              (Strategy.filter s Eateries.eateries <> []))
          Strategy.all );
    ]

(** [is_subsequence small big] is whether [small] can be obtained from [big] by
    deleting elements without reordering. *)
let rec is_subsequence small big =
  match (small, big) with
  | [], _ -> true
  | _, [] -> false
  | x :: xs, y :: ys ->
      if x = y then is_subsequence xs ys else is_subsequence small ys

let gen_eatery =
  G.(
    map3
      (fun name region kind -> { Eateries.name; region; kind; hours = [] })
      (string_size ~gen:printable (int_range 1 6))
      (oneof_list Navigation.[ North; West; Central; Collegetown ])
      (oneof_list Eateries.[ Dining_hall; Cafe; Off_campus ]))

let strategy_properties =
  let gen =
    G.pair
      (G.oneof_list Strategy.all)
      (G.list_size (G.int_range 0 12) gen_eatery)
  in
  let print (s, es) =
    s.Strategy.name ^ " on " ^ string_of_string_list (names_of es)
  in
  [
    QCheck2.Test.make ~name:"filter keeps only valid types, in original order"
      ~count:300 ~print gen (fun (s, es) ->
        let kept = Strategy.filter s es in
        List.for_all (fun e -> List.mem e.Eateries.kind s.Strategy.valid) kept
        && is_subsequence kept es);
    QCheck2.Test.make ~name:"filter drops only eateries of invalid types"
      ~count:300 ~print gen (fun (s, es) ->
        let kept = Strategy.filter s es in
        List.for_all
          (fun e ->
            List.mem e kept || not (List.mem e.Eateries.kind s.Strategy.valid))
          es);
  ]

(* Ics_parser Tests*)

(* Locations in the sample file. If the parser is changed to keep only the
   building name (dropping room numbers), update these constants. *)
let loc_ives_305 = "Ives Hall 305"
let loc_upson_142 = "Upson Hall 142"
let loc_rock_103 = "Rockefeller Hall 103"
let loc_lincoln_124 = "Lincoln Hall 124"
let loc_goldwin = "Goldwin Smith Hall 132-HEC Aud"
let loc_ives_115 = "Ives Hall 115"

(* Expected schedule for data/2026FA_Schedule_example.ics, derived by hand from
   the BYDAY, DTSTART, DTEND, SUMMARY and LOCATION lines of each event. Times
   are minutes since midnight, ex. 09:05 = 545. *)
let cs_lecture = meeting "CS 4820" Schedule.Lecture loc_ives_305 545 595
let cs_discussion = meeting "CS 4820" Schedule.Discussion loc_upson_142 610 685
let span_seminar = meeting "SPAN 1210" Schedule.Seminar loc_rock_103 740 790

let music_studio =
  meeting "MUSIC 3111" (Schedule.Other "Studio") loc_lincoln_124 895 970

let econ_lecture = meeting "ECON 3120" Schedule.Lecture loc_goldwin 805 880

let econ_discussion =
  meeting "ECON 3120" Schedule.Discussion loc_ives_115 610 660

let sample_expected =
  schedule_of_assoc
    Schedule.
      [
        (Monday, [ cs_lecture; cs_discussion; span_seminar; music_studio ]);
        (Tuesday, [ span_seminar; econ_lecture ]);
        (Wednesday, [ cs_lecture; span_seminar; music_studio ]);
        (Thursday, [ econ_lecture ]);
        (Friday, [ cs_lecture; econ_discussion; span_seminar ]);
      ]

let sample_path = "../data/2026FA_Schedule_example.ics"

(** [string_of_schedule s] is a compact printable form of [s]. *)
let string_of_schedule s =
  String.concat "\n"
    (List.map
       (fun (day, ms) ->
         Schedule.day_name day ^ ": "
         ^ String.concat ", "
             (List.map
                (fun m ->
                  Printf.sprintf "%s %s %s %d-%d" m.Schedule.name
                    (Schedule.meeting_type_name m.Schedule.meeting_type)
                    m.Schedule.location m.Schedule.start_time
                    m.Schedule.end_time)
                ms))
       s)

(** [default_fields] are the properties of one valid weekly Monday lecture. *)
let default_fields =
  [
    ("SUMMARY;LANGUAGE=en-us", "CS 4820\\, Lecture");
    ("DTSTART", "20260824T090500");
    ("DTEND", "20260824T095500");
    ("RRULE", "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO");
    ("LOCATION", "Ives Hall 305");
  ]

(** [set key value fields] is [fields] with the value of [key] replaced. *)
let set key value fields =
  List.map (fun (k, v) -> if k = key then (k, value) else (k, v)) fields

(** [drop key fields] is [fields] without [key]. *)
let drop key fields = List.filter (fun (k, _) -> k <> key) fields

(** [ics_of_fields fields] is a one-event calendar with the given properties. *)
let ics_of_fields fields =
  "BEGIN:VCALENDAR\nBEGIN:VEVENT\n"
  ^ String.concat "" (List.map (fun (k, v) -> k ^ ":" ^ v ^ "\n") fields)
  ^ "END:VEVENT\nEND:VCALENDAR\n"

(** [monday_of schedule] is the meetings on Monday in [schedule]. *)
let monday_of schedule = List.assoc Schedule.Monday schedule

(* One case per kind of rejection the parser specifies. *)
let invalid_inputs =
  [
    ("no LOCATION", ics_of_fields (drop "LOCATION" default_fields));
    ( "time zone on DTSTART",
      ics_of_fields
        (("DTSTART;TZID=America/New_York", "20260824T090500")
        :: drop "DTSTART" default_fields) );
    ( "end before start",
      ics_of_fields (set "DTEND" "20260824T085500" default_fields) );
    ( "monthly class",
      ics_of_fields (set "RRULE" "FREQ=MONTHLY;BYDAY=MO" default_fields) );
    ( "invalid hour (24:55 would otherwise be a valid later end)",
      ics_of_fields (set "DTEND" "20260824T245500" default_fields) );
    ("not a calendar", "hello world\n");
  ]

(** [make_invalid_test (label, contents)] is a test that parsing [contents]
    raises [Invalid_argument]. *)
let make_invalid_test (label, contents) =
  "malformed input raises Invalid_argument: " ^ label >:: fun _ ->
  expect_invalid_argument (fun () -> parse_string contents)

(** [two_event_calendar first second] is a calendar whose events start at the
    times given by [first] and [second], listed in that order, both on Mondays.
    Each time is [(start, finish)] as an ICS timestamp pair. *)
let two_event_calendar (s1, e1) (s2, e2) =
  let event s e =
    ics_of_fields (set "DTEND" e (set "DTSTART" s default_fields))
  in
  let body text =
    (* keep only the event, not the calendar markers *)
    let lines = String.split_on_char '\n' text in
    String.concat "\n"
      (List.filter
         (fun l -> l <> "BEGIN:VCALENDAR" && l <> "END:VCALENDAR")
         lines)
  in
  "BEGIN:VCALENDAR\n"
  ^ body (event s1 e1)
  ^ body (event s2 e2)
  ^ "END:VCALENDAR\n"

let parser_tests =
  [
    ( "sample file gives the hand-derived schedule" >:: fun _ ->
      assert_equal sample_expected
        (Ics_parser.parse_file sample_path)
        ~printer:string_of_schedule );
    ( "meetings are sorted by start time, not file order" >:: fun _ ->
      let text =
        two_event_calendar
          ("20260824T150000", "20260824T160000")
          ("20260824T080000", "20260824T090000")
      in
      assert_equal [ 480; 900 ]
        (List.map
           (fun m -> m.Schedule.start_time)
           (monday_of (parse_string text)))
        ~printer:(fun l -> string_of_string_list (List.map string_of_int l)) );
    ( "a folded line is joined to the previous line" >:: fun _ ->
      let text =
        "BEGIN:VCALENDAR\n\
         BEGIN:VEVENT\n\
         SUMMARY:CS 4820\\, Lecture\n\
         DTSTART:20260824T090500\n\
         DTEND:20260824T095500\n\
         RRULE:FREQ=WEEKLY;BYDAY=MO\n\
         LOCATION:Ives Hall\n\
        \  305\n\
         END:VEVENT\n\
         END:VCALENDAR\n"
      in
      assert_equal "Ives Hall 305"
        (List.hd (monday_of (parse_string text))).Schedule.location
        ~printer:Fun.id );
    ( "Windows (CRLF) line endings are accepted" >:: fun _ ->
      let crlf =
        String.concat "\r\n"
          (String.split_on_char '\n' (ics_of_fields default_fields))
      in
      assert_equal [ cs_lecture ] (monday_of (parse_string crlf)) );
    ( "a missing file raises Sys_error" >:: fun _ ->
      match Ics_parser.parse_file "no_such_file_anywhere.ics" with
      | _ -> assert_failure "expected Sys_error"
      | exception Sys_error _ -> () );
  ]
  @ List.map make_invalid_test invalid_inputs

(* Round-trip property: serialise random class lists to ICS text, parse them
   back, and compare to a reference model built directly from the lists. *)

(** [code_of_day d] is the two-letter ICS code for [d]. *)
let code_of_day = function
  | Schedule.Monday -> "MO"
  | Schedule.Tuesday -> "TU"
  | Schedule.Wednesday -> "WE"
  | Schedule.Thursday -> "TH"
  | Schedule.Friday -> "FR"
  | Schedule.Saturday -> "SA"
  | Schedule.Sunday -> "SU"

(** [ics_of_specs specs] is an ICS calendar with one weekly event per
    [(days, meeting)] in [specs]. *)
let ics_of_specs specs =
  let event (days, m) =
    Printf.sprintf
      "BEGIN:VEVENT\n\
       DTSTART:20260824T%02d%02d00\n\
       DTEND:20260824T%02d%02d00\n\
       RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=%s\n\
       SUMMARY;LANGUAGE=en-us:%s\\, %s\n\
       LOCATION:%s\n\
       END:VEVENT\n"
      (m.Schedule.start_time / 60)
      (m.Schedule.start_time mod 60)
      (m.Schedule.end_time / 60)
      (m.Schedule.end_time mod 60)
      (String.concat "," (List.map code_of_day days))
      m.Schedule.name
      (Schedule.meeting_type_name m.Schedule.meeting_type)
      m.Schedule.location
  in
  "BEGIN:VCALENDAR\n"
  ^ String.concat "" (List.map event specs)
  ^ "END:VCALENDAR\n"

(** [model_schedule specs] is the schedule the parser should return for [specs]:
    for each day, the meetings listing that day, stably sorted by start time. *)
let model_schedule specs =
  List.map
    (fun day ->
      ( day,
        List.stable_sort
          (fun a b -> compare a.Schedule.start_time b.Schedule.start_time)
          (List.filter_map
             (fun (days, m) -> if List.mem day days then Some m else None)
             specs) ))
    Schedule.weekdays

let gen_spec =
  G.(
    let* days = list_size (int_range 1 7) (oneof_list Schedule.weekdays) in
    let* name =
      oneof_list [ "CS 1110"; "MATH 1920"; "SPAN 1210"; "ECON 3120" ]
    in
    let* meeting_type =
      oneof_list
        Schedule.[ Lecture; Discussion; Seminar; Other "Studio"; Other "Lab" ]
    in
    let* location =
      oneof_list
        [ "Ives Hall 305"; "Upson Hall 142"; "Olin Hall"; "Online"; "" ]
    in
    let* start_time = int_range 0 1438 in
    let+ end_time = int_range (start_time + 1) 1439 in
    (days, { Schedule.name; meeting_type; location; start_time; end_time }))

let parser_properties =
  [
    QCheck2.Test.make ~name:"parsing serialised classes matches the model"
      ~count:200
      ~print:(fun specs -> ics_of_specs specs)
      (G.list_size (G.int_range 0 8) gen_spec)
      (fun specs -> parse_string (ics_of_specs specs) = model_schedule specs);
  ]

(* Schedule_csv Tests *)

let csv_header =
  "\"Day\",\"Class\",\"Meeting Type\",\"Location\",\"Start Time\",\"End Time\"\r\n"

(** [csv_of schedule] writes [schedule] with [Schedule_csv.write_file] to a
    scratch file in [output/] and is the text of that file. The file is deleted
    afterward. *)
let csv_of schedule =
  (* OUnit runs tests in parallel processes, so each call needs its own file. *)
  (if not (Sys.file_exists "output") then
     try Sys.mkdir "output" 0o755 with Sys_error _ -> ());
  let path = Filename.temp_file ~temp_dir:"output" "scratch" ".csv" in
  let filename = Filename.basename path in
  Fun.protect
    ~finally:(fun () -> if Sys.file_exists path then Sys.remove path)
    (fun () ->
      Schedule_csv.write_file filename schedule;
      read_file path)

let csv_tests =
  [
    ( "one row per meeting with HH:MM times; empty days have no rows"
    >:: fun _ ->
      let schedule =
        schedule_of_assoc
          Schedule.
            [
              (Monday, [ cs_lecture; cs_discussion ]);
              (Friday, [ econ_discussion ]);
            ]
      in
      let expected =
        csv_header
        ^ "\"Monday\",\"CS 4820\",\"Lecture\",\"Ives Hall \
           305\",\"09:05\",\"09:55\"\r\n"
        ^ "\"Monday\",\"CS 4820\",\"Discussion\",\"Upson Hall \
           142\",\"10:10\",\"11:25\"\r\n"
        ^ "\"Friday\",\"ECON 3120\",\"Discussion\",\"Ives Hall \
           115\",\"10:10\",\"11:00\"\r\n"
      in
      assert_equal expected (csv_of schedule) ~printer:String.escaped );
    ( "quotes inside a field are doubled and commas stay quoted" >:: fun _ ->
      let m =
        meeting "He said \"hi\"" Schedule.Lecture "Ives Hall, Room 305" 545 595
      in
      let expected =
        csv_header
        ^ "\"Monday\",\"He said \"\"hi\"\"\",\"Lecture\",\"Ives Hall, Room \
           305\",\"09:05\",\"09:55\"\r\n"
      in
      assert_equal expected
        (csv_of (schedule_of_assoc [ (Schedule.Monday, [ m ]) ]))
        ~printer:String.escaped );
    ( "the parsed sample file exports to header plus 13 rows" >:: fun _ ->
      let text = csv_of (Ics_parser.parse_file sample_path) in
      let lines =
        List.filter (fun l -> l <> "") (String.split_on_char '\n' text)
      in
      assert_equal 14 (List.length lines) ~printer:string_of_int;
      (* Spot check a row typed by hand from the sample .ics. *)
      assert_bool "missing the Tuesday ECON 3120 row"
        (List.mem
           "\"Tuesday\",\"ECON 3120\",\"Lecture\",\"Goldwin Smith Hall 132-HEC \
            Aud\",\"13:25\",\"14:40\"\r"
           lines) );
    ( "filenames that are not a plain .csv name are rejected" >:: fun _ ->
      List.iter
        (fun filename ->
          expect_invalid_argument (fun () ->
              Schedule_csv.write_file filename (schedule_of_assoc [])))
        [ "sub/out.csv"; ".csv"; "out.txt"; "out" ] );
  ]

let qcheck_tests =
  List.map QCheck_runner.to_ounit2_test
    (navigation_properties @ eateries_properties @ strategy_properties
   @ parser_properties)

let tests =
  "BigRedMealPlanner"
  >::: [
         "Schedule" >::: schedule_tests;
         "Navigation" >::: navigation_tests;
         "Eateries" >::: eateries_tests;
         "Strategy" >::: strategy_tests;
         "Ics_parser" >::: parser_tests;
         "Schedule_csv" >::: csv_tests;
         "QCheck properties" >::: qcheck_tests;
       ]

let _ = run_test_tt_main tests
