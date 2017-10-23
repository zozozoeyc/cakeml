open preamble
     ml_translatorTheory ml_translatorLib ml_progLib
     cfTacticsBaseLib cfTacticsLib basisFunctionsLib
     mlstringTheory mlcommandLineProgTheory fsFFITheory fsioConstantsProgTheory

val _ = new_theory"fsioProg";
val _ = translation_extends "fsioConstantsProg";

(* stdin, stdout, stderr *)
(* these are functions as append_prog rejects constants *)
(* TODO: use add_Dlet instead to use constants *)
val _ = process_topdecs`
    fun stdin () = Word8.fromInt 0;
    fun stdout () = Word8.fromInt 1;
    fun stderr () = Word8.fromInt 2
    ` |> append_prog

(* writei: higher-lever write function which calls #write until something is written or
* a filesystem error is raised and outputs the number of bytes written.
* It assumes that iobuff is initialised
* write: idem, but keeps writing until the whole (specified part of the) buffer
* is written *)

val _ =
  process_topdecs`fun writei fd n i =
    let val a = Word8Array.update iobuff 0 fd
        val a = Word8Array.update iobuff 1 n
        val a = Word8Array.update iobuff 2 i
        val a = #(write) "" iobuff in
        if Word8Array.sub iobuff 0 = Word8.fromInt 1
        then raise InvalidFD
        else
          let val nw = Word8.toInt(Word8Array.sub iobuff 1) in
            if nw = 0 then writei fd n i
            else nw
          end
    end
    fun write fd n i =
      if n = 0 then () else
        let val nw = writei fd (Word8.fromInt n) (Word8.fromInt i) in
          if nw < n then write fd (n-nw) (i+nw) else () end` |> append_prog

(* Output functions on given file descriptor *)
val _ =
  process_topdecs` fun write_char fd c =
    (Word8Array.update iobuff 3 (Word8.fromInt(Char.ord c)); write fd 1 0; ())

    fun print_char c = write_char (stdout()) c
    fun prerr_char c = write_char (stderr()) c
    ` |> append_prog

(* writes a string into a file *)
val _ =
  process_topdecs` fun output fd s =
  if s = "" then () else
  let val z = String.size s
      val n = if z <= 255 then z else 255
      val fl = Word8Array.copyVec s 0 n iobuff 3
      val a = write fd n 0 in
         output fd (String.substring s n (z-n))
  end;
  fun print_string s = output (stdout()) s;
  fun prerr_string s = output (stderr()) s;
    ` |> append_prog

val _ = process_topdecs`
  fun print_list ls =
    case ls of [] => () | (x::xs) => (print_string x; print_list xs)`
       |> append_prog ;

(* val print_newline : unit -> unit *)
val _ = process_topdecs`
    fun write_newline fd = write_char fd #"\n"
    fun print_newline () = write_char (stdout()) #"\n"
    fun prerr_newline () = write_char (stderr()) #"\n"
    ` |> append_prog

val _ = process_topdecs`
fun openIn fname =
  let val a = Word8Array.copyVec fname 0 (String.size fname) iobuff 0
      val a = Word8Array.update iobuff (String.size fname) (Word8.fromInt 0)
      val a = #(open_in) "" iobuff in
        if Word8Array.sub iobuff 0 = Word8.fromInt 0
        then Word8Array.sub iobuff 1
        else raise BadFileName
  end
fun openOut fname =
  let val a = Word8Array.copyVec fname 0 (String.size fname) iobuff 0
      val a = Word8Array.update iobuff (String.size fname) (Word8.fromInt 0)
      val a = #(open_out) "" iobuff in
        if Word8Array.sub iobuff 0 = Word8.fromInt 0
        then Word8Array.sub iobuff 1
        else raise BadFileName
  end` |> append_prog
val _ = process_topdecs`

fun close fd =
  let val a = Word8Array.update iobuff 0 fd
      val a = #(close) "" iobuff in
        if Word8Array.sub iobuff 0 = Word8.fromInt 1
        then () else raise InvalidFD
  end` |> append_prog

(* wrapper for ffi call *)
val _ = process_topdecs`
  fun read fd n =
    let val a = Word8Array.update iobuff 0 fd
        val a = Word8Array.update iobuff 1 n in
          (#(read) "" iobuff;
          if Word8.toInt (Word8Array.sub iobuff 0) <> 1
          then Word8.toInt(Word8Array.sub iobuff 1)
          else raise InvalidFD)
    end` |> append_prog

(* reads 1 char *)
val _ = process_topdecs`
fun read_byte fd =
    if read fd (Word8.fromInt 1) = 0 then raise EndOfFile
    else Word8Array.sub iobuff 3
` |> append_prog

val _ = (append_prog o process_topdecs)`
  fun read_char fd = Char.chr(Word8.toInt(read_byte fd))`

