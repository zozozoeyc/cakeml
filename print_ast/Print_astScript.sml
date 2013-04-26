(*Generated by Lem from print_ast/print_ast.lem.*)
open bossLib Theory Parse res_quanTheory
open fixedPointTheory finite_mapTheory listTheory pairTheory pred_setTheory
open integerTheory set_relationTheory sortingTheory stringTheory wordsTheory

val _ = numLib.prefer_num();



open AstTheory MiniMLTheory TokensTheory

val _ = new_theory "Print_ast"

(*open MiniML*)
(*open Tokens*)

(*val Num : Int.int -> num*)

(*val CHR : num -> string*)

(*val string_first : string -> string*)

(*val first_ord : string -> num*)

(*val (%) : num -> num -> num*)

 val num_to_string_defn = Hol_defn "num_to_string" `
 (num_to_string n acc =
  if n = 0 then
    acc
  else
    num_to_string (n DIV 10) ( STRCAT ( STRING (CHR  (n MOD 10 + 48)) "")  acc))`;

val _ = Defn.save_defn num_to_string_defn;

(*val int_to_string : Int.int -> string*)
val _ = Define `
 (int_to_string n =
  if n = & 0 then
    "0"
  else if int_gt n ( & 0) then
    num_to_string ( Num n) ""
  else STRCAT 
    "~" ( num_to_string ( Num ( (int_sub) ( & 0) n)) ""))`;


(*val spaces : num -> string -> string*)
 val spaces_defn = Hol_defn "spaces" `
 
(spaces n s =
  if (n:num) = 0 then
    s
  else STRCAT 
    " "  (spaces (n - 1) s))`;

val _ = Defn.save_defn spaces_defn;

val _ = Define `
 (space_append s1 s2 =
  if s2 = "" then
    s1
  else 
    let f = STRING (SUB ( s2,0)) "" in
      if (f = ")") \/ (f = " ") \/ (f = ",") then STRCAT 
    s1  s2
  else STRCAT 
    s1 ( STRCAT   " "  s2))`;


 val tok_to_string_def = Define `

(tok_to_string NewlineT s = STRCAT  "\n"  s)
/\
(tok_to_string (WhitespaceT n) s = spaces n s)
/\
(tok_to_string (IntT i) s = space_append (int_to_string i) s)
/\
(tok_to_string (LongidT id) s = space_append id s)
/\
(tok_to_string (TyvarT tv) s = space_append ( STRCAT "'"  tv) s)
/\
(tok_to_string AndT s = STRCAT  "and "  s)
/\
(tok_to_string AndalsoT s = STRCAT  "andalso "  s)
/\
(tok_to_string CaseT s = STRCAT  "case "  s)
/\
(tok_to_string DatatypeT s = STRCAT  "datatype "  s)
/\
(tok_to_string ElseT s = STRCAT  "else "  s)
/\
(tok_to_string EndT s = STRCAT  "end "  s)
/\
(tok_to_string FnT s = STRCAT  "fn "  s)
/\
(tok_to_string FunT s = STRCAT  "fun "  s)
/\
(tok_to_string IfT s = STRCAT  "if "  s)
/\
(tok_to_string InT s = STRCAT  "in "  s)
/\
(tok_to_string LetT s = STRCAT  "let "  s)
/\
(tok_to_string OfT s = STRCAT  "of "  s)
/\
(tok_to_string OpT s = STRCAT  "op "  s)
/\
(tok_to_string OrelseT s = STRCAT  "orelse "  s)
/\
(tok_to_string RecT s = STRCAT  "rec "  s)
/\
(tok_to_string ThenT s = STRCAT  "then "  s)
/\
(tok_to_string ValT s = STRCAT  "val "  s)
/\
(tok_to_string LparT s = 
  if s = "" then
    "("
  else if STRING (SUB ( s,0)) "" = "*" then STRCAT 
    "( "  s
  else STRCAT 
    "("  s)
/\
(tok_to_string RparT s = space_append ")" s)
/\
(tok_to_string CommaT s = STRCAT  ", "  s)
/\
(tok_to_string SemicolonT s = STRCAT  ";"  s)
/\
(tok_to_string BarT s = STRCAT  "| "  s)
/\
(tok_to_string EqualsT s = STRCAT  "= "  s)
/\
(tok_to_string DarrowT s = STRCAT  "=> "  s)
/\
(tok_to_string ArrowT s = STRCAT  "-> "  s)
/\
(tok_to_string StarT s = STRCAT  "* "  s)
/\
(tok_to_string TypeT s = STRCAT  "type "  s)
/\
(tok_to_string WithT s = STRCAT  "with "  s)`;


 val tok_list_to_string_defn = Hol_defn "tok_list_to_string" `
 
(tok_list_to_string [] = "")
/\
(tok_list_to_string (t::l) = 
  tok_to_string t (tok_list_to_string l))`;

