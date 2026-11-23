type region =
  | North
  | West
  | Central
  | Collegetown

val region_name : region -> string
(** The display name of a region, e.g. ["North"]. *)

val region_of_location : string -> region option
(** [region_of_location location] maps a class location like ["Ives Hall 305"]
    to a region by its building name, ignoring case and surrounding spaces.
    Returns [None] for unknown buildings and online classes. *)
