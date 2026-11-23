type meal_slot = {
  day : Schedule.weekday;
  start_time : Schedule.time;
  end_time : Schedule.time;
  before : Schedule.class_meeting option;
  after : Schedule.class_meeting option;
}

val short_break_minutes : int
(** A slot shorter than this many minutes is a short break. *)

val slot_length : meal_slot -> int
(** [slot_length s] is [s.end_time - s.start_time]. *)

val class_region : Schedule.class_meeting -> Navigation.region
(** [class_region c] is [Navigation.region_of_location c.location], or [Central]
    if that is [None]. *)

val allowed_regions : meal_slot -> Navigation.region list option
(** [allowed_regions s] is [None] (anywhere) if [s] is not a short break or has
    no class before or after it. Otherwise it is [Some rs], where [rs] is the
    [class_region] of [s.before] and [s.after], whichever exist, without
    duplicates. *)

val allowed_eateries : meal_slot -> Eateries.eatery list
(** [allowed_eateries s] is every eatery in [Eateries.eateries] that is in one
    of [allowed_regions s] and is open at [s.start_time] on [s.day]. *)

val find_meal_slots : Schedule.weekly_schedule -> meal_slot list
(** [find_meal_slots schedule] is the free periods in [schedule] where a meal
    could fit, in order by day and then by start time. *)
