type meal_slot = {
  day : Schedule.weekday;
  start_time : Schedule.time;
  end_time : Schedule.time;
  before : Schedule.class_meeting option;
  after : Schedule.class_meeting option;
}

let short_break_minutes = 60
let slot_length _slot = failwith "TODO"
let class_region _meeting = failwith "TODO"
let allowed_regions _slot = failwith "TODO"
let allowed_eateries _slot = failwith "TODO"
let find_meal_slots _schedule = failwith "TODO"
