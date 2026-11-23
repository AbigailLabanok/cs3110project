type meal_slot = {
  day : Schedule.weekday;
  start_time : Schedule.time;
  end_time : Schedule.time;
  before : Schedule.class_meeting option;
  after : Schedule.class_meeting option;
}

let short_break_minutes = 60
let minimum_meal_slot = 60

(** [slot_length slot] returns the amount of time, in minutes, from the start to
    the end of the slot. *)
let slot_length slot = slot.end_time - slot.start_time

(** [class_region meeting] returns the region of where the class [meeting] is
    located at, or [Central] if no location is available for [meeting]. *)
let class_region meeting =
  match Navigation.region_of_location meeting.Schedule.location with
  | Some region -> region
  | None -> Navigation.Central

(** [add_region] returns a list of Navigation.region objects that contains the
    given region [region]. It checks to make sure that [region] doesn't already
    exist in [regions]. *)
let add_region region regions =
  if List.mem region regions then regions else region :: regions

(** [allowed_regions slot] is [None] (anywhere) if [slot] is not a short break
    or has no class before or after it. Otherwise it is [Some regions], where
    [regions] is the [class_region] of [slot.before] and [slot.after], whichever
    exist, without duplicates. *)
let allowed_regions slot =
  if slot_length slot >= short_break_minutes then None
  else
    match (slot.before, slot.after) with
    | None, None -> None
    | before, after ->
        let add_class_region regions = function
          | None -> regions
          | Some class_meeting ->
              add_region (class_region class_meeting) regions
        in
        Some (List.fold_left add_class_region [] [ before; after ])

(** [allowed_eateries slot] is every eatery in [Eateries.eateries] that is in
    one of [allowed_regions slot] and is open at [slot.start_time] on
    [slot.day]. *)
let allowed_eateries slot =
  let regions = allowed_regions slot in
  Eateries.eateries
  |> List.filter (fun eatery ->
      let region_matches =
        match regions with
        | None -> true
        | Some regions -> List.mem eatery.Eateries.region regions
      in
      region_matches && Eateries.is_open eatery slot.day slot.start_time)

(** [slots_for_day day meetings] finds the possible meal slots given the
    meetings for a given day. *)
let slots_for_day day meetings =
  match meetings with
  | [] -> []
  | first :: remaining ->
      let rec loop previous latest_end acc = function
        | [] -> List.rev acc
        | current :: rest ->
            let acc =
              if current.Schedule.start_time > latest_end then
                {
                  day;
                  start_time = latest_end;
                  end_time = current.Schedule.start_time;
                  before = Some previous;
                  after = Some current;
                }
                :: acc
              else acc
            in
            if current.Schedule.end_time > latest_end then
              loop current current.Schedule.end_time acc rest
            else loop previous latest_end acc rest
      in
      loop first first.Schedule.end_time [] remaining

(** [find_meal_slots schedule] is the free periods in [schedule] where a meal
    could fit, in order by day and then by start time. *)
let find_meal_slots schedule =
  List.concat_map (fun (day, meetings) -> slots_for_day day meetings) schedule
  |> List.filter (fun slot -> slot_length slot >= minimum_meal_slot)
