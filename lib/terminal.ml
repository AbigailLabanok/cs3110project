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

let display_meal_plan slots =
  print_endline "";
  print_endline "Your Suggested Meal Plan:";

  if slots = [] then
    print_endline "No meal times found."
  else
    List.iter
      (fun slot ->
        let day = Schedule.day_name slot.Planner.day in
        let start_time = Schedule.format_time slot.Planner.start_time in
        let end_time = Schedule.format_time slot.Planner.end_time in
        let duration = Planner.slot_length slot in

        Printf.printf "\n%s\n" day;
        Printf.printf "Available time: %s - %s\n" start_time end_time;
        Printf.printf "Break length: %d minutes\n" duration;

        (match slot.Planner.before with
        | Some c ->
            Printf.printf "Previous class: %s (%s)\n"
              c.Schedule.name c.Schedule.location
        | None -> ());

        (match slot.Planner.after with
        | Some c ->
            Printf.printf "Next class: %s (%s)\n"
              c.Schedule.name c.Schedule.location
        | None -> ());

        let eateries = Planner.allowed_eateries slot in

        print_endline "Suggested eateries:";

        let rec take n lst =
          match (n, lst) with
          | 0, _ | _, [] -> []
          | n, x :: xs -> x :: take (n - 1) xs
        in

        if eateries = [] then
          print_endline "No available eateries found."
        else
          List.iter
            (fun eatery ->
              Printf.printf "- %s (%s)\n"
                eatery.Eateries.name
                (Navigation.region_name eatery.Eateries.region))
            (take 5 eateries))
      slots