open BigRedMealPlanner

let () =
  if Array.length Sys.argv <> 3 then (
    prerr_endline "Usage: BigRedMealPlanner <input.ics> <output.csv>";
    exit 1);
  try
    let schedule = Ics_parser.parse_file Sys.argv.(1) in
    Schedule_csv.write_file Sys.argv.(2) schedule;
    Printf.printf "Wrote schedule to output/%s\n" Sys.argv.(2)
  with Sys_error message | Invalid_argument message ->
    prerr_endline ("Error: " ^ message);
    exit 1