val _ = Defn.save_defn tok_list_to_string_defn;

(*type 'a tree = L of 'a | N of 'a tree * 'a tree*)
val _ = Hol_datatype `
 tok_tree = L of token | N of tok_tree => tok_tree`;


(*val (^^) : forall 'a. 'a tree -> 'a tree -> 'a tree*)
(*val (^^) : tok_tree -> tok_tree -> tok_tree*)

(*val tree_to_list : forall 'a. 'a tree -> 'a list -> 'a list*)
(*val tree_to_list : tok_tree -> list token -> list token*)
 val tree_to_list_defn = Hol_defn "tree_to_list" `

(tree_to_list (L x) acc = x ::acc)
/\
(tree_to_list (N x1 x2) acc = tree_to_list x1 (tree_to_list x2 acc))`;

val _ = Defn.save_defn tree_to_list_defn;

(* Should include "^", but I don't know how to get that into HOL, since
 * antiquote seem stronger than strings.  See the specification in
 * print_astProofsScript. *)
val _ = Define `
 (is_sml_infix s =
  let c = ORD (SUB ( s,0)) in
    if c < 65 (* "A" *) then
      if c < 60 (* "<" *) then
        (s = "*") \/
        (s = "+") \/ 
        (s = "-") \/
        (s = "/") \/
        (s = "::") \/ 
        (s = ":=")
      else
        (s = "<") \/ 
        (s = "<=") \/ 
        (s = "<>") \/
        (s = "=") \/ 
        (s = ">") \/ 
        (s = ">=") \/ 
        (s = "@")
    else
      if c < 109 (* "m" *) then
        if c < 100 then
          s = "before"
        else
          s = "div" 
      else
        if c < 111 then
          s = "mod"
        else
          s = "o")`;


(*val join_trees : forall 'a. 'a tree -> 'a tree list -> 'a tree*)
(*val join_trees : tok_tree -> list tok_tree -> tok_tree*)
 val join_trees_defn = Hol_defn "join_trees" `

(join_trees sep [x] = x)
/\
(join_trees sep (x::y::l) = N 
  x (N   sep  (join_trees sep (y ::l))))`;

val _ = Defn.save_defn join_trees_defn;

 val lit_to_tok_tree_def = Define `

(lit_to_tok_tree (Bool T) = L (LongidT "true"))
/\
(lit_to_tok_tree (Bool F) = L (LongidT "false"))
/\
(lit_to_tok_tree (IntLit n) = L (IntT n))
/\
(lit_to_tok_tree Unit = N (L LparT) (L RparT))`;


val _ = Define `
 (var_to_tok_tree v =
  if is_sml_infix v then N 
    (L OpT)  (L (LongidT v))
  else
    L (LongidT v))`;


val _ = Define `
 (id_to_tok_tree v =
  (case v of
      Short v =>
        L (LongidT v)
    | Long m v =>
        L (LongidT ( STRCAT m ( STRCAT   "."  v)))
  ))`;


 val pat_to_tok_tree_defn = Hol_defn "pat_to_tok_tree" `

(pat_to_tok_tree (Pvar v) = var_to_tok_tree v)
/\
(pat_to_tok_tree (Plit l) = lit_to_tok_tree l)
/\
(pat_to_tok_tree (Pcon c []) = id_to_tok_tree c)
/\
(pat_to_tok_tree (Pcon c ps) = N 
  (L LparT) (N ( id_to_tok_tree c) (N   
    (L LparT) (N ( join_trees (L CommaT) ( MAP pat_to_tok_tree ps)) (N  
    (L RparT)  (L RparT))))))
/\
(pat_to_tok_tree (Pref p) = N 
  (L LparT) (N   (L (LongidT "ref")) (N   (pat_to_tok_tree p)  (L RparT))))`;

val _ = Defn.save_defn pat_to_tok_tree_defn;

val _ = Define `
 (inc_indent i = 
  if (i:num) < 30 then
    i + 2
  else
    i)`;


