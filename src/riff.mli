type t = {
  id: string;
  payload: payload
} and chunk_list = {
  list_type: string;
  chunks: t list
} and payload =
  | Data of data
  | List of chunk_list
and data

val read : string -> t

val write : t -> string -> unit

