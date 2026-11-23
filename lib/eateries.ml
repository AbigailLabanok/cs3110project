open Schedule

type eatery_type =
  | Dining_hall
  | Cafe
  | Off_campus

type eatery = {
  name : string;
  region : Navigation.region;
  kind : eatery_type;
  hours : (weekday list * time * time) list;
}

let get_eatery_type = function
  | Dining_hall -> "Dining hall"
  | Cafe -> "Cafe"
  | Off_campus -> "Off campus"

(* [hm h m] is the time [h]:[m] in minutes since midnight. *)
let hm h m = (h * 60) + m
let every_day = Schedule.weekdays
let weekdays_only = [ Monday; Tuesday; Wednesday; Thursday; Friday ]
let mon_to_thu = [ Monday; Tuesday; Wednesday; Thursday ]
let weekends = [ Saturday; Sunday ]

let eateries =
  (*TODO: Add more eateries, correct opening hours*)
  Navigation.
    [
      (* North *)
      {
        name = "Morrison Dining";
        region = North;
        kind = Dining_hall;
        hours =
          [
            (every_day, hm 0 0, hm 0 0);
            (every_day, hm 0 0, hm 0 0);
            (every_day, hm 0 0, hm 0 0);
          ];
      };
      {
        name = "North Star Dining Room";
        region = North;
        kind = Dining_hall;
        hours =
          [
            (weekdays_only, hm 0 0, hm 0 0);
            (weekdays_only, hm 0 0, hm 0 0);
            (weekends, hm 0 0, hm 0 0);
            (every_day, hm 0 0, hm 0 0);
          ];
      };
      {
        name = "Risley Dining Room";
        region = North;
        kind = Dining_hall;
        hours =
          [ (weekdays_only, hm 0 0, hm 0 0); (mon_to_thu, hm 0 0, hm 0 0) ];
      };
      {
        name = "Bear Necessities";
        region = North;
        kind = Cafe;
        hours = [ (weekdays_only, hm 0 0, hm 0 0); (weekends, hm 0 0, hm 0 0) ];
      };
      (* West *)
      {
        name = "Cook House Dining Room";
        region = West;
        kind = Dining_hall;
        hours =
          [
            (weekdays_only, hm 0 0, hm 0 0);
            (weekends, hm 0 0, hm 0 0);
            (every_day, hm 0 0, hm 0 0);
          ];
      };
      {
        name = "Becker House Dining Room";
        region = West;
        kind = Dining_hall;
        hours =
          [
            (weekdays_only, hm 0 0, hm 0 0);
            (weekdays_only, hm 0 0, hm 0 0);
            (every_day, hm 0 0, hm 0 0);
          ];
      };
      {
        name = "Jansen's Dining Room at Bethe House";
        region = West;
        kind = Dining_hall;
        hours =
          [
            (every_day, hm 0 0, hm 0 0);
            (weekdays_only, hm 0 0, hm 0 0);
            (every_day, hm 0 0, hm 0 0);
          ];
      };
      {
        name = "Keeton House Dining Room";
        region = West;
        kind = Dining_hall;
        hours =
          [ (weekdays_only, hm 0 0, hm 0 0); (mon_to_thu, hm 0 0, hm 0 0) ];
      };
      {
        name = "Rose House Dining Room";
        region = West;
        kind = Dining_hall;
        hours = [ (weekends, hm 0 0, hm 0 0); (weekdays_only, hm 0 0, hm 0 0) ];
      };
      (* Central *)
      {
        name = "Okenshields";
        region = Central;
        kind = Dining_hall;
        hours =
          [ (weekdays_only, hm 0 0, hm 0 0); (mon_to_thu, hm 0 0, hm 0 0) ];
      };
      {
        name = "Mattin's Cafe";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 0 0, hm 0 0); (weekends, hm 0 0, hm 0 0) ];
      };
      {
        name = "Trillium";
        region = Central;
        kind = Cafe;
        hours =
          [ (weekdays_only, hm 0 0, hm 0 0); (weekdays_only, hm 0 0, hm 0 0) ];
      };
      {
        name = "Martha's Cafe";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 0 0, hm 0 0) ];
      };
      {
        name = "Terrace";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 0 0, hm 0 0) ];
      };
      {
        name = "Cafe Jennie";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 0 0, hm 0 0); (weekends, hm 0 0, hm 0 0) ];
      };
      (* Collegetown *)
      {
        name = "Collegetown Bagels";
        region = Collegetown;
        kind = Off_campus;
        hours = [ (weekdays_only, hm 0 0, hm 0 0); (weekends, hm 0 0, hm 0 0) ];
      };
    ]

let is_open e day t =
  List.exists
    (fun (days, opens, closes) -> List.mem day days && opens <= t && t < closes)
    e.hours

type meal_plan = {
  plan_name : string;
  swipes_per_week : int option;
  brbs : float;
}

let meal_plans =
  [
    { plan_name = "Unlimited"; swipes_per_week = None; brbs = 400.0 };
    (* TODO: Add more meal plans*)
  ]