val _ = Define `
 (newline indent = N  
  (L NewlineT)  (L (WhitespaceT indent)))`;


 val exp_to_tok_tree_defn = Hol_defn "exp_to_tok_tree" `

(exp_to_tok_tree indent (Raise r) = N 
  (L LparT) (N   (L (LongidT "raise")) (N   (L (LongidT "Bind"))  (L RparT))))
/\
(exp_to_tok_tree indent (Lit l) =
  lit_to_tok_tree l)
/\
(exp_to_tok_tree indent (Con c []) =
  id_to_tok_tree c)
/\
(exp_to_tok_tree indent (Con c es) = N 
  (L LparT) (N
  (
  id_to_tok_tree c) (N   
  (L LparT) (N
  (
  join_trees (L CommaT) ( MAP (exp_to_tok_tree indent) es)) (N   
  (L RparT)  (L RparT))))))
/\
(exp_to_tok_tree indent (Var vid) =
  id_to_tok_tree vid)
/\
(exp_to_tok_tree indent (Fun v e) = N
  (
  newline indent) (N  
  (L LparT) (N  
  (L FnT) (N
  (
  var_to_tok_tree v) (N   
  (L DarrowT) (N   
  (exp_to_tok_tree (inc_indent indent) e)  
  (L RparT)))))))
/\
(exp_to_tok_tree indent (Uapp uop e) =
  let s = 
    (case uop of
        Opref => "ref"
      | Opderef => "!"
    )
  in N 
    (L LparT) (N  
    (L (LongidT s)) (N  
    (exp_to_tok_tree indent e) 
    (L RparT))))
/\
(exp_to_tok_tree indent (App Opapp e1 e2) = N 
  (L LparT) (N  
  (exp_to_tok_tree indent e1) (N   
  (exp_to_tok_tree indent e2)  
  (L RparT))))
/\
(exp_to_tok_tree indent (App Equality e1 e2) = N 
  (L LparT) (N  
  (exp_to_tok_tree indent e1) (N   
  (L EqualsT) (N   
  (exp_to_tok_tree indent e2)  
  (L RparT)))))
/\
(exp_to_tok_tree indent (App (Opn o0) e1 e2) =
  let s = (case o0 of
      Plus => "+"
    | Minus => "-"
    | Times => "*"
    | Divide => "div"
    | Modulo => "mod"
  )
  in N 
    (L LparT) (N  
    (exp_to_tok_tree indent e1) (N   
    (L (LongidT s)) (N   
    (exp_to_tok_tree indent e2)  
    (L RparT)))))
/\
(exp_to_tok_tree indent (App (Opb o') e1 e2) =
  let s = (case o' of
      Lt => "<"
    | Gt => ">"
    | Leq => "<="
    | Geq => ">"
  )
  in N 
    (L LparT) (N  
    (exp_to_tok_tree indent e1) (N   
    (L (LongidT s)) (N   
    (exp_to_tok_tree indent e2)  
    (L RparT)))))
/\
(exp_to_tok_tree indent (App Opassign e1 e2) = N 
  (L LparT) (N  
  (exp_to_tok_tree indent e1) (N   
  (L (LongidT ":=")) (N   
  (exp_to_tok_tree indent e2)  
  (L RparT)))))
/\
(exp_to_tok_tree indent (Log lop e1 e2) = N 
  (L LparT) (N  
  (exp_to_tok_tree indent e1)(N   
  (if lop = And then 
     L AndalsoT
   else 
     L OrelseT) (N  
  (exp_to_tok_tree indent e2)  
  (L RparT)))))
/\
(exp_to_tok_tree indent (If e1 e2 e3) = N
  (
  newline indent) (N  
  (L LparT) (N  
  (L IfT) (N  
  (exp_to_tok_tree indent e1) (N 
  ( 
  newline indent) (N  
  (L ThenT) (N  
  (exp_to_tok_tree (inc_indent indent) e2) (N
  (
  newline indent) (N  
  (L ElseT) (N  
  (exp_to_tok_tree (inc_indent indent) e3)  
  (L RparT)))))))))))
/\
(exp_to_tok_tree indent (Mat e pes) = N
  (
  newline indent) (N  
  (L LparT) (N  
  (L CaseT) (N   
  (exp_to_tok_tree indent e) (N   
  (L OfT) (N
  (
  newline (inc_indent (inc_indent indent))) (N
  (
  join_trees ( N(newline (inc_indent indent))  (L BarT)) 
               ( MAP (pat_exp_to_tok_tree (inc_indent indent)) pes))  
  (L RparT))))))))
/\
(exp_to_tok_tree indent (Let v e1 e2) = N
  (
  newline indent) (N  
  (L LetT) (N   (L ValT) (N 
  ( 
  var_to_tok_tree v) (N   
  (L EqualsT) (N  
  (exp_to_tok_tree indent e1) (N 
  ( 
  newline indent) (N  
  (L InT) (N  
  (exp_to_tok_tree (inc_indent indent) e2) (N 
  ( 
  newline indent)  (L EndT)))))))))))
/\
(exp_to_tok_tree indent (Letrec funs e) = N
  (
  newline indent) (N  
  (L LetT) (N   (L FunT) (N 
  ( 
  join_trees ( N(newline indent)  (L AndT)) 
               ( MAP (fun_to_tok_tree indent) funs)) (N 
  ( 
  newline indent) (N  
  (L InT) (N  
  (exp_to_tok_tree indent e) (N 
  ( 
  newline indent)  (L EndT)))))))))
/\
(pat_exp_to_tok_tree indent (p,e) = N
  (
  pat_to_tok_tree p) (N   
  (L DarrowT) 
  (exp_to_tok_tree (inc_indent (inc_indent indent)) e)))
/\
(fun_to_tok_tree indent (v1,v2,e) = N
  (
  var_to_tok_tree v1) (N
  (
  var_to_tok_tree v2) (N   
  (L EqualsT) 
  (exp_to_tok_tree (inc_indent indent) e))))`;

