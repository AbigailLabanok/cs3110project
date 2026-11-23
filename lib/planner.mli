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
(** [slot_length slot] is the amount of time, in minutes, from the start to the
    end of the slot. *)

val class_region : Schedule.class_meeting -> Navigation.region
(** [class_region meeting] returns the region of where the class [meeting] is
    located at, or [Central] if no location is available for [meeting]. *)

val allowed_regions : meal_slot -> Navigation.region list option
(** [allowed_regions slot] is [None] (anywhere) if [slot] is not a short break
    or has no class before or after it. Otherwise it is [Some regions], where
    [regions] is the [class_region] of [slot.before] and [slot.after], whichever
    exist, without duplicates. *)

val allowed_eateries : meal_slot -> Eateries.eatery list
(** [allowed_eateries slot] is every eatery in [Eateries.eateries] that is in
    one of [allowed_regions slot] and is open at [slot.start_time] on
    [slot.day]. *)

val find_meal_slots : Schedule.weekly_schedule -> meal_slot list
(** [find_meal_slots schedule] is the free periods in [schedule] where a meal
    could fit, in order by day and then by start time. *)
