(* Test suite for Planner. *)

open OUnit2
open BigRedMealPlanner

(** [meeting name location start finish] is a lecture. *)
let meeting name location start_time end_time =
  {
    Schedule.name;
    meeting_type = Schedule.Lecture;
    location;
    start_time;
    end_time;
  }

(** [slot day start finish before after] is a meal slot. *)
let slot day start_time end_time before after =
  { Planner.day; start_time; end_time; before; after }

let ives = meeting "CS 4820" "Ives Hall 305" 545 595
let upson = meeting "CS 4820" "Upson Hall 142" 610 685

(** [schedule_of_assoc assoc] is a seven-day schedule using [assoc]; other days
    are empty. *)
let schedule_of_assoc assoc =
  List.map
    (fun d -> (d, try List.assoc d assoc with Not_found -> []))
    Schedule.weekdays

let slot_tests =
  [
    ( "slot_length is end minus start" >:: fun _ ->
      assert_equal 90
        (Planner.slot_length (slot Schedule.Monday 600 690 None None))
        ~printer:string_of_int );
    ( "a long slot allows any region" >:: fun _ ->
      assert_equal None
        (Planner.allowed_regions
           (slot Schedule.Monday 700 790 (Some ives) (Some upson))) );
    ( "a slot of exactly short_break_minutes is not short" >:: fun _ ->
      assert_equal None
        (Planner.allowed_regions
           (slot Schedule.Monday 700
              (700 + Planner.short_break_minutes)
              (Some ives) (Some upson))) );
    ( "a short slot between two Central classes allows only Central" >:: fun _ ->
      assert_equal (Some [ Navigation.Central ])
        (Planner.allowed_regions
           (slot Schedule.Monday 685 730 (Some upson) (Some ives))) );
  ]

(** [check_slots schedule] fails unless every slot from [find_meal_slots]
    [schedule] has positive length, does not overlap any class that day, has its
    [before] class ending no later than the slot starts and its [after] class
    starting no earlier than the slot ends, and the slots are ordered by day
    then start time. *)
let check_slots schedule =
  let slots = Planner.find_meal_slots schedule in
  List.iter
    (fun s ->
      assert_bool "slot has non-positive length" (Planner.slot_length s > 0);
      let classes = List.assoc s.Planner.day schedule in
      List.iter
        (fun c ->
          assert_bool "slot overlaps a class"
            (s.Planner.end_time <= c.Schedule.start_time
            || c.Schedule.end_time <= s.Planner.start_time))
        classes;
      (match s.Planner.before with
      | Some b ->
          assert_bool "before class ends after slot starts"
            (b.Schedule.end_time <= s.Planner.start_time)
      | None -> ());
      match s.Planner.after with
      | Some a ->
          assert_bool "after class starts before slot ends"
            (a.Schedule.start_time >= s.Planner.end_time)
      | None -> ())
    slots;
  let day_rank d =
    let rec go i = function
      | [] -> -1
      | x :: rest -> if x = d then i else go (i + 1) rest
    in
    go 0 Schedule.weekdays
  in
  let keys =
    List.map (fun s -> (day_rank s.Planner.day, s.Planner.start_time)) slots
  in
  assert_equal (List.sort compare keys) keys ~msg:"slots out of order"

let two_class_monday =
  schedule_of_assoc
    [
      ( Schedule.Monday,
        [
          meeting "A" "Ives Hall 305" 545 595;
          meeting "B" "Upson Hall 142" 780 840;
        ] );
    ]

let find_slot_tests =
  [
    ( "slots lie in gaps between classes (two-class Monday)" >:: fun _ ->
      check_slots two_class_monday );
    ( "the 595-780 gap on that Monday is offered as a meal slot" >:: fun _ ->
      assert_bool "no slot found in a 3-hour gap"
        (List.exists
           (fun s ->
             s.Planner.day = Schedule.Monday
             && s.Planner.start_time >= 595
             && s.Planner.end_time <= 780)
           (Planner.find_meal_slots two_class_monday)) );
    ( "a 5-minute gap between classes is not a meal slot" >:: fun _ ->
      let tight =
        schedule_of_assoc
          [
            ( Schedule.Monday,
              [
                meeting "A" "Ives Hall 305" 545 595;
                meeting "B" "Upson Hall 142" 600 660;
              ] );
          ]
      in
      assert_bool "5-minute gap should not fit a meal"
        (not
           (List.exists
              (fun s ->
                s.Planner.start_time >= 595 && s.Planner.end_time <= 600)
              (Planner.find_meal_slots tight))) );
  ]

let eatery_tests =
  [
    ( "allowed_eateries is non-empty for a noon slot" >:: fun _ ->
      assert_bool "no eatery allowed for a 90-minute noon slot"
        (Planner.allowed_eateries (slot Schedule.Monday 720 810 None None) <> [])
    );
  ]

let suite =
  "planner"
  >::: [
         "slots and regions" >::: slot_tests;
         "find_meal_slots" >::: find_slot_tests;
         "allowed_eateries" >::: eatery_tests;
       ]

let _ = run_test_tt_main suite