val _ = Defn.save_defn exp_to_tok_tree_defn;

 val tc_to_tok_tree_def = Define `

(tc_to_tok_tree TC_int =
  L (LongidT "int"))
/\
(tc_to_tok_tree TC_bool =
  L (LongidT "bool"))
/\
(tc_to_tok_tree TC_unit =
  L (LongidT "unit"))
/\
(tc_to_tok_tree TC_ref =
  L (LongidT "ref"))`;


 val type_to_tok_tree_defn = Hol_defn "type_to_tok_tree" `

(type_to_tok_tree (Tvar tn) =
  L (TyvarT tn))
/\
(type_to_tok_tree (Tapp [t1;t2] TC_fn) = N 
  (L LparT) (N   (type_to_tok_tree t1) (N   (L ArrowT) (N   (type_to_tok_tree t2)  
  (L RparT)))))
/\
(type_to_tok_tree (Tapp ts tc0) =
  if ts = [] then
    (tc_to_tok_tree tc0)
  else N 
    (L LparT) (N
    (
    join_trees (L CommaT) ( MAP type_to_tok_tree ts)) (N   (L RparT)  
    (tc_to_tok_tree tc0))))`;

val _ = Defn.save_defn type_to_tok_tree_defn;

val _ = Define `
 (variant_to_tok_tree (c,ts) =
  if ts = [] then
    var_to_tok_tree c 
  else N
    (
    var_to_tok_tree c) (N   (L OfT) 
    ( 
    join_trees (L StarT) ( MAP type_to_tok_tree ts))))`;


(*val typedef_to_tok_tree : num -> tvarN list * typeN * (conN * t list) list -> token tree*)
(*val typedef_to_tok_tree : num -> list tvarN * typeN * list (conN * list t) -> tok_tree*)
val _ = Define `
 (typedef_to_tok_tree indent (tvs, name, variants) = N 
  (if tvs = [] then 
     L (LongidT name)
   else N  
     (L LparT) (N 
     ( 
     join_trees (L CommaT) ( MAP (\ tv . L (TyvarT tv)) tvs)) (N   
     (L RparT) 
     (L (LongidT name))))) (N   
  (L EqualsT) (N
  (
  newline (inc_indent (inc_indent indent)))
  (
  join_trees ( N(newline (inc_indent indent))  (L BarT)) 
               ( MAP variant_to_tok_tree variants)))))`;


 val dec_to_tok_tree_def = Define `
 
(dec_to_tok_tree indent (Dlet p e) = N 
  (L ValT) (N
  (
  pat_to_tok_tree p) (N   
  (L EqualsT) (N
  (
  exp_to_tok_tree (inc_indent indent) e) 
  (L SemicolonT)))))
/\
(dec_to_tok_tree indent (Dletrec funs) = N 
  (L FunT) (N 
  ( 
  join_trees ( N(newline indent)  (L AndT)) 
             ( MAP (fun_to_tok_tree indent) funs)) 
  (L SemicolonT)))
/\
(dec_to_tok_tree indent (Dtype types) = N 
  (L DatatypeT) (N 
  ( 
  join_trees ( N(newline indent)  (L AndT)) 
             ( MAP (typedef_to_tok_tree indent) types)) 
  (L SemicolonT)))`;


val _ = Define `
 (dec_to_sml_string d = 
  tok_list_to_string (tree_to_list (dec_to_tok_tree 0 d) []))`;

val _ = export_theory()

