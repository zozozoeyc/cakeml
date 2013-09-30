open HolKernel Parse boolLib bossLib lcsymtacs miscLib;

val _ = new_theory "holSemantics";

open holSyntaxTheory;
open sholSyntaxTheory;
open sholSyntaxExtraTheory;
open sholSemanticsTheory;
open listTheory arithmeticTheory combinTheory pairTheory;

(*

   This script defines the semantics of stateful HOL in terms of the
   semantics of the stateless HOL. This file has three parts:

    (1) a translation from stateful types, terms, sequents to
        stateless types, terms and sequents is define as a relation,

    (2) the semantics of stateful sequents is define in using the
        translation relation from above, and

    (3) finally, we prove that for any derivation in the stateful
        version there is a derivation in the stateless version for
        the appropriate translation of the sequent.

   Parts (2) and (3) imply soundness of stateful HOL, if soundness has
   been proved for the stateless version.

*)

infix \\
val op \\ = op THEN;

(* -- part 1 -- *)

val const_def_def = Define `
  const_def n defs =
    case defs of
    | [] => NONE
    | (Constdef name tm::defs) =>
         if n = name then SOME (0,tm) else const_def n defs
    | (Typedef name tm abs rep::defs) =>
         if n = abs then SOME (1,tm) else
         if n = rep then SOME (2,tm) else const_def n defs
    | d::defs => const_def n defs`

val type_def_def = Define `
  type_def n defs =
    case defs of
    | [] => NONE
    | (Typedef name tm x y::defs) =>
         if n = name then SOME (tm,x,y) else type_def n defs
    | d::defs => type_def n defs`;

val (term_rules,term_ind,term_cases) = xHol_reln "term" `
  (type defs (Tyvar s) (Tyvar s)) /\
  (type defs Bool (Tyapp (Typrim "bool" 0) [])) /\
  (type defs Ind (Tyapp (Typrim "ind" 0) [])) /\
  (type defs tx tx1 /\ type defs ty ty1 ==>
   type defs (Fun tx ty) (Tyapp (Typrim "fun" 2) [tx1; ty1])) /\
  (EVERY2 (type defs) tys tys1 /\
   (type_def s defs = SOME (tm,abs,rep)) /\ term defs tm tm1 ==>
   type defs (Tyapp s tys) (Tyapp (Tydefined s tm1) tys1)) /\
  (type defs ty ty1 ==>
   term defs (Var s ty) (Var s ty1)) /\
  (type defs (Fun ty (Fun ty Bool)) ty1 ==>
   term defs (Equal ty) (Const "=" ty1 Prim)) /\
  (type defs (Fun (Fun ty Bool) ty) ty1 ==>
   term defs (Select ty) (Const "@" ty1 Prim)) /\
  (term defs x x1 /\ term defs y y1 /\ welltyped (Comb x y) ==>
   term defs (Comb x y) (Comb x1 y1)) /\
  (type defs ty ty1 /\ term defs x x1 ==>
   term defs (Abs s ty x) (Abs s ty1 x1)) /\
  (type defs ty ty1 /\
   (const_def s defs = SOME (n,tm)) /\ term defs tm tm1 ==>
   term defs (Const s ty) (Const s ty1 (if n = 0 then Defined tm1 else
                                        if n = 1 then Tyabs s tm1 else
                                     (* if n = 2 then *) Tyrep s tm1)))`

val seq_trans_def = Define `
  seq_trans ((defs,h),c) (h1,c1) <=>
    EVERY2 (term defs) h h1 /\ term defs c c1`;


(* -- part 2 -- *)

val hol_seq_def = Define `
  hol_seq ((defs,hyps),tm) = ?h c. seq_trans ((defs,hyps),tm) (h,c) /\ h |= c`;


(* -- part 3 -- *)

val _ = Parse.overload_on("α",``(Tyvar "a"):sholSyntax$type``)
val id_stm = ``Abs "x" α (Var "x" α)``
val id_ok = prove(
  ``term_ok ^id_stm``,
  simp[Once proves_cases] >>
  disj1_tac >>
  simp[Once proves_cases] >>
  simp[Once proves_cases] >>
  disj1_tac >>
  simp[Once proves_cases] )
val _ = Parse.overload_on("Ts",``^id_stm === ^id_stm``)
val truth_sthm =
   proves_rules
