(*Generated by Lem from fpOpt.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory fpValTreeTheory;

val _ = numLib.prefer_num();



val _ = new_theory "fpOpt"

(*
  Definition of the fp_pattern language for Icing optimizations
*)

(*open import Pervasives*)
(*open import Lib*)
(*open import FpValTree*)

val _ = Hol_datatype `
 fp_pat =
       Word of word64
     | Var of num
     | Unop of fp_uop => fp_pat
     | Binop of fp_bop => fp_pat => fp_pat
     | Terop of fp_top => fp_pat => fp_pat => fp_pat
     | Pred of fp_pred => fp_pat
     | Cmp of fp_cmp => fp_pat => fp_pat
     | Scope of sc => fp_pat`;


(* Substitutions are maps (paired lists) from numbers to 'a *)
val _ = type_abbrev((*  'v *) "subst" , ``: (num # 'v) list``);

(*val substLookup: forall 'v. subst 'v -> nat -> maybe 'v*)
 val _ = Define `
 ((substLookup:(num#'v)list -> num -> 'v option) ([]) n=  NONE)
    /\ ((substLookup:(num#'v)list -> num -> 'v option) ((m, v)::s) n=
       (if (m = n) then SOME v else substLookup s n))`;


(*val substUpdate: forall 'v. nat -> 'v -> subst 'v -> maybe (subst 'v)*)
 val substUpdate_defn = Defn.Hol_multi_defns `
 ((substUpdate:num -> 'v ->(num#'v)list ->((num#'v)list)option) n v1 []=  NONE)
    /\ ((substUpdate:num -> 'v ->(num#'v)list ->((num#'v)list)option) n v1 ((m,v2)::s)=
       (if (n = m) then SOME ((m,v1)::s)
      else
        (case (substUpdate n v1 s) of
          NONE => NONE
        | SOME sNew => SOME ((m,v2)::sNew)
        )))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) substUpdate_defn;

(*val substAdd: forall 'v. nat -> 'v -> subst 'v -> subst 'v*)
 val _ = Define `
 ((substAdd:num -> 'v ->(num#'v)list ->(num#'v)list) n v s=
     ((case (substUpdate n v s) of
      SOME sNew => sNew
    | NONE => (n,v)::s
    )))`;


(* Matching a fp_pattern with the top-level of a value tree,
  if a matching exists an option with a substitution is returned.
  The matcher takes an additional substituion as argument to make sure
  that we do not double match a fp_pattern to different expressions
*)
(*val matchValTree: fp_pat -> fp_val -> subst fp_val -> maybe (subst fp_val)*)
 val matchValTree_defn = Defn.Hol_multi_defns `
 ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Word w1) (Fp_const w2) s=
     (if (w1 = w2) then SOME s else NONE))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Var n) v s=
       ((case substLookup s n of
        SOME v1 => if v1 = v then SOME s else NONE
      | NONE => SOME (substAdd n v s)
      )))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Unop op1 p) (Fp_uop op2 v) s=
       (if (op1 = op2)
      then matchValTree p v s
      else NONE))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Binop b1 p1 p2) (Fp_bop b2 v1 v2) s=
       (if (b1 = b2)
      then
        (case matchValTree p1 v1 s of
          NONE => NONE
        | SOME s1 => matchValTree p2 v2 s1
        )
      else NONE))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Terop t1 p1 p2 p3) (Fp_top t2 v1 v2 v3) s=
       (if (t1 = t2)
      then
        (case matchValTree p1 v1 s of
          NONE => NONE
        | SOME s1 =>
          (case matchValTree p2 v2 s1 of
            NONE => NONE
          | SOME s2 => matchValTree p3 v3 s2
          )
        )
      else NONE))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Scope sc1 p) (Fp_sc sc2 v) s=
       (if sc1 = sc2 then matchValTree p v s else NONE))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Pred pred1 p) (Fp_pred pred2 v) s=
       (if (pred1 = pred2) then matchValTree p v s else NONE))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) (Cmp cmp1 p1 p2) (Fp_cmp cmp2 v1 v2) s=
       (if (cmp1 = cmp2)
      then
        (case matchValTree p1 v1 s of
          NONE => NONE
        | SOME s1 => matchValTree p2 v2 s1
        )
      else NONE))
    /\ ((matchValTree:fp_pat -> fp_val ->(num#fp_val)list ->((num#fp_val)list)option) _ _ s=  NONE)`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) matchValTree_defn;

(* Instantiate a given fp_pattern with a substitution into a value tree *)
(*val instValTree: fp_pat -> subst fp_val -> maybe fp_val*)
 val instValTree_defn = Hol_defn "instValTree" `
 ((instValTree:fp_pat ->(num#fp_val)list ->(fp_val)option)f s= 
  ((case (f,s) of
       ( (Word w), s ) => SOME (Fp_const w)
     | ( (Var n), s ) => substLookup s n
     | ( (Unop u p), s ) => (case instValTree p s of
                                  NONE => NONE
                              | SOME v => SOME (Fp_uop u v)
                            )
     | ( (Binop op p1 p2), s ) => (case (instValTree p1 s, instValTree p2 s) of
                                        (SOME v1, SOME v2) => SOME
                                                                (Fp_bop 
                                                                 op v1 
                                                                 v2)
                                    | (_, _) => NONE
                                  )
     | ( (Terop op p1 p2 p3), s ) => (case (instValTree p1 s, instValTree 
                                                              p2 s , 
                                           instValTree p3 s) of
                                           (SOME v1, SOME v2, SOME v3) => 
                                     SOME (Fp_top op v1 v2 v3)
                                       | (_, _, _) => NONE
                                     )
     | ( (Scope sc p), s ) => (case instValTree p s of
                                    NONE => NONE
                                | SOME v => SOME (Fp_sc sc v)
                              )
     | ( (Pred pr p1), s ) => (case instValTree p1 s of
                                    NONE => NONE
                                | SOME v => SOME (Fp_pred pr v)
                              )
     | ( (Cmp cmp p1 p2), s ) => (case (instValTree p1 s, instValTree p2 s) of
                                       (SOME v1, SOME v2) => SOME
                                                               (Fp_cmp 
                                                                cmp v1 
                                                                v2)
                                   | (_, _) => NONE
                                 )
   )))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn instValTree_defn;

(* Define a floating-point rewrite as a pair of a source and target fp_pattern *)
val _ = type_abbrev( "fp_rw" , ``: (fp_pat # fp_pat)``);

(** Rewriting on value trees is done in the semantics by picking a fp_path
  that walks down the value tree structure and then applies the rewrite in place
  if it matches **)

(* Datatype for fp_paths into a value tree. Here is the leaf node meaning that the
  rewrite should be applied *)
val _ = Hol_datatype `
 fp_path =   Left of fp_path | Right of fp_path | Center of fp_path | Here`;


(*val maybe_map: forall 'v. ('v -> 'v) -> maybe 'v -> maybe 'v*)
 val _ = Define `
 ((maybe_map:('v -> 'v) -> 'v option -> 'v option) f NONE=  NONE)
    /\ ((maybe_map:('v -> 'v) -> 'v option -> 'v option) f (SOME res)=  (SOME (f res)))`;


(* Function rwFp_pathValTree b rw p v recurses through value tree v using fp_path p
  until p = Here or no further recursion is possible because of a mismatch.
  In case of a mismatch the function simply returns Nothing.
  Flag b is used to track whether we have passed an `opt` annotation allowing
  optimizations to be applied.
  Only if b is true, and p = Here, the rewrite rw is applied. *)
(*val rwFp_pathValTree: bool -> fp_rw -> fp_path -> fp_val -> maybe fp_val*)
 val rwFp_pathValTree_defn = Defn.Hol_multi_defns `
 ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) F rw Here v=  NONE)
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) T rw Here v=
       (let (lhs, rhs) = rw in
      (case matchValTree lhs v [] of
          NONE => NONE
        | SOME s => instValTree rhs s
      )))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Left p) (Fp_bop op v1 v2)=
       (maybe_map (\ v1 .  Fp_bop op v1 v2) (rwFp_pathValTree b rw p v1)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Right p) (Fp_bop op v1 v2)=
       (maybe_map (\ v2 .  Fp_bop op v1 v2) (rwFp_pathValTree b rw p v2)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Center p) (Fp_uop op v1)=
       (maybe_map (\ v .  Fp_uop op v) (rwFp_pathValTree b rw p v1)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Left p) (Fp_top op v1 v2 v3)=
       (maybe_map (\ v1 .  Fp_top op v1 v2 v3) (rwFp_pathValTree b rw p v1)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Center p) (Fp_top op v1 v2 v3)=
       (maybe_map (\ v2 .  Fp_top op v1 v2 v3) (rwFp_pathValTree b rw p v2)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Right p) (Fp_top op v1 v2 v3)=
       (maybe_map (\ v3 .  Fp_top op v1 v2 v3) (rwFp_pathValTree b rw p v3)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Center p) (Fp_sc sc v)=
       (maybe_map (\ v .  Fp_sc sc v) (rwFp_pathValTree ((sc = Opt) \/ b) rw p v)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Center p) (Fp_pred pr v)=
       (maybe_map (\ v .  Fp_pred pr v) (rwFp_pathValTree b rw p v)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Left p) (Fp_cmp cmp v1 v2)=
       (maybe_map (\ v1 .  Fp_cmp cmp v1 v2) (rwFp_pathValTree b rw p v1)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) b rw (Right p) (Fp_cmp cmp v1 v2)=
       (maybe_map (\ v2 .  Fp_cmp cmp v1 v2) (rwFp_pathValTree b rw p v2)))
    /\ ((rwFp_pathValTree:bool -> fp_pat#fp_pat -> fp_path -> fp_val ->(fp_val)option) _ _ _ _=  NONE)`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) rwFp_pathValTree_defn;

(* Datatype holding a single rewrite application in the form of a fp_path into the
  value tree and a number giving the index of the rewrite to be used *)
val _ = Hol_datatype `
 rewrite_app =   RewriteApp of fp_path => num`;
 (* which rewrite rule *)

(*val nth: forall 'v. list 'v -> nat -> maybe 'v*)
 val nth_defn = Defn.Hol_multi_defns `
 ((nth:'v list -> num -> 'v option) [] n=  NONE)
    /\ ((nth:'v list -> num -> 'v option) (x::xs) n=
       (if (n =( 0 : num)) then NONE
      else if (n =( 1 : num)) then SOME x
      else nth xs (n -( 1 : num))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) nth_defn;

(* rwAllValTree rwApps canOpt rws v applies all the rewrite_app's in rwApps to
    value tree v using rwFp_pathValTree *)
(*val rwAllValTree: list rewrite_app -> bool -> list fp_rw -> fp_val -> maybe fp_val*)
 val rwAllValTree_defn = Defn.Hol_multi_defns `
 ((rwAllValTree:(rewrite_app)list -> bool ->(fp_pat#fp_pat)list -> fp_val ->(fp_val)option) [] canOpt rws v=  (SOME v))
    /\ ((rwAllValTree:(rewrite_app)list -> bool ->(fp_pat#fp_pat)list -> fp_val ->(fp_val)option) ((RewriteApp p n)::rs) canOpt rws v=
       ((case nth rws n of
        NONE => NONE
      | SOME rw =>
        (case rwFp_pathValTree canOpt rw p v of
          NONE => NONE
        | SOME vNew => rwAllValTree rs canOpt rws vNew
        )
      )))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) rwAllValTree_defn;val _ = export_theory()
