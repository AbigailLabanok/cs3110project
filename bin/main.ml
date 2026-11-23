open BigRedMealPlanner

let () =
  Terminal.welcome_msg ();
  Terminal.instructions ();

  let file = Terminal.ask_user "Enter your .ics file path:" in

  try
    let schedule = Ics_parser.parse_file file in
    Schedule_csv.write_file "output/schedule.csv" schedule;
    print_endline "Schedule saved to output/schedule.csv"
  with Sys_error message | Invalid_argument message ->
    prerr_endline ("Error: " ^ message);
    exit 1