|> CONJUNCTS
|> C (curry List.nth) 14
|> SPEC id_stm
|> UNDISCH
|> PROVE_HYP id_ok

val Ts_ok = save_thm("Ts_ok",
   proves_rules
|> CONJUNCTS
|> C (curry List.nth) 13
|> SPEC ``Ts``
|> Q.SPEC `[]`
|> SIMP_RULE (srw_ss())[truth_sthm])
val _ = export_rewrites["Ts_ok"]

val Ts_has_type_Bool = prove(
  ``Ts has_type Bool``,
  simp[EQUATION_HAS_TYPE_BOOL])

val _ = Parse.overload_on("Arb",``λty. Comb (Select ty) (Abs "x" ty Ts)``)

val Arb_ok = prove(
  ``∀ty. type_ok ty ⇒ term_ok (Arb ty)``,
  rw[] >>
  simp[Once proves_cases] >>
  disj1_tac >>
  conj_tac >- simp[Once proves_cases] >>
  conj_tac >- simp[Once proves_cases] >>
  METIS_TAC[Ts_has_type_Bool,welltyped_def,WELLTYPED_LEMMA])

val term_type_11 = prove(
  ``(!ty ty1. type defs ty ty1 ==> !ty2. type defs ty ty2 ==> (ty1 = ty2)) ∧
    (∀tm tm1. term defs tm tm1 ⇒ ∀tm2. term defs tm tm2 ⇒ (tm1 = tm2))``,
  HO_MATCH_MP_TAC term_ind >>
  rpt conj_tac >> rpt gen_tac
  >- simp[Once term_cases]
  >- simp[Once term_cases]
  >- simp[Once term_cases]
  >- (strip_tac >> simp[Once term_cases] >> METIS_TAC[])
  >- (strip_tac >> simp[Once term_cases] >>
      fs[EVERY2_EVERY,EVERY_MEM,FORALL_PROD] >>
      rw[LIST_EQ_REWRITE] >> rfs[MEM_ZIP] >>
      METIS_TAC[] )
  >> (strip_tac >> simp[Once term_cases] >> METIS_TAC[]))

val term_type_11_inv = prove(
  ``(!ty ty1. type defs ty ty1 ==> !ty2. type defs ty2 ty1 ==> (ty = ty2)) ∧
    (∀tm tm1. term defs tm tm1 ⇒ ∀tm2. term defs tm2 tm1 ⇒ (tm = tm2))``,
  HO_MATCH_MP_TAC term_ind >>
  rpt conj_tac >> rpt gen_tac
  >- simp[Once term_cases]
  >- simp[Once term_cases]
  >- simp[Once term_cases]
  >- (strip_tac >> simp[Once term_cases] >> METIS_TAC[])
  >- (strip_tac >> simp[Once term_cases] >>
      fs[EVERY2_EVERY,EVERY_MEM,FORALL_PROD] >>
      rw[LIST_EQ_REWRITE] >> rfs[MEM_ZIP] >>
      METIS_TAC[] )
  >- (strip_tac >> simp[Once term_cases] >> METIS_TAC[])
  >- (
    strip_tac >>
    simp[Once term_cases] >>
    rw[] >- ( res_tac >> fs[] ) >>
    BasicProvers.EVERY_CASE_TAC >>
    fsrw_tac[ARITH_ss][] )
  >- (
    strip_tac >>
    simp[Once term_cases] >>
    rw[] >- ( res_tac >> fs[] ) >>
    BasicProvers.EVERY_CASE_TAC >>
    fsrw_tac[ARITH_ss][] )
  >- (strip_tac >> simp[Once term_cases] >> METIS_TAC[])
  >- (strip_tac >> simp[Once term_cases] >> METIS_TAC[])
  >- ( strip_tac >> simp[Once term_cases] >> rw[] ))

