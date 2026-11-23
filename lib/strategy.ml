open Eateries

type t = {
  name : string;
  description : string;
  valid : eatery_type list;
}

let filter s eateries = List.filter (fun e -> List.mem e.kind s.valid) eateries

let save_brbs =
  {
    name = "save-brbs";
    description = "Save BRBs: eat at dining halls and off campus.";
    valid = [ Dining_hall; Off_campus ];
  }

let save_cash =
  {
    name = "save-cash";
    description = "Save cash: eat at dining halls and cafes.";
    valid = [ Dining_hall; Cafe ];
  }

let save_swipes =
  {
    name = "save-swipes";
    description = "Save meal swipes: eat at cafes and off campus.";
    valid = [ Cafe; Off_campus ];
  }

let save_brbs_and_swipes =
  {
    name = "save-brbs-and-swipes";
    description = "Save BRBs and meal swipes: eat only off campus.";
    valid = [ Off_campus ];
  }

let save_brbs_and_cash =
  {
    name = "save-brbs-and-cash";
    description = "Save BRBs and cash: eat only at dining halls.";
    valid = [ Dining_hall ];
  }

let save_cash_and_swipes =
  {
    name = "save-cash-and-swipes";
    description = "Save cash and meal swipes: eat only at cafes.";
    valid = [ Cafe ];
  }

let all =
  [
    save_brbs;
    save_cash;
    save_swipes;
    save_brbs_and_swipes;
    save_brbs_and_cash;
    save_cash_and_swipes;
  ]

let of_name n =
  let n = String.lowercase_ascii (String.trim n) in
  List.find_opt (fun s -> s.name = n) all
