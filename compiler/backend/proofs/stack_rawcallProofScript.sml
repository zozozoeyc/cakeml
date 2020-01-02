(*
  Correctness proof for stack_rawcall
*)

open preamble stackLangTheory stackSemTheory stackPropsTheory stack_rawcallTheory
local open wordSemTheory labPropsTheory in end

val _ = new_theory"stack_rawcallProof";
val _ = (max_print_depth := 18);

val word_shift_def = backend_commonTheory.word_shift_def
val theWord_def = wordSemTheory.theWord_def;
val isWord_def = wordSemTheory.isWord_def;

val _ = set_grammar_ancestry["stack_rawcall","stackLang","stackSem","stackProps"];
Overload good_dimindex[local] = ``labProps$good_dimindex``
Overload comp[local] = ``stack_rawcall$comp``
Overload compile[local] = ``stack_rawcall$compile``

Definition state_ok_def:
  state_ok i code <=>
    !n v.
      lookup n i = SOME v ==>
      ?p. lookup n code = SOME (Seq (StackAlloc v) p)
End

Definition state_rel_def:
  state_rel i s t <=>
    ?c (* co cc *).
      domain c = domain s.code /\
      t = s with <| code := c (* ;
                    compile := cc ;
                    compile_oracle := co *) |> /\