(* val input : in_channel -> bytes -> int -> int -> int
* input ic buf pos len reads up to len characters from the given channel ic,
* storing them in byte sequence buf, starting at character number pos. *)
(* TODO: input0 as local fun *)
val _ =
  process_topdecs`
fun input fd buff off len =
let fun input0 off len count =
    let val nread = read fd (Word8.fromInt(min len 255)) in
        if nread = 0 then count else
          (Word8Array.copy iobuff 3 nread buff off;
           input0 (off + nread) (len - nread) (count + nread))
    end
in input0 off len 0 end
` |> append_prog

(* read a line (same semantics as SML's TextIO.inputLine) *)
(* simple, inefficient version that reads 1 char at a time *)
val () = (append_prog o process_topdecs)`
  fun inputLine fd =
    let
      fun realloc arr =
        let
          val len = Word8Array.length arr
          val arr' = Word8Array.array (2*len) (Word8.fromInt 0)
        in (Word8Array.copy arr 0 len arr' 0; arr') end
      val nl = Word8.fromInt (Char.ord #"\n")
      fun inputLine_aux arr i =
        if i < Word8Array.length arr then
          let
            val c = read_byte fd
            val u = Word8Array.update arr i c
          in
            if c = nl then SOME (Word8Array.substring arr 0 (i+1))
            else inputLine_aux arr (i+1)
          end
          handle EndOfFile =>
            if i = 0 then NONE
            else (Word8Array.update arr i nl;
                  SOME (Word8Array.substring arr 0 (i+1)))
        else inputLine_aux (realloc arr) i
      in inputLine_aux (Word8Array.array 127 (Word8.fromInt 0)) 0 end`;

(* This version doesn't work because CF makes it difficult (impossible?) to
   work with references/arrays inside data structures (here inside a pair)
val () = (append_prog o process_topdecs)`
  fun inputLine fd =
    let
      fun realloc arr =
        let
          val len = Word8Array.length arr
          val arr' = Word8Array.array (2*len) (Word8.fromInt 0)
        in (Word8Array.copy arr 0 len arr' 0; arr') end
      val nl = Word8.fromInt (Char.ord #"\n")
      fun inputLine_aux arr i =
        if i < Word8Array.length arr then
          let val c = read_byte fd
          in if c = nl then (arr,i+1) else
            (Word8Array.update arr i c;
             inputLine_aux arr (i+1))
          end handle EndOfFile => (arr,i)
        else inputLine_aux (realloc arr) i
      val res = inputLine_aux (Word8Array.array 127 (Word8.fromInt 0)) 0
      val arr = fst res val nr = snd res
    in if nr = 0 then NONE else
      (Word8Array.update arr (nr-1) nl;
       SOME (Word8Array.substring arr 0 nr))
    end`;
*)

(*

Version of inputLine that reads chunks at a time, but has to return the unused
part of the last chunk. I expect this will not end up being used, because something like the above simpler version becomes efficient if we switch to buffered streams.  I.e., the buffering shouldn't be inputLine-specific.

(* generalisable to splitl *)
val _ = process_topdecs`
fun find_newline s i l =
  if i >= l then l else
  if String.sub s i = #"\n" then i
  else find_newline s (i+1) l
fun split_newline s =
  let val l = String.size s
      val i = find_newline s 0 l in
        (String.substring s 0 i, String.substring s i (l-i))
  end
` |> append_prog

(* using lets/ifs as case take a while in xlet *)
(* if/if take a while in xcf *)
val _ = process_topdecs`
fun inputLine fd lbuf =
  let fun inputLine_aux lacc =
    let val nr = read fd (Word8.fromInt 255) in
      if nr = 0 then (String.concat (List.rev lacc), "") else
        let val lread = Word8Array.substring iobuff 3 nr
            val split = split_newline lread
            val line = fst split
            val lrest = snd split in
              if lrest = "" then inputLine_aux (line :: lacc)
              else (String.concat (List.rev("\n" :: line :: lacc)),
                    String.extract lrest 1 NONE)
        end
    end
  val split = split_newline lbuf
  val line = fst split
  val lrest = snd split in
    if lrest = "" then
      let val split' = inputLine_aux [] in
        (String.concat (line :: fst split' :: []), snd split') end
    else (String.concat (line :: "\n" :: []), String.extract lrest 1 NONE)
  end` |> append_prog
*)

val _ = (append_prog o process_topdecs) `
  fun inputLines fd =
    case inputLine fd of
        NONE => []
      | SOME l => l::inputLines fd`;

val _ = (append_prog o process_topdecs) `
  fun inputLinesFrom fname =
    let
      val fd = openIn fname
      val lines = inputLines fd
    in
      close fd; SOME lines
    end handle BadFileName => NONE`;

val _ = ml_prog_update (close_module NONE);

val _ = export_theory();
