type region =
  | North
  | West
  | Central
  | Collegetown

let region_name = function
  | North -> "North"
  | West -> "West"
  | Central -> "Central"
  | Collegetown -> "Collegetown"

let buildings =
  [
    ("ives hall", Central);
    ("upson hall", Central);
    ("rockefeller hall", Central);
    ("lincoln hall", Central);
    ("goldwin smith hall", Central);
    ("bill and melinda gates hall", Central);
    ("duffield hall", Central);
    ("phillips hall", Central);
    ("frank h t rhodes hall", Central);
    ("hollister hall", Central);
    ("thurston hall", Central);
    ("kimball hall", Central);
    ("carpenter hall", Central);
    ("olin hall", Central);
    ("uris hall", Central);
    ("baker laboratory", Central);
    ("physical sciences building", Central);
    ("clark hall", Central);
    ("malott hall", Central);
    ("white hall", Central);
    ("mcgraw hall", Central);
    ("morrill hall", Central);
    ("stimson hall", Central);
    ("klarman hall", Central);
    ("statler hall", Central);
    ("sage hall", Central);
    ("barton hall", Central);
    ("bailey hall", Central);
    ("martha van rensselaer hall", Central);
    ("warren hall", Central);
    ("kennedy hall", Central);
    ("bradfield hall", Central);
    ("emerson hall", Central);
    ("corson hall", Central);
    ("weill hall", Central);
    ("snee hall", Central);
    ("bard hall", Central);
    ("stocking hall", Central);
  ]

(* [matches_building loc name] is whether lowercase [loc] is exactly [name] or
   starts with [name] followed by a space. *)
let matches_building loc name =
  let n = String.length name in
  String.starts_with ~prefix:name loc && (String.length loc = n || loc.[n] = ' ')

let region_of_location location =
  let loc = String.lowercase_ascii (String.trim location) in
  List.find_map
    (fun (name, region) ->
      if matches_building loc name then Some region else None)
    buildings
