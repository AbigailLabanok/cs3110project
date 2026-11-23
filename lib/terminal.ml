let welcome_msg () =
  print_endline "CORNELL MEAL PLANNER";
  print_endline "This program helps Cornell students plan meals by using class schedules.";
  print_endline ""

let instructions () =
  print_endline "Instructions:";
  print_endline "1. Input your scheduler as an .ics file path.";
  print_endline "2. Enter some of your dining hall preferences.";
  print_endline "3. Receive your personalized meal plan.";
  print_endline ""

let ask_user question =
  print_string (question ^ " ");
  flush stdout;
  read_line ()
