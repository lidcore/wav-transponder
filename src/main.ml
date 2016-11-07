let usage = "wav-transponder <source.wav> <new-data.wav> <merged-file.wav>"

let on_error reason =
  Printf.eprintf "Error: %s\n%!" reason;
  Printf.eprintf "Usage: %s\n%!" usage;
  exit 1

exception Found of (Riff.t*Riff.t)
exception Invalid_format

open Riff

let () =
  Printexc.record_backtrace true;

  if Array.length Sys.argv <> 4 then
    on_error "Invalid arguments!";

  let source_file = Sys.argv.(1) in
  let data_file = Sys.argv.(2) in
  let merged_file = Sys.argv.(3) in

  let source =
    read source_file
  in

  let data =
    read data_file
  in

  let data_chunk,fmt_chunk =
    let data_chunk = ref None in
    let fmt_chunk = ref None in
    let rec f chunk =
      match chunk with
        | {id;_} when id = "data" ->
            data_chunk := Some chunk 
        | {id;_} when id = "fmt " ->
            fmt_chunk := Some chunk
        | {payload;_} ->
            begin match payload with
              | List {chunks;_} ->
                  List.iter f chunks
              | _ -> ()
            end
    in
    f data;
    match !data_chunk, !fmt_chunk with
      | Some data_chunk, Some fmt_chunk ->
          data_chunk, fmt_chunk
      | _ -> raise Invalid_format
  in

  let merged =
    let rec f = function
      | {id;_} when id = "data" -> data_chunk
      | {id;_} when id = "fmt " -> fmt_chunk
      | {id;payload} ->
          let payload =
            match payload with
              | List {list_type;chunks} ->
                 let chunks = List.map f chunks in
                 List {list_type;chunks}
              | _ -> payload
          in
          {id;payload}
    in
    f source 
  in

  Riff.write merged merged_file
