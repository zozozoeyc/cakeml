open HolKernel boolLib bossLib

open pred_setTheory
open pegTheory cmlPEGTheory gramTheory gramPropsTheory
open lcsymtacs boolSimps
open preamble
open mp_then

open pegSoundTheory

val _ = new_theory "pegComplete"
val _ = set_grammar_ancestry ["pegSound"]

val _ = set_trace "Goalstack.print_goal_at_top" 0


val MAP_EQ_CONS = Q.prove(
  `MAP f l = h::t <=> ∃h0 t0. l = h0::t0 ∧ f h0 = h ∧ MAP f t0 = t`,
  metis_tac[MAP_EQ_CONS])

fun FIXEQ_CONV t = let
  val (l,r) = dest_eq t
in
  if null (free_vars l) andalso not (null (free_vars r)) then
    REWR_CONV EQ_SYM_EQ
  else NO_CONV
end t

val FIXEQ_TAC = CONV_TAC (DEPTH_CONV FIXEQ_CONV) >>
                RULE_ASSUM_TAC (CONV_RULE (DEPTH_CONV FIXEQ_CONV))

fun simp thl = lcsymtacs.simp thl >> FIXEQ_TAC
fun fs thl = lcsymtacs.fs thl >> FIXEQ_TAC


fun PULLV v t = let
  val (bv,b) = dest_abs(rand t)
in
  if bv = v then ALL_CONV
  else BINDER_CONV (PULLV v) THENC SWAP_VARS_CONV
end t

fun REFINE_EXISTS_TAC t (asl, w) = let
  val (qvar, body) = dest_exists w
  val ctxt = free_varsl (w::asl)
  val qvars = set_diff (free_vars t) ctxt
  val newgoal = subst [qvar |-> t] body
  fun chl [] ttac = ttac
    | chl (h::t) ttac = X_CHOOSE_THEN h (chl t ttac)
in
  SUBGOAL_THEN
    (list_mk_exists(rev qvars, newgoal))
    (chl (rev qvars) (fn th => Tactic.EXISTS_TAC t THEN ACCEPT_TAC th))
    (asl, w)
end


fun unify_firstconj k th (g as (asl,w)) = let
  val (exvs, body) = strip_exists w
  val c = hd (strip_conj body)
  val (favs, fabody) = strip_forall (concl th)
  val con = #2 (dest_imp fabody)
  val theta = Unify.simp_unify_terms (set_diff (free_vars c) exvs) c con
  fun inst_exvs theta =
      case theta of
          [] => ALL_TAC
        | {redex,residue} :: rest =>
          if mem redex exvs andalso null (intersect (free_vars residue) exvs)
          then
            if null (intersect (free_vars residue) favs) then
              CONV_TAC (PULLV redex) THEN EXISTS_TAC residue THEN
              inst_exvs rest
            else CONV_TAC (PULLV redex) THEN REFINE_EXISTS_TAC residue THEN
                 inst_exvs rest
          else inst_exvs rest
  fun inst_favs theta th =
      case theta of
          [] => k th
        | {redex,residue} :: rest =>
          if mem redex favs then
            inst_favs rest (th |> CONV_RULE (PULLV redex) |> SPEC residue)
          else inst_favs rest th
in
  inst_exvs theta THEN inst_favs theta th
end g


val _ = augment_srw_ss [rewrites [
  peg_eval_seql_CONS, peg_eval_tok_SOME, tokeq_def, bindNT_def, mktokLf_def,
  peg_eval_choicel_CONS, pegf_def, peg_eval_seq_SOME, pnt_def, peg_eval_try,
  try_def]]

val has_length = assert (can (find_term (same_const listSyntax.length_tm)) o
                         concl)

val peg_eval_choice_NONE =
  ``peg_eval G (i, choice s1 s2 f) NONE``
    |> SIMP_CONV (srw_ss()) [Once peg_eval_cases]

val disjImpI = Q.prove(`~p \/ q ⇔ p ⇒ q`, DECIDE_TAC)

val ptree_head_eq_tok0 = Q.prove(
  `(ptree_head pt = TOK tk) ⇔ (pt = Lf (TOK tk))`,
  Cases_on `pt` >> simp[]);
val ptree_head_eq_tok = save_thm(
  "ptree_head_eq_tok",
  CONJ ptree_head_eq_tok0
       (CONV_RULE (LAND_CONV (REWR_CONV EQ_SYM_EQ)) ptree_head_eq_tok0))
val _ = export_rewrites ["ptree_head_eq_tok"]

open NTpropertiesTheory
val firstSet_nUQTyOp = Q.store_thm(
  "firstSet_nUQTyOp[simp]",
  `firstSet cmlG (NN nUQTyOp::rest) = {AlphaT s | T} ∪ {SymbolT s | T}`,
  simp[Once firstSet_NT, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSet_nTyOp = Q.store_thm(
  "firstSet_nTyOp[simp]",
  `firstSet cmlG (NN nTyOp :: rest) =
      {AlphaT s | T} ∪ {SymbolT s | T} ∪ {LongidT s1 s2 | T}`,
  simp[Once firstSet_NT, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSet_nTyVarList = Q.store_thm(
  "firstSet_nTyVarList[simp]",
  `firstSet cmlG [NT (mkNT nTyVarList)] = { TyvarT s | T }`,
  simp[firstSetML_eqn] >> simp[firstSetML_def] >>
  simp[cmlG_applied, cmlG_FDOM] >> simp[firstSetML_def] >>
  simp[cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM] >>
  simp[firstSetML_def]);
val _ =
    firstSetML_def |> CONJUNCTS |> (fn l => List.take(l,2)) |> rewrites
                   |> (fn ss => augment_srw_ss [ss])

val firstSet_nLetDec = Q.store_thm(
  "firstSet_nLetDec[simp]",
  `firstSet cmlG [NT (mkNT nLetDec)] = {ValT; FunT}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_FDOM,
       cmlG_applied, INSERT_UNION_EQ]);

val firstSet_nLetDecs = Q.store_thm(
  "firstSet_nLetDecs[simp]",
  `firstSet cmlG [NT (mkNT nLetDecs)] = {ValT; FunT; SemicolonT}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_FDOM,
       cmlG_applied] >>
  simp[Once firstSetML_def, cmlG_FDOM, cmlG_applied, INSERT_UNION_EQ]);

val firstSet_nTypeDec = Q.store_thm(
  "firstSet_nTypeDec[simp]",
  `firstSet cmlG [NT (mkNT nTypeDec)] = {DatatypeT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied]);

val firstSet_nTypeAbbrevDec = Q.store_thm(
  "firstSet_nTypeAbbrevDec[simp]",
  `firstSet cmlG [NT (mkNT nTypeAbbrevDec)] = {TypeT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied])

val firstSet_nDecl = Q.store_thm(
  "firstSet_nDecl[simp]",
  `firstSet cmlG [NT (mkNT nDecl)] =
      {ValT; FunT; DatatypeT;ExceptionT;TypeT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied,
       INSERT_UNION_EQ]);

val firstSet_nDecls = Q.store_thm(
  "firstSet_nDecls[simp]",
  `firstSet cmlG [NN nDecls] =
      {ValT; DatatypeT; FunT; SemicolonT; ExceptionT; TypeT}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_applied, cmlG_FDOM] >>
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM] >>
  ONCE_REWRITE_TAC [firstSetML_def] >>
  simp[cmlG_applied, cmlG_FDOM, INSERT_UNION_EQ, INSERT_COMM]);

val firstSet_nMultOps = Q.store_thm(
  "firstSet_nMultOps[simp]",
  `firstSet cmlG (NT (mkNT nMultOps)::rest) =
      {AlphaT "div"; AlphaT"mod"; StarT; SymbolT "/"}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_FDOM, cmlG_applied,
       INSERT_UNION_EQ]);

val firstSet_nRelOps = Q.store_thm(
  "firstSet_nRelOps[simp]",
  `firstSet cmlG (NT (mkNT nRelOps)::rest) =
      {SymbolT "<"; SymbolT ">"; SymbolT "<="; SymbolT ">="; SymbolT "<>";
       EqualsT}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSet_nAddOps = Q.store_thm(
  "firstSet_nAddOps[simp]",
  `firstSet cmlG (NT (mkNT nAddOps)::rest) = {SymbolT "+"; SymbolT "-"}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_applied, cmlG_FDOM,
       INSERT_UNION_EQ]);

val firstSet_nCompOps = Q.store_thm(
  "firstSet_nCompOps[simp]",
  `firstSet cmlG (NT (mkNT nCompOps)::rest) = {AlphaT "o"; SymbolT ":="}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_FDOM, cmlG_applied,
       INSERT_UNION_EQ])

val firstSet_nListOps = Q.store_thm(
  "firstSet_nListOps[simp]",
  `firstSet cmlG (NT (mkNT nListOps)::rest) = {SymbolT "::"; SymbolT "@"}`,
  simp[firstSetML_eqn, Once firstSetML_def, cmlG_FDOM, cmlG_applied,
       INSERT_UNION_EQ, INSERT_COMM])

val firstSet_nUQTyOp = Q.store_thm(
  "firstSet_nUQTyOp",
  `firstSet cmlG [NT (mkNT nUQTyOp)] = { AlphaT l | T } ∪ { SymbolT l | T }`,
  dsimp[EXTENSION, EQ_IMP_THM, firstSet_def] >> rpt conj_tac >>
  simp[Once relationTheory.RTC_CASES1, cmlG_applied, cmlG_FDOM] >>
  dsimp[]);

val firstSet_nStructure = Q.store_thm(
  "firstSet_nStructure[simp]",
  `firstSet cmlG [NT (mkNT nStructure)] = {StructureT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied]);


val firstSet_nTopLevelDec = Q.store_thm(
  "firstSet_nTopLevelDec[simp]",
  `firstSet cmlG [NT (mkNT nTopLevelDec)] =
    {ValT; FunT; DatatypeT; StructureT; ExceptionT; TypeT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied, INSERT_UNION_EQ, INSERT_COMM]);

val firstSet_nSpecLine = Q.store_thm(
  "firstSet_nSpecLine[simp]",
  `firstSet cmlG [NT (mkNT nSpecLine)] = {ValT; DatatypeT; TypeT; ExceptionT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied, INSERT_UNION_EQ, INSERT_COMM]);

val firstSet_nSpecLineList = Q.store_thm(
  "firstSet_nSpecLineList[simp]",
  `firstSet cmlG [NT (mkNT nSpecLineList)] =
      {ValT; DatatypeT; TypeT; SemicolonT; ExceptionT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied] >>
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied,
       INSERT_UNION_EQ, INSERT_COMM]);

