open BigRedMealPlanner

let () =
  Terminal.welcome_msg ();
  Terminal.instructions ();

  let file = Terminal.ask_user "Enter your .ics file path:" in

  try
    let schedule = Ics_parser.parse_file file in
    Schedule_csv.write_file "schedule.csv" schedule;
    print_endline "Schedule saved to output/schedule.csv";

    let meal_slots = Planner.find_meal_slots schedule in
    Terminal.display_meal_plan meal_slots
  with Sys_error message | Invalid_argument message ->
    prerr_endline ("Error: " ^ message);
    exit 1
