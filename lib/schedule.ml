type weekday =
  | Monday
  | Tuesday
  | Wednesday
  | Thursday
  | Friday
  | Saturday
  | Sunday

type time = int

type meeting_type =
  | Lecture
  | Discussion
  | Seminar
  | Other of string

type class_meeting = {
  name : string;
  meeting_type : meeting_type;
  location : string;
  start_time : time;
  end_time : time;
}

type weekly_schedule = (weekday * class_meeting list) list

let weekdays = [ Monday; Tuesday; Wednesday; Thursday; Friday; Saturday; Sunday ]

(** [day_name day] is the full English name of [day]. *)
let day_name = function
  | Monday -> "Monday"
  | Tuesday -> "Tuesday"
  | Wednesday -> "Wednesday"
  | Thursday -> "Thursday"
  | Friday -> "Friday"
  | Saturday -> "Saturday"
  | Sunday -> "Sunday"

(** [meeting_type_name kind] is the display name of [kind]. *)
let meeting_type_name = function
  | Lecture -> "Lecture"
  | Discussion -> "Discussion"
  | Seminar -> "Seminar"
  | Other name -> name

(** [format_time time] formats minutes since midnight as 24-hour HH:MM. Requires
    [0 <= time < 1440]. *)
let format_time time = Printf.sprintf "%02d:%02d" (time / 60) (time mod 60)
