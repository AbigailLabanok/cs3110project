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
  (*TODO: Add more eateries, fix hours*)
  Navigation.
    [
      (* North *)
      {
        name = "Morrison Dining";
        region = North;
        kind = Dining_hall;
        hours =
          [
            (mon_to_thu, hm 7 0, hm 8 0);
            (every_day, hm 8 0, hm 16 0);
            (every_day, hm 17 0, hm 20 30);
          ];
      };
      {
        name = "North Star Dining Room";
        region = North;
        kind = Dining_hall;
        hours =
          [ (weekends, hm 10 0, hm 14 0); (every_day, hm 17 30, hm 22 30) ];
      };
      {
        name = "Risley Dining Room";
        region = North;
        kind = Dining_hall;
        hours =
          [
            (weekdays_only, hm 11 0, hm 14 0); (weekdays_only, hm 17 0, hm 19 0);
          ];
      };
      {
        name = "Bear Necessities";
        region = North;
        kind = Cafe;
        hours =
          [
            (every_day, hm 0 0, hm 2 0);
            (weekdays_only, hm 8 0, hm 10 0);
            (every_day, hm 10 0, hm 24 0);
          ];
      };
      (* West *)
      {
        name = "Cook House Dining Room";
        region = West;
        kind = Dining_hall;
        hours = [ (weekends, hm 10 0, hm 14 0); (every_day, hm 17 30, hm 22 0) ];
      };
      {
        name = "Becker House Dining Room";
        region = West;
        kind = Dining_hall;
        hours =
          [
            (weekdays_only, hm 7 0, hm 10 0);
            (weekdays_only, hm 14 0, hm 15 30);
            (every_day, hm 10 0, hm 14 0);
            (every_day, hm 17 0, hm 20 0);
          ];
      };
      {
        name = "Jansen's Dining Room at Bethe House";
        region = West;
        kind = Dining_hall;
        hours =
          [
            (every_day, hm 10 0, hm 14 0);
            (weekdays_only, hm 7 0, hm 10 0);
            (every_day, hm 16 30, hm 19 0);
          ];
      };
      {
        name = "Keeton House Dining Room";
        region = West;
        kind = Dining_hall;
        hours = [ (weekends, hm 10 0, hm 14 0); (every_day, hm 17 0, hm 20 0) ];
      };
      {
        name = "Rose House Dining Room";
        region = West;
        kind = Dining_hall;
        hours =
          [
            (weekdays_only, hm 7 30, hm 10 0);
            (weekends, hm 8 0, hm 9 30);
            (weekends, hm 10 0, hm 14 0);
            (every_day, hm 17 0, hm 20 0);
          ];
      };
      (* Central *)
      {
        name = "Okenshields";
        region = Central;
        kind = Dining_hall;
        hours =
          [
            (weekdays_only, hm 10 30, hm 14 30);
            (weekdays_only, hm 16 30, hm 21 0);
          ];
      };
      {
        name = "Mattin's Cafe";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 7 0, hm 17 0) ];
      };
      {
        name = "Trillium";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 8 0, hm 15 0) ];
      };
      {
        name = "Martha's Cafe";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 8 0, hm 15 0) ];
      };
      {
        name = "Terrace";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 10 0, hm 15 0) ];
      };
      {
        name = "Cafe Jennie";
        region = Central;
        kind = Cafe;
        hours = [ (weekdays_only, hm 8 30, hm 18 0) ];
      };
      (* Collegetown *)
      {
        name = "Collegetown Bagels";
        region = Collegetown;
        kind = Off_campus;
        hours = [ (every_day, hm 6 30, hm 24 0) ];
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