val firstSet_nV = Q.store_thm(
  "firstSet_nV",
  `firstSet cmlG (NN nV:: rest) =
      { AlphaT s | s ≠ "" ∧ ¬isUpper (HD s) ∧ s ≠ "before" ∧ s ≠ "div" ∧
                   s ≠ "mod" ∧ s ≠ "o" ∧ s ≠ "true" ∧ s ≠ "false" ∧ s ≠ "ref" ∧
                   s ≠ "nil"} ∪
      { SymbolT s | s ≠ "+" ∧ s ≠ "*" ∧ s ≠ "-" ∧ s ≠ "/" ∧ s ≠ "<" ∧ s ≠ ">" ∧
                    s ≠ "<=" ∧ s ≠ ">=" ∧ s ≠ "<>" ∧ s ≠ ":=" ∧ s ≠ "::" ∧
                    s ≠ "@"}`,
  simp[Once firstSet_NT, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSet_nFQV = Q.store_thm(
  "firstSet_nFQV",
  `firstSet cmlG [NT (mkNT nFQV)] =
      firstSet cmlG [NT (mkNT nV)] ∪
      { LongidT m i | (m,i) | i ≠ "" ∧ (isAlpha (HD i) ⇒ ¬isUpper (HD i)) ∧
                              i ∉ {"true"; "false"; "ref"; "nil"}}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied] >>
  dsimp[Once EXTENSION]);

val firstSet_nConstructorName = Q.store_thm(
  "firstSet_nConstructorName",
  `firstSet cmlG (NN nConstructorName :: rest) =
      { LongidT str s | (str,s) | s ≠ "" ∧ isAlpha (HD s) ∧ isUpper (HD s) ∨
                                  s ∈ {"true"; "false"; "ref"; "nil"}} ∪
      { AlphaT s | s ≠ "" ∧ isUpper (HD s) } ∪
      { AlphaT s | s ∈ {"true"; "false"; "ref"; "nil"}}`,
  ntac 2 (simp [Once firstSet_NT, cmlG_applied, cmlG_FDOM]) >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSetML_nConstructorName = Q.store_thm(
  "firstSetML_nConstructorName[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ⇒
    (firstSetML cmlG sn (NN nConstructorName::rest) =
     firstSet cmlG [NN nConstructorName])`,
  simp[firstSetML_eqn] >>
  ntac 2 (simp[firstSetML_def] >> simp[cmlG_applied, cmlG_FDOM]) >>
  strip_tac >> simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[firstSetML_def]);

val firstSetML_nV = Q.store_thm(
  "firstSetML_nV[simp]",
  `mkNT nV ∉ sn ⇒
    (firstSetML cmlG sn (NN nV::rest) = firstSet cmlG [NN nV])`,
  simp[firstSetML_eqn] >> simp[firstSetML_def] >>
  simp[cmlG_FDOM, cmlG_applied] >> strip_tac >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSetML_nFQV = Q.store_thm(
  "firstSetML_nFQV[simp]",
  `mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ⇒
    (firstSetML cmlG sn (NN nFQV::rest) = firstSet cmlG [NN nFQV])`,
  simp[firstSetML_eqn] >>
  ntac 2 (simp[firstSetML_def] >> simp[cmlG_FDOM, cmlG_applied]) >>
  strip_tac >> simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSet_nEtuple = Q.store_thm(
  "firstSet_nEtuple[simp]",
  `firstSet cmlG [NT (mkNT nEtuple)] = {LparT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied]);

val firstSet_nEliteral = Q.store_thm(
  "firstSet_nEliteral[simp]",
  `firstSet cmlG [NT (mkNT nEliteral)] =
     {IntT i | T} ∪ {StringT s | T} ∪ {CharT c | T} ∪ {WordT w | T}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied] >>
  dsimp[Once EXTENSION] >> gen_tac >> eq_tac >> rw[]);

val firstSetML_nEliteral = Q.store_thm(
  "firstSetML_nEliteral[simp]",
  ‘mkNT nEliteral ∉ sn ⇒
     firstSetML cmlG sn (NT (mkNT nEliteral)::rest) =
     firstSet cmlG [NT (mkNT nEliteral)]’,
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION] >> metis_tac[]);

val firstSet_nEbase = Q.store_thm(
  "firstSet_nEbase[simp]",
  `firstSet cmlG [NT (mkNT nEbase)] =
      {LetT; LparT; LbrackT; OpT} ∪ firstSet cmlG [NT (mkNT nFQV)] ∪
      firstSet cmlG [NT (mkNT nEliteral)] ∪
      firstSet cmlG [NT (mkNT nConstructorName)]`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied] >>
  dsimp[Once EXTENSION] >> gen_tac >> eq_tac >> rw[] >> simp[]);

val firstSetML_nEbase = Q.store_thm(
  "firstSetML_nEbase[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEliteral ∉ sn ⇒
    firstSetML cmlG sn (NT (mkNT nEbase)::rest) =
    firstSet cmlG [NT (mkNT nEbase)]`,
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM] >> strip_tac >>
  Cases_on `mkNT nEtuple ∈ sn` >>
  simp[Once firstSetML_def, cmlG_FDOM, cmlG_applied] >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSet_nEapp = Q.store_thm(
  "firstSet_nEapp[simp]",
  `firstSet cmlG [NT (mkNT nEapp)] = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[Once firstSetML_eqn, SimpLHS] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]) >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSetML_nEapp = Q.store_thm(
  "firstSetML_nEapp[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEliteral ∉ sn
   ⇒
    firstSetML cmlG sn (NT (mkNT nEapp) :: rest) =
    firstSet cmlG [NT(mkNT nEbase)]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]) >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSet_nEmult = Q.store_thm(
  "firstSet_nEmult[simp]",
  `firstSet cmlG [NT (mkNT nEmult)] = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nEmult = Q.store_thm(
  "firstSetML_nEmult[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEliteral ∉ sn
  ⇒
    firstSetML cmlG sn (NT (mkNT nEmult) :: rest) =
    firstSet cmlG [NT (mkNT nEbase)]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nEadd = Q.store_thm(
  "firstSet_nEadd[simp]",
  `firstSet cmlG [NT (mkNT nEadd)] = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nEadd = Q.store_thm(
  "firstSetML_nEadd[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nEliteral ∉ sn⇒
    firstSetML cmlG sn (NT (mkNT nEadd) :: rest) =
    firstSet cmlG [NT(mkNT nEbase)]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nElistop = Q.store_thm(
  "firstSet_nElistop[simp]",
  `firstSet cmlG (NT (mkNT nElistop)::rest) =
       firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nElistop = Q.store_thm(
  "firstSetML_nElistop[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nElistop ∉ sn ∧
    mkNT nEliteral ∉ sn
   ⇒
    firstSetML cmlG sn (NT (mkNT nElistop) :: rest) =
    firstSet cmlG [NT(mkNT nEbase)]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nErel = Q.store_thm(
  "firstSet_nErel[simp]",
  `firstSet cmlG (NT(mkNT nErel)::rest) = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nErel = Q.store_thm(
  "firstSetML_nErel[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nElistop ∉ sn ∧
    mkNT nEliteral ∉ sn
   ⇒
    firstSetML cmlG sn (NT (mkNT nErel) :: rest) = firstSet cmlG [NN nEbase]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nEcomp = Q.store_thm(
  "firstSet_nEcomp[simp]",
  `firstSet cmlG (NT(mkNT nEcomp)::rest) = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nEcomp = Q.store_thm(
  "firstSetML_nEcomp[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nElistop ∉ sn ∧ mkNT nEliteral ∉ sn ⇒
    firstSetML cmlG sn (NT (mkNT nEcomp) :: rest) = firstSet cmlG [NN nEbase]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nEbefore = Q.store_thm(
  "firstSet_nEbefore[simp]",
  `firstSet cmlG (NT(mkNT nEbefore)::rest) =
      firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nEbefore = Q.store_thm(
  "firstSetML_nEbefore[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nEbefore ∉ sn ∧ mkNT nElistop ∉ sn ∧ mkNT nEliteral ∉ sn ⇒
    firstSetML cmlG sn (NT (mkNT nEbefore)::rest) = firstSet cmlG [NN nEbase]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nEtyped = Q.store_thm(
  "firstSet_nEtyped[simp]",
  `firstSet cmlG (NT(mkNT nEtyped)::rest) = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nEtyped = Q.store_thm(
  "firstSetML_nEtyped[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nEbefore ∉ sn ∧ mkNT nEtyped ∉ sn ∧ mkNT nElistop ∉ sn ∧
    mkNT nEliteral ∉ sn
   ⇒
    firstSetML cmlG sn (NT (mkNT nEtyped)::rest) = firstSet cmlG [NN nEbase]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nElogicAND = Q.store_thm(
  "firstSet_nElogicAND[simp]",
  `firstSet cmlG (NT(mkNT nElogicAND)::rest) = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nElogicAND = Q.store_thm(
  "firstSetML_nElogicAND[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nEbefore ∉ sn ∧ mkNT nEtyped ∉ sn ∧ mkNT nElogicAND ∉ sn ∧
    mkNT nElistop ∉ sn ∧ mkNT nEliteral ∉ sn
   ⇒
    firstSetML cmlG sn (NT (mkNT nElogicAND)::rest) =
      firstSet cmlG [NN nEbase]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nElogicOR = Q.store_thm(
  "firstSet_nElogicOR[simp]",
  `firstSet cmlG (NT(mkNT nElogicOR)::rest) = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nElogicOR = Q.store_thm(
  "firstSetML_nElogicOR[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nEbefore ∉ sn ∧ mkNT nEtyped ∉ sn ∧ mkNT nElogicAND ∉ sn ∧
    mkNT nElogicOR ∉ sn ∧ mkNT nElistop ∉ sn ∧ mkNT nEliteral ∉ sn
  ⇒
    firstSetML cmlG sn (NT (mkNT nElogicOR)::rest) =
      firstSet cmlG [NN nEbase]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nEhandle = Q.store_thm(
  "firstSet_nEhandle[simp]",
  `firstSet cmlG (NT(mkNT nEhandle)::rest) = firstSet cmlG [NT (mkNT nEbase)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSetML_nEhandle = Q.store_thm(
  "firstSetML_nEhandle[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nEbefore ∉ sn ∧ mkNT nEtyped ∉ sn ∧ mkNT nElogicAND ∉ sn ∧
    mkNT nElogicOR ∉ sn ∧ mkNT nEhandle ∉ sn ∧ mkNT nElistop ∉ sn ∧
    mkNT nEliteral ∉ sn
   ⇒
    firstSetML cmlG sn (NT (mkNT nEhandle)::rest) =
      firstSet cmlG [NN nEbase]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]));

val firstSet_nE = Q.store_thm(
  "firstSet_nE",
  `firstSet cmlG (NT(mkNT nE)::rest) =
      firstSet cmlG [NT (mkNT nEbase)] ∪ {IfT; CaseT; FnT; RaiseT}`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]) >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSet_nTopLevelDecs = Q.store_thm(
  "firstSet_nTopLevelDecs[simp]",
  `firstSet cmlG [NN nTopLevelDecs] =
      {ValT; FunT; SemicolonT; DatatypeT; StructureT; ExceptionT; TypeT} ∪
      firstSet cmlG [NT (mkNT nE)]`,
  simp[Once firstSet_NT, cmlG_applied, cmlG_FDOM] >>
  ONCE_REWRITE_TAC [firstSet_NT] >> simp[cmlG_applied, cmlG_FDOM] >>
  simp[INSERT_UNION_EQ, INSERT_COMM] >>
  simp[EXTENSION, EQ_IMP_THM] >> rpt strip_tac >> rveq >> simp[]);

val firstSet_nNonETopLevelDecs = Q.store_thm(
  "firstSet_nNonETopLevelDecs[simp]",
  `firstSet cmlG [NN nNonETopLevelDecs] =
      {ValT; FunT; SemicolonT; DatatypeT; StructureT; ExceptionT; TypeT}`,
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied] >>
  simp[Once firstSet_NT, cmlG_FDOM, cmlG_applied] >>
  simp[INSERT_COMM, INSERT_UNION_EQ]);

val firstSet_nEseq = Q.store_thm(
  "firstSet_nEseq[simp]",
  `firstSet cmlG (NN nEseq :: rest) = firstSet cmlG [NN nE]`,
  simp[SimpLHS, Once firstSet_NT, cmlG_FDOM, cmlG_applied] >>
  simp[firstSet_nE]);

val NOTIN_firstSet_nE = Q.store_thm(
  "NOTIN_firstSet_nE[simp]",
  `ValT ∉ firstSet cmlG (NT (mkNT nE) :: rest) ∧
    StructureT ∉ firstSet cmlG (NT (mkNT nE) :: rest) ∧
    FunT ∉ firstSet cmlG (NT (mkNT nE) :: rest) ∧
    DatatypeT ∉ firstSet cmlG (NT (mkNT nE) :: rest) ∧
    ExceptionT ∉ firstSet cmlG (NT (mkNT nE) :: rest) ∧
    SemicolonT ∉ firstSet cmlG (NT (mkNT nE) :: rest) ∧
    RparT ∉ firstSet cmlG (NN nE :: rest) ∧
    RbrackT ∉ firstSet cmlG (NN nE :: rest) ∧
    TypeT ∉ firstSet cmlG (NN nE :: rest)`,
  simp[firstSet_nE, firstSet_nFQV] >>
  rpt (dsimp[Once firstSet_NT, cmlG_FDOM, cmlG_applied, disjImpI]))

val firstSetML_nE = Q.store_thm(
  "firstSetML_nE[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nEbefore ∉ sn ∧ mkNT nEtyped ∉ sn ∧ mkNT nElogicAND ∉ sn ∧
    mkNT nElogicOR ∉ sn ∧ mkNT nEhandle ∉ sn ∧ mkNT nE ∉ sn ∧
    mkNT nElistop ∉ sn ∧ mkNT nEliteral ∉ sn ⇒
    firstSetML cmlG sn (NT (mkNT nE)::rest) = firstSet cmlG [NN nE]`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM, firstSet_nE]) >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSet_nE' = Q.store_thm(
  "firstSet_nE'",
  `firstSet cmlG (NT(mkNT nE')::rest) =
      firstSet cmlG [NT (mkNT nEbase)] ∪ {IfT; RaiseT}`,
  simp[SimpLHS, firstSetML_eqn] >>
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]) >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSetML_nE' = Q.store_thm(
  "firstSetML_nE'[simp]",
  `mkNT nConstructorName ∉ sn ∧ mkNT nUQConstructorName ∉ sn ∧
    mkNT nEbase ∉ sn ∧ mkNT nFQV ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nEapp ∉ sn ∧
    mkNT nEmult ∉ sn ∧ mkNT nEadd ∉ sn ∧ mkNT nErel ∉ sn ∧ mkNT nEcomp ∉ sn ∧
    mkNT nEbefore ∉ sn ∧ mkNT nEtyped ∉ sn ∧ mkNT nElogicAND ∉ sn ∧
    mkNT nElogicOR ∉ sn ∧ mkNT nE' ∉ sn ∧ mkNT nElistop ∉ sn ∧
    mkNT nEliteral ∉ sn
   ⇒
    firstSetML cmlG sn (NT (mkNT nE')::rest) = firstSet cmlG [NN nE']`,
  ntac 2 (simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM, firstSet_nE']) >>
  simp[Once EXTENSION, EQ_IMP_THM] >> dsimp[]);

val firstSet_nElist1 = Q.store_thm(
  "firstSet_nElist1[simp]",
  `firstSet cmlG (NT (mkNT nElist1)::rest) = firstSet cmlG [NT (mkNT nE)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]);

val firstSet_nElist2 = Q.store_thm(
  "firstSet_nElist2[simp]",
  `firstSet cmlG (NT (mkNT nElist2)::rest) = firstSet cmlG [NT (mkNT nE)]`,
  simp[SimpLHS, firstSetML_eqn] >>
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM]);

val firstSetML_nPtuple = Q.store_thm(
  "firstSetML_nPtuple[simp]",
  `mkNT nPtuple ∉ sn ⇒ (firstSetML cmlG sn (NN nPtuple :: rest) = {LparT})`,
  simp[Once firstSetML_def, cmlG_FDOM, cmlG_applied]);

val firstSet_nPtuple = Q.store_thm(
  "firstSet_nPtuple[simp]",
  `firstSet cmlG (NN nPtuple :: rest) = {LparT}`,
  simp[firstSetML_eqn, firstSetML_nPtuple]);

val firstSet_nPbase = Q.store_thm(
  "firstSet_nPbase[simp]",
  `firstSet cmlG (NN nPbase :: rest) =
      {LparT; UnderbarT; LbrackT} ∪ {IntT i | T } ∪ {StringT s | T } ∪
      {CharT c | T } ∪
      firstSet cmlG [NN nConstructorName] ∪ firstSet cmlG [NN nV]`,
  simp[SimpLHS, firstSetML_eqn] >>
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSetML_nPbase = Q.store_thm(
  "firstSetML_nPbase[simp]",
  `mkNT nPbase ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nConstructorName ∉ sn ∧
    mkNT nUQConstructorName ∉ sn ∧ mkNT nPtuple ∉ sn ⇒
    firstSetML cmlG sn (NN nPbase :: rest) = firstSet cmlG [NN nPbase]`,
  simp[Once firstSetML_def, cmlG_FDOM, cmlG_applied] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSet_nPapp = Q.store_thm(
  "firstSet_nPapp[simp]",
  `firstSet cmlG (NN nPapp :: rest) = firstSet cmlG [NN nPbase]`,
  simp[SimpLHS, firstSetML_eqn] >>
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSetML_nPapp = Q.store_thm(
  "firstSetML_nPapp[simp]",
  `mkNT nPbase ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nConstructorName ∉ sn ∧
    mkNT nUQConstructorName ∉ sn ∧ mkNT nPtuple ∉ sn ∧ mkNT nPapp ∉ sn ⇒
    firstSetML cmlG sn (NN nPapp :: rest) = firstSet cmlG [NN nPbase]`,
  simp[Once firstSetML_def, cmlG_FDOM, cmlG_applied] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSet_nPcons = Q.store_thm(
  "firstSet_nPcons[simp]",
  `firstSet cmlG (NN nPcons :: rest) = firstSet cmlG [NN nPbase]`,
  simp[SimpLHS, firstSetML_eqn] >>
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM])

val firstSetML_nPcons = Q.store_thm(
  "firstSetML_nPcons[simp]",
  `mkNT nPbase ∉ sn ∧ mkNT nV ∉ sn ∧ mkNT nConstructorName ∉ sn ∧
    mkNT nUQConstructorName ∉ sn ∧ mkNT nPtuple ∉ sn ∧ mkNT nPapp ∉ sn ∧
    mkNT nPcons ∉ sn ⇒
    firstSetML cmlG sn (NN nPcons :: rest) = firstSet cmlG [NN nPbase]`,
  simp[Once firstSetML_def, cmlG_FDOM, cmlG_applied]);

val firstSet_nPattern = Q.store_thm(
  "firstSet_nPattern[simp]",
  `firstSet cmlG (NN nPattern :: rest) = firstSet cmlG [NN nPbase]`,
  simp[SimpLHS, firstSetML_eqn] >>
  simp[Once firstSetML_def, cmlG_applied, cmlG_FDOM] >>
  dsimp[Once EXTENSION, EQ_IMP_THM]);

val firstSet_nPatternList = Q.store_thm(
  "firstSet_nPatternList[simp]",
  `firstSet cmlG (NN nPatternList :: rest) = firstSet cmlG [NN nPattern]`,
  simp[SimpLHS, Once firstSet_NT, cmlG_FDOM, cmlG_applied] >> simp[]);

val firstSet_nPbaseList1 = Q.store_thm(
  "firstSet_nPbaseList1[simp]",
  `firstSet cmlG (NN nPbaseList1 :: rest) = firstSet cmlG [NN nPbase]`,
  simp[SimpLHS, Once firstSet_NT, cmlG_FDOM, cmlG_applied] >> simp[]);

val NOTIN_firstSet_nV = Q.store_thm(
  "NOTIN_firstSet_nV[simp]",
  `CommaT ∉ firstSet cmlG [NN nV] ∧ LparT ∉ firstSet cmlG [NN nV] ∧
    RparT ∉ firstSet cmlG [NN nV] ∧ UnderbarT ∉ firstSet cmlG [NN nV] ∧
    BarT ∉ firstSet cmlG [NN nV] ∧ OpT ∉ firstSet cmlG [NN nV] ∧
    FnT ∉ firstSet cmlG [NN nV] ∧ IfT ∉ firstSet cmlG [NN nV] ∧
    EqualsT ∉ firstSet cmlG [NN nV] ∧ DarrowT ∉ firstSet cmlG [NN nV] ∧
    ValT ∉ firstSet cmlG [NN nV] ∧
    ExceptionT ∉ firstSet cmlG [NN nV] ∧
    EndT ∉ firstSet cmlG [NN nV] ∧
    AndT ∉ firstSet cmlG [NN nV] ∧
    FunT ∉ firstSet cmlG [NN nV] ∧
    LbrackT ∉ firstSet cmlG [NN nV] ∧
    RbrackT ∉ firstSet cmlG [NN nV] ∧
    InT ∉ firstSet cmlG [NN nV] ∧
    IntT i ∉ firstSet cmlG [NN nV] ∧
    StringT s ∉ firstSet cmlG [NN nV] ∧
    CharT c ∉ firstSet cmlG [NN nV] ∧
    ThenT ∉ firstSet cmlG [NN nV] ∧
    ElseT ∉ firstSet cmlG [NN nV] ∧
    CaseT ∉ firstSet cmlG [NN nV] ∧
    LetT ∉ firstSet cmlG [NN nV] ∧
    OfT ∉ firstSet cmlG [NN nV] ∧
    RaiseT ∉ firstSet cmlG [NN nV] ∧
    DatatypeT ∉ firstSet cmlG [NN nV] ∧
    TypeT ∉ firstSet cmlG [NN nV] ∧
    SemicolonT ∉ firstSet cmlG [NN nV] ∧ ColonT ∉ firstSet cmlG [NN nV] ∧
    StructureT ∉ firstSet cmlG [NN nV] ∧ WordT w ∉ firstSet cmlG [NN nV]`,
  simp[firstSet_nV]);

val NOTIN_firstSet_nFQV = Q.store_thm(
  "NOTIN_firstSet_nFQV[simp]",
  `AndT ∉ firstSet cmlG [NN nFQV] ∧
    BarT ∉ firstSet cmlG [NN nFQV] ∧
    CaseT ∉ firstSet cmlG [NN nFQV] ∧
    CharT c ∉ firstSet cmlG [NN nFQV] ∧
    ColonT ∉ firstSet cmlG [NN nFQV] ∧
    CommaT ∉ firstSet cmlG [NN nFQV] ∧
    DarrowT ∉ firstSet cmlG [NN nFQV] ∧
    DatatypeT ∉ firstSet cmlG [NN nFQV] ∧
    ElseT ∉ firstSet cmlG [NN nFQV] ∧
    EndT ∉ firstSet cmlG [NN nFQV] ∧
    EqualsT ∉ firstSet cmlG [NN nFQV] ∧
    ExceptionT ∉ firstSet cmlG [NN nFQV] ∧
    FnT ∉ firstSet cmlG [NN nFQV] ∧
    FunT ∉ firstSet cmlG [NN nFQV] ∧
    IfT ∉ firstSet cmlG [NN nFQV] ∧
    InT ∉ firstSet cmlG [NN nFQV] ∧
    IntT i ∉ firstSet cmlG [NN nFQV] ∧
    LbrackT ∉ firstSet cmlG [NN nFQV] ∧
    LetT ∉ firstSet cmlG [NN nFQV] ∧
    LparT ∉ firstSet cmlG [NN nFQV] ∧
    OfT ∉ firstSet cmlG [NN nFQV] ∧
    OpT ∉ firstSet cmlG [NN nFQV] ∧
    RaiseT ∉ firstSet cmlG [NN nFQV] ∧
    RbrackT ∉ firstSet cmlG [NN nFQV] ∧
    RparT ∉ firstSet cmlG [NN nFQV] ∧
    SemicolonT ∉ firstSet cmlG [NN nFQV] ∧
    StringT s ∉ firstSet cmlG [NN nFQV] ∧
    StructureT ∉ firstSet cmlG [NN nFQV] ∧
    ThenT ∉ firstSet cmlG [NN nFQV] ∧
    TypeT ∉ firstSet cmlG [NN nFQV] ∧
    UnderbarT ∉ firstSet cmlG [NN nFQV] ∧
    ValT ∉ firstSet cmlG [NN nFQV] ∧
    WordT w ∉ firstSet cmlG [NN nFQV]`,
  simp[firstSet_nFQV]);

val NOTIN_firstSet_nConstructorName = Q.store_thm(
  "NOTIN_firstSet_nConstructorName[simp]",
  `AndT ∉ firstSet cmlG [NN nConstructorName] ∧
    BarT ∉ firstSet cmlG [NN nConstructorName] ∧
    ColonT ∉ firstSet cmlG [NN nConstructorName] ∧
    CaseT ∉ firstSet cmlG [NN nConstructorName] ∧
    CharT c ∉ firstSet cmlG [NN nConstructorName] ∧
    CommaT ∉ firstSet cmlG [NN nConstructorName] ∧
    DarrowT ∉ firstSet cmlG [NN nConstructorName] ∧
    DatatypeT ∉ firstSet cmlG [NN nConstructorName] ∧
    ElseT ∉ firstSet cmlG [NN nConstructorName] ∧
    EndT ∉ firstSet cmlG [NN nConstructorName] ∧
    EqualsT ∉ firstSet cmlG [NN nConstructorName] ∧
    ExceptionT ∉ firstSet cmlG [NN nConstructorName] ∧
    FnT ∉ firstSet cmlG [NN nConstructorName] ∧
    FunT ∉ firstSet cmlG [NN nConstructorName] ∧
    IfT ∉ firstSet cmlG [NN nConstructorName] ∧
    InT ∉ firstSet cmlG [NN nConstructorName] ∧
    IntT i ∉ firstSet cmlG [NN nConstructorName] ∧
    LbrackT ∉ firstSet cmlG [NN nConstructorName] ∧
    LetT ∉ firstSet cmlG [NN nConstructorName] ∧
    LparT ∉ firstSet cmlG [NN nConstructorName] ∧
    OfT ∉ firstSet cmlG [NN nConstructorName] ∧
    OpT ∉ firstSet cmlG [NN nConstructorName] ∧
    RaiseT ∉ firstSet cmlG [NN nConstructorName] ∧
    RbrackT ∉ firstSet cmlG [NN nConstructorName] ∧
    RparT ∉ firstSet cmlG [NN nConstructorName] ∧
    SemicolonT ∉ firstSet cmlG [NN nConstructorName] ∧
    StringT s ∉ firstSet cmlG [NN nConstructorName] ∧
    StructureT ∉ firstSet cmlG [NN nConstructorName] ∧
    ThenT ∉ firstSet cmlG [NN nConstructorName] ∧
    TypeT ∉ firstSet cmlG [NN nConstructorName] ∧
    UnderbarT ∉ firstSet cmlG [NN nConstructorName] ∧
    ValT ∉ firstSet cmlG [NN nConstructorName] ∧
    WordT w ∉ firstSet cmlG [NN nConstructorName]`,
  simp[firstSet_nConstructorName]);

val cmlPEG_total =
    peg_eval_total |> Q.GEN `G` |> Q.ISPEC `cmlPEG`
                             |> C MATCH_MP PEG_wellformed

val peg_respects_firstSets = Q.store_thm(
  "peg_respects_firstSets",
  `∀N i0 t.
      t ∉ firstSet cmlG [NT N] ∧ ¬peg0 cmlPEG (nt N I) ∧
      nt N I ∈ Gexprs cmlPEG ⇒
      peg_eval cmlPEG (t::i0, nt N I) NONE`,
  rpt gen_tac >> CONV_TAC CONTRAPOS_CONV >> simp[] >>
  Cases_on `nt N I ∈ Gexprs cmlPEG` >> simp[] >>
  IMP_RES_THEN (qspec_then `t::i0` (qxchl [`r`] assume_tac)) cmlPEG_total >>
  pop_assum (assume_tac o MATCH_MP (CONJUNCT1 peg_deterministic)) >>
  simp[] >>
  `r = NONE ∨ ∃i ptl. r = SOME(i,ptl)`
    by metis_tac[optionTheory.option_CASES, pairTheory.pair_CASES] >>
  simp[] >> rveq >>
  `∃pt. ptl = [pt] ∧ ptree_head pt = NT N ∧ valid_ptree cmlG pt ∧
        MAP TK (t::i0) = ptree_fringe pt ++ MAP TK i`
    by metis_tac [peg_sound] >>
  rveq >> Cases_on `peg0 cmlPEG (nt N I)` >> simp[] >>
  `LENGTH i < LENGTH (t::i0)` by metis_tac [not_peg0_LENGTH_decreases] >>
  `ptree_fringe pt = [] ∨ ∃tk rest. ptree_fringe pt = TK tk:: MAP TK rest`
    by (Cases_on `ptree_fringe pt` >> simp[] >> fs[] >> rveq >>
        fs[MAP_EQ_APPEND] >> metis_tac[])
  >- (fs[] >> pop_assum kall_tac >>
      first_x_assum (mp_tac o Q.AP_TERM `LENGTH`) >> simp[]) >>
  fs[] >> rveq >> metis_tac [firstSet_nonempty_fringe])

val sym2peg_def = Define`
  sym2peg (TOK tk) = tokeq tk ∧
  sym2peg (NT N) = nt N I
`;

val not_peg0_peg_eval_NIL_NONE = Q.store_thm(
  "not_peg0_peg_eval_NIL_NONE",
  `¬peg0 G sym ∧ sym ∈ Gexprs G ∧ wfG G ⇒
    peg_eval G ([], sym) NONE`,
  strip_tac >>
  `∃r. peg_eval G ([], sym) r`
    by metis_tac [peg_eval_total] >>
  Cases_on `r` >> simp[] >> Cases_on `x` >>
  erule mp_tac not_peg0_LENGTH_decreases >> simp[]);

val list_case_lemma = Q.prove(
  `([x] = case a of [] => [] | h::t => f h t) ⇔
    (a ≠ [] ∧ [x] = f (HD a) (TL a))`,
  Cases_on `a` >> simp[]);

val left_insert1_def = Define`
  (left_insert1 pt (Lf x) = Lf x) ∧
  (left_insert1 pt (Nd n subs) =
     case subs of
         [x] => Nd n [Nd n [pt]; x]
       | [x; y] => Nd n [left_insert1 pt x; y]
       | _ => Nd n subs)
`;

val left_insert1_FOLDL = Q.store_thm(
  "left_insert1_FOLDL",
  `left_insert1 pt (FOLDL (λa b. Nd (mkNT P) [a; b]) acc arg) =
    FOLDL (λa b. Nd (mkNT P) [a; b]) (left_insert1 pt acc) arg`,
  qid_spec_tac `acc` >> Induct_on `arg` >> simp[left_insert1_def]);

val eapp_reassociated = Q.store_thm(
  "eapp_reassociated",
  `∀pt bpt pf bf.
      valid_ptree cmlG pt ∧ ptree_head pt = NN nEapp ∧
      ptree_fringe pt = MAP TK pf ∧
      valid_ptree cmlG bpt ∧ ptree_head bpt = NN nEbase ∧
      ptree_fringe bpt = MAP TK bf ⇒
      ∃pt' bpt'.
        valid_ptree cmlG pt' ∧ valid_ptree cmlG bpt' ∧
        ptree_head pt' = NN nEapp ∧ ptree_head bpt' = NN nEbase ∧
        ptree_fringe bpt' ++ ptree_fringe pt' = MAP TK (pf ++ bf) ∧
        Nd (mkNT nEapp) [pt; bpt] = left_insert1 bpt' pt'`,
  ho_match_mp_tac grammarTheory.ptree_ind >>
  simp[MAP_EQ_CONS, cmlG_applied, cmlG_FDOM] >>
  qx_gen_tac `subs` >> strip_tac >>
  map_every qx_gen_tac [`bpt`, `pf`, `bf`] >> strip_tac >> rveq >>
  fs[MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rveq
  >- (asm_match `ptree_head pt0 = NN nEapp` >>
      asm_match `ptree_fringe pt0 = MAP TK pf` >>
      Q.UNDISCH_THEN `ptree_head bpt = NN nEbase` mp_tac >>
      asm_match `ptree_head bpt0 = NN nEbase` >>
      asm_match `ptree_fringe bpt0 = MAP TK bf0` >> strip_tac >>
      first_x_assum (qspecl_then [`bpt0`, `pf`, `bf0`] mp_tac) >>
      simp[] >> disch_then (qxchl [`ppt'`, `bpt'`] strip_assume_tac) >>
      map_every qexists_tac [`Nd (mkNT nEapp) [ppt'; bpt]`, `bpt'`] >>
      dsimp[cmlG_FDOM, cmlG_applied, left_insert1_def]) >>
  Q.UNDISCH_THEN `ptree_head bpt = NN nEbase` mp_tac >>
  asm_match `ptree_head bpt0 = NN nEbase` >> strip_tac >>
  map_every qexists_tac [`Nd (mkNT nEapp) [bpt]`, `bpt0`] >>
  dsimp[cmlG_applied, cmlG_FDOM, left_insert1_def]);

val leftmost_def = Define`
  leftmost (Lf s) = Lf s ∧
  leftmost (Nd n args) =
    if args ≠ [] ∧ n = mkNT nTbase then HD args
    else
      case args of
          [] => Nd n args
        | h::_ => leftmost h
`;

val left_insert2_def = Define`
  (left_insert2 pt (Lf x) = Lf x) ∧
  (left_insert2 pt (Nd n subs) =
     case subs of
         [Nd n2 [tb]] => if n2 <> mkNT nTbase then Nd n subs
                         else Nd n [Nd n [pt]; tb]
       | [x; y] => Nd n [left_insert2 pt x; y]
       | _ => Nd n subs)
`;

val left_insert2_FOLDL = Q.store_thm(
  "left_insert2_FOLDL",
  `left_insert2 pt (FOLDL (λa b. Nd (mkNT P) [a; b]) acc arg) =
    FOLDL (λa b. Nd (mkNT P) [a; b]) (left_insert2 pt acc) arg`,
  qid_spec_tac `acc` >> Induct_on `arg` >> simp[left_insert2_def]);


val dtype_reassociated = Q.store_thm(
  "dtype_reassociated",
  `∀pt bpt pf bf.
      valid_ptree cmlG pt ∧ ptree_head pt = NN nDType ∧
      ptree_fringe pt = MAP TK pf ∧
      valid_ptree cmlG bpt ∧ ptree_head bpt = NN nTyOp ∧
      ptree_fringe bpt = MAP TK bf ⇒
      ∃pt' bpt'.
        valid_ptree cmlG pt' ∧ valid_ptree cmlG bpt' ∧
        valid_ptree cmlG (leftmost pt') ∧ ptree_head (leftmost pt') = NN nTyOp ∧
        ptree_head pt' = NN nDType ∧ ptree_head bpt' = NN nTbase ∧
        ptree_fringe bpt' ++ ptree_fringe pt' = MAP TK (pf ++ bf) ∧
        Nd (mkNT nDType) [pt; bpt] = left_insert2 bpt' pt'`,
  ho_match_mp_tac grammarTheory.ptree_ind >>
  simp[MAP_EQ_CONS, cmlG_applied, cmlG_FDOM] >>
  qx_gen_tac `subs` >> strip_tac >>
  map_every qx_gen_tac [`bpt`, `pf`, `bf`] >> strip_tac >> rveq >>
  fs[MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rveq
  >- (asm_match `ptree_head pt0 = NN nDType` >>
      asm_match `ptree_fringe pt0 = MAP TK pf` >>
      Q.UNDISCH_THEN `ptree_head bpt = NN nTyOp` mp_tac >>
      asm_match `ptree_head bpt0 = NN nTyOp` >>
      asm_match `ptree_fringe bpt0 = MAP TK bf0` >> strip_tac >>
      first_x_assum (qspecl_then [`bpt0`, `pf`, `bf0`] mp_tac) >>
      simp[] >> disch_then (qxchl [`ppt'`, `bpt'`] strip_assume_tac) >>
      map_every qexists_tac [`Nd (mkNT nDType) [ppt'; bpt]`, `bpt'`] >>
      dsimp[cmlG_FDOM, cmlG_applied, left_insert2_def, leftmost_def]) >>
  asm_match `ptree_head bpt0 = NN nTbase` >>
  map_every qexists_tac [`Nd (mkNT nDType) [Nd (mkNT nTbase) [bpt]]`, `bpt0`] >>
  dsimp[cmlG_applied, cmlG_FDOM, left_insert2_def, leftmost_def]);


val left_insert_def = Define`
  (left_insert (Lf x) p sep c = Lf x) ∧
  (left_insert (Nd n subs) p sep c =
     if n <> p then Nd n subs
     else
       case subs of
           [c0] => Nd p [Nd p [c]; sep; c0]
         | [p'; s'; c'] => Nd p [left_insert p' p sep c; s'; c']
         | _ => Nd p subs)
`;

val lassoc_reassociated = Q.store_thm(
  "lassoc_reassociated",
  `∀G P SEP C ppt spt cpt pf sf cf.
      G.rules ' P = {[NT P; SEP; C]; [C]} ⇒
      valid_ptree G ppt ∧ ptree_head ppt = NT P ∧
      ptree_fringe ppt = MAP TOK pf ∧
      valid_ptree G spt ∧ ptree_head spt = SEP ∧ ptree_fringe spt = MAP TOK sf ∧
      valid_ptree G cpt ∧ ptree_head cpt = C ∧ ptree_fringe cpt = MAP TOK cf ⇒
      ∃cpt' spt' ppt'.
        valid_ptree G ppt' ∧ ptree_head ppt' = NT P ∧
        valid_ptree G spt' ∧ ptree_head spt' = SEP ∧
        valid_ptree G cpt' ∧ ptree_head cpt' = C ∧
        ptree_fringe cpt' ++ ptree_fringe spt' ++ ptree_fringe ppt' =
        MAP TOK (pf ++ sf ++ cf) ∧
        Nd P [ppt; spt; cpt] = left_insert ppt' P spt' cpt'`,
  rpt gen_tac >> strip_tac >>
  map_every qid_spec_tac [`cf`, `sf`, `pf`, `cpt`, `spt`, `ppt`] >>
  ho_match_mp_tac grammarTheory.ptree_ind >> simp[MAP_EQ_SING] >>
  qx_gen_tac `subs` >> strip_tac >> simp[MAP_EQ_CONS] >>
  reverse (rpt strip_tac) >> rveq >> fs[]
  >- (qpat_x_assum `!x. PP x` kall_tac >>
      asm_match `ptree_fringe c0pt = MAP TOK pf` >>
      map_every qexists_tac [`c0pt`, `spt`, `Nd P [cpt]`] >>
      simp[left_insert_def]) >>
  asm_match `ptree_head ppt = NT P` >>
  asm_match `ptree_head s0pt = ptree_head spt` >>
  asm_match `ptree_head cpt = ptree_head c0pt` >>
  fs [MAP_EQ_APPEND] >> rveq >>
  asm_match `ptree_fringe ppt = MAP TOK pf` >>
  asm_match `ptree_fringe s0pt = MAP TOK sf0` >>
  asm_match `ptree_fringe c0pt = MAP TOK cf0` >>
  first_x_assum (fn th =>
    first_x_assum (qspec_then `ppt` mp_tac) >>
    mp_tac (assert (is_forall o concl) th)) >>
  simp[] >> simp[DISJ_IMP_THM, FORALL_AND_THM] >> strip_tac >>
  disch_then (qspecl_then [`s0pt`, `c0pt`, `pf`, `sf0`, `cf0`] mp_tac) >>
  simp[] >>
  disch_then (qxchl [`cpt'`, `spt'`, `ppt'`] strip_assume_tac) >>
  map_every qexists_tac [`cpt'`, `spt'`, `Nd P [ppt'; spt; cpt]`] >>
  simp[DISJ_IMP_THM, FORALL_AND_THM, left_insert_def])

val left_insert_mk_linfix = Q.store_thm(
  "left_insert_mk_linfix",
  `left_insert (mk_linfix N acc arg) N s c =
    mk_linfix N (left_insert acc N s c) arg`,
  qid_spec_tac `acc` >> completeInduct_on `LENGTH arg` >> rw[] >>
  full_simp_tac (srw_ss() ++ DNF_ss)[] >>
  `arg = [] ∨ ∃h1 t. arg = h1::t` by (Cases_on `arg` >> simp[])
  >- simp[mk_linfix_def] >>
  `t = [] ∨ ∃h2 t2. t = h2::t2` by (Cases_on `t` >> simp[])
  >- simp[mk_linfix_def] >>
  rw[] >> simp[mk_linfix_def, left_insert_def]);

val firstSets_nV_nConstructorName = Q.store_thm(
  "firstSets_nV_nConstructorName",
  `¬(t ∈ firstSet cmlG [NN nConstructorName] ∧ t ∈ firstSet cmlG [NN nV])`,
  Cases_on `t ∈ firstSet cmlG [NN nV]` >> simp[] >>
  fs[firstSet_nV, firstSet_nConstructorName]);

val elim_disjineq = Q.prove( `p \/ x ≠ y ⇔ (x = y ⇒ p)`, DECIDE_TAC)
val elim_det = Q.prove(`(!x. P x ⇔ (x = y)) ==> P y`, METIS_TAC[])

val peg_det = CONJUNCT1 peg_deterministic

val peg_seql_NONE_det = Q.store_thm(
  "peg_seql_NONE_det",
  `peg_eval G (i0, seql syms f) NONE ⇒
    ∀f' r. peg_eval G (i0, seql syms f') r ⇔ r = NONE`,
  Induct_on `syms` >> simp[] >> rpt strip_tac >>
  rpt (first_x_assum (assume_tac o MATCH_MP peg_det)) >> simp[]);

val peg_seql_NONE_append = Q.store_thm(
  "peg_seql_NONE_append",
  `∀i0 f. peg_eval G (i0, seql (l1 ++ l2) f) NONE ⇔
           peg_eval G (i0, seql l1 I) NONE ∨
           ∃i' r. peg_eval G (i0, seql l1 I) (SOME(i',r)) ∧
                  peg_eval G (i', seql l2 I) NONE`,
  Induct_on `l1` >> simp[] >- metis_tac [peg_seql_NONE_det] >>
  map_every qx_gen_tac [`h`, `i0`] >>
  Cases_on `peg_eval G (i0,h) NONE` >> simp[] >>
  dsimp[] >> metis_tac[]);

val peg_seql_SOME_append = Q.store_thm(
  "peg_seql_SOME_append",
  `∀i0 l2 f i r.
      peg_eval G (i0, seql (l1 ++ l2) f) (SOME(i,r)) ⇔
      ∃i' r1 r2.
          peg_eval G (i0, seql l1 I) (SOME(i',r1)) ∧
          peg_eval G (i', seql l2 I) (SOME(i,r2)) ∧
          (r = f (r1 ++ r2))`,
  Induct_on `l1` >> simp[]
  >- (Induct_on `l2` >- simp[] >>
      ONCE_REWRITE_TAC [peg_eval_seql_CONS] >>
      simp_tac (srw_ss() ++ DNF_ss) []) >>
  dsimp[] >> metis_tac[]);

fun has_const c = assert (Lib.can (find_term (same_const c)) o concl)

val eOR_wrongtok = Q.store_thm(
  "eOR_wrongtok",
  `¬peg_eval cmlPEG (RaiseT::i0, nt (mkNT nElogicOR) I) (SOME(i,r)) ∧
    ¬peg_eval cmlPEG (FnT::i0, nt (mkNT nElogicOR) I) (SOME(i,r)) ∧
    ¬peg_eval cmlPEG (CaseT::i0, nt (mkNT nElogicOR) I) (SOME(i,r)) ∧
    ¬peg_eval cmlPEG (IfT::i0, nt (mkNT nElogicOR) I) (SOME(i,r))`,
  rpt conj_tac >>
  qmatch_abbrev_tac `¬peg_eval cmlPEG (ttk::i0, nt (mkNT nElogicOR) I) (SOME(i,r))` >>
  strip_tac >>
  `peg_eval cmlPEG (ttk::i0, nt (mkNT nElogicOR) I) NONE`
    suffices_by (first_assum (assume_tac o MATCH_MP peg_det) >> simp[]) >>
  simp[Abbr`ttk`, peg_respects_firstSets]);

val nE'_nE = Q.store_thm(
  "nE'_nE",
  `∀i0 i r.
      peg_eval cmlPEG (i0, nt (mkNT nE') I) (SOME(i,r)) ∧
      (i ≠ [] ⇒ HD i ≠ HandleT) ⇒
      ∃r'. peg_eval cmlPEG (i0, nt (mkNT nE) I) (SOME(i,r'))`,
  gen_tac >> completeInduct_on `LENGTH i0` >> gen_tac >> strip_tac >>
  full_simp_tac (srw_ss() ++ DNF_ss) [AND_IMP_INTRO] >>
  simp[peg_eval_NT_SOME] >> simp[cmlpeg_rules_applied] >>
  rpt strip_tac >> rveq >> simp[peg_eval_tok_NONE] >> fs[]
  >- (dsimp[] >> metis_tac[DECIDE``x<SUC x``])
  >- (dsimp[] >> DISJ2_TAC >> DISJ1_TAC >>
      simp[peg_eval_NT_SOME] >>
      simp_tac list_ss [cmlpeg_rules_applied] >>
      ONCE_REWRITE_TAC [peg_eval_seql_CONS] >>
      dsimp[] >>
      first_assum (strip_assume_tac o MATCH_MP peg_det) >>
      dsimp[] >> simp[peg_eval_tok_NONE] >> Cases_on `i` >> fs[])
  >- (dsimp[] >> DISJ2_TAC >> simp[peg_eval_seq_NONE] >>
      rpt (first_x_assum (assume_tac o MATCH_MP peg_det)) >>
      simp[peg_respects_firstSets] >>
      first_x_assum match_mp_tac >> simp[] >>
      rpt (first_x_assum (assume_tac o MATCH_MP elim_det)) >>
      imp_res_tac length_no_greater >> fs[] >> simp[]) >>
  fs[eOR_wrongtok]);


val nE'_bar_nE = Q.store_thm(
  "nE'_bar_nE",
  `∀i0 i i' r r'.
        peg_eval cmlPEG (i0, nt (mkNT nE) I) (SOME(i,r)) ∧
        (i ≠ [] ⇒ HD i ≠ BarT ∧ HD i ≠ HandleT) ∧ i' ≠ [] ∧
        peg_eval cmlPEG (i0, nt (mkNT nE') I) (SOME(i',r')) ⇒
        HD i' ≠ BarT`,
  gen_tac >> completeInduct_on `LENGTH i0` >> rpt strip_tac >>
  full_simp_tac (srw_ss() ++ DNF_ss) [AND_IMP_INTRO] >> rw[] >>
  rpt (qpat_x_assum `peg_eval X Y Z` mp_tac) >>
  simp[peg_eval_NT_SOME] >>
  simp_tac std_ss [cmlpeg_rules_applied] >>
  simp_tac std_ss [Once peg_eval_choicel_CONS] >> strip_tac
  >- ((* raise case *)
      simp_tac (list_ss ++ DNF_ss) [Once peg_eval_choicel_CONS] >>
      simp_tac (list_ss ++ DNF_ss) [peg_eval_seql_CONS] >>
      pop_assum (strip_assume_tac o SIMP_RULE (srw_ss()) []) >>
      rw[] >> simp[peg_eval_tok_NONE] >> DISJ2_TAC >>
      conj_tac
      >- (fs[] >> metis_tac[DECIDE``x < SUC x``]) >>
      simp[elim_disjineq] >> rpt strip_tac >> rw[] >>
      fs[eOR_wrongtok]) >>
  first_x_assum (assume_tac o MATCH_MP peg_seql_NONE_det) >>
  qpat_x_assum `peg_eval cmlPEG X Y` mp_tac >>
  simp_tac std_ss [Once peg_eval_choicel_CONS, pegf_def, peg_eval_seq_SOME,
                   peg_eval_empty, peg_eval_seq_NONE, pnt_def] >>
  strip_tac
  >- ((* handle case *)
      rveq >> pop_assum mp_tac >>
      simp[Once peg_eval_NT_SOME, elim_disjineq, disjImpI] >>
      simp[cmlpeg_rules_applied] >> rw[] >> fs[eOR_wrongtok] >>
      pop_assum (assume_tac o MATCH_MP peg_det) >> fs[] >> rw[] >>
      fs[]) >>
  asm_simp_tac list_ss [Once peg_eval_choicel_CONS] >>
  pop_assum mp_tac >>
  asm_simp_tac list_ss [Once peg_eval_choicel_CONS] >>
  strip_tac
  >- ((* if-then-else *)
      full_simp_tac list_ss [peg_eval_seql_CONS, tokeq_def, pnt_def, pegf_def,
                             peg_eval_tok_SOME, peg_eval_seql_NIL,
                             peg_eval_seq_NONE, peg_eval_empty] >> rveq >>
      dsimp[] >>
      rpt (first_x_assum (assume_tac o MATCH_MP peg_det o has_const ``nE``)) >>
      simp[elim_disjineq, peg_eval_seq_NONE] >>
      rpt (first_x_assum (assume_tac o MATCH_MP elim_det)) >>
      simp[eOR_wrongtok, peg_respects_firstSets] >>
      simp[peg_eval_tok_NONE] >> rpt strip_tac >> rveq >>
      asm_match `peg_eval cmlPEG (ii, nt (mkNT nE') I) (SOME(ii', r))` >>
      asm_match `peg_eval cmlPEG (IfT::i1, nt (mkNT nEhandle) I) NONE` >>
      fs[] >>
      `LENGTH ii < SUC (LENGTH i1)` suffices_by metis_tac[] >>
      imp_res_tac length_no_greater >> fs[] >> simp[]) >>
  asm_simp_tac list_ss [Once peg_eval_choicel_CONS] >>
  full_simp_tac list_ss [pnt_def, pegf_def, peg_eval_seq_SOME, peg_eval_seq_NONE,
                         peg_eval_empty] >>
  pop_assum mp_tac >>
  asm_simp_tac list_ss [elim_disjineq, Once peg_eval_choicel_CONS] >> strip_tac
  >- ((* fn v => e *)
      pop_assum mp_tac >>
      asm_simp_tac list_ss [peg_eval_seql_CONS, tokeq_def, peg_eval_tok_SOME] >>
      strip_tac >> rveq >> simp[peg_eval_tok_NONE, eOR_wrongtok]) >>
  pop_assum mp_tac >>
  asm_simp_tac list_ss [peg_eval_choicel_SING, peg_eval_seql_CONS,
                        peg_eval_seql_NIL, peg_eval_tok_SOME, tokeq_def] >>
  rpt strip_tac >> rveq >> fs[] >> simp[eOR_wrongtok]);

val nestoppers_def = Define`
  nestoppers =
     UNIV DIFF ({AndalsoT; ArrowT; BarT; ColonT; HandleT; OrelseT;
                 AlphaT "before"} ∪
                firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nRelOps] ∪
                firstSet cmlG [NN nListOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nCompOps] ∪
                firstSet cmlG [NN nEbase] ∪ firstSet cmlG [NN nTyOp])
`;
val _ = export_rewrites ["nestoppers_def"]

val stoppers_def = Define`
  (stoppers nAndFDecls = nestoppers DELETE AndT) ∧
  (stoppers nDconstructor =
     UNIV DIFF ({StarT; OfT; ArrowT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nDecl = nestoppers DIFF {BarT; StarT; AndT; OfT}) ∧
  (stoppers nDecls =
     nestoppers DIFF
     {BarT; StarT; AndT; SemicolonT; FunT; ValT; DatatypeT; OfT; ExceptionT;
      TypeT}) ∧
  (stoppers nDType = UNIV DIFF firstSet cmlG [NN nTyOp]) ∧
  (stoppers nDtypeCons =
     UNIV DIFF ({ArrowT; BarT; StarT; OfT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nDtypeDecl =
     UNIV DIFF ({ArrowT; BarT; StarT; OfT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nDtypeDecls =
     UNIV DIFF ({AndT; ArrowT; BarT; StarT; OfT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nE = nestoppers) ∧
  (stoppers nE' = BarT INSERT nestoppers) ∧
  (stoppers nEadd =
     UNIV DIFF (firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nEbase])) ∧
  (stoppers nEapp = UNIV DIFF firstSet cmlG [NN nEbase]) ∧
  (stoppers nEbefore =
     UNIV DIFF ({AlphaT "before"} ∪
                firstSet cmlG [NN nCompOps] ∪
                firstSet cmlG [NN nRelOps] ∪
                firstSet cmlG [NN nListOps] ∪
                firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nEbase])) ∧
  (stoppers nEcomp =
     UNIV DIFF (firstSet cmlG [NN nCompOps] ∪
                firstSet cmlG [NN nRelOps] ∪
                firstSet cmlG [NN nListOps] ∪
                firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nEbase])) ∧
  (stoppers nEhandle = nestoppers) ∧
  (stoppers nElist1 = nestoppers DELETE CommaT) ∧
  (stoppers nElist2 = nestoppers DELETE CommaT) ∧
  (stoppers nElistop = UNIV DIFF (firstSet cmlG [NN nMultOps] ∪
                                  firstSet cmlG [NN nAddOps] ∪
                                  firstSet cmlG [NN nListOps] ∪
                                  firstSet cmlG [NN nEbase])) ∧
  (stoppers nElogicAND =
     UNIV DIFF ({AndalsoT; ColonT; ArrowT; AlphaT "before"} ∪
                firstSet cmlG [NN nCompOps] ∪
                firstSet cmlG [NN nRelOps] ∪
                firstSet cmlG [NN nListOps] ∪
                firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nEbase]∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nElogicOR =
     UNIV DIFF ({AndalsoT; ColonT; ArrowT; OrelseT; AlphaT "before"} ∪
                firstSet cmlG [NN nCompOps] ∪
                firstSet cmlG [NN nRelOps] ∪
                firstSet cmlG [NN nListOps] ∪
                firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nEbase] ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nEmult =
     UNIV DIFF (firstSet cmlG [NN nEbase] ∪
                firstSet cmlG [NN nMultOps])) ∧
  (stoppers nErel =
     UNIV DIFF (firstSet cmlG [NN nRelOps] ∪
                firstSet cmlG [NN nListOps] ∪
                firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nEbase])) ∧
  (stoppers nEseq = nestoppers DELETE SemicolonT) ∧
  (stoppers nEtyped =
     UNIV DIFF ({ColonT; ArrowT; AlphaT "before"} ∪
                firstSet cmlG [NN nCompOps] ∪
                firstSet cmlG [NN nListOps] ∪
                firstSet cmlG [NN nRelOps] ∪
                firstSet cmlG [NN nMultOps] ∪
                firstSet cmlG [NN nAddOps] ∪
                firstSet cmlG [NN nEbase] ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nFDecl = nestoppers) ∧
  (stoppers nLetDec = nestoppers DELETE AndT) ∧
  (stoppers nLetDecs = nestoppers DIFF {AndT; FunT; ValT; SemicolonT}) ∧
  (stoppers nNonETopLevelDecs = ∅) ∧
  (stoppers nOptTypEqn =
     UNIV DIFF ({ArrowT; StarT; EqualsT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nPcons =
     UNIV DIFF ({LparT; UnderbarT; LbrackT; SymbolT "::"} ∪ { IntT i | T } ∪
                { StringT s | T } ∪ { CharT c | T } ∪
                firstSet cmlG [NN nV] ∪ firstSet cmlG [NN nConstructorName])) ∧
  (stoppers nPapp =
     UNIV DIFF ({LparT; UnderbarT; LbrackT} ∪ { IntT i | T } ∪
                { StringT s | T } ∪ { CharT c | T } ∪
                firstSet cmlG [NN nV] ∪ firstSet cmlG [NN nConstructorName])) ∧
  (stoppers nPattern =
     UNIV DIFF ({LparT; UnderbarT; LbrackT; ColonT; ArrowT; StarT} ∪
                { AlphaT s | T } ∪ { SymbolT s | T } ∪ { LongidT s1 s2 | T } ∪
                { IntT i | T } ∪ { StringT s | T } ∪ { CharT c | T } ∪
                firstSet cmlG [NN nV] ∪ firstSet cmlG [NN nConstructorName])) ∧
  (stoppers nPatternList =
     UNIV DIFF ({CommaT; LparT; UnderbarT; LbrackT; ColonT; ArrowT; StarT} ∪
                { AlphaT s | T } ∪ { SymbolT s | T } ∪ { LongidT s1 s2 | T } ∪
                {IntT i | T} ∪ { StringT s | T } ∪ { CharT c | T } ∪
                firstSet cmlG [NN nV] ∪ firstSet cmlG [NN nConstructorName])) ∧
  (stoppers nPbaseList1 = UNIV DIFF firstSet cmlG [NN nPbase]) ∧
  (stoppers nPE = nestoppers) ∧
  (stoppers nPE' = BarT INSERT nestoppers) ∧
  (stoppers nPEs = nestoppers) ∧
  (stoppers nPType = UNIV DIFF ({StarT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nSpecLine =
     UNIV DIFF ({ArrowT; AndT; BarT; StarT; OfT; EqualsT} ∪
                firstSet cmlG [NN nTyOp])) ∧
  (stoppers nSpecLineList =
     UNIV DIFF ({ValT; DatatypeT; TypeT; ExceptionT; SemicolonT;
                 ArrowT; AndT; BarT; StarT; OfT; EqualsT} ∪
                firstSet cmlG [NN nTyOp])) ∧
  (stoppers nTopLevelDec =
     nestoppers DIFF {BarT; StarT; AndT; OfT}) ∧
  (stoppers nTopLevelDecs = ∅) ∧
  (stoppers nType = UNIV DIFF ({ArrowT; StarT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nTypeAbbrevDec =
     UNIV DIFF ({ArrowT; StarT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nTypeDec =
     UNIV DIFF ({AndT; ArrowT; StarT; BarT; OfT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nTypeList1 =
     UNIV DIFF ({CommaT; ArrowT; StarT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nTypeList2 =
     UNIV DIFF ({CommaT; ArrowT; StarT} ∪ firstSet cmlG [NN nTyOp])) ∧
  (stoppers nTyVarList = {RparT}) ∧
  (stoppers nOptionalSignatureAscription = UNIV DELETE SealT) ∧
  (stoppers _ = UNIV)
`;
val _ = export_rewrites ["stoppers_def"]


fun attack_asmguard (g as (asl,w)) = let
  val (l,r) = dest_imp w
  val (h,c) = dest_imp l
in
  SUBGOAL_THEN h (fn th => DISCH_THEN (fn imp => MP_TAC (MATCH_MP imp th)))
end g
val normlist = REWRITE_TAC [GSYM APPEND_ASSOC, listTheory.APPEND]

val eapp_complete = Q.store_thm(
  "eapp_complete",
  `(∀pt' pfx' sfx' N.
       LENGTH pfx' < LENGTH master ∧ valid_ptree cmlG pt' ∧
       mkNT N ∈ FDOM cmlPEG.rules ∧
       ptree_head pt' = NN N ∧ ptree_fringe pt' = MAP TK pfx' ∧
       (sfx' ≠ [] ⇒ HD sfx' ∈ stoppers N) ⇒
       peg_eval cmlPEG (pfx' ++ sfx', nt (mkNT N) I) (SOME(sfx', [pt']))) ∧
    (∀pt' sfx'.
       valid_ptree cmlG pt' ∧ ptree_head pt' = NN nEbase ∧
       ptree_fringe pt' = MAP TK master ∧
       (sfx' ≠ [] ⇒ HD sfx' ∈ stoppers nEbase) ⇒
       peg_eval cmlPEG (master ++ sfx', nt (mkNT nEbase) I) (SOME (sfx', [pt'])))
    ⇒
     ∀pfx apt sfx.
       IS_SUFFIX master pfx ∧ valid_ptree cmlG apt ∧
       ptree_head apt = NN nEapp ∧ ptree_fringe apt = MAP TK pfx ∧
       (sfx ≠ [] ⇒ HD sfx ∈ stoppers nEapp) ⇒
       peg_eval cmlPEG (pfx ++ sfx, nt (mkNT nEapp) I) (SOME(sfx, [apt]))`,
  strip_tac >>
  simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, (*list_case_lemma, *)
       peg_eval_rpt, GSYM LEFT_EXISTS_AND_THM, GSYM RIGHT_EXISTS_AND_THM] >>
  gen_tac >>
  completeInduct_on `LENGTH pfx` >> qx_gen_tac `pfx` >> strip_tac >>
  rveq >> fs[GSYM RIGHT_FORALL_IMP_THM] >>
  map_every qx_gen_tac [`apt`, `sfx`] >> strip_tac >>
  `∃subs. apt = Nd (mkNT nEapp) subs`
    by (Cases_on `apt` >> fs[MAP_EQ_CONS] >> rw[]) >>
  fs[MAP_EQ_CONS, MAP_EQ_APPEND, cmlG_FDOM, cmlG_applied] >> rw[] >>
  fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
  >- (asm_match `ptree_head apt = NN nEapp` >>
      asm_match `ptree_fringe apt = MAP TK af` >>
      asm_match `ptree_head bpt = NN nEbase` >>
      asm_match `ptree_fringe bpt = MAP TK bf` >>
      qspecl_then [`apt`, `bpt`, `af`, `bf`] mp_tac eapp_reassociated >>
      simp[MAP_EQ_APPEND, GSYM LEFT_EXISTS_AND_THM, GSYM RIGHT_EXISTS_AND_THM]>>
      disch_then (qxchl [`apt'`, `bpt'`, `bf'`, `af'`] strip_assume_tac) >>
      simp[] >> map_every qexists_tac [`[bpt']`,`af' ++ sfx`] >>
      CONV_TAC EXISTS_AND_CONV >>
      `LENGTH (af ++ bf) ≤ LENGTH master`
        by (Q.UNDISCH_THEN `af ++ bf = bf' ++ af'` SUBST_ALL_TAC >>
            fs[rich_listTheory.IS_SUFFIX_compute] >>
            imp_res_tac rich_listTheory.IS_PREFIX_LENGTH >> fs[]) >>
      erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_Ebase) >>
      erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_Eapp) >>
      simp[] >> ntac 2 strip_tac >>
      `LENGTH (bf' ++ af') ≤ LENGTH master` by metis_tac[] >> fs[] >>
      conj_tac
      >- (normlist >> first_assum (match_mp_tac o has_length) >> simp[]) >>
      simp[] >>
      first_x_assum (qspecl_then [`af'`, `apt'`, `sfx`] mp_tac) >> simp[] >>
      `LENGTH af + LENGTH bf = LENGTH bf' + LENGTH af'`
        by metis_tac [listTheory.LENGTH_APPEND] >> simp[] >>
      fs[rich_listTheory.IS_SUFFIX_compute, listTheory.REVERSE_APPEND] >>
      imp_res_tac rich_listTheory.IS_PREFIX_APPEND1 >> simp[] >>
      disch_then (qxchl [`bpt_list`, `ii`, `blist`] strip_assume_tac) >>
      erule mp_tac peg_sound >> disch_then (qxchl [`bpt2`] strip_assume_tac) >>
      fs[] >> rveq >>
      qexists_tac `[bpt2]::blist` >>
      simp[Once peg_eval_cases, left_insert1_FOLDL,
           left_insert1_def] >> metis_tac[]) >>
  asm_match `ptree_head bpt = NN nEbase` >>
  map_every qexists_tac [`[bpt]`, `sfx`, `[]`] >>
  simp[left_insert1_def] >> reverse conj_tac
  >- (simp[Once peg_eval_cases] >>
      Cases_on `sfx` >>
      fs[peg_respects_firstSets, not_peg0_peg_eval_NIL_NONE]) >>
  first_x_assum (kall_tac o assert (is_forall o concl)) >>
  fs[rich_listTheory.IS_SUFFIX_compute] >>
  imp_res_tac rich_listTheory.IS_PREFIX_LENGTH >>
  fs[DECIDE ``x:num ≤ y ⇔ x = y ∨ x < y``] >>
  `pfx = master`
    by metis_tac[rich_listTheory.IS_PREFIX_LENGTH_ANTI,
                 REVERSE_11, listTheory.LENGTH_REVERSE] >>
  rveq >> simp[]);

val leftmost_FOLDL = Q.store_thm(
  "leftmost_FOLDL",
  `leftmost (FOLDL (λa b. Nd (mkNT nDType) [a;b]) acc args) =
    leftmost acc`,
  qid_spec_tac `acc` >> Induct_on `args` >> simp[leftmost_def]);

val dtype_complete = Q.store_thm(
  "dtype_complete",
  `(∀pt' pfx' sfx' N.
       LENGTH pfx' < LENGTH master ∧ valid_ptree cmlG pt' ∧
       mkNT N ∈ FDOM cmlPEG.rules ∧
       ptree_head pt' = NN N ∧ ptree_fringe pt' = MAP TK pfx' ∧
       (sfx' ≠ [] ⇒ HD sfx' ∈ stoppers N) ⇒
       peg_eval cmlPEG (pfx' ++ sfx', nt (mkNT N) I) (SOME(sfx', [pt']))) ∧
    (∀pt' sfx'.
       valid_ptree cmlG pt' ∧ ptree_head pt' = NN nTbase ∧
       ptree_fringe pt' = MAP TK master ∧
       (sfx' ≠ [] ⇒ HD sfx' ∈ stoppers nEbase) ⇒
       peg_eval cmlPEG (master ++ sfx',nt (mkNT nTbase) I) (SOME (sfx', [pt'])))
    ⇒
     ∀pfx apt sfx.
       IS_SUFFIX master pfx ∧ valid_ptree cmlG apt ∧
       ptree_head apt = NN nDType ∧ ptree_fringe apt = MAP TK pfx ∧
       (sfx ≠ [] ⇒ HD sfx ∈ stoppers nDType) ⇒
       peg_eval cmlPEG (pfx ++ sfx, nt (mkNT nDType) I) (SOME(sfx, [apt]))`,
  strip_tac >>
  simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, (*list_case_lemma, *)
       peg_eval_rpt, GSYM LEFT_EXISTS_AND_THM, GSYM RIGHT_EXISTS_AND_THM] >>
  gen_tac >>
  completeInduct_on `LENGTH pfx` >> qx_gen_tac `pfx` >> strip_tac >>
  rveq >> fs[GSYM RIGHT_FORALL_IMP_THM] >>
  map_every qx_gen_tac [`apt`, `sfx`] >> strip_tac >>
  `∃subs. apt = Nd (mkNT nDType) subs`
    by (Cases_on `apt` >> fs[MAP_EQ_CONS] >> rw[]) >>
  fs[MAP_EQ_CONS, MAP_EQ_APPEND, cmlG_FDOM, cmlG_applied] >> rw[] >>
  fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
  >- (asm_match `ptree_head apt = NN nDType` >>
      asm_match `ptree_fringe apt = MAP TK af` >>
      asm_match `ptree_head bpt = NN nTyOp` >>
      asm_match `ptree_fringe bpt = MAP TK bf` >>
      qspecl_then [`apt`, `bpt`, `af`, `bf`] mp_tac dtype_reassociated >>
      simp[MAP_EQ_APPEND, GSYM LEFT_EXISTS_AND_THM, GSYM RIGHT_EXISTS_AND_THM]>>
      disch_then (qxchl [`apt'`, `bpt'`, `bf'`, `af'`] strip_assume_tac) >>
      simp[] >> map_every qexists_tac [`[bpt']`,`af' ++ sfx`] >>
      CONV_TAC EXISTS_AND_CONV >>
      `LENGTH (af ++ bf) ≤ LENGTH master`
        by (Q.UNDISCH_THEN `af ++ bf = bf' ++ af'` SUBST_ALL_TAC >>
            fs[rich_listTheory.IS_SUFFIX_compute] >>
            imp_res_tac rich_listTheory.IS_PREFIX_LENGTH >> fs[]) >>
      erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_Tbase) >>
      erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_DType) >>
      simp[] >> ntac 2 strip_tac >>
      `LENGTH (bf' ++ af') ≤ LENGTH master` by metis_tac[] >> fs[] >>
      conj_tac
      >- (normlist >> first_assum (match_mp_tac o has_length) >> simp[]) >>
      simp[] >>
      first_x_assum (qspecl_then [`af'`, `apt'`, `sfx`] mp_tac) >> simp[] >>
      `LENGTH af + LENGTH bf = LENGTH bf' + LENGTH af'`
        by metis_tac [listTheory.LENGTH_APPEND] >> simp[] >>
      fs[rich_listTheory.IS_SUFFIX_compute, listTheory.REVERSE_APPEND] >>
      imp_res_tac rich_listTheory.IS_PREFIX_APPEND1 >> simp[] >>
      disch_then (qxchl [`bpt_list`, `ii`, `blist`] strip_assume_tac) >>
      erule mp_tac peg_sound >> disch_then (qxchl [`bpt2`] strip_assume_tac) >>
      fs[] >> rveq >> fs[leftmost_FOLDL] >>
      `∃subs. bpt2 = Nd (mkNT nTbase) subs`
        by (Cases_on`bpt2` >> fs[listTheory.APPEND_EQ_CONS] >> rw[] >>
            fs[MAP_EQ_CONS]) >>
      `∃tyoppt. subs = [tyoppt] ∧ ptree_head tyoppt = NN nTyOp ∧
                valid_ptree cmlG tyoppt`
        by (fs[cmlG_applied, cmlG_FDOM, leftmost_def, MAP_EQ_CONS] >> fs[]) >>
      rveq >>
      qexists_tac `[tyoppt]::blist` >>
      simp[left_insert2_def, left_insert2_FOLDL] >>
      simp[Once peg_eval_cases] >>
      qexists_tac `ii` >> simp[] >>
      qpat_x_assum `peg_eval X Y Z` mp_tac >>
      simp[SimpL ``(==>)``, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_Tbase) >>
      simp[] >> strip_tac >> fs[cmlG_FDOM, cmlG_applied] >>
      Cases_on `af'` >> fs[] >>
      Cases_on `ptree_fringe tyoppt` >> fs[] >> rveq >>
      asm_match `ptree_fringe tyoppt = TK h::tks` >>
      `h ≠ LparT ∧ ¬isTyvarT h`
        by (erule mp_tac
                  (REWRITE_RULE [GSYM AND_IMP_INTRO] firstSet_nonempty_fringe)>>
            simp[] >> rpt strip_tac >> rveq >> fs[]) >>
      simp[]) >>
  asm_match `ptree_head bpt = NN nTbase` >>
  map_every qexists_tac [`[bpt]`, `sfx`, `[]`] >>
  simp[] >> reverse conj_tac
  >- (simp[Once peg_eval_cases] >>
      Cases_on `sfx` >>
      fs[peg_respects_firstSets, not_peg0_peg_eval_NIL_NONE]) >>
  first_x_assum (kall_tac o assert (is_forall o concl)) >>
  fs[rich_listTheory.IS_SUFFIX_compute] >>
  imp_res_tac rich_listTheory.IS_PREFIX_LENGTH >>
  fs[DECIDE ``x:num ≤ y ⇔ x = y ∨ x < y``] >>
  `pfx = master`
    by metis_tac[rich_listTheory.IS_PREFIX_LENGTH_ANTI,
                 REVERSE_11, listTheory.LENGTH_REVERSE] >>
  rveq >> simp[]);

(* could generalise this slightly: allowing for nullable seps, but this would
   require a more complicated condition on the sfx, something like
     (sfx ≠ [] ∧ ¬nullable cmlG [SEP] ⇒ HD sfx ∉ firstSet cmlG [SEP]) ∧
     (sfx ≠ [] ∧ nullable cmlG [SEP] ⇒ HD sfx ∉ firstSet cmlG [C])
   and I can't be bothered with that right now. *)

val peg_linfix_complete = Q.store_thm(
  "peg_linfix_complete",
  `(∀n. SEP = NT n ⇒
         ∃nn. n = mkNT nn ∧ nt (mkNT nn) I ∈ Gexprs cmlPEG ∧
              stoppers nn = UNIV) ∧
    (∀n. C = NT n ⇒ ∃nn. n = mkNT nn) ∧
    (∀t. t ∈ firstSet cmlG [SEP] ⇒ t ∉ stoppers P) ∧
    (∀n. C = NT (mkNT n) ⇒
         (∀t. t ∈ firstSet cmlG [SEP] ⇒ t ∈ stoppers n) ∧
         (∀t. t ∈ stoppers P ⇒ t ∈ stoppers n)) ∧
    ¬peg0 cmlPEG (sym2peg C) ∧ ¬nullable cmlG [C] ∧
    ¬peg0 cmlPEG (sym2peg SEP) ∧ ¬nullable cmlG [SEP] ∧
    cmlG.rules ' (mkNT P) = { [NT (mkNT P); SEP; C] ; [C] } ∧
    (∀pt pfx0 sfx.
       LENGTH pfx0 < LENGTH master ∧
       (∀n. ptree_head pt = NT (mkNT n) ∧ sfx ≠ [] ⇒ HD sfx ∈ stoppers n) ∧
       valid_ptree cmlG pt ∧ ptree_head pt ∈ {SEP; C} ∧
       ptree_fringe pt = MAP TOK pfx0 ⇒
       peg_eval cmlPEG (pfx0 ++ sfx, sym2peg (ptree_head pt))
                       (SOME(sfx,[pt]))) ∧
    (∀pt sfx.
       valid_ptree cmlG pt ∧ ptree_head pt = C ∧
       (∀n. C = NT (mkNT n) ∧ sfx ≠ [] ⇒ HD sfx ∈ stoppers n) ∧
       ptree_fringe pt = MAP TOK master ⇒
       peg_eval cmlPEG (master ++ sfx, sym2peg C) (SOME(sfx,[pt])))
 ⇒
    ∀pfx pt sfx.
      IS_SUFFIX master pfx ∧
      valid_ptree cmlG pt ∧ ptree_head pt = NT (mkNT P) ∧
      (sfx ≠ [] ⇒ HD sfx ∈ stoppers P) ∧
      ptree_fringe pt = MAP TOK pfx
  ⇒
      peg_eval cmlPEG (pfx ++ sfx,
                       peg_linfix (mkNT P) (sym2peg C) (sym2peg SEP))
                      (SOME(sfx,[pt]))`,
  strip_tac >>
  simp[peg_linfix_def, list_case_lemma, peg_eval_rpt] >> dsimp[] >>
  gen_tac >>
  completeInduct_on `LENGTH pfx` >> rpt strip_tac >>
  full_simp_tac (srw_ss() ++ DNF_ss) [] >> rveq >>
  `∃subs. pt = Nd (mkNT P) subs`
    by (Cases_on `pt` >> fs[MAP_EQ_CONS] >> rw[] >> fs[]) >> rw[] >> fs[] >>
  Q.UNDISCH_THEN `MAP ptree_head subs ∈ cmlG.rules ' (mkNT P)` mp_tac >>
  simp[MAP_EQ_CONS] >> reverse (rpt strip_tac) >> rveq >> fs[]
  >- (asm_match `ptree_fringe cpt = MAP TK pfx` >>
      map_every qexists_tac [`sfx`, `[cpt]`, `[]`] >>
      first_x_assum (kall_tac o has_length) >>
      conj_tac
      >- (fs[rich_listTheory.IS_SUFFIX_compute] >>
          IMP_RES_THEN (assume_tac o SIMP_RULE (srw_ss()) [])
            rich_listTheory.IS_PREFIX_LENGTH >>
          Cases_on `cpt`
          >- fs[MAP_EQ_SING, sym2peg_def] >>
          fs[] >> rveq >> fs[sym2peg_def] >>
          fs[DECIDE ``x:num ≤ y ⇔ x < y ∨ x = y``] >>
          `pfx = master` suffices_by rw[] >>
          metis_tac[rich_listTheory.IS_PREFIX_LENGTH_ANTI, REVERSE_11,
                    listTheory.LENGTH_REVERSE]) >>
      simp[Once peg_eval_cases, mk_linfix_def, peg_eval_seq_NONE] >>
      DISJ1_TAC >>
      Cases_on `SEP` >> fs[sym2peg_def, peg_eval_tok_NONE]
      >- (Cases_on `sfx` >> fs[] >> strip_tac >> fs[]) >> rveq >> fs[] >>
      Cases_on `sfx` >- simp[not_peg0_peg_eval_NIL_NONE, PEG_wellformed] >>
      fs[] >> metis_tac [peg_respects_firstSets]) >>
  fs[DISJ_IMP_THM, FORALL_AND_THM] >>
  asm_match `
    cmlG.rules ' (mkNT P) = {[NN P; ptree_head spt; ptree_head cpt];
                             [ptree_head cpt]}
  ` >> asm_match `ptree_head ppt = NN P` >>
  fs[MAP_EQ_APPEND] >> rw[] >>
  asm_match `ptree_fringe ppt = MAP TK pf` >>
  asm_match `ptree_fringe spt = MAP TK sf` >>
  asm_match `ptree_fringe cpt = MAP TK cf` >>
  qispl_then [`cmlG`, `mkNT P`, `ptree_head spt`, `ptree_head cpt`,
              `ppt`, `spt`, `cpt`, `pf`, `sf`, `cf`] mp_tac
    lassoc_reassociated >> simp[MAP_EQ_APPEND] >>
  dsimp[] >>
  map_every qx_gen_tac [`cpt'`, `spt'`, `ppt'`]  >> rpt strip_tac >>
  asm_match `ptree_fringe cpt' = MAP TK cf'` >>
  asm_match `ptree_fringe spt' = MAP TK sf'` >>
  asm_match `ptree_fringe ppt' = MAP TK pf'` >>
  map_every qexists_tac [`sf' ++ pf' ++ sfx`, `[cpt']`] >>
  `0 < LENGTH (MAP TK sf') ∧ 0 < LENGTH (MAP TK cf')`
    by metis_tac [fringe_length_not_nullable] >>
  ntac 2 (pop_assum mp_tac) >> simp[] >> ntac 2 strip_tac >>
  CONV_TAC EXISTS_AND_CONV >> conj_tac
  >- (REWRITE_TAC [GSYM APPEND_ASSOC] >>
      first_x_assum match_mp_tac >> simp[] >>
      conj_tac
      >- (fs[rich_listTheory.IS_SUFFIX_compute] >>
          IMP_RES_THEN mp_tac rich_listTheory.IS_PREFIX_LENGTH >>
          simp[]) >>
      Cases_on `sf'` >> fs[] >>
      rpt (first_x_assum (kall_tac o has_length)) >> rpt strip_tac >>
      fs[] >>
      asm_match `ptree_fringe spt' = TK s1::MAP TK ss` >>
      `s1 ∈ firstSet cmlG [ptree_head spt']`
        by metis_tac [firstSet_nonempty_fringe] >>
      metis_tac[]) >>
  first_x_assum (qspecl_then [`pf'`, `ppt'`, `sfx`] mp_tac) >>
  first_assum (SUBST1_TAC o assert (listSyntax.is_append o lhs o concl)) >>
  simp[] >>
  `IS_SUFFIX master pf'`
    by (first_x_assum (SUBST_ALL_TAC o
                       assert (listSyntax.is_append o lhs o concl)) >>
        fs[rich_listTheory.IS_SUFFIX_compute,
           listTheory.REVERSE_APPEND] >>
        metis_tac[rich_listTheory.IS_PREFIX_APPEND1]) >>
  simp[] >>
  disch_then (qxchl [`pf1`, `cplist`, `sclist`] strip_assume_tac) >>
  first_x_assum (kall_tac o assert (is_forall o concl)) >>
  first_x_assum (qspecl_then [`spt'`, `sf'`, `pf' ++ sfx`] mp_tac o
                 assert (free_in ``spt:mlptree`` o concl)) >>
  simp[] >>
  Q.UNDISCH_THEN `IS_SUFFIX master (pf ++ sf ++ cf)` mp_tac >>
  simp[rich_listTheory.IS_SUFFIX_compute] >>
  disch_then (mp_tac o MATCH_MP rich_listTheory.IS_PREFIX_LENGTH) >>
  simp[] >> strip_tac >> attack_asmguard
  >- (gen_tac >> disch_then (CONJUNCTS_THEN assume_tac) >> fs[]) >>
  strip_tac >>
  simp[Once peg_eval_cases] >> dsimp[] >> DISJ2_TAC >>
  map_every qexists_tac [`pf1`, `sclist`, `pf' ++ sfx`, `[spt']`,
                         `cplist`] >> simp[] >>
  Cases_on `ptree_head cpt`
  >- (fs[sym2peg_def] >>
      simp[mk_linfix_def, left_insert_mk_linfix, left_insert_def]) >>
  simp[left_insert_mk_linfix] >> fs[sym2peg_def] >>
  first_x_assum (mp_tac o MATCH_MP peg_sound) >> rw[] >>
  simp[mk_linfix_def, left_insert_def]);

val peg_eval_NT_NONE = save_thm(
  "peg_eval_NT_NONE",
  ``peg_eval cmlPEG (i0, nt (mkNT n) I) NONE``
     |> SIMP_CONV (srw_ss()) [Once peg_eval_cases])

val stdstart =
    simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, MAP_EQ_CONS] >> rw[] >>
    fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]

fun note_tac s g = (print (s ^ "\n"); ALL_TAC g)

val list_case_eq = prove_case_eq_thm {
  case_def= TypeBase.case_def_of ``:'a list``,
  nchotomy = TypeBase.nchotomy_of ``:'a list``}

fun hasc cnm t = #1 (dest_const t) = cnm handle HOL_ERR _ => false
fun const_assum0 f cnm k =
  f (k o assert (can (find_term (hasc cnm)) o concl))
val const_assum = const_assum0 first_assum
val const_x_assum = const_assum0 first_x_assum

val completeness = Q.store_thm(
  "completeness",
  `∀pt N pfx sfx.
      valid_ptree cmlG pt ∧ ptree_head pt = NT (mkNT N) ∧
      mkNT N ∈ FDOM cmlPEG.rules ∧
      (sfx ≠ [] ⇒ HD sfx ∈ stoppers N) ∧ ptree_fringe pt = MAP TOK pfx ⇒
      peg_eval cmlPEG (pfx ++ sfx, nt (mkNT N) I)
                      (SOME(sfx, [pt]))`,
  ho_match_mp_tac parsing_ind >> qx_gen_tac `pt` >>
  disch_then (strip_assume_tac o SIMP_RULE (srw_ss() ++ DNF_ss) []) >>
  RULE_ASSUM_TAC (SIMP_RULE (srw_ss() ++ CONJ_ss) [AND_IMP_INTRO]) >>
  map_every qx_gen_tac [`N`, `pfx`, `sfx`] >> strip_tac >> fs[] >>
  `∃subs. pt = Nd (mkNT N) subs`
  by (Cases_on `pt` >> simp[] >> fs[] >> rw[] >> fs[MAP_EQ_SING]) >>
  rveq >> fs[] >>
  rpt (first_x_assum (mp_tac o assert (free_in ``cmlG.rules`` o concl))) >>
  Cases_on `N` >> simp[cmlG_applied, cmlG_FDOM]
  >- (print_tac "nV" >>
      simp[peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG, peg_V_def,
           peg_eval_choice, peg_eval_tok_NONE] >>
      dsimp[MAP_EQ_SING] >> rpt strip_tac >> rveq >>
      fs[MAP_EQ_SING])
  >- (print_tac "nUQTyOp" >>
      simp[MAP_EQ_SING] >> simp[peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG,
           peg_eval_choice, peg_eval_tok_NONE] >>
      strip_tac >> rveq >> fs[MAP_EQ_SING])
  >- (print_tac "nUQConstructorName" >>
      simp[MAP_EQ_SING, peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG, peg_UQConstructorName_def] >>
      strip_tac >> rveq >> fs[MAP_EQ_SING])
  >- (print_tac "nTyvarN" >> dsimp[MAP_EQ_SING] >> simp[peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG] >> rpt strip_tac >>
      fs[MAP_EQ_SING])
  >- (print_tac "nTypeName" >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, FDOM_cmlPEG] >>
      rpt strip_tac >> rveq >> fs[]
      >- (DISJ1_TAC >> fs[MAP_EQ_SING] >> rveq >>
          asm_match `ptree_head pt = NN nUQTyOp` >>
          first_x_assum (qspecl_then [`pt`, `nUQTyOp`, `sfx`] mp_tac)>>
          simp[NT_rank_def] >> fs[])
      >- (DISJ2_TAC >> fs[MAP_EQ_CONS] >> simp[peg_eval_seq_NONE] >> rveq >>
          fs[] >>
          asm_match `ptree_head tyvl_pt = NN nTyVarList` >>
          asm_match `ptree_head tyop_pt = NN nUQTyOp` >>
          fs [MAP_EQ_APPEND, MAP_EQ_SING, MAP_EQ_CONS] >> rveq >>
          asm_match `ptree_fringe tyop_pt = MAP TK opf` >> conj_tac
          >- simp[Once peg_eval_cases, FDOM_cmlPEG,
                  cmlpeg_rules_applied, peg_eval_tok_NONE] >>
          dsimp[] >>
          map_every qexists_tac [`[tyvl_pt]`, `opf ++ sfx`, `[tyop_pt]`] >>
          simp[] >>
          asm_match `ptree_fringe tyvl_pt = MAP TK vlf` >>
          normlist >>
          simp[FDOM_cmlPEG]) >>
      DISJ2_TAC >> fs[MAP_EQ_CONS] >> rveq >> fs[MAP_EQ_CONS] >> rveq >>
      simp[peg_eval_seq_NONE, peg_eval_tok_NONE] >>
      simp[Once peg_eval_cases, FDOM_cmlPEG, cmlpeg_rules_applied,
           peg_eval_tok_NONE])
  >- (print_tac "nTypeList2" >> dsimp[MAP_EQ_CONS] >>
      map_every qx_gen_tac [`typt`, `tylpt`] >> rw[] >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS] >> rw[] >>
      simp[peg_eval_NT_SOME] >> simp[cmlpeg_rules_applied, FDOM_cmlPEG] >>
      dsimp[] >> asm_match `ptree_fringe typt = MAP TK tyf` >>
      asm_match `MAP TK lf = ptree_fringe tylpt` >>
      first_assum (qspecl_then [`typt`, `nType`, `tyf`, `CommaT::lf ++ sfx`]
                               mp_tac o has_length) >>
      simp_tac (srw_ss() ++ ARITH_ss) [FDOM_cmlPEG] >> simp[] >> strip_tac >>
      map_every qexists_tac [`[typt]`, `lf ++ sfx`, `[tylpt]`] >>
      simp[FDOM_cmlPEG])
  >- (print_tac "nTypeList1" >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rw[] >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS] >> rw[]
      >- (first_assum (unify_firstconj kall_tac) >> simp[NT_rank_def] >>
          simp[peg_eval_tok_NONE] >> Cases_on `sfx` >> fs[]) >>
      normlist >> first_assum (unify_firstconj kall_tac) >> simp[NT_rank_def])
  >- (print_tac "nTypeDec" >> dsimp[MAP_EQ_CONS] >> qx_gen_tac `dtspt` >>
      rw[] >> fs[DISJ_IMP_THM, FORALL_AND_THM, MAP_EQ_CONS] >> rw[] >>
      simp[peg_eval_NT_SOME] >>
      simp[FDOM_cmlPEG, cmlpeg_rules_applied, peg_TypeDec_def] >>
      asm_match `MAP TK pfx = ptree_fringe dtspt` >>
      match_mp_tac
      (peg_linfix_complete
         |> Q.INST [`SEP` |-> `TK AndT`, `C` |-> `NN nDtypeDecl`,
                    `P` |-> `nDtypeDecls`, `master` |-> `pfx`]
         |> SIMP_RULE (srw_ss() ++ DNF_ss) [sym2peg_def, MAP_EQ_CONS,
                                            cmlG_applied, EXTENSION,
                                            DISJ_COMM, AND_IMP_INTRO]) >>
      simp[FDOM_cmlPEG])
  >- (print_tac "nTypeAbbrevDec" >> dsimp[MAP_EQ_CONS] >>
      qx_genl_tac [`nmpt`, `typt`] >> rw[] >>
      fs[DISJ_IMP_THM, FORALL_AND_THM, MAP_EQ_CONS] >> rw[] >>
      simp[peg_eval_NT_SOME] >>
      simp[FDOM_cmlPEG, cmlpeg_rules_applied] >> dsimp[] >>
      qexists_tac `[nmpt]` >> simp[] >>
      fs[MAP_EQ_APPEND] >> rveq >> fs[MAP_EQ_CONS] >> rveq >>
      REWRITE_TAC [GSYM APPEND_ASSOC, listTheory.APPEND] >>
      first_assum (unify_firstconj kall_tac) >> simp[])
  >- (print_tac "nType" >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, MAP_EQ_CONS] >> rw[] >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
      >- (first_assum (unify_firstconj kall_tac) >> simp[NT_rank_def] >>
          simp[peg_eval_tok_NONE] >> Cases_on `sfx` >> fs[]) >>
      normlist >> first_assum (unify_firstconj kall_tac) >>
      simp[])
  >- (print_tac "nTyVarList" >> simp[peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG] >>
      disch_then assume_tac >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`C` |-> `NN nTyvarN`, `SEP` |-> `TK CommaT`,
                                 `P` |-> `nTyVarList`,
                                 `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                      [sym2peg_def, cmlG_applied, cmlG_FDOM, EXTENSION,
                       DISJ_COMM, AND_IMP_INTRO]) >>
      simp[MAP_EQ_SING] >> simp[cmlG_FDOM, cmlG_applied] >>
      `NT_rank (mkNT nTyvarN) < NT_rank (mkNT nTyVarList)`
      by simp[NT_rank_def]>> simp[FDOM_cmlPEG] >> fs[])
  >- (print_tac "nTyOp" >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, MAP_EQ_CONS] >>
      rw[] >> fs[MAP_EQ_CONS] >- simp[NT_rank_def] >>
      simp[peg_respects_firstSets, firstSet_nUQTyOp])
  >- (print_tac "nTopLevelDecs" >> dsimp[MAP_EQ_CONS] >> rpt conj_tac >>
      rpt gen_tac >> strip_tac >> rveq >> simp[peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG] >> fs[]
      >- (disj1_tac >> dsimp[] >> fs[DISJ_IMP_THM, FORALL_AND_THM] >> rw[] >>
          rename1 `ptree_head Ept = NN nE` >>
          fs[MAP_EQ_APPEND, MAP_EQ_CONS] >> rveq >>
          rename1 `ptree_fringe Ept = MAP TK Efr` >>
          rename1 `ptree_head TLDpt = NN nTopLevelDecs` >>
          rename1 `ptree_fringe TLDpt = MAP TK TLDfr` >>
          first_assum
            (qspecl_then [`Ept`, `nE`, `Efr`, `SemicolonT :: TLDfr`]
                         mp_tac) >>
          impl_tac >- simp[] >>
          strip_tac >>
          map_every qexists_tac [`[Ept]`, `TLDfr`, `[TLDpt]`] >>
          simp[] >> conj_tac
          >- asm_simp_tac bool_ss [GSYM APPEND_ASSOC, APPEND] >>
          first_x_assum
            (qspecl_then [`TLDpt`, `nTopLevelDecs`, `TLDfr`, `[]`] mp_tac) >>
          simp[])
      >- (disj2_tac >> fs[MAP_EQ_APPEND] >> fs[DISJ_IMP_THM, FORALL_AND_THM] >>
          rveq >>
          rename1 `ptree_head TLDpt = NN nTopLevelDec` >>
          rename1 `ptree_head NeTLDspt = NN nNonETopLevelDecs` >>
          rename1 `ptree_fringe TLDpt = MAP TK TLDfr` >>
          rename1 `ptree_fringe NeTLDspt = MAP TK NeTLDsfr` >>
          `peg_eval cmlPEG (TLDfr ++ NeTLDsfr, nt (mkNT nTopLevelDec) I)
                           (SOME (NeTLDsfr, [TLDpt]))`
             by (Cases_on `NeTLDsfr = []`
                 >- (loseC ``LENGTH`` >>
                     first_x_assum (qspecl_then [`TLDpt`, `nTopLevelDec`, `[]`]
                                                mp_tac) >>
                     simp[NT_rank_def]) >>
                 loseC ``NT_rank`` >>
                 `0 < LENGTH NeTLDsfr` by (Cases_on `NeTLDsfr` >> fs[]) >>
                 first_x_assum irule >> simp[] >>
                 Cases_on `NeTLDsfr` >> fs[] >>
                 rename1 `ptree_fringe NeTLDspt = TK tok1 :: _` >>
                 `tok1 ∈ firstSet cmlG [NN nNonETopLevelDecs]`
                   by metis_tac[firstSet_nonempty_fringe] >>
                 fs[]) >>
          `0 < LENGTH (MAP TK TLDfr)`
            by metis_tac[fringe_length_not_nullable, nullable_TopLevelDec] >>
          fs[] >>
          `∃tok1 TLDfr0. TLDfr = tok1 :: TLDfr0` by (Cases_on `TLDfr` >> fs[])>>
          rveq >> fs[] >>
          `tok1 ∈ firstSet cmlG [NN nTopLevelDec]`
            by metis_tac[firstSet_nonempty_fringe] >>
          pop_assum (fn th =>
            `peg_eval cmlPEG (tok1::(TLDfr0 ++ NeTLDsfr), nt (mkNT nE) I) NONE`
            by (irule peg_respects_firstSets >> simp[] >> strip_tac >>
                assume_tac th >> fs[firstSet_nE] >> rveq >> fs[])) >> simp[] >>
          disj1_tac >>
          map_every qexists_tac [`[TLDpt]`, `NeTLDsfr`, `[NeTLDspt]`] >>
          simp[] >> loseC ``NT_rank`` >>
          first_x_assum
            (qspecl_then [`NeTLDspt`, `nNonETopLevelDecs`, `NeTLDsfr`, `[]`]
                         mp_tac) >> simp[])
      >- (fs[MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rveq >> disj2_tac >>
          conj_tac
          >- (disj1_tac >> irule peg_respects_firstSets >> simp[]) >>
          disj2_tac >> conj_tac
          >- (disj1_tac >> irule peg_respects_firstSets >> simp[]) >>
          fs[] >> `mkNT nTopLevelDecs ∈ FDOM cmlPEG.rules` by simp[] >>
          metis_tac[APPEND_NIL, DECIDE ``x < SUC x``])
      >- (simp[not_peg0_peg_eval_NIL_NONE] >> disj2_tac >>
          simp[peg_eval_tok_NONE]))
  >- (print_tac "nTopLevelDec" >> simp[peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG] >> strip_tac >>
      fs[MAP_EQ_SING] >> rw[] >> fs[]
      >- (DISJ1_TAC >> first_x_assum match_mp_tac >>
                    simp[NT_rank_def, FDOM_cmlPEG]) >>
      DISJ2_TAC >> reverse conj_tac
      >- (first_x_assum match_mp_tac >> simp[NT_rank_def, FDOM_cmlPEG]) >>
      `0 < LENGTH (MAP TK pfx)`
      by metis_tac [fringe_length_not_nullable, nullable_Decl] >> fs[] >>
      Cases_on `pfx` >> fs[] >>
      match_mp_tac peg_respects_firstSets >>
      simp[PEG_exprs] >> strip_tac >> rw[] >>
      `StructureT ∈ firstSet cmlG [NN nDecl]`
        by metis_tac [firstSet_nonempty_fringe] >> fs[])
  >- (print_tac "nTbase" >> stdstart
      >- simp[peg_eval_tok_NONE]
      >- (DISJ1_TAC >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_TyOp) >>
          simp[] >> Cases_on `pfx` >> simp[peg_eval_tok_NONE] >>
          strip_tac >> rveq >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[])
      >- (DISJ1_TAC >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_TyOp) >>
          simp[] >> Cases_on `pfx` >> simp[peg_eval_tok_NONE] >>
          strip_tac >> rveq >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[])
      >- (DISJ2_TAC >> simp[NT_rank_def] >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_TyOp) >>
          simp[] >> Cases_on `pfx` >> simp[peg_eval_tok_NONE] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> dsimp[])
      >- (DISJ2_TAC >> reverse conj_tac
          >- (DISJ1_TAC >> normlist >> first_assum (unify_firstconj kall_tac) >>
              simp[]) >>
          DISJ2_TAC >> DISJ2_TAC >>
          asm_match `ptree_head lpt = NN nTypeList2` >>
          `∃subs. lpt = Nd (mkNT nTypeList2) subs`
            by (Cases_on `lpt` >> fs[MAP_EQ_CONS] >> rw[]) >>
          fs[MAP_EQ_CONS, MAP_EQ_APPEND, cmlG_FDOM, cmlG_applied] >> rw[] >>
          fs[MAP_EQ_CONS, MAP_EQ_APPEND] >> rw[] >>
          normlist >> first_assum (unify_firstconj kall_tac) >>
          asm_match `ptree_head typt = NN nType` >> qexists_tac `typt` >>
          simp[peg_eval_tok_NONE]) >>
      DISJ1_TAC >> normlist >> simp[])
  >- (print_tac "nStructure" >> dsimp[MAP_EQ_CONS] >> rw[] >>
      fs[DISJ_IMP_THM, FORALL_AND_THM, MAP_EQ_CONS, MAP_EQ_APPEND] >>
      rw[] >> fs[] >>
      simp[peg_eval_NT_SOME] >> simp[cmlpeg_rules_applied, FDOM_cmlPEG] >>
      dsimp[] >> loseC ``NT_rank`` >>
      normlist >> first_assum (unify_firstconj kall_tac) >> simp[] >>
      normlist >> simp[] >>
      first_assum (unify_firstconj kall_tac) >> simp[])
  >- (print_tac "nStructName" >>
      simp[MAP_EQ_SING, peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG, peg_StructName_def] >>
      strip_tac >> rveq >> fs[MAP_EQ_SING])
  >- (print_tac "nSpecLineList" >>
      simp[peg_eval_NT_SOME] >>
      simp[cmlpeg_rules_applied, FDOM_cmlPEG] >> simp[MAP_EQ_CONS] >>
      strip_tac >> rveq >> fs[MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >>
      rw[]
      >- (asm_match `ptree_head slpt = NN nSpecLine` >>
          asm_match `ptree_fringe slpt = MAP TK sf` >>
          asm_match `ptree_head sllpt = NN nSpecLineList` >>
          asm_match `ptree_fringe sllpt = MAP TK lf` >>
          DISJ1_TAC >>
          map_every qexists_tac [`[slpt]`, `lf ++ sfx`, `[sllpt]`] >>
          simp[] >>
          `0 < LENGTH (MAP TK sf)`
            by metis_tac [nullable_SpecLine, fringe_length_not_nullable] >>
          fs[] >>
          Cases_on `lf = []` >> fs[] >- simp[NT_rank_def] >>
          `0 < LENGTH lf` by (Cases_on `lf` >> fs[]) >>
          REWRITE_TAC [GSYM APPEND_ASSOC] >>
          first_x_assum (match_mp_tac o has_length) >> simp[] >>
          Cases_on `lf` >> fs[] >> rpt strip_tac >> rw[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[])
      >- (DISJ2_TAC >> fs[MAP_EQ_CONS] >> rw[] >>
          simp[peg_respects_firstSets, PEG_exprs]) >>
      DISJ2_TAC >> Cases_on `sfx` >> fs[peg_eval_tok_NONE]
      >- simp[not_peg0_peg_eval_NIL_NONE, PEG_exprs, PEG_wellformed] >>
      simp[peg_respects_firstSets, PEG_exprs])
  >- (print_tac "nSpecLine" >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, MAP_EQ_CONS] >> rw[] >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
      >- (DISJ1_TAC >> normlist >>
          first_assum (unify_firstconj kall_tac o has_length) >> simp[])
      >- simp[peg_eval_tok_NONE]
      >- (simp[peg_eval_tok_NONE] >> DISJ1_TAC >> normlist >>
          first_assum (unify_firstconj kall_tac) >> simp[] >> normlist >>
          simp[] >> first_assum match_mp_tac >> simp[])
      >- simp[peg_eval_tok_NONE]
      >- simp[peg_eval_tok_NONE]
      >- (DISJ1_TAC >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable  nullable_TypeDec)>>
          simp[] >> Cases_on `pfx` >> fs[peg_eval_tok_NONE] >> strip_tac >>
          rw[]>> IMP_RES_THEN mp_tac firstSet_nonempty_fringe >>
          simp[])
      >- (DISJ2_TAC >> simp[NT_rank_def] >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable  nullable_TypeDec)>>
          simp[] >> Cases_on `pfx` >> fs[peg_eval_tok_NONE] >> strip_tac >>
          rw[]>> IMP_RES_THEN mp_tac firstSet_nonempty_fringe >>
          simp[]))
  >- (print_tac "nSignatureValue" >> dsimp[MAP_EQ_CONS] >>
      simp[peg_eval_NT_SOME] >> simp[FDOM_cmlPEG, cmlpeg_rules_applied] >>
      rw[] >> fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >>
      rw[] >> normlist >> simp[])
  >- (print_tac "nRelOps" >> simp[peg_eval_NT_SOME] >>
      simp[FDOM_cmlPEG, cmlpeg_rules_applied, MAP_EQ_SING] >>
      strip_tac >> fs[MAP_EQ_SING,peg_eval_tok_NONE])
  (*>- (print_tac "nREPLTop" >> simp[MAP_EQ_CONS] >> rw[] >>
      fs[DISJ_IMP_THM, FORALL_AND_THM, MAP_EQ_APPEND, MAP_EQ_CONS] >> rw[]
      >- (simp[peg_eval_NT_SOME] >> simp[cmlpeg_rules_applied, FDOM_cmlPEG] >>
          DISJ2_TAC >> asm_match `ptree_head tdpt = NN nTopLevelDec` >>
          asm_match `ptree_fringe tdpt = MAP TK tf` >>
          conj_tac
          >- (DISJ1_TAC >>
              `0 < LENGTH (MAP TK tf)`
                by metis_tac[fringe_length_not_nullable,nullable_TopLevelDec] >>
              fs[] >>
              `∃tf0 tft. tf = tf0 :: tft` by (Cases_on `tf` >> fs[]) >> rveq >>
              fs[] >>
              `tf0 ∈ firstSet cmlG [NN nTopLevelDec]`
                by metis_tac [firstSet_nonempty_fringe] >>
              match_mp_tac peg_respects_firstSets >>
              simp[PEG_exprs] >> fs[]) >>
          normlist >> simp[]) >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, FDOM_cmlPEG] >>
      normlist >> simp[])*)
  >- (print_tac "nPtuple" >> stdstart
      >- (simp[peg_eval_tok_NONE] >>
          erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_PatternList) >>
          simp[] >>
          asm_match `ptree_fringe pt = MAP TK f` >> Cases_on `f` >> fs[] >>
          strip_tac >> rw[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[]) >>
      normlist >> simp[])
  >- (print_tac "nPcons" >> stdstart
      >- (normlist >> first_assum (unify_firstconj kall_tac o has_length) >>
          asm_match `ptree_head ppt = NN nPapp` >> qexists_tac `ppt` >>
          simp[] >> first_x_assum (match_mp_tac o has_const ``LENGTH``) >>
          simp[firstSet_nV, firstSet_nConstructorName]) >>
      first_assum (unify_firstconj kall_tac) >> simp[] >>
      conj_tac >- simp[NT_rank_def] >>
      Cases_on `sfx` >> fs[peg_eval_tok_NONE])
  >- (print_tac "nPbaseList1" >> stdstart
      >- (first_x_assum (unify_firstconj mp_tac) >> simp[] >>
          asm_match `ptree_fringe pt = MAP TK pfx` >>
          disch_then (qspec_then `pt` mp_tac) >> simp[NT_rank_def] >>
          strip_tac >> disj2_tac >> rename1 `sfx ≠ []` >>
          Cases_on `sfx` >> simp[not_peg0_peg_eval_NIL_NONE] >>
          match_mp_tac peg_respects_firstSets >> simp[] >> fs[]) >>
      normlist >> first_assum (unify_firstconj mp_tac) >>
      simp_tac (srw_ss()) [] >>
      erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_PbaseList1) >>
      simp[] >> rename1 `0 < LENGTH plf` >> strip_tac >>
      rename1 `ptree_head ppt = NN nPbase` >>
      disch_then (qspec_then `ppt` mp_tac) >> simp[] >>
      strip_tac >> first_x_assum match_mp_tac >> simp[] >>
      erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_Pbase) >>
      simp[])
  >- (print_tac "nPbase" >> stdstart >>
      TRY (simp[peg_respects_firstSets, peg_eval_tok_NONE] >> NO_TAC)
      >- simp[NT_rank_def]
      >- (DISJ2_TAC >> reverse conj_tac >- simp[NT_rank_def] >>
          erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_ConstructorName) >>
          simp[] >> Cases_on `pfx` >> fs[] >>
          match_mp_tac peg_respects_firstSets >> simp[] >>
          metis_tac [firstSets_nV_nConstructorName, firstSet_nonempty_fringe])
      >- (simp[NT_rank_def] >>
          erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_Ptuple) >>
          simp[] >> Cases_on `pfx` >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >>
          simp[peg_respects_firstSets, peg_eval_tok_NONE])
      >- (simp[peg_respects_firstSets, peg_eval_tok_NONE] >>
          normlist >> simp[]))
  >- (print_tac "nPatternList" >> stdstart
      >- (first_assum (unify_firstconj kall_tac) >> simp[NT_rank_def] >>
          Cases_on `sfx` >> fs[peg_eval_tok_NONE]) >>
      normlist >> first_assum (unify_firstconj kall_tac o has_length) >>
      simp[])
  >- (print_tac "nPattern" >> stdstart >> dsimp[]
      >- (simp[NT_rank_def] >>
          rename[`sfx ≠ [] ⇒ _`] >> Cases_on `sfx` >> simp[peg_eval_tok_NONE] >>
          fs[]) >>
      disj1_tac >> normlist >> first_assum (unify_firstconj kall_tac) >>
      simp[APPEND_EQ_CONS] >> first_x_assum match_mp_tac >> simp[])
  >- (print_tac "nPapp" >> stdstart
      >- (DISJ1_TAC >>
          erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_Pbase) >>
          rw[] >> normlist >>
          first_assum (unify_firstconj kall_tac) >> simp[] >>
          normlist >> simp[] >>
          erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_ConstructorName) >>
          rw[]) >>
      DISJ2_TAC >> simp[NT_rank_def] >>
      (* case split on possible forms of Pbase *)
      asm_match `ptree_head bpt = NN nPbase` >>
      `∃subs. bpt = Nd (mkNT nPbase) subs`
        by (Cases_on `bpt` >> fs[MAP_EQ_CONS]) >> rveq >>
      fs[cmlG_FDOM,cmlG_applied,MAP_EQ_CONS] >> rveq >> fs[]
      >- (DISJ1_TAC >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_V) >>
          simp[] >> Cases_on `pfx` >> fs[] >>
          match_mp_tac peg_respects_firstSets >> simp[] >>
          metis_tac [firstSets_nV_nConstructorName, firstSet_nonempty_fringe])
      >- (DISJ2_TAC >> first_assum (unify_firstconj kall_tac) >>
          asm_match `ptree_fringe pt = MAP TK pfx` >> qexists_tac `pt` >>
          simp[NT_rank_def] >>
          Cases_on `sfx` >> fs[peg_respects_firstSets, not_peg0_peg_eval_NIL_NONE])
      >- (fs[MAP_EQ_CONS] >> simp[peg_respects_firstSets])
      >- (fs[MAP_EQ_CONS] >> simp[peg_respects_firstSets])
      >- (fs[MAP_EQ_CONS] >> simp[peg_respects_firstSets])
      >- (DISJ1_TAC >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_Ptuple) >>
          simp[] >> Cases_on `pfx` >> fs[] >>
          match_mp_tac peg_respects_firstSets >> simp[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[]) >>
      fs[MAP_EQ_CONS] >> simp[peg_respects_firstSets])
  >- (print_tac "nPType" >> stdstart
      >- (normlist >> first_assum (unify_firstconj kall_tac) >> simp[]) >>
      first_assum (unify_firstconj kall_tac) >> simp[NT_rank_def] >>
      Cases_on `sfx` >> fs[peg_eval_tok_NONE])
  >- (print_tac "nPEs" >>
      simp[MAP_EQ_CONS] >> strip_tac >> rw[] >> fs[] >> rw[]
      >- ((* single nPE *)
         simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> DISJ2_TAC >>
         reverse CONJ_ASM2_TAC >- simp[NT_rank_def] >>
         pop_assum mp_tac >>
         simp[peg_eval_tok_NONE] >>
         ONCE_REWRITE_TAC [peg_eval_NT_SOME] >> simp[cmlpeg_rules_applied] >>
         strip_tac >> rveq >> fs[MAP_EQ_APPEND, MAP_EQ_CONS] >> rveq >> dsimp[] >>
         first_assum
           (assume_tac o MATCH_MP (CONJUNCT1 peg_deterministic) o
            assert (free_in ``DarrowT`` o concl)) >>
         simp[] >>
         simp[Once peg_eval_NT_NONE, cmlpeg_rules_applied, peg_eval_tok_NONE] >>
         asm_match `peg_eval cmlPEG (i2, nt (mkNT nE) I) (SOME(sfx,r2))` >>
         Cases_on `peg_eval cmlPEG (i2, nt (mkNT nE') I) NONE` >> simp[] >>
         DISJ1_TAC >>
         `∃rr. peg_eval cmlPEG (i2, nt (mkNT nE') I) rr`
           by simp[MATCH_MP peg_eval_total PEG_wellformed] >>
         `∃i3 r3. rr = SOME(i3,r3)`
           by metis_tac[optionTheory.option_CASES, pairTheory.pair_CASES] >>
         rveq >> pop_assum (assume_tac o MATCH_MP peg_det) >>
         simp[] >> Cases_on `i3` >> simp[] >>
         metis_tac[nE'_bar_nE, listTheory.HD, listTheory.NOT_CONS_NIL]) >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> dsimp[] >>
      DISJ1_TAC >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rveq >>
      asm_match `ptree_head pept = NN nPE'` >>
      asm_match `ptree_fringe pept = MAP TK pef` >>
      asm_match `ptree_head pspt = NN nPEs` >>
      asm_match `ptree_fringe pspt = MAP TK psf` >>
      map_every qexists_tac [`[pept]`, `psf ++ sfx`, `[pspt]`] >>
      normlist >>
      conj_tac
      >- simp[firstSet_nConstructorName, firstSet_nV, firstSet_nFQV] >>
      simp[])
  >- (print_tac "nPE'" >> simp[MAP_EQ_CONS] >> strip_tac >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> dsimp[] >>
      rveq >> fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >>
      rveq >>
      asm_match `ptree_head ppt = NN nPattern` >>
      asm_match `ptree_fringe ppt = MAP TK pf` >>
      asm_match `ptree_head e'pt = NN nE'` >>
      asm_match `MAP TK ef = ptree_fringe e'pt` >>
      map_every qexists_tac [`[ppt]`, `ef ++ sfx`, `[e'pt]`] >> simp[] >>
      normlist >> simp[])
  >- (print_tac "nPE" >> simp[MAP_EQ_CONS] >> strip_tac >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> dsimp[] >>
      rveq >> fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >>
      rveq >>
      asm_match `ptree_head ppt = NN nPattern` >>
      asm_match `ptree_fringe ppt = MAP TK pf` >>
      asm_match `ptree_head ept = NN nE` >>
      asm_match `MAP TK ef = ptree_fringe ept` >>
      map_every qexists_tac [`[ppt]`, `ef ++ sfx`, `[ept]`] >> simp[] >>
      normlist >> simp[])
  >- (print_tac "nOptionalSignatureAscription" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied]>>
      strip_tac >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rw[] >>
      Cases_on `sfx` >> simp[peg_eval_tok_NONE] >> fs[])
  >- (print_tac "nOptTypEqn" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      strip_tac >> rw[] >> fs[MAP_EQ_CONS] >> rw[] >>
      Cases_on `sfx` >> simp[peg_eval_tok_NONE] >> fs[])
  >- (print_tac "nOpID" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      dsimp[pairTheory.EXISTS_PROD, peg_eval_tok_NONE] >> rpt strip_tac >>
      rveq >> fs[MAP_EQ_CONS] >> simp[peg_eval_seq_NONE, peg_eval_tok_NONE])
  >- (print_tac "nNonETopLevelDecs" >> strip_tac >>
      fs[MAP_EQ_CONS] >> rveq >> fs[MAP_EQ_APPEND]
      >- (rename1 `ptree_head TLDpt = NN nTopLevelDec` >>
          rename1 `ptree_head NeTLDpt = NN nNonETopLevelDecs` >>
          rename1 `ptree_fringe TLDpt = MAP TK TLDfr` >>
          rename1 `ptree_fringe NeTLDpt = MAP TK NeTLDfr` >>
          simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rveq >>
          `peg_eval cmlPEG (TLDfr ++ NeTLDfr, nt (mkNT nTopLevelDec) I)
                           (SOME (NeTLDfr, [TLDpt]))`
            by (Cases_on `NeTLDfr`
                >- (fs[] >> loseC ``LENGTH`` >>
                    first_x_assum (qspecl_then [`TLDpt`, `nTopLevelDec`, `[]`]
                                               mp_tac) >>
                    simp[NT_rank_def]) >>
                first_x_assum irule >> simp[] >> fs[] >>
                rename1 `ptree_fringe NeTLDpt = TK tok1 :: _` >>
                `tok1 ∈ firstSet cmlG [NN nNonETopLevelDecs]`
                  by metis_tac[firstSet_nonempty_fringe] >>
                rw[] >> fs[]) >>
          disj1_tac >>
          map_every qexists_tac [`[TLDpt]`, `NeTLDfr`, `[NeTLDpt]`] >> simp[] >>
          first_x_assum
            (qspecl_then [`NeTLDpt`, `nNonETopLevelDecs`, `NeTLDfr`, `[]`]
                         mp_tac) >>
          simp[] >> disch_then irule >>
          `0 < LENGTH (ptree_fringe TLDpt)` suffices_by simp[] >>
          irule fringe_length_not_nullable >> simp[] >> qexists_tac `cmlG` >>
          simp[])
      >- (fs[MAP_EQ_CONS] >> rveq >>
          simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> disj2_tac >>
          conj_tac
          >- (disj1_tac >> irule peg_respects_firstSets >> simp[]) >> fs[] >>
          `mkNT nTopLevelDecs ∈ FDOM cmlPEG.rules` by simp[] >>
          metis_tac[APPEND_NIL, DECIDE ``x < SUC x``])
      >- (simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
          simp[not_peg0_peg_eval_NIL_NONE, peg_eval_tok_NONE]))
  >- (print_tac "nMultOps" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      rw[] >> fs[MAP_EQ_CONS, peg_eval_tok_NONE])
  >- (print_tac "nListOps" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      rw[] >> fs[MAP_EQ_CONS, peg_eval_tok_NONE])
  >- (print_tac "nLetDecs" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[]>>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
      >- (DISJ1_TAC >>
          asm_match `ptree_head lpt = NN nLetDec` >>
          asm_match `ptree_fringe lpt = MAP TK lf` >>
          asm_match `ptree_head lspt = NN nLetDecs` >>
          asm_match `ptree_fringe lspt = MAP TK lsf` >>
          map_every qexists_tac [`[lpt]`, `lsf ++ sfx`, `[lspt]`] >>
          `0 < LENGTH (MAP TK lf)`
            by metis_tac [fringe_length_not_nullable,
                          nullable_LetDec] >> fs[] >>
          Cases_on`lsf` >> fs[] >- simp[NT_rank_def] >>
          normlist >>
          first_x_assum (match_mp_tac o has_length) >> simp[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> rw[] >> rw[])
      >- simp[peg_respects_firstSets] >>
      DISJ2_TAC >> Cases_on `sfx` >>
      simp[not_peg0_peg_eval_NIL_NONE, peg_eval_tok_NONE] >>
      fs[peg_respects_firstSets])
  >- (print_tac "nLetDec" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      rw[] >> fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >>
      rw[] >> dsimp[peg_eval_tok_NONE] >>
      asm_match `ptree_head vpt = NN nV` >>
      asm_match `ptree_fringe vpt = MAP TK vf` >>
      asm_match `ptree_head ept = NN nE` >>
      asm_match `MAP TK ef = ptree_fringe ept` >>
      map_every qexists_tac [`[vpt]`, `ef ++ sfx`, `[ept]`] >>
      normlist >>
      simp[])
  >- (print_tac "nFQV" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied,
           peg_longV_def] >> rw[] >> fs[MAP_EQ_SING] >> rveq >>
      simp[NT_rank_def, peg_eval_seq_NONE, peg_respects_firstSets,
           firstSet_nV])
  >- (print_tac "nFDecl" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_APPEND, MAP_EQ_CONS, DISJ_IMP_THM, FORALL_AND_THM] >> rw[] >>
      dsimp[] >>
      asm_match `ptree_head vpt = NN nV` >>
      asm_match `ptree_fringe vpt = MAP TK vf` >>
      asm_match `ptree_head plpt = NN nPbaseList1` >>
      asm_match `ptree_fringe plpt = MAP TK plf` >>
      asm_match `ptree_head ept = NN nE` >>
      asm_match `MAP TK ef = ptree_fringe ept` >>
      map_every qexists_tac [`[vpt]`, `plf ++ EqualsT::ef ++ sfx`, `[plpt]`,
                             `ef ++ sfx`, `[ept]`] >> simp[] >>
      normlist >>
      simp[])
  >- (print_tac "nEtyped" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
      >- (dsimp[] >> DISJ2_TAC >> DISJ1_TAC >> simp[NT_rank_def] >>
          simp[peg_eval_tok_NONE] >> Cases_on `sfx` >> fs[]) >>
      dsimp[] >> DISJ1_TAC >>
      normlist >>
      first_assum (unify_firstconj kall_tac o has_length) >> simp[])
  >- (print_tac "nEtuple" >> fs[FDOM_cmlPEG])
  >- (print_tac "nEseq" >> stdstart
      >- (normlist >> first_assum (unify_firstconj kall_tac) >> simp[]) >>
      first_assum(unify_firstconj kall_tac) >> simp[NT_rank_def] >>
      Cases_on `sfx` >> fs[peg_eval_tok_NONE])
  >- (print_tac "nErel" >>
      disch_then assume_tac >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nErel`, `SEP` |-> `NN nRelOps`,
                                 `C` |-> `NN nElistop`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      conj_tac >- simp[firstSet_nFQV, firstSet_nConstructorName,
                       firstSet_nV] >> fs[])
  >- (print_tac "nEmult" >> disch_then assume_tac >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nEmult`, `SEP` |-> `NN nMultOps`,
                                 `C` |-> `NN nEapp`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      fs[] >> simp[firstSet_nFQV, firstSet_nV, firstSet_nConstructorName] >>
      rw[disjImpI, stringTheory.isUpper_def])
  >- (print_tac "nElogicOR" >> disch_then assume_tac >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nElogicOR`, `SEP` |-> `TK OrelseT`,
                                 `C` |-> `NN nElogicAND`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      conj_tac >- simp[firstSet_nFQV, firstSet_nConstructorName,
                       firstSet_nV] >> fs[])
  >- (print_tac "nElogicAND" >> disch_then assume_tac >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nElogicAND`, `SEP` |-> `TK AndalsoT`,
                                 `C` |-> `NN nEtyped`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      conj_tac >- simp[firstSet_nV,firstSet_nConstructorName,firstSet_nFQV] >>
      fs[])
  >- (print_tac "nEliteral" >> stdstart >> simp[peg_eval_tok_NONE])
  >- (print_tac "nElistop" >> stdstart
      >- (normlist >> first_assum (unify_firstconj kall_tac) >>
          asm_match `ptree_head eaddpt = NN nEadd` >>
          qexists_tac `eaddpt` >>
          asm_match `ptree_head oppt = NN nListOps` >>
          asm_match `ptree_fringe oppt = MAP TK opf` >>
          `0 < LENGTH (MAP TK opf)`
            by metis_tac[fringe_length_not_nullable,
                         nullable_ListOps] >> fs[] >>
          `(∀l1 l2. HD (opf ++ l1 ++ l2) = HD opf) ∧ opf ≠ []`
            by (Cases_on `opf` >> fs[]) >>
          `HD opf ∈ stoppers nEadd`
            by (Cases_on `opf` >> fs[] >>
                first_assum
                  (mp_tac o
                   MATCH_MP (firstSet_nonempty_fringe
                               |> GEN_ALL |> Q.ISPEC `cmlG`
                               |> REWRITE_RULE [GSYM AND_IMP_INTRO])) >>
                simp[] >>
                rw[firstSet_nFQV, firstSet_nV, firstSet_nConstructorName,
                   disjImpI]) >>
          conj_tac >- (normlist >> loseC ``NT_rank`` >>
                       first_x_assum match_mp_tac >> simp[] >>
                       fs[]) >>
          normlist >> first_assum (unify_firstconj kall_tac) >> simp[] >>
          normlist >> first_assum (match_mp_tac o has_length) >>
          simp[] >> CONV_TAC NumRelNorms.sum_lt_norm >>
          metis_tac [fringe_length_not_nullable,
                     nullable_Eadd, listTheory.LENGTH_MAP,
                     arithmeticTheory.ZERO_LESS_ADD]) >>
      first_assum (unify_firstconj kall_tac) >> simp[] >>
      conj_tac >- simp[NT_rank_def] >>
      Cases_on `sfx` >> fs[not_peg0_peg_eval_NIL_NONE] >>
      simp[peg_respects_firstSets])
  >- (print_tac "nElist2" >> fs[FDOM_cmlPEG])
  >- (print_tac "nElist1" >> stdstart
      >- (first_assum (unify_firstconj kall_tac) >> simp[NT_rank_def] >>
          Cases_on `sfx` >> fs[peg_eval_tok_NONE]) >>
      normlist >> first_assum (unify_firstconj kall_tac) >> simp[])
  >- (print_tac "nEhandle" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      strip_tac >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
      >- (asm_match `ptree_head ept = NN nElogicOR` >>
          map_every qexists_tac [`[ept]`, `sfx`, `[]`] >>
          simp[NT_rank_def, peg_eval_tok_NONE] >> DISJ1_TAC >>
          Cases_on `sfx` >> simp[] >> strip_tac >> fs[]) >>
      asm_match `ptree_head ept = NN nElogicOR` >>
      asm_match `ptree_head pespt = NN nPEs` >>
      asm_match `MAP TK pesf = ptree_fringe pespt` >>
      qexists_tac `[ept]` >> dsimp[] >>
      qexists_tac `pesf ++ sfx` >> normlist >>
      simp[firstSet_nConstructorName, firstSet_nFQV, firstSet_nV])
  >- (print_tac "nEcomp" >> disch_then assume_tac >>
      simp[peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nEcomp`, `SEP` |-> `NN nCompOps`,
                                 `C` |-> `NN nErel`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM] >> conj_tac
      >- (conj_tac
          >- simp[firstSet_nV, firstSet_nFQV, firstSet_nConstructorName,
                  stringTheory.isUpper_def] >>
          simp[NT_rank_def]) >>
      fs[])
  >- (print_tac "nEbefore" >> disch_then assume_tac >>
      simp[peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nEbefore`,
                                 `SEP` |-> `TK (AlphaT "before")`,
                                 `C` |-> `NN nEcomp`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      conj_tac >- simp[firstSet_nConstructorName, firstSet_nFQV, firstSet_nV,
                       stringTheory.isUpper_def]>>
      fs[])
  >- (print_tac "nEbase" >> note_tac "** Slow nEbase beginning" >> stdstart >>
      TRY (simp[peg_eval_tok_NONE] >> NO_TAC)
      >- (note_tac "Ebase:Eseq (not ())" >>
          simp[peg_eval_tok_NONE, peg_eval_seq_NONE, peg_respects_firstSets] >>
          disj2_tac >>
          conj_tac
          >- (erule mp_tac
                    (MATCH_MP fringe_length_not_nullable nullable_Eseq) >>
              rename1 `ptree_fringe pt = MAP TK f` >> Cases_on `f` >>
              simp[] >> fs[] >>
              IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[] >>
              rpt strip_tac >> fs[firstSet_nE]) >>
          disj1_tac >> dsimp[peg_EbaseParen_def] >>
          asm_match `ptree_head qpt = NN nEseq` >>
          `∃subs. qpt = Nd (mkNT nEseq) subs`
            by (Cases_on `qpt` >> fs[MAP_EQ_CONS]) >>
          fs[cmlG_FDOM, cmlG_applied, MAP_EQ_CONS] >> rveq >>
          fs[MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM, MAP_EQ_CONS] >>
          rw[]
          >- (rpt disj2_tac >>
              simp[peg_eval_tok_NONE, peg_EbaseParenFn_def, list_case_eq,
                   bool_case_eq] >>
              rename [`ptree_head e_pt = NN nE`,
                      `ptree_head seq_pt = NN nEseq`,
                      `ptree_fringe e_pt = MAP TK etoks`,
                      `MAP TK seqtoks = ptree_fringe seq_pt`] >>
              last_assum (qpat_assum `ptree_head e_pt = NN nE` o
                           mp_then Any mp_tac) >>
              last_x_assum (qpat_assum `ptree_head seq_pt = NN nEseq` o
                            mp_then Any mp_tac) >>
              simp[] >> rpt strip_tac >>
              first_x_assum (qspecl_then [`seqtoks`, `RparT :: sfx`] mp_tac) >>
              simp[] >>
              pop_assum
                (qspec_then `SemicolonT :: seqtoks ++ [RparT] ++ sfx` mp_tac) >>
              simp[] >> rpt strip_tac >>
              goal_assum
                (first_assum o mp_then (Pos hd) mp_tac) >>
              simp[] >> metis_tac[APPEND_ASSOC, APPEND]) >>
          rpt disj1_tac >>
          rename [`ptree_head e_pt = NN nE`,
                  `ptree_fringe e_pt = MAP TK etoks`] >>
          first_x_assum
            (qspecl_then [`e_pt`, `nE`, `etoks`, `[RparT] ++ sfx`] mp_tac) >>
          simp[] >> strip_tac >>
          goal_assum
            (first_assum o mp_then (Pos hd) mp_tac) >>
          simp[peg_EbaseParenFn_def])
      >- (note_tac "Ebase:Etuple" >> disj2_tac >>
          simp[peg_eval_tok_NONE, peg_eval_seq_NONE] >>
          asm_match `ptree_head qpt = NN nEtuple` >>
          `∃subs. qpt = Nd (mkNT nEtuple) subs`
            by (Cases_on `qpt` >> fs[MAP_EQ_CONS]) >>
          fs[cmlG_FDOM, cmlG_applied, MAP_EQ_CONS] >> rveq >>
          fs[MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM, MAP_EQ_CONS] >>
          rw[]
          >- simp[peg_eval_NT_NONE, cmlpeg_rules_applied, peg_eval_tok_NONE]
          >- (erule mp_tac
                    (MATCH_MP fringe_length_not_nullable nullable_Elist2) >>
              rename1 `ptree_fringe pt = MAP TK f` >> Cases_on `f` >>
              simp[] >> fs[] >>
              IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[] >>
              rpt strip_tac >> fs[firstSet_nE])
          >- (disj1_tac >> dsimp[peg_EbaseParen_def, peg_eval_tok_NONE] >>
              disj2_tac >> disj1_tac >> const_x_assum "NT_rank" kall_tac >>
              asm_match `ptree_head qpt = NN nElist2` >>
              `∃subs. qpt = Nd (mkNT nElist2) subs`
                 by (Cases_on `qpt` >> fs[MAP_EQ_CONS]) >>
              fs[cmlG_FDOM, cmlG_applied, MAP_EQ_CONS] >> rveq >>
              fs[MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM, MAP_EQ_CONS] >>
              rw[] >>
              first_assum
                (const_assum "nE" o mp_then Any mp_tac) >>
              first_x_assum
                (const_assum "nElist1" o mp_then Any mp_tac) >>
              simp[] >> rpt strip_tac >>
              rename [`ptree_head e_pt = NN nE`, `ptree_head l_pt = NN nElist1`,
                      `ptree_fringe e_pt = MAP TK etks`,
                      `MAP TK ltks = ptree_fringe l_pt`] >>
              first_x_assum (qspecl_then [`ltks`, `[RparT] ++ sfx`] mp_tac) >>
              simp[] >>
              strip_tac >>
              goal_assum (first_assum o mp_then Any mp_tac) >>
              simp[] >>
              first_x_assum
                (qspecl_then [`CommaT::ltks ++ [RparT] ++ sfx`] mp_tac) >>
              simp[] >> strip_tac >>
              goal_assum (first_assum o mp_then Any mp_tac) >>
              simp[peg_EbaseParenFn_def]))
      >- simp[peg_eval_NT_NONE, peg_eval_seq_NONE, cmlpeg_rules_applied,
              peg_eval_tok_NONE]
      >- (disj2_tac >>
          erule mp_tac (MATCH_MP fringe_length_not_nullable nullable_FQV) >>
          rename1 `ptree_fringe pt = MAP TK f` >> Cases_on `f` >>
          simp[] >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[] >>
          rpt strip_tac
          >- (simp[peg_eval_seq_NONE, peg_eval_NT_NONE, cmlpeg_rules_applied] >>
              rpt strip_tac >> simp[peg_eval_tok_NONE] >>
              rename1 `tk ∈ firstSet _ _` >> Cases_on `tk` >> simp[] >>
              fs[NOTIN_firstSet_nFQV])
          >- (simp[peg_eval_tok_NONE] >> metis_tac[NOTIN_firstSet_nFQV]) >>
          disj2_tac >> conj_tac
          >- (simp[peg_EbaseParen_def, peg_eval_tok_NONE] >>
              metis_tac[NOTIN_firstSet_nFQV]) >> conj_tac
          >- (simp[peg_eval_tok_NONE] >> metis_tac[NOTIN_firstSet_nFQV]) >>
          simp[peg_eval_tok_NONE] >> conj_tac
          >- metis_tac[NOTIN_firstSet_nFQV] >>
          const_x_assum "NT_rank" (first_assum o mp_then (Pos hd) mp_tac) >>
          simp[NT_rank_def])
      >- (note_tac "nConstructorName" >> disj2_tac >>
          erule mp_tac
            (MATCH_MP fringe_length_not_nullable nullable_ConstructorName) >>
          rename1 `ptree_fringe pt = MAP TK f` >> Cases_on `f` >>
          simp[] >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[] >>
          rpt strip_tac >> simp[peg_eval_tok_NONE]
          >- (simp[peg_eval_seq_NONE, peg_eval_NT_NONE, cmlpeg_rules_applied] >>
              rpt strip_tac >> simp[peg_eval_tok_NONE] >>
              rename1 `tk ∈ firstSet _ _` >> Cases_on `tk` >> simp[] >>
              fs[NOTIN_firstSet_nFQV])
          >- metis_tac[NOTIN_firstSet_nConstructorName] >> disj2_tac >> conj_tac
          >- (simp[peg_EbaseParen_def, peg_eval_tok_NONE] >>
              metis_tac[NOTIN_firstSet_nConstructorName]) >> conj_tac
          >- metis_tac[NOTIN_firstSet_nConstructorName] >> conj_tac
          >- metis_tac[NOTIN_firstSet_nConstructorName] >> disj2_tac >> conj_tac
          >- (simp[peg_eval_seq_NONE] >> irule peg_respects_firstSets >>
              simp[peg0_nFQV] >> simp[firstSet_nFQV] >> conj_tac
              >- metis_tac[firstSets_nV_nConstructorName] >>
              fs[firstSet_nConstructorName]) >>
          disj1_tac >> const_x_assum "NT_rank" irule >> simp[NT_rank_def])
      >- (note_tac "nEliteral" >> disj1_tac >>
          const_x_assum "NT_rank" irule >> simp[NT_rank_def])
      >- (note_tac "let-in-end" >> disj2_tac >> simp[peg_eval_tok_NONE] >>
          conj_tac
          >- simp[peg_eval_seq_NONE, peg_eval_NT_NONE, cmlpeg_rules_applied,
                  peg_eval_tok_NONE] >> disj2_tac >> conj_tac
          >- simp[peg_EbaseParen_def, peg_eval_tok_NONE] >> disj1_tac >>
          dsimp[] >>
          rename[`ptree_head ld_pt = NN nLetDecs`,
                 `ptree_fringe ld_pt = MAP TK ldtks`,
                 ‘ptree_head es_pt = NN nEseq’,
                 ‘ptree_fringe es_pt = MAP TK estks’] >>
          map_every qexists_tac [‘[ld_pt]’,
                                 ‘estks ++ [EndT] ++ sfx’,
                                 ‘[es_pt]’] >> simp[] >>
          simp_tac bool_ss [APPEND, GSYM APPEND_ASSOC] >> conj_tac >>
          const_x_assum "LENGTH" irule >> simp[])
      >- (note_tac "empty list" >> simp[peg_eval_tok_NONE] >> disj2_tac >>
          conj_tac
          >- simp[peg_eval_seq_NONE, peg_eval_NT_NONE, cmlpeg_rules_applied,
                  peg_eval_tok_NONE] >> disj2_tac >> conj_tac
          >- simp[peg_EbaseParen_def, peg_eval_tok_NONE] >>
          disj1_tac >> disj2_tac >>
          simp[peg_respects_firstSets])
      >- (note_tac "[..]" >> simp[peg_eval_tok_NONE] >> disj2_tac >> conj_tac
          >- simp[peg_eval_seq_NONE, peg_eval_NT_NONE, cmlpeg_rules_applied,
                  peg_eval_tok_NONE] >> disj2_tac >> conj_tac
          >- simp[peg_EbaseParen_def, peg_eval_tok_NONE] >> disj1_tac >>
          simp_tac bool_ss [GSYM APPEND_ASSOC, APPEND] >>
          const_x_assum "LENGTH" irule >> simp[])
      >- (note_tac "op ID" >> simp[peg_eval_tok_NONE] >> disj2_tac >> conj_tac
          >- simp[peg_eval_seq_NONE, peg_eval_NT_NONE, cmlpeg_rules_applied,
                  peg_eval_tok_NONE] >> disj2_tac >> conj_tac
          >- simp[peg_eval_tok_NONE, peg_EbaseParen_def] >>
          disj2_tac >> simp[peg_respects_firstSets, peg_eval_seq_NONE]))
  >- (print_tac "nEapp" >> disch_then assume_tac >>
      match_mp_tac (eapp_complete
                      |> Q.INST [`master` |-> `pfx`]
                      |> SIMP_RULE (bool_ss ++ DNF_ss) [AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >> simp[])
  >- (print_tac "nEadd" >> disch_then assume_tac >>
      simp[peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nEadd`, `SEP` |-> `NN nAddOps`,
                                 `C` |-> `NN nEmult`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      conj_tac >- simp[firstSet_nConstructorName, firstSet_nFQV, firstSet_nV,
                       stringTheory.isUpper_def]>>
      fs[])
  >- (print_tac "nE'" >>
      simp_tac list_ss [MAP_EQ_CONS, Once peg_eval_NT_SOME,
                        Once peg_eval_choicel_CONS,
                        cmlpeg_rules_applied] >>
      strip_tac >>
      full_simp_tac list_ss [MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM,
                             FORALL_AND_THM] >> rveq >>
      full_simp_tac list_ss [] >>
      RULE_ASSUM_TAC (SIMP_RULE (srw_ss()) []) >> rveq >>
      RULE_ASSUM_TAC (SIMP_RULE (srw_ss()) [MAP_EQ_CONS]) >> rveq
      >- (asm_simp_tac list_ss [peg_eval_seql_CONS, peg_eval_tok_SOME,
                                peg_eval_tok_NONE, tokeq_def, pnt_def] >>
          RW_TAC list_ss [] >>
          simp_tac list_ss [Once peg_eval_choicel_CONS] >> DISJ2_TAC >>
          conj_tac >- simp[peg_respects_firstSets, pnt_def,
                           peg_eval_seq_NONE] >>
          simp_tac list_ss [Once peg_eval_choicel_CONS] >> DISJ1_TAC >>
          dsimp[] >>
          normlist >>
          Q.REFINE_EXISTS_TAC `[somept]` >> simp[] >>
          first_assum (unify_firstconj kall_tac o has_length) >> simp[] >>
          Q.REFINE_EXISTS_TAC `[somept]` >> simp[] >>
          first_assum (unify_firstconj kall_tac o has_length) >>
          simp[])
      >- (DISJ1_TAC >> simp[]) >>
      DISJ2_TAC >>
      `0 < LENGTH (MAP TK pfx)`
        by metis_tac [fringe_length_not_nullable, nullable_ElogicOR] >>
      full_simp_tac list_ss [] >> conj_tac
      >- (Cases_on `pfx` >> fs[peg_eval_tok_NONE, disjImpI] >> rw[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >>
          simp[firstSet_nConstructorName, firstSet_nFQV, firstSet_nV]) >>
      simp_tac std_ss [Once peg_eval_choicel_CONS] >> DISJ1_TAC >>
      simp[NT_rank_def] >> first_x_assum match_mp_tac >> simp[NT_rank_def] >>
      rpt strip_tac >> fs[] >> pop_assum mp_tac >> simp[])
  >- (print_tac "nE" >>
      simp[Once peg_eval_NT_SOME, cmlpeg_rules_applied, MAP_EQ_CONS] >> rw[] >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >>
      rw[peg_eval_tok_NONE, peg_respects_firstSets, peg_eval_seq_NONE]
      >- (DISJ2_TAC >> Q.REFINE_EXISTS_TAC `[ppt]` >> simp[] >>
          normlist >> first_assum (unify_firstconj kall_tac o has_length) >>
          simp[] >>
          Q.REFINE_EXISTS_TAC `[ppt]` >> simp[] >> normlist >>
          first_assum (unify_firstconj kall_tac o has_length) >>
          simp[])
      >- (DISJ2_TAC >> Q.REFINE_EXISTS_TAC `[ppt]` >> simp[] >>
          normlist >> first_assum (unify_firstconj kall_tac o has_length) >>
          simp[])
      >- (DISJ2_TAC >> Q.REFINE_EXISTS_TAC `[ppt]` >> simp[] >>
          normlist >> first_assum (unify_firstconj kall_tac o has_length) >>
          simp[]) >>
      DISJ2_TAC >> simp[NT_rank_def] >>
      `0 < LENGTH (MAP TK pfx)`
        by metis_tac [fringe_length_not_nullable, nullable_Ehandle] >> fs[] >>
      Cases_on `pfx` >> fs[disjImpI] >> rw[] >>
      IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[])
  >- (print_tac "nDtypeDecls" >> fs[FDOM_cmlPEG])
  >- (print_tac "nDtypeDecl" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rw[] >>
      Q.REFINE_EXISTS_TAC `[pt]` >> simp[] >> normlist >>
      first_assum (unify_firstconj kall_tac o has_length) >> simp[] >>
      rename1 `peg_eval cmlPEG (ppfx ++ sfx, _) _` >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nDtypeCons`, `SEP` |-> `TK BarT`,
                                 `C` |-> `NN nDconstructor`,
                                 `master` |-> `ppfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      dsimp[EXTENSION, EQ_IMP_THM])
  >- (print_tac "nDtypeCons" >> fs[FDOM_cmlPEG])
  >- (print_tac "nDecls" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >> rw[]
      >- (DISJ1_TAC >>
          asm_match `ptree_head dpt = NN nDecl` >>
          asm_match `ptree_head dspt = NN nDecls` >>
          asm_match `ptree_fringe dspt = MAP TK dsf` >>
          asm_match `ptree_fringe dpt = MAP TK df` >>
          map_every qexists_tac [`[dpt]`, `dsf ++ sfx`, `[dspt]`] >>
          `0 < LENGTH(MAP TK df)`
            by metis_tac [fringe_length_not_nullable, nullable_Decl] >>
          fs[] >>
          Cases_on `dsf` >- (fs[] >> simp[NT_rank_def]) >>
          normlist >> first_x_assum (match_mp_tac o has_length) >>
          simp[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >>
          simp[] >> rw[] >> simp[])
      >- simp[peg_respects_firstSets] >>
      DISJ2_TAC >> Cases_on `sfx` >>
      fs[not_peg0_peg_eval_NIL_NONE, peg_eval_tok_NONE, peg_respects_firstSets])
  >- (print_tac "nDecl" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >>
      rw[peg_eval_tok_NONE]
      >- (DISJ1_TAC >> normlist >>
          first_assum (unify_firstconj kall_tac o has_length) >> simp[])
      >- (dsimp[] >>
          asm_match `ptree_head tpt = NN nTypeDec` >>
          `0 < LENGTH (ptree_fringe tpt)`
            by metis_tac[fringe_length_not_nullable, nullable_TypeDec] >>
          pop_assum mp_tac >> simp[] >> Cases_on `pfx` >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[])
      >- (simp[NT_rank_def, peg_eval_tok_NONE] >>
          asm_match `ptree_head tpt = NN nTypeDec` >>
          `0 < LENGTH (ptree_fringe tpt)`
            by metis_tac[fringe_length_not_nullable, nullable_TypeDec] >>
          pop_assum mp_tac >> simp[] >> Cases_on `pfx` >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[])
      >- (dsimp[] >> asm_match `ptree_head tpt = NN nTypeAbbrevDec` >>
          `0 < LENGTH (ptree_fringe tpt)`
            by metis_tac[fringe_length_not_nullable, nullable_TypeAbbrevDec] >>
          pop_assum mp_tac >> simp[] >> Cases_on `pfx` >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[])
      >- (asm_match `ptree_head tpt = NN nTypeAbbrevDec` >>
          `0 < LENGTH (ptree_fringe tpt)`
            by metis_tac[fringe_length_not_nullable, nullable_TypeAbbrevDec] >>
          pop_assum mp_tac >> simp[] >> Cases_on `pfx` >> fs[] >>
          IMP_RES_THEN mp_tac firstSet_nonempty_fringe >> simp[] >>
          rpt strip_tac >> disj2_tac >> simp[peg_respects_firstSets] >> rw[] >>
          first_x_assum match_mp_tac >> simp[NT_rank_def]))
  >- (print_tac "nDconstructor" >> stdstart
      >- (normlist >> first_assum (unify_firstconj kall_tac) >> simp[]) >>
      first_assum (unify_firstconj kall_tac) >> simp[NT_rank_def] >>
      Cases_on `sfx` >> fs[peg_eval_tok_NONE])
  >- (print_tac "nDType" >> disch_then assume_tac >>
      match_mp_tac (dtype_complete
                      |> Q.INST [`master` |-> `pfx`]
                      |> SIMP_RULE (bool_ss ++ DNF_ss) [AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >> simp[])
  >- (print_tac "nConstructorName" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >>
      rw[] >- simp[NT_rank_def] >>
      DISJ2_TAC >> simp[peg_eval_seq_NONE] >>
      match_mp_tac peg_respects_firstSets >> simp[] >>
      simp[firstSet_NT, cmlG_FDOM, cmlG_applied, disjImpI] >>
      dsimp[])
  >- (print_tac "nCompOps" >>
      simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
      fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM] >>
      rw[peg_eval_tok_NONE])
  >- (print_tac "nAndFDecls" >> disch_then assume_tac >>
      simp[peg_eval_NT_SOME, cmlpeg_rules_applied] >>
      match_mp_tac (peg_linfix_complete
                      |> Q.INST [`P` |-> `nAndFDecls`, `SEP` |-> `TK AndT`,
                                 `C` |-> `NN nFDecl`, `master` |-> `pfx`]
                      |> SIMP_RULE (srw_ss() ++ DNF_ss)
                           [sym2peg_def, cmlG_applied, MAP_EQ_CONS,
                            AND_IMP_INTRO]) >>
      simp[cmlG_applied, cmlG_FDOM, NT_rank_def] >>
      dsimp[EXTENSION, EQ_IMP_THM] >> fs[]) >>
  print_tac "nAddOps" >>
  simp[MAP_EQ_CONS, Once peg_eval_NT_SOME, cmlpeg_rules_applied] >> rw[] >>
  fs[MAP_EQ_CONS, MAP_EQ_APPEND, DISJ_IMP_THM, FORALL_AND_THM,
     peg_eval_tok_NONE])

(* two valid parse-trees with the same head, and the same fringes, which
   are all tokens, must be identical. *)
val cmlG_unambiguous = Q.store_thm(
  "cmlG_unambiguous",
  `valid_ptree cmlG pt1 ∧ ptree_head pt1 = NT (mkNT N) ∧
    valid_ptree cmlG pt2 ∧ ptree_head pt2 = NT (mkNT N) ∧
    mkNT N ∈ FDOM cmlPEG.rules ∧ (* e.g., nTopLevelDecs *)
    ptree_fringe pt2 = ptree_fringe pt1 ∧
    (∀s. s ∈ set (ptree_fringe pt1) ⇒ ∃t. s = TOK t) ⇒
    pt1 = pt2`,
  rpt strip_tac >>
  `∃ts. ptree_fringe pt1 = MAP TK ts`
    by (Q.UNDISCH_THEN `ptree_fringe pt2 = ptree_fringe pt1` kall_tac >>
        qabbrev_tac `l = ptree_fringe pt1` >> markerLib.RM_ALL_ABBREVS_TAC >>
        Induct_on `l` >> rw[] >> fs[DISJ_IMP_THM, FORALL_AND_THM] >> rw[] >>
        metis_tac[listTheory.MAP]) >>
  qspecl_then [`pt`, `N`, `ts`, `[]`] (ASSUME_TAC o Q.GEN `pt`)
    completeness >>
  pop_assum (fn th => MP_TAC (Q.SPEC `pt1` th) THEN
                      MP_TAC (Q.SPEC `pt2` th)) >> simp[] >>
  metis_tac[PAIR_EQ, peg_deterministic, SOME_11, CONS_11])

val _ = export_theory();
