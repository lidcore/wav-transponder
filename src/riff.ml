type t = {
  id: string;
  payload: payload
} and chunk_list = {
  list_type: string;
  chunks: t list
} and payload =
  | Data of data
  | List of chunk_list
and data = {
  filename: string;
  offset: int;
  len: int
}

let read_int ic =
  let total = 4 in
  let rec aux cur = function
    | 0 -> cur
    | n ->
      let b = input_byte ic in
      let cur =
        b lsl ((total-n)*8) + cur
      in
      aux cur (n-1)
  in
  aux 0 total

let int_string n =
  let s = Bytes.create 4 in
  Bytes.set s 0 (char_of_int (n land 0xff)) ;
  Bytes.set s 1 (char_of_int ((n land 0xff00) lsr 8)) ;
  Bytes.set s 2 (char_of_int ((n land 0xff0000) lsr 16)) ;
  Bytes.set s 3 (char_of_int ((n land 0x7f000000) lsr 24)) ;
  s

let rec chunk_len chunk =
  match chunk.payload with
    | Data {len;_} -> len
    | List {chunks;_} ->
        List.fold_left (fun cur chunk ->
          cur + 8 + (chunk_len chunk)) 4 chunks

let rec read_chunk filename offset ic =
  let id = really_input_string ic 4 in
  let len = read_int ic in
  let offset = offset+8 in
  let payload =
    match id with
      | "RIFF"
      | "LIST" ->
          let list_type = really_input_string ic 4 in
          let read = 4 in
          let rec f cur read =
            if read = len then
              cur
            else begin
              let chunk = read_chunk filename (offset+read) ic in
              let chunk_len = chunk_len chunk in
              let read = read+8+chunk_len in
              f (chunk::cur) read
            end
          in
          let chunks = List.rev (f [] read) in
          List {list_type;chunks}
      | _ ->
        seek_in ic (offset+len);
        Data {filename;offset;len}
  in
  {id;payload}

let write_channel oc ic len =
  let buflen = 1024 in
  let buf = Bytes.create buflen in 
  let rec f len =
    if len > 0 then begin
      let ret = input ic buf 0 (min buflen len) in
      if ret > 0 then begin
        output oc buf 0 ret;
        f (len-ret)
      end
    end
  in
  f len

let open_chunk {filename;offset;_} =
  let ic = open_in filename in
  seek_in ic offset;
  ic

let write_data oc ({len;_} as data) =
  let ic = open_chunk data in
  write_channel oc ic len;
  close_in ic

let rec write_chunk oc ({id;payload} as chunk) =
  output_string oc id;
  output_string oc (int_string (chunk_len chunk));
  write_payload oc payload
and write_payload oc = function
  | Data data -> write_data oc data
  | List {list_type;chunks} ->
      output_string oc list_type;
      List.iter (write_chunk oc) chunks  

let read filename =
  let ic = open_in filename in
  let ret = read_chunk filename 0 ic in
  close_in ic;
  ret
    
let write chunk filename =
  let oc = open_out filename in
  write_chunk oc chunk;
  close_out oc