val has_type_IMP = prove(
  ``∀tm ty. tm has_type ty ⇒ ∀defs tm1. term defs tm tm1 ⇒ ∃ty1. type defs ty ty1 ∧ tm1 has_type ty1``,
  HO_MATCH_MP_TAC holSyntaxTheory.has_type_strongind >> rw[] >>
  TRY (
    qpat_assum`term defs (Comb X Y) Z`mp_tac >>
    rw[Once term_cases] >>
    rw[Once has_type_cases] >>
    fs[Q.SPEC`Fun X Y`(CONJUNCT1 (SPEC_ALL term_cases))] >>
    METIS_TAC[term_type_11] ) >>
  TRY (
    qpat_assum`term defs (Abs X Y A) Z`mp_tac >>
    rw[Once term_cases] >>
    rw[Once has_type_cases] >>
    rw[Once term_cases] >>
    METIS_TAC[term_type_11] ) >>
  (
    last_x_assum mp_tac >>
    rw[Once term_cases] >>
    rw[Once has_type_cases] >>
    METIS_TAC[term_type_11] ))

val term_equation = prove(
  ``!x y z. (x === y) has_type Bool ⇒
    (term defs (x === y) z ⇔ ∃x1 y1. (z = x1 === y1) ∧ term defs x x1 ∧ term defs y y1)``,
  rpt gen_tac >> strip_tac >>
  simp[equation_def,holSyntaxTheory.equation_def] >>
  simp[Once term_cases] >>
  simp[Once term_cases] >>
  simp[Once term_cases] >>
  srw_tac[boolSimps.DNF_ss][] >>
  simp[Once term_cases] >>
  srw_tac[boolSimps.DNF_ss][] >>
  simp[Q.SPEC`Fun X Y`(CONJUNCT1 (SPEC_ALL term_cases))] >>
  srw_tac[boolSimps.DNF_ss][] >>
  simp[Q.SPEC`Bool`(CONJUNCT1 (SPEC_ALL term_cases))] >>
  fs[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
  rw[EQ_IMP_THM] >>
  METIS_TAC[term_type_11,has_type_IMP,holSyntaxTheory.WELLTYPED,WELLTYPED_LEMMA])

val term_welltyped = prove(
  ``(∀ty ty1. type defs ty ty1 ⇒ T) ∧
    (∀tm tm1. term defs tm tm1 ⇒ (welltyped tm ⇔ welltyped tm1))``,
  HO_MATCH_MP_TAC (theorem"term_strongind") >>
  simp[] >> rw[] >>
  rw[EQ_IMP_THM] >> fs[] >>
  fs[WELLTYPED,holSyntaxTheory.WELLTYPED] >>
  imp_res_tac has_type_IMP >>
  fs[Q.SPEC`Fun X Y`(CONJUNCT1 (SPEC_ALL term_cases))] >> rw[] >>
  METIS_TAC[has_type_IMP,term_type_11,WELLTYPED_LEMMA,holSyntaxTheory.WELLTYPED_LEMMA])

val welltyped_equation = prove(
  ``holSyntax$welltyped (s === t) ⇔ (s === t) has_type Bool``,
  rw[holSyntaxTheory.equation_def] >>
  rw[Once holSyntaxTheory.has_type_cases] >>
  rw[Once holSyntaxTheory.has_type_cases] >>
  rw[Once holSyntaxTheory.has_type_cases] >>
  METIS_TAC[holSyntaxTheory.WELLTYPED,holSyntaxTheory.WELLTYPED_LEMMA])

val ALPHAVARS_IMP = prove(
  ``∀env tp. holSyntax$ALPHAVARS env tp ⇒
      ∀defs tp1 env1.
        LIST_REL (term defs) (MAP FST(tp::env)) (MAP FST(tp1::env1))∧
        LIST_REL (term defs) (MAP SND(tp::env)) (MAP SND(tp1::env1))⇒
        sholSyntax$ALPHAVARS env1 tp1``,
  Induct >> simp[ALPHAVARS_def,holSyntaxTheory.ALPHAVARS_def] >- (
    Cases >> simp[] >> metis_tac[term_type_11] ) >>
  rw[] >>
  imp_res_tac term_type_11 >> rw[] >- (
    Cases_on`env1`>>fs[ALPHAVARS_def]>>
    metis_tac[PAIR_EQ,pair_CASES,FST,SND] ) >>
  Cases_on`env1`>>fs[ALPHAVARS_def]>>
  Cases_on`tp1=h'`>>fs[]>>
  rpt BasicProvers.VAR_EQ_TAC >>
  conj_tac >- metis_tac[term_type_11_inv] >>
  conj_tac >- metis_tac[term_type_11_inv] >>
  first_x_assum (match_mp_tac o MP_CANON) >>
  map_every qexists_tac[`tp`,`defs`] >>
  simp[])

val RACONV_IMP = prove(
  ``∀env tp. RACONV env tp ⇒
    ∀defs tp1 env1.
      LIST_REL (term defs) (MAP FST(tp::env)) (MAP FST(tp1::env1))∧
      LIST_REL (term defs) (MAP SND(tp::env)) (MAP SND(tp1::env1))⇒
      RACONV env1 tp1``,
   HO_MATCH_MP_TAC holSyntaxTheory.RACONV_ind >>
   simp[] >> rw[] >>
   Cases_on`tp1` >>
   fs[Q.SPEC`Var X Y`(CONJUNCT2 (SPEC_ALL term_cases))] >>
   fs[Q.SPEC`Select X`(CONJUNCT2 (SPEC_ALL term_cases))] >>
   fs[Q.SPEC`Equal X`(CONJUNCT2 (SPEC_ALL term_cases))] >>
   fs[Q.SPEC`Const X Y`(CONJUNCT2 (SPEC_ALL term_cases))] >>
   fs[Q.SPEC`Comb X Y`(CONJUNCT2 (SPEC_ALL term_cases))] >>
   rw[RACONV] >> fsrw_tac[ARITH_ss][] >>
   TRY (match_mp_tac(MP_CANON(CONJUNCT1 term_type_11)) >> metis_tac[]) >>
   TRY (match_mp_tac(MP_CANON(CONJUNCT2 term_type_11)) >> metis_tac[]) >>
   TRY (first_x_assum match_mp_tac >> simp[] >> metis_tac[]) >>
   TRY (last_x_assum match_mp_tac >> simp[] >> metis_tac[]) >>
   TRY (
     match_mp_tac (MP_CANON ALPHAVARS_IMP) >>
     qexists_tac`env` >>
     qexists_tac`Var x1 ty1,Var x2 ty2` >>
     qexists_tac`defs` >>
     simp[] >>
     simp[Once term_cases] >>
     simp[Once term_cases] ) >>
   fs[Q.SPEC`Abs X Y Z`(CONJUNCT2 (SPEC_ALL term_cases))] >>
   rw[RACONV] >- metis_tac[term_type_11] >>
   first_x_assum match_mp_tac >> simp[] >>
   qexists_tac`defs` >> simp[])

val ALPHAVARS_IMP_inv = prove(
  ``∀env1 tp1. sholSyntax$ALPHAVARS env1 tp1 ⇒
      ∀defs tp env.
        LIST_REL (term defs) (MAP FST(tp::env)) (MAP FST(tp1::env1))∧
        LIST_REL (term defs) (MAP SND(tp::env)) (MAP SND(tp1::env1))⇒
        holSyntax$ALPHAVARS env tp``,
  Induct >> simp[ALPHAVARS_def,holSyntaxTheory.ALPHAVARS_def] >- (
    Cases >> simp[] >> metis_tac[term_type_11_inv] ) >>
  rw[] >>
  imp_res_tac term_type_11_inv >> rw[] >- (
    Cases_on`env`>>fs[holSyntaxTheory.ALPHAVARS_def]>>
    metis_tac[PAIR_EQ,pair_CASES,FST,SND] ) >>
  Cases_on`env`>>fs[holSyntaxTheory.ALPHAVARS_def]>>
  Cases_on`tp=h'`>>fs[]>>
  rpt BasicProvers.VAR_EQ_TAC >>
  conj_tac >- metis_tac[term_type_11] >>
  conj_tac >- metis_tac[term_type_11] >>
  first_x_assum (match_mp_tac o MP_CANON) >>
  map_every qexists_tac[`tp1`,`defs`] >>
  simp[])

val RACONV_IMP_inv = prove(
  ``∀env1 tp1. RACONV env1 tp1 ⇒
    ∀defs tp env.
      LIST_REL (term defs) (MAP FST(tp::env)) (MAP FST(tp1::env1))∧
      LIST_REL (term defs) (MAP SND(tp::env)) (MAP SND(tp1::env1))⇒
      RACONV env tp``,
   HO_MATCH_MP_TAC RACONV_ind >>
   simp[] >> rw[] >>
   Cases_on`tp` >>
   fs[Q.SPECL[`A`,`Var X Y`](CONJUNCT2 (SPEC_ALL term_cases))] >>
   fs[Q.SPECL[`A`,`Const X Y Z`](CONJUNCT2 (SPEC_ALL term_cases))] >>
   fs[Q.SPECL[`A`,`Comb X Y`](CONJUNCT2 (SPEC_ALL term_cases))] >>
   rw[holSyntaxTheory.RACONV] >> fsrw_tac[ARITH_ss][] >>
   TRY (imp_res_tac term_type_11_inv >> fs[] >> NO_TAC) >>
   TRY (last_x_assum mp_tac >> rw[] >> fsrw_tac[ARITH_ss][]) >>
   TRY (first_x_assum match_mp_tac >> simp[] >> metis_tac[]) >>
   TRY (last_x_assum match_mp_tac >> simp[] >> metis_tac[]) >>
   TRY (
     match_mp_tac (MP_CANON ALPHAVARS_IMP_inv) >>
     qexists_tac`env1` >>
     qexists_tac`Var x1 ty1,Var x2 ty2` >>
     qexists_tac`defs` >>
     simp[] >>
     simp[Once term_cases] >>
     simp[Once term_cases] ) >>
   fs[Q.SPECL[`A`,`Abs X Y Z`](CONJUNCT2 (SPEC_ALL term_cases))] >>
   rw[holSyntaxTheory.RACONV] >- metis_tac[term_type_11_inv] >>
   first_x_assum match_mp_tac >> simp[] >>
   qexists_tac`defs` >> simp[])

val ACONV_IMP = prove(
  ``∀defs t1 t2 t11 t22. ACONV t1 t2 ∧ term defs t1 t11 ∧ term defs t2 t22 ⇒ ACONV t11 t22``,
  rw[ACONV_def,holSyntaxTheory.ACONV_def] >>
  match_mp_tac (MP_CANON RACONV_IMP) >>
  simp[EXISTS_PROD] >>
  metis_tac[])

val ACONV_IMP_inv = prove(
  ``∀defs t1 t2 t11 t22. ACONV t11 t22 ∧ term defs t1 t11 ∧ term defs t2 t22 ⇒ ACONV t1 t2``,
  rw[ACONV_def,holSyntaxTheory.ACONV_def] >>
  match_mp_tac (MP_CANON RACONV_IMP_inv) >>
  simp[EXISTS_PROD] >>
  metis_tac[])

val LIST_REL_term_UNION = prove(
  ``∀defs l1 l2 r1 r2. LIST_REL (term defs) l1 r1 ∧ LIST_REL (term defs) l2 r2 ⇒
      LIST_REL (term defs) (TERM_UNION l1 l2) (TERM_UNION r1 r2)``,
  gen_tac >> Induct >> simp[TERM_UNION_def,holSyntaxTheory.TERM_UNION_def] >>
  rw[] >> simp[TERM_UNION_def] >> rw[] >>
  fs[EVERY2_EVERY,EXISTS_MEM,EVERY_MEM] >>
  rfs[MEM_ZIP,GSYM LEFT_FORALL_IMP_THM] >- (
    imp_res_tac holSyntaxTheory.TERM_UNION_NONEW >>
    metis_tac[TERM_UNION_THM,MEM_EL,ACONV_SYM,ACONV_TRANS,ACONV_IMP] ) >>
  imp_res_tac TERM_UNION_NONEW >>
  METIS_TAC[holSyntaxTheory.TERM_UNION_THM,MEM_EL,ACONV_IMP_inv,holSyntaxTheory.ACONV_SYM,holSyntaxTheory.ACONV_TRANS])

val proves_IMP = store_thm("proves_IMP",
  ``(∀defs ty. type_ok defs ty ⇒ ∃ty1. type defs ty ty1 ∧ type_ok ty1) ∧
    (∀defs tm. term_ok defs tm ⇒ ∃tm1. term defs tm tm1 ∧ term_ok tm1) ∧
    (∀defs. context_ok defs ⇒ T) ∧
    (∀dh c. dh |- c ⇒ ∃h1 c1. seq_trans (dh,c) (h1,c1) ∧ h1 |- c1)``,
  HO_MATCH_MP_TAC holSyntaxTheory.proves_strongind >>
  conj_tac >- simp[Once term_cases,Once proves_cases] >>
  conj_tac >- simp[Once term_cases,Once proves_cases] >>
  conj_tac >- simp[Once term_cases,Once proves_cases] >>
  conj_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once term_cases] >> rw[] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once proves_cases] >>
    METIS_TAC[]) >>
  conj_tac >- (
    rw[] >>
    simp[Once proves_cases] >>
    METIS_TAC[has_type_IMP] ) >>
  conj_tac >- (
    rw[] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once proves_cases] >>
    METIS_TAC[] ) >>
  conj_tac >- (
    rw[] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once CONJ_COMM] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once CONJ_COMM] >>
    simp[Once term_cases] >>
    simp[Once proves_cases] >>
    METIS_TAC[] ) >>
  conj_tac >- (
    rw[] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once CONJ_COMM] >>
    simp[Once term_cases] >>
    simp[Once proves_cases] >>
    METIS_TAC[] ) >>
  conj_tac >- (
    rw[] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once proves_cases] >>
    fs[welltyped_def,holSyntaxTheory.welltyped_def] >>
    map_every qexists_tac[`tm1`,`tm1'`] >> rw[] >>
    disj1_tac >>
    conj_tac >- METIS_TAC[has_type_IMP] >>
    conj_tac >- METIS_TAC[has_type_IMP] >>
    imp_res_tac holSyntaxTheory.WELLTYPED_LEMMA >> fs[] >> rw[] >>
    imp_res_tac has_type_IMP >>
    fs[Q.SPEC`Fun X Y`(CONJUNCT1 (SPEC_ALL term_cases))] >> rw[] >>
    IMP_RES_TAC WELLTYPED_LEMMA >> rw[] >>
    METIS_TAC[term_type_11] ) >>
  conj_tac >- (
    rw[] >>
    simp[Once term_cases] >>
    srw_tac[boolSimps.DNF_ss][] >>
    simp[Once proves_cases] >>
    METIS_TAC[] ) >>
  conj_tac >- (
    rpt gen_tac >>
    simp[Once term_cases] >> rw[] >>
    qexists_tac`x1` >> rw[] >>
    simp[Once proves_cases] >>
    METIS_TAC[] ) >>
  conj_tac >- (
    rpt gen_tac >>
    simp[Once term_cases] >> rw[] >>
    qexists_tac`y1` >> rw[] >>
    simp[Once proves_cases] >>
    METIS_TAC[] ) >>
  conj_tac >- (
    rpt gen_tac >>
    simp[Once term_cases] >> rw[] >>
    qexists_tac`x1` >> rw[] >>
    simp[Once proves_cases] >>
    METIS_TAC[] ) >>
  conj_tac >- (
    rw[seq_trans_def,EVERY2_EVERY,EVERY_MEM] >>
    rfs[MEM_ZIP,FORALL_PROD,GSYM LEFT_FORALL_IMP_THM] >>
    METIS_TAC[List.nth(CONJUNCTS proves_rules,13),MEM,MEM_EL] ) >>
  conj_tac >- rw[] >>
  conj_tac >- rw[seq_trans_def] >>
  conj_tac >- (
    rw[seq_trans_def] >>
    qspecl_then[`tm`,`tm`,`tm1 === tm1`]mp_tac term_equation >>
    simp[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    `welltyped tm1` by METIS_TAC[soundness,has_meaning_welltyped] >>
    `welltyped tm` by METIS_TAC[term_welltyped] >>
    simp[] >> strip_tac >>
    qexists_tac`tm1 === tm1` >>
    simp[] >>
    METIS_TAC[List.nth(CONJUNCTS proves_rules,14)] ) >>
  conj_tac >- (
    rw[seq_trans_def] >>
    `∀t. MEM t (c1::h1) ∨ MEM t (c1'::h1') ⇒ t has_type Bool` by (
      imp_res_tac soundness >>
      fs[sequent_def,EVERY_MEM] >>
      METIS_TAC[] ) >>
    `welltyped (l === m1) ∧ welltyped (m2 === r)` by METIS_TAC[term_welltyped,welltyped_def,MEM] >>
    fs[welltyped_equation,holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    qexists_tac`TERM_UNION h1 h1'` >>
    qspecl_then[`l`,`m1`,`c1`]mp_tac term_equation >>
    simp[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >> strip_tac >>
    qspecl_then[`m2`,`r`,`c1'`]mp_tac term_equation >>
    simp[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >> strip_tac >>
    imp_res_tac term_type_11 >> rw[] >>
    qexists_tac`x1 === y1'` >>
    qspecl_then[`l`,`r`,`x1 === y1'`]mp_tac term_equation >>
    simp[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    imp_res_tac holSyntaxTheory.ACONV_TYPE >>
    discharge_hyps >- METIS_TAC[] >>
    strip_tac >> simp[] >>
    conj_tac >- METIS_TAC[LIST_REL_term_UNION] >>
    match_mp_tac(List.nth(CONJUNCTS proves_rules,15)) >>
    METIS_TAC[ACONV_IMP]) >>
  conj_tac >- (
    rw[seq_trans_def] >>
    qspecl_then[`l1`,`r1`,`c1`]mp_tac term_equation >>
    simp[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    `∀t. MEM t (c1::h1) ∨ MEM t (c1'::h1') ⇒ t has_type Bool` by (
      imp_res_tac soundness >> fs[sequent_def,EVERY_MEM] >>
      METIS_TAC[] ) >>
    `welltyped (l1 === r1) ∧ welltyped (l2 === r2)` by (
      imp_res_tac term_welltyped >>
      METIS_TAC[MEM,welltyped_def] ) >>
    fs[welltyped_equation,holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    strip_tac >>
    qspecl_then[`l2`,`r2`,`c1'`]mp_tac term_equation >>
    simp[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    strip_tac >>
    qspecl_then[`Comb l1 l2`,`Comb r1 r2`,`Comb x1 x1' === Comb y1 y1'`]mp_tac term_equation >>
    simp[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    strip_tac >>
    map_every qexists_tac[`TERM_UNION h1 h1'`,`Comb x1 x1' === Comb y1 y1'`] >>
    simp[LIST_REL_term_UNION] >>
    simp[Q.SPEC`Comb X Y`(CONJUNCT2 (SPEC_ALL term_cases))] >>
    srw_tac[boolSimps.DNF_ss][] >- METIS_TAC[] >>
    match_mp_tac(List.nth(CONJUNCTS proves_rules,16)) >>
    simp[] >>
    conj_asm1_tac >- METIS_TAC[term_welltyped] >>
    conj_tac >- METIS_TAC[term_welltyped] >>
    fs[WELLTYPED,holSyntaxTheory.WELLTYPED] >>
    imp_res_tac has_type_IMP >> rfs[] >>
    fs[Q.SPEC`Fun X Y`(CONJUNCT1 (SPEC_ALL term_cases))] >> rw[] >>
    imp_res_tac WELLTYPED_LEMMA >> rw[] >>
    METIS_TAC[term_type_11] ) >>
  conj_tac >- (
    rw[seq_trans_def] >>
    qexists_tac`h1` >>
    simp[] >>
    qspecl_then[`l`,`r`,`c1`]mp_tac term_equation >>
    simp[] >>
    `c1 has_type Bool` by (
      imp_res_tac soundness >>
      fs[sequent_def] ) >>
    `l === r has_type Bool` by (
      simp[GSYM welltyped_equation] >>
      metis_tac[term_welltyped,welltyped_def] ) >>
    simp[] >> strip_tac >>
    qexists_tac`Abs x ty1 x1 === Abs x ty1 y1` >>
    qspecl_then[`Abs x ty l`,`Abs x ty r`,`Abs x ty1 x1 === Abs x ty1 y1`]mp_tac term_equation >>
    fs[holSyntaxTheory.EQUATION_HAS_TYPE_BOOL] >>
    strip_tac >>
    simp[Q.SPEC`Abs X Y Z`(CONJUNCT2 (SPEC_ALL term_cases))] >>
    conj_tac >- METIS_TAC[] >>
    match_mp_tac(List.nth(CONJUNCTS proves_rules,17)) >>
    simp[] >>
    fs[EVERY_MEM,EVERY2_EVERY] >>
    rfs[MEM_ZIP,GSYM LEFT_FORALL_IMP_THM] >>
    fs[MEM_EL,GSYM LEFT_FORALL_IMP_THM] >>
    cheat (* relate VFREE_INs *)) >>
  cheat)

val _ = export_theory();