(*    s.compile = pure_cc compile t.compile /\
      t.compile_oracle = (I ## compile ## I) o s.compile_oracle /\ *)
      state_ok i s.code /\
      !n b.
        lookup n s.code = SOME b ==>
        ?i. state_ok i s.code /\
            lookup n c = SOME (comp_top i b)
End

Theorem state_rel_thm =
  state_rel_def |> SIMP_RULE (srw_ss()) [state_component_equality];

Triviality with_stack_space:
  t1 with stack_space := t1.stack_space = t1
Proof
  fs [state_component_equality]
QED

Theorem comp_LN:
  !(i:num num_map) b. comp_top LN b = b /\ comp LN b = b
Proof
  recInduct comp_ind \\ rw []
  \\ Cases_on `p` \\ simp [Once comp_def,Once comp_top_def]
  \\ fs [CaseEq"option",pair_case_eq,PULL_EXISTS,comp_seq_def,lookup_def]
  \\ CCONTR_TAC \\ fs []
  \\ rename [`oo <> NONE`]
  \\ Cases_on `oo` \\ fs []
  \\ PairCases_on `x` \\ fs [] \\ fs []
  \\ TRY (rename [`oo <> NONE`]
          \\ Cases_on `oo` \\ fs []
          \\ PairCases_on `x` \\ fs [] \\ fs [])
  \\ TRY (rename [`NONE <> oo`]
          \\ Cases_on `oo` \\ fs []
          \\ PairCases_on `x` \\ fs [] \\ fs [])
QED

Theorem get_labels_comp:
  get_labels (comp_top i e) = get_labels e
Proof
  cheat
QED

val simple_case =
  qexists_tac `0`
  \\ fs [Once comp_def,evaluate_def,get_var_def,set_var_def,loc_check_def,mem_load_def,
         alloc_def,gc_def,set_store_def,inst_def,assign_def,word_exp_def,get_vars_def,
         mem_store_def,get_fp_var_def,set_fp_var_def,wordLangTheory.word_op_def]
  \\ fs [CaseEq"option",CaseEq"word_loc",bool_case_eq,CaseEq"ffi_result",pair_case_eq,
         CaseEq"inst",CaseEq"arith",IS_SOME_EXISTS,CaseEq"list",CaseEq"memop",
         CaseEq"addr",CaseEq"fp",CaseEq"binop"] \\ rfs []
  \\ rveq \\ fs []
  \\ simp [state_rel_def,PULL_EXISTS]
  \\ fs [state_rel_thm,state_component_equality,empty_env_def]
  \\ fs [state_rel_thm,state_component_equality,empty_env_def,dec_clock_def]

Theorem evaluate_comp_Inst:
  evaluate (Inst i,s) = (r,s1) /\ r ≠ SOME Error /\ state_rel i' s t ==>
  ∃ck t1 k1.
    state_rel i' s1 t1 ∧
    evaluate (comp i' (Inst i),t with clock := ck + t.clock) =
    (r,t1 with stack_space := k1) ∧
    (r ≠ SOME TimeOut ∧ r ≠ SOME (Halt (Word 2w)) ⇒
     k1 = t1.stack_space)
Proof
  rw [] \\ reverse simple_case
  THEN1 (pairarg_tac \\ fs [] \\ fs [bool_case_eq] \\ rveq \\ fs [])
  \\ every_case_tac \\ fs [word_exp_def]
QED

Theorem comp_correct:
   !p (s:('a,'c,'b)stackSem$state) t i r s1.
     evaluate (p,s) = (r,s1) /\ r <> SOME Error /\ state_rel i s t
     ==>
     (?ck t1 k1.
        state_rel i s1 t1 /\
        evaluate (stack_rawcall$comp_top i p,t with clock := t.clock + ck) =
          (r,t1 with stack_space := k1) /\
        (r <> SOME TimeOut /\ r <> SOME (Halt (Word 2w)) ==> k1 = t1.stack_space)) /\
     (?ck t1 k1.
        state_rel i s1 t1 /\
        evaluate (stack_rawcall$comp i p,t with clock := t.clock + ck) =
          (r,t1 with stack_space := k1) /\
        (r <> SOME TimeOut /\ r <> SOME (Halt (Word 2w)) ==> k1 = t1.stack_space))
Proof
  recInduct evaluate_ind \\ rpt conj_tac \\ rpt gen_tac
  \\ strip_tac \\ simp [comp_top_def]
  THEN1
   (rename [`Skip`] \\ simple_case)
  THEN1
   (rename [`Halt`] \\ simple_case)
  THEN1
   (rename [`Alloc`] \\ simple_case)
  THEN1
   (rename [`Inst`] \\ match_mp_tac evaluate_comp_Inst \\ fs [])
  THEN1
   (rename [`Get`] \\ simple_case)
  THEN1
   (rename [`Set`] \\ simple_case)
  THEN1
   (rename [`Tick`] \\ simple_case)
  THEN1
   (rename [`Seq`]
    \\ rpt gen_tac \\ strip_tac
    \\ conj_asm1_tac THEN1
     (fs [evaluate_def] \\ rpt (pairarg_tac \\ fs [])
      \\ reverse (fs [CaseEq"bool"]) \\ rveq \\ fs []
      THEN1
       (first_x_assum drule \\ strip_tac \\ fs []
        \\ qexists_tac `ck'` \\ fs [] \\ metis_tac [])
      \\ first_x_assum drule \\ rewrite_tac [GSYM AND_IMP_INTRO]
      \\ disch_then kall_tac \\ strip_tac
      \\ first_x_assum drule \\ rewrite_tac [GSYM AND_IMP_INTRO]
      \\ disch_then kall_tac \\ strip_tac
      \\ `t1 with stack_space := t1.stack_space = t1` by fs [state_component_equality]
      \\ fs []
      \\ qpat_x_assum `evaluate (comp i c1,_) = (NONE,_)` assume_tac
      \\ drule evaluate_add_clock \\ fs []
      \\ disch_then (qspec_then `ck'` assume_tac)
      \\ qexists_tac `ck + ck'` \\ fs []
      \\ asm_exists_tac \\ simp [state_component_equality])
    \\ Cases_on `comp i (Seq c1 c2) = Seq (comp i c1) (comp i c2)`
    THEN1 asm_rewrite_tac []
    \\ fs [] \\ simp [comp_top_def]
    \\ ntac 1 (pop_assum mp_tac)
    \\ simp [Q.SPECL[`Seq c1 c2`] comp_def]
    \\ simp [comp_seq_def]
    \\ simp [CaseEq"option",pair_case_eq,FORALL_PROD,PULL_EXISTS]
    \\ Cases_on `dest_case (c1,c2)` \\ fs []
    \\ PairCases_on `x` \\ fs []
    \\ Cases_on `lookup x1 i` \\ fs []
    \\ disch_then kall_tac
    \\ fs [dest_case_def,CaseEq"stackLang$prog",CaseEq"option",CaseEq"sum"]
    \\ rveq \\ fs []
    \\ qpat_x_assum `evaluate _ = _` kall_tac
    \\ qpat_x_assum `evaluate _ = _` mp_tac
    \\ qpat_x_assum `!x. _` kall_tac
    \\ simp [evaluate_def]
    \\ IF_CASES_TAC \\ fs []
    \\ IF_CASES_TAC \\ fs [find_code_def]
    \\ qpat_assum `state_rel i s t` (mp_tac o REWRITE_RULE [state_rel_thm])
    \\ strip_tac
    \\ qpat_assum `state_ok i _` (mp_tac o REWRITE_RULE [state_ok_def])
    \\ disch_then drule \\ strip_tac
    \\ first_assum drule
    \\ strip_tac \\ fs []
    \\ IF_CASES_TAC \\ fs [] \\ rveq
    \\ Cases_on `s.clock = 0` \\ fs []
    THEN1
     (rpt strip_tac \\ rveq \\ fs []
      \\ qexists_tac `0` \\ fs []
      \\ simp [state_rel_def,PULL_EXISTS]
      \\ asm_exists_tac \\ simp [empty_env_def]
      \\ rw [] \\ fs [] \\ simp [evaluate_def,dest_Seq_def,comp_top_def,empty_env_def]
      \\ fs [state_component_equality,empty_env_def])
    \\ fs [dec_clock_def]
    \\ last_x_assum mp_tac
    \\ simp [Once evaluate_def]
    \\ simp [Once evaluate_def,find_code_def,dec_clock_def]
    \\ TOP_CASE_TAC \\ Cases_on `q` \\ fs []
    \\ rpt strip_tac \\ rveq \\ fs [] \\ rfs []
    \\ `state_rel i
           (s with stack_space := k + s.stack_space)
           (t with stack_space := k + t.stack_space)`
         by fs [state_rel_thm]
    \\ first_x_assum drule
    \\ rewrite_tac [GSYM AND_IMP_INTRO]
    \\ disch_then kall_tac
    \\ simp[Once comp_def]
    \\ simp [Once evaluate_def,find_code_def,dec_clock_def,comp_top_def]
    \\ simp[Once comp_def]
    \\ strip_tac
    \\ asm_exists_tac \\ simp []
    \\ rw []
    THEN1
     (simp [Once evaluate_def,comp_top_def,dest_Seq_def,dec_clock_def]
      \\ qexists_tac `ck` \\ fs []
      \\ once_rewrite_tac [CONJ_COMM] \\ asm_exists_tac \\ simp []
      \\ ntac 2 (pop_assum mp_tac)
      \\ simp [evaluate_def]
      \\ qpat_abbrev_tac `pat1 = (comp i' p, _)`
      \\ qpat_abbrev_tac `pat2 = (comp i' p, _)`
      \\ qsuff_tac `pat1 = pat2` \\ fs []
      \\ unabbrev_all_tac \\ fs [state_component_equality])
    THEN1
     (simp [evaluate_def]
      \\ simp [comp_top_def,dest_Seq_def,dec_clock_def]
      \\ qexists_tac `ck` \\ fs []
      \\ once_rewrite_tac [CONJ_COMM] \\ asm_exists_tac \\ simp []
      \\ qpat_x_assum `_ = (_,_)` mp_tac
      \\ simp [evaluate_def])
    THEN1
     (simp [evaluate_def]
      \\ simp [comp_top_def,dest_Seq_def,dec_clock_def]
      \\ qpat_x_assum `_ = (_,_)` mp_tac
      (* \\ qpat_x_assum `_ = (_,_)` mp_tac *)
      \\ simp [evaluate_def]
      \\ `k + s.stack_space < x <=> s.stack_space < x - k` by fs []
      \\ asm_rewrite_tac [] \\ pop_assum kall_tac
      \\ IF_CASES_TAC \\ fs [empty_env_def]
      THEN1
       (rw [] \\ fs [state_component_equality,empty_env_def]
        \\ qexists_tac `ck` \\ fs [])
      \\ simp [dest_Seq_def,comp_top_def]
      \\ TOP_CASE_TAC \\ fs []
      \\ TOP_CASE_TAC \\ fs []
      \\ strip_tac \\ rveq \\ fs []
      \\ qexists_tac `ck + 1` \\ fs []
      \\ once_rewrite_tac [CONJ_COMM] \\ asm_exists_tac \\ simp []))
  THEN1
   (rename [`Return`] \\ simple_case)
  THEN1
   (rename [`Raise`] \\ simple_case)
  THEN1
   (rename [`If`] \\ cheat)
  THEN1
   (rename [`While`] \\ cheat)
  THEN1
   (rename [`JumpLower`] \\ cheat)
  THEN1
   (rename [`RawCall`] \\ cheat)
  THEN1
   (rename [`Call`] \\ cheat)
  THEN1
   (rename [`Install`]
    \\ fs [evaluate_def,CaseEq"option",pair_case_eq,CaseEq"word_loc",
           state_rel_thm,Once comp_def,PULL_EXISTS]
    \\ rpt (pairarg_tac \\ fs [])
    \\ fs [evaluate_def,CaseEq"option",pair_case_eq,CaseEq"word_loc",CaseEq"list",
           CaseEq"bool"] \\ rveq \\ fs [PULL_EXISTS,with_stack_space]
    \\ fs [get_var_def]
    \\ qabbrev_tac `new_prog = (k,prog)::v7`
    \\ fs [domain_union]
    \\ (conj_asm1_tac THEN1 (fs [state_ok_def,lookup_union] \\ rw [] \\ res_tac \\ fs []))
    \\ fs [lookup_union,CaseEq"option"]
    \\ (reverse (rpt strip_tac) THEN1
     (res_tac \\ fs []
      \\ qexists_tac `i'` \\ fs []
      \\ fs [state_ok_def,lookup_union] \\ rw [] \\ res_tac \\ fs []))
    \\ qexists_tac `LN` \\ fs []
    \\ simp [state_ok_def,lookup_def,comp_LN]
    \\ fs [domain_lookup,EXTENSION]
    \\ last_x_assum (qspec_then `n` mp_tac)
    \\ Cases_on `lookup n t.code` \\ fs [])
  THEN1
   (rename [`CodeBufferWrite`] \\ simple_case)
  THEN1
   (rename [`DataBufferWrite`] \\ simple_case)
  THEN1
   (rename [`FFI`] \\ simple_case)
  THEN1
   (rename [`LocValue`] \\ simple_case
    \\ res_tac \\ disj2_tac \\ asm_exists_tac \\ fs [get_labels_comp])
  THEN1
   (rename [`StackAlloc`] \\ simple_case)
  THEN1
   (rename [`StackFree`] \\ simple_case)
  THEN1
   (rename [`StackLoad`] \\ simple_case)
  THEN1
   (rename [`StackLoadAny`] \\ simple_case)
  THEN1
   (rename [`StackStore`] \\ simple_case)
  THEN1
   (rename [`StackStoreAny`] \\ simple_case)
  THEN1
   (rename [`StackGetSize`] \\ simple_case)
  THEN1
   (rename [`StackSetSize`] \\ simple_case)
  THEN1
   (rename [`BitmapLoad`] \\ simple_case)
QED

Theorem domain_fromAList_compile_toAList:
  domain (fromAList (compile (toAList code))) = domain code
Proof
  cheat
QED

Theorem state_ok_collect_info:
  state_ok (collect_info (toAList code) LN) code
Proof
  cheat
QED

Theorem compile_semantics:
   s.use_stack ∧
   semantics start s <> Fail
   ==>
   semantics start (s with
                    code := fromAList (stack_rawcall$compile (toAList s.code))) =
   semantics start s
Proof
  simp[GSYM AND_IMP_INTRO] >> strip_tac >>
  simp[semantics_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  DEEP_INTRO_TAC some_intro >> full_simp_tac(srw_ss())[] >>
  conj_tac >- (
    gen_tac >> ntac 2 strip_tac >>
    IF_CASES_TAC >> full_simp_tac(srw_ss())[] >- (
      first_x_assum(qspec_then`k'`mp_tac)>>simp[]>>
      (fn g => subterm (fn tm => Cases_on`^(assert has_pair_type tm)`) (#2 g) g) >>
      simp[] >>
      qmatch_assum_rename_tac`_ = (res,_)` >>
      Cases_on`res=SOME Error`>>simp[]>>
      drule comp_correct >>
      fs [comp_top_def] >> simp [Once comp_def] >>
      simp [Once state_rel_def,PULL_EXISTS] >>
      disch_then (qspec_then `collect_info (toAList s.code) LN` mp_tac) >>
      disch_then (qspec_then `fromAList (compile (toAList s.code))` mp_tac) >>
      impl_tac >-
       (simp [domain_fromAList_compile_toAList]
        \\ conj_asm1_tac \\ simp [state_ok_collect_info]
        \\ rw [] \\ asm_exists_tac \\ simp []
        \\ simp [compile_def,lookup_fromAList,ALOOKUP_MAP]
        \\ fs [ALOOKUP_toAList]) >>
      strip_tac >>
      qpat_x_assum`_ ≠ SOME TimeOut`mp_tac >>
      (fn g => subterm (fn tm => Cases_on`^(assert has_pair_type tm)`) (#2 g) g) >>
      strip_tac >>
      drule (Q.GEN`extra`evaluate_add_clock) >>
      disch_then(qspec_then`ck`mp_tac) >> full_simp_tac(srw_ss())[] >>
      fs[]) >>
    DEEP_INTRO_TAC some_intro >> full_simp_tac(srw_ss())[] >>
    conj_tac >- (
      srw_tac[][] >>
      Cases_on`r=TimeOut`>>full_simp_tac(srw_ss())[]>>
      qpat_x_assum `evaluate _ = (SOME r, t)` assume_tac >>
      drule comp_correct >>
      fs [comp_top_def] >> simp [Once comp_def] >>
      simp [Once state_rel_def,PULL_EXISTS] >>
      disch_then (qspec_then `collect_info (toAList s.code) LN` mp_tac) >>
      disch_then (qspec_then `fromAList (compile (toAList s.code))` mp_tac) >>
      impl_tac >-
       (conj_tac THEN1 (strip_tac \\ fs [])
        \\ simp [domain_fromAList_compile_toAList]
        \\ conj_asm1_tac \\ simp [state_ok_collect_info]
        \\ rw [] \\ asm_exists_tac \\ simp []
        \\ simp [compile_def,lookup_fromAList,ALOOKUP_MAP]
        \\ fs [ALOOKUP_toAList]) >>
      strip_tac >>
      old_dxrule(GEN_ALL evaluate_add_clock) >>
      disch_then(qspec_then `k'` mp_tac) >>
      impl_tac >- (CCONTR_TAC >> fs[]) >> simp [] >>
      dxrule evaluate_add_clock >>
      dxrule evaluate_add_clock >>
      disch_then(qspec_then `ck + k` mp_tac) >>
      impl_tac >- (CCONTR_TAC >> fs[]) >> simp [] >>
      rpt (disch_then assume_tac) >>
      fs[state_component_equality] >>
      rveq >> rpt(PURE_FULL_CASE_TAC >> fs[]) >>
      fs [state_rel_thm]) >>
    drule comp_correct >>
    fs [comp_top_def] >> simp [Once comp_def] >>
    simp [Once state_rel_def,PULL_EXISTS] >>
    disch_then (qspec_then `collect_info (toAList s.code) LN` mp_tac) >>
    disch_then (qspec_then `fromAList (compile (toAList s.code))` mp_tac) >>
    impl_tac >-
     (conj_tac THEN1 (strip_tac \\ fs [])
      \\ simp [domain_fromAList_compile_toAList]
      \\ conj_asm1_tac \\ simp [state_ok_collect_info]
      \\ rw [] \\ asm_exists_tac \\ simp []
      \\ simp [compile_def,lookup_fromAList,ALOOKUP_MAP]
      \\ fs [ALOOKUP_toAList]) >>
    strip_tac >>
    asm_exists_tac >> simp[] >>
    BasicProvers.TOP_CASE_TAC >> full_simp_tac(srw_ss())[] >>
    BasicProvers.TOP_CASE_TAC >> full_simp_tac(srw_ss())[]) >>
  strip_tac >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >- (
    first_x_assum(qspec_then`k`mp_tac)>>simp[]>>
    first_x_assum(qspec_then`k`mp_tac)>>
    (fn g => subterm (fn tm => Cases_on`^(assert has_pair_type tm)`) (#2 g) g) >>
    simp[] >> strip_tac >> fs[] >>
    drule comp_correct >>
    fs [comp_top_def] >> simp [Once comp_def] >>
    simp [Once state_rel_def,PULL_EXISTS] >>
    qexists_tac `collect_info (toAList s.code) LN` >>
    qexists_tac `fromAList (compile (toAList s.code))` >>
    simp [domain_fromAList_compile_toAList] >>
    conj_asm1_tac \\ simp [state_ok_collect_info] >>
    conj_tac THEN1
     (rw [] \\ asm_exists_tac \\ fs []
      \\ simp [compile_def,lookup_fromAList,ALOOKUP_MAP]
      \\ fs [ALOOKUP_toAList]) >>
    srw_tac[][] >>
    qpat_x_assum`_ ≠ SOME TimeOut`mp_tac >>
    (fn g => subterm (fn tm => Cases_on`^(assert has_pair_type tm)`) (#2 g) g) >> srw_tac[][] >>
    drule (GEN_ALL evaluate_add_clock) >>
    disch_then(qspec_then`ck`mp_tac)>>simp[]) >>
  DEEP_INTRO_TAC some_intro >> full_simp_tac(srw_ss())[] >>
  conj_tac >- (
    srw_tac[][] >>
    qpat_x_assum`∀k t. _`(qspec_then`k`mp_tac) >>
    (fn g => subterm (fn tm => Cases_on`^(assert has_pair_type tm)`) (#2 g) g) >>
    simp[] >>
    last_x_assum mp_tac >>
    last_x_assum mp_tac >>
    last_x_assum(qspec_then`k`mp_tac) >>
    srw_tac[][] >> full_simp_tac(srw_ss())[] >>
    `q <> SOME Error` by
      (strip_tac \\ first_x_assum (qspec_then `k` mp_tac) \\ fs []) >>
    drule comp_correct >>
    fs [comp_top_def] >> simp [Once comp_def] >>
    simp [Once state_rel_def,PULL_EXISTS] >>
    disch_then (qspec_then `collect_info (toAList s.code) LN` mp_tac) >>
    disch_then (qspec_then `fromAList (compile (toAList s.code))` mp_tac) >>
    (impl_tac >-
     (simp [domain_fromAList_compile_toAList]
      \\ conj_asm1_tac \\ simp [state_ok_collect_info]
      \\ rw [] \\ asm_exists_tac \\ simp []
      \\ simp [compile_def,lookup_fromAList,ALOOKUP_MAP]
      \\ fs [ALOOKUP_toAList])) >>
    rveq \\ fs [] >>
    strip_tac >> pop_assum mp_tac >> pop_assum mp_tac >>
    last_x_assum assume_tac >>
    drule (GEN_ALL evaluate_add_clock) >>
    disch_then(qspec_then`ck`mp_tac)>>simp[] >>
    rpt strip_tac >> rveq \\ fs []) >>
  srw_tac[][] >>
  qmatch_abbrev_tac`build_lprefix_lub l1 = build_lprefix_lub l2` >>
  `(lprefix_chain l1 ∧ lprefix_chain l2) ∧ equiv_lprefix_chain l1 l2`
    suffices_by metis_tac[build_lprefix_lub_thm,lprefix_lub_new_chain,unique_lprefix_lub] >>
  conj_asm1_tac >- (
    UNABBREV_ALL_TAC >>
    conj_tac >>
    Ho_Rewrite.ONCE_REWRITE_TAC[GSYM o_DEF] >>
    REWRITE_TAC[IMAGE_COMPOSE] >>
    match_mp_tac prefix_chain_lprefix_chain >>
    simp[prefix_chain_def,PULL_EXISTS] >>
    qx_genl_tac[`k1`,`k2`] >>
    qspecl_then[`k1`,`k2`]mp_tac LESS_EQ_CASES >>
    match_mp_tac(PROVE[]``((a ⇒ c) ∧ (b ⇒ d)) ⇒ (a ∨ b ⇒ c ∨ d)``) \\
    simp[LESS_EQ_EXISTS] \\
    conj_tac \\ strip_tac \\ rveq \\
    qmatch_goalsub_abbrev_tac`e,ss` \\
    Q.ISPECL_THEN[`p`,`e`,`ss`]mp_tac(GEN_ALL evaluate_add_clock_io_events_mono) \\
    simp[Abbr`ss`]) >>
  simp[equiv_lprefix_chain_thm] >>
  unabbrev_all_tac >> simp[PULL_EXISTS] >>
  ntac 2 (pop_assum kall_tac) >>
  simp[LNTH_fromList,PULL_EXISTS] >>
  simp[GSYM FORALL_AND_THM] >>
  rpt gen_tac >>
  (fn g => subterm (fn tm => Cases_on`^(assert has_pair_type tm)`) (#2 g) g) >> full_simp_tac(srw_ss())[] >>
  (fn g => subterm (fn tm => Cases_on`^(assert (fn tm => has_pair_type tm andalso free_in tm (#2 g)) tm)`) (#2 g) g) >> full_simp_tac(srw_ss())[] >>
  `q' <> SOME Error` by
    (last_x_assum (qspec_then `k` mp_tac) \\ fs [] \\ rw [] \\ fs []) >>
  drule comp_correct >>
  fs [comp_top_def] >> simp [Once comp_def] >>
  simp [Once state_rel_def,PULL_EXISTS] >>
  disch_then (qspec_then `collect_info (toAList s.code) LN` mp_tac) >>
  disch_then (qspec_then `fromAList (compile (toAList s.code))` mp_tac) >>
  impl_tac >-
   (simp [domain_fromAList_compile_toAList]
    \\ conj_asm1_tac \\ simp [state_ok_collect_info]
    \\ rw [] \\ asm_exists_tac \\ simp []
    \\ simp [compile_def,lookup_fromAList,ALOOKUP_MAP]
    \\ fs [ALOOKUP_toAList]) >>
  strip_tac >>
  reverse conj_tac >- (
    fs [state_rel_thm] >>
    srw_tac[][] >>
    qexists_tac`ck+k`>>simp[] ) >>
  srw_tac[][] >>
  qexists_tac`k`>>simp[] >>
  ntac 2 (qhdtm_x_assum`evaluate`mp_tac) >>
  qmatch_assum_abbrev_tac`evaluate (e,ss) = _` >>
  fs [state_rel_thm] >>
  Q.ISPECL_THEN[`ck`,`e`,`ss`]mp_tac(GEN_ALL evaluate_add_clock_io_events_mono)>>
  simp[Abbr`ss`] >>
  ntac 3 strip_tac >> full_simp_tac(srw_ss())[] >>
  full_simp_tac(srw_ss())[IS_PREFIX_APPEND] >>
  simp[EL_APPEND1] >> rfs [] >> simp[EL_APPEND1]
QED


(*

(* TODO: does this have to initialize the data_buffer to empty? *)
val make_init_def = Define `
  make_init c code oracle s =
    s with <| code := code; use_alloc := T; use_stack := T; gc_fun := word_gc_fun c
            ; compile := λc. s.compile c o (MAP prog_comp)
            ; compile_oracle := oracle |>`;

Theorem prog_comp_lambda:
   prog_comp = λ(n,p). ^(rhs (concl (SPEC_ALL prog_comp_def)))
Proof
  srw_tac[][FUN_EQ_THM,prog_comp_def,LAMBDA_PROD,FORALL_PROD]
QED

Theorem make_init_semantics:
   (!k prog. ALOOKUP code k = SOME prog ==> k <> gc_stub_location /\ alloc_arg prog) /\
   (∀n k p.  MEM (k,p) (FST (SND (oracle n))) ⇒ k ≠ gc_stub_location ∧ alloc_arg p) /\
   s.use_stack ∧ s.use_store ∧ ~s.use_alloc /\ s.code = fromAList (compile c code) /\
   s.compile_oracle = (I ## MAP prog_comp ## I) o oracle /\
   LENGTH s.bitmaps + LENGTH s.data_buffer.buffer + s.data_buffer.space_left < dimword (:α) − 1 ∧
   LENGTH s.stack * (dimindex (:α) DIV 8) < dimword (:α) ∧
   ALL_DISTINCT (MAP FST code) /\
   semantics start (make_init c (fromAList code) oracle s) <> Fail ==>
   semantics start (s:('a,'c,'ffi) stackSem$state) =
   semantics start (make_init c (fromAList code) oracle s)
Proof
  srw_tac[][]
  \\ drule (CONV_RULE(LAND_CONV(move_conj_left(can dest_neg)))compile_semantics
            |> GEN_ALL)
  \\ disch_then (qspecl_then [`s.compile`,`c`,`s.gc_fun`] mp_tac)
  \\ full_simp_tac(srw_ss())[make_init_def,lookup_fromAList]
  \\ impl_tac THEN1 (srw_tac[][] \\ res_tac \\ full_simp_tac(srw_ss())[])
  \\ disch_then (assume_tac o GSYM)
  \\ full_simp_tac(srw_ss())[] \\ AP_TERM_TAC
  \\ full_simp_tac(srw_ss())[state_component_equality]
  \\ full_simp_tac(srw_ss())[spt_eq_thm,wf_fromAList,lookup_fromAList,compile_def]
  \\ srw_tac[][]
  \\ srw_tac[][ALOOKUP_APPEND] \\ BasicProvers.CASE_TAC
  \\ simp[prog_comp_lambda,ALOOKUP_MAP_2]
  \\ simp[ALOOKUP_toAList,lookup_fromAList]
QED

Theorem next_lab_EQ_MAX = Q.prove(`
  !q (n:num) aux. next_lab q aux = MAX aux (next_lab q 0)`,
  ho_match_mp_tac next_lab_ind>>Cases_on`q`>>rw[]>>
  once_rewrite_tac [next_lab_def]>>
  simp_tac (srw_ss()) [] >>
  every_case_tac >>
  simp_tac (srw_ss()) [] >>
  rpt (qpat_x_assum `!x. _` (mp_tac o SIMP_RULE std_ss [])) >>
  rpt strip_tac >>
  rpt (pop_assum (fn th => once_rewrite_tac [th])) >>
  fs [AC MAX_ASSOC MAX_COMM]) |> SIMP_RULE std_ss [];

val MAX_SIMP = prove(
  ``MAX n (MAX n m) = MAX n m``,
  fs [MAX_DEF]);

Theorem next_lab_thm:
   !p.
      next_lab (p:'a stackLang$prog) 2 =
      case p of
      | Seq p1 p2 => MAX (next_lab p1 2) (next_lab p2 2)
      | If _ _ _ p1 p2 => MAX (next_lab p1 2) (next_lab p2 2)
      | While _ _ _ p => next_lab p 2
      | Call NONE _ NONE => 2
      | Call NONE _ (SOME (_,_,l2)) => MAX (l2 + 2) 2
      | Call (SOME (p,_,_,l2)) _ NONE => MAX (next_lab p 2) (l2 + 2)
      | Call (SOME (p,_,_,l2)) _ (SOME (p',_,l3)) =>
           MAX (MAX (next_lab p 2) (next_lab p' 2)) (MAX l2 l3 + 2)
      | _ => 2
Proof
  Induct \\ simp [Once next_lab_def] \\ fs []
  \\ once_rewrite_tac [next_lab_EQ_MAX]
  \\ once_rewrite_tac [next_lab_EQ_MAX]
  \\ once_rewrite_tac [next_lab_EQ_MAX]
  \\ fs [AC MAX_ASSOC MAX_COMM,MAX_SIMP]
  \\ every_case_tac \\ fs []
  \\ once_rewrite_tac [next_lab_EQ_MAX]
  \\ once_rewrite_tac [next_lab_EQ_MAX]
  \\ once_rewrite_tac [next_lab_EQ_MAX]
  \\ fs [AC MAX_ASSOC MAX_COMM,MAX_SIMP]
  \\ fs [MAX_DEF]
QED

Theorem extract_labels_next_lab:
    ∀p (aux:num) e.
    MEM e (extract_labels p) ⇒
    SND e < next_lab p 2
Proof
  ho_match_mp_tac next_lab_ind>>Cases_on`p`>>rw[]>>
  once_rewrite_tac [next_lab_thm]>>fs[extract_labels_def]>>
  fs[extract_labels_def]>>
  BasicProvers.EVERY_CASE_TAC>>fs []>>fs[MAX_DEF]
QED

Theorem stack_alloc_lab_pres:
    ∀n nl p aux.
  EVERY (λ(l1,l2). l1 = n ∧ l2 ≠ 0 ∧ l2 ≠ 1) (extract_labels p) ∧
  ALL_DISTINCT (extract_labels p) ∧
  next_lab p 2 ≤ nl ⇒
  let (cp,nl') = comp n nl p in
  EVERY (λ(l1,l2). l1 = n ∧ l2 ≠ 0 ∧ l2 ≠ 1) (extract_labels cp) ∧
  ALL_DISTINCT (extract_labels cp) ∧
  (∀lab. MEM lab (extract_labels cp) ⇒ MEM lab (extract_labels p) ∨ (nl ≤ SND lab ∧ SND lab < nl')) ∧
  nl ≤ nl'
Proof
  HO_MATCH_MP_TAC comp_ind>>Cases_on`p`>>rw[]>>
  once_rewrite_tac [comp_def]>>fs[extract_labels_def]
  >-
    (BasicProvers.EVERY_CASE_TAC>>fs[]>>rveq>>fs[extract_labels_def]>>
    rpt(pairarg_tac>>fs[])>>rveq>>fs[extract_labels_def]>>
    qpat_x_assum`A<=nl` mp_tac>>
    simp[Once next_lab_thm]>>
    strip_tac>>
    fs[ALL_DISTINCT_APPEND]
    >-
      (CCONTR_TAC>>fs[]>>
      res_tac>>fs[])
    >>
      `next_lab q 2 ≤ m'` by fs[]>>
      fs[]>>rfs[]>>
      `r < nl ∧ r' < nl` by
        fs[MAX_DEF]>>
      rw[]>>
      TRY(CCONTR_TAC>>fs[]>>
      res_tac>>fs[])
      >- metis_tac[]
      >>
        imp_res_tac extract_labels_next_lab>>fs[])
  >>
  TRY
  (rpt(pairarg_tac>>fs[])>>rveq>>fs[extract_labels_def]>>
  qpat_x_assum`A<=nl` mp_tac>>
  simp[Once next_lab_thm])>>
  (strip_tac>>
  fs[ALL_DISTINCT_APPEND]>>rw[]
  >-
    (CCONTR_TAC>>fs[]>>
    res_tac>>fs[]>- metis_tac[]>>
    imp_res_tac extract_labels_next_lab>>
    fs[])
  >>
    res_tac>>fs[])
QED

Theorem stack_alloc_comp_stack_asm_name:
    ∀n m p.
  stack_asm_name c p ∧ stack_asm_remove (c:'a asm_config) p ⇒
  let (p',m') = comp n m p in
  stack_asm_name c p' ∧ stack_asm_remove (c:'a asm_config) p'
Proof
  ho_match_mp_tac comp_ind>>Cases_on`p`>>rw[]>>
  simp[Once comp_def]
  >-
    (Cases_on`o'`>-
      fs[Once comp_def,stack_asm_name_def,stack_asm_remove_def]
    >>
    PairCases_on`x`>>SIMP_TAC std_ss [Once comp_def]>>fs[]>>
    FULL_CASE_TAC>>fs[]>>
    TRY(PairCases_on`x`)>>
    rpt(pairarg_tac>>fs[])>>rw[]>>
    fs[stack_asm_name_def,stack_asm_remove_def])
  >>
    rpt(pairarg_tac>>fs[])>>rw[]>>
    fs[stack_asm_name_def,stack_asm_remove_def]
QED

Theorem stack_alloc_stack_asm_convs:
    EVERY (λ(n,p). stack_asm_name c p) prog ∧
  EVERY (λ(n,p). (stack_asm_remove (c:'a asm_config) p)) prog ∧
  (* conf_ok is too strong, but we already have it anyway *)
  conf_ok (:'a) conf ∧
  addr_offset_ok c 0w ∧
  reg_name 10 c ∧ good_dimindex(:'a) ∧
  c.valid_imm (INL Add) 8w ∧
  c.valid_imm (INL Add) 4w ∧
  c.valid_imm (INL Add) 1w ∧
  c.valid_imm (INL Sub) 1w
  ⇒
  EVERY (λ(n,p). stack_asm_name c p) (compile conf prog) ∧
  EVERY (λ(n,p). stack_asm_remove c p) (compile conf prog)
Proof
  fs[compile_def]>>rw[]>>
    TRY (EVAL_TAC>>every_case_tac >>
         EVAL_TAC>>every_case_tac >>
         fs [] >> EVAL_TAC >>
     fs[reg_name_def, labPropsTheory.good_dimindex_def,
        asmTheory.offset_ok_def, data_to_wordTheory.conf_ok_def,
        data_to_wordTheory.shift_length_def]>>
     pairarg_tac>>fs[]>>NO_TAC)
  >>
  fs[EVERY_MAP,EVERY_MEM,FORALL_PROD,prog_comp_def]>>
  rw[]>>res_tac>>
  drule stack_alloc_comp_stack_asm_name>>fs[]>>
  disch_then(qspecl_then[`p_1`,`next_lab p_2 2`] assume_tac)>>
  pairarg_tac>>fs[]
QED

Theorem stack_alloc_reg_bound:
   10 ≤ sp ∧
    EVERY (\p. reg_bound p sp)
       (MAP SND prog1) ==>
    EVERY (\p. reg_bound p sp)
       (MAP SND (compile dc prog1))
Proof
  fs[stack_allocTheory.compile_def]>>
  strip_tac>>CONJ_TAC
  >-
    (EVAL_TAC>>TOP_CASE_TAC>>EVAL_TAC>>fs[]>>
    IF_CASES_TAC>>EVAL_TAC>>fs[])
  >>
  pop_assum mp_tac>>
  qid_spec_tac`prog1`>>Induct>>
  fs[stack_allocTheory.prog_comp_def,FORALL_PROD]>>
  ntac 3 strip_tac>>fs[]>>
  qpat_x_assum`reg_bound p_2 sp` mp_tac>>
  qpat_x_assum`10 ≤ sp` mp_tac>>
  rpt (pop_assum kall_tac)>>
  (qpat_abbrev_tac`l = next_lab _ _`) >> pop_assum kall_tac>>
  qid_spec_tac `p_2` >>
  qid_spec_tac `l` >>
  qid_spec_tac `p_1` >>
  ho_match_mp_tac stack_allocTheory.comp_ind>>
  Cases_on`p_2`>>rw[]>>
  simp[Once stack_allocTheory.comp_def]>>
  fs[reg_bound_def]>>
  TRY(ONCE_REWRITE_TAC [stack_allocTheory.comp_def]>>
    Cases_on`o'`>>TRY(PairCases_on`x`)>>fs[reg_bound_def]>>
    BasicProvers.EVERY_CASE_TAC)>>
  rpt(pairarg_tac>>fs[reg_bound_def])
QED

Theorem stack_alloc_call_args:
   EVERY (λp. call_args p 1 2 3 4 0) (MAP SND prog1) ==>
   EVERY (λp. call_args p 1 2 3 4 0) (MAP SND (compile dc prog1))
Proof
  fs[stack_allocTheory.compile_def]>>
  strip_tac>>CONJ_TAC
  >-
    (EVAL_TAC>>TOP_CASE_TAC>>EVAL_TAC>>fs[]>>
    IF_CASES_TAC>>EVAL_TAC>>fs[])
  >>
  pop_assum mp_tac>>
  qid_spec_tac`prog1`>>Induct>>
  fs[stack_allocTheory.prog_comp_def,FORALL_PROD]>>
  ntac 3 strip_tac>>fs[]>>
  (qpat_abbrev_tac`l = next_lab _ _`) >> pop_assum kall_tac>>
  qpat_x_assum`call_args p_2 1 2 3 4 0` mp_tac>>
  rpt (pop_assum kall_tac)>>
  qid_spec_tac `p_2` >>
  qid_spec_tac `l` >>
  qid_spec_tac `p_1` >>
  ho_match_mp_tac stack_allocTheory.comp_ind>>
  Cases_on`p_2`>>rw[]>>
  simp[Once stack_allocTheory.comp_def]>>fs[call_args_def]>>
  TRY(ONCE_REWRITE_TAC [stack_allocTheory.comp_def]>>
    Cases_on`o'`>>TRY(PairCases_on`x`)>>fs[call_args_def]>>
    BasicProvers.EVERY_CASE_TAC)>>
  rpt(pairarg_tac>>fs[call_args_def])
QED

Theorem compile_has_fp_ops[simp]:
  compile (dconf with <| has_fp_ops := b1; has_fp_tern := b2 |>) code = compile dconf code
Proof
  fs [compile_def,stubs_def,word_gc_code_def]
  \\ every_case_tac \\ fs []
  \\ fs [data_to_wordTheory.small_shift_length_def,
         word_gc_move_code_def,
         word_gc_move_list_code_def,
         word_gc_move_loop_code_def,
         word_gc_move_roots_bitmaps_code_def,
         word_gc_move_bitmaps_code_def,
         word_gc_move_bitmap_code_def,
         word_gen_gc_move_code_def,
         word_gen_gc_move_list_code_def,
         word_gen_gc_move_roots_bitmaps_code_def,
         word_gen_gc_move_bitmaps_code_def,
         word_gen_gc_move_bitmap_code_def,
         word_gen_gc_move_data_code_def,
         word_gen_gc_move_refs_code_def,
         word_gen_gc_move_loop_code_def,
         word_gen_gc_partial_move_code_def,
         word_gen_gc_partial_move_list_code_def,
         word_gen_gc_partial_move_roots_bitmaps_code_def,
         word_gen_gc_partial_move_bitmaps_code_def,
         word_gen_gc_partial_move_bitmap_code_def,
         word_gen_gc_partial_move_data_code_def,
         word_gen_gc_partial_move_ref_list_code_def]
QED

*)

val _ = export_theory();