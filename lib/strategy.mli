type t = {
  name : string;
  description : string;
  valid : Eateries.eatery_type list;
}

val filter : t -> Eateries.eatery list -> Eateries.eatery list
(** [filter s eateries] is the eateries in [eateries] whose type is in
    [s.valid], in their original order. *)

val save_brbs : t
(** Valid: dining halls and off-campus eateries. *)

val save_cash : t
(** Valid: dining halls and cafes. *)

val save_swipes : t
(** Valid: cafes and off-campus eateries. *)

val save_brbs_and_swipes : t
(** Valid: off-campus eateries only. *)

val save_brbs_and_cash : t
(** Valid: dining halls only. *)

val save_cash_and_swipes : t
(** Valid: cafes only. *)

val all : t list
(** Every strategy, in the order to list them to the user. *)

val of_name : string -> t option
(** [of_name n] is the strategy in [all] whose [name] is [n], ignoring case and
    surrounding spaces, or [None] if there is none. *)
