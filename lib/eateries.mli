type eatery_type =
  | Dining_hall
  | Cafe
  | Off_campus

type eatery = {
  name : string;
  region : Navigation.region;
  kind : eatery_type;
  hours : (Schedule.weekday list * Schedule.time * Schedule.time) list;
}

val get_eatery_type : eatery_type -> string
(** The display name of an eatery type, e.g. ["Dining hall"]. *)

val eateries : eatery list
(** Every eatery the planner can choose from. *)

val is_open : eatery -> Schedule.weekday -> Schedule.time -> bool
(** [is_open e day t] is whether some [(days, opens, closes)] in [e.hours] has
    [day] in [days] and [opens <= t < closes]. *)

type meal_plan = {
  plan_name : string;
  swipes_per_week : int option;
  brbs : float;
}

val meal_plans : meal_plan list
(** The meal plans a student can choose from. [swipes_per_week = None] means
    unlimited swipes. *)
