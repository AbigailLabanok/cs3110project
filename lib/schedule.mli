type weekday =
  | Monday
  | Tuesday
  | Wednesday
  | Thursday
  | Friday
  | Saturday
  | Sunday

type time = int
(** Minutes since midnight, from 0 through 1439. *)

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
(** A typical teaching week: Monday through Sunday, each appearing once,
    including empty days, with meetings sorted by start time. *)

val weekdays : weekday list
(** All seven days in Monday-through-Sunday order. *)

val day_name : weekday -> string
(** The full English name of a weekday. *)

val meeting_type_name : meeting_type -> string
(** The display name of a meeting type. *)

val format_time : time -> string
(** Formats minutes since midnight as 24-hour HH:MM. Requires
    [0 <= time < 1440]. *)
