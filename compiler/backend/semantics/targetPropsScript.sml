open preamble
     ffiTheory
     asmTheory asmSemTheory asmPropsTheory
     targetSemTheory;

val _ = new_theory"targetProps";

val _ = set_grammar_ancestry["ffi","asm","targetSem","misc"];

val asserts_WEAKEN = Q.store_thm("asserts_WEAKEN",
  `!n next s P Q.
      (!k. k <= n ==>
        (next k = next' k) ∧
        (P (FOLDR next s (REVERSE (GENLIST ((-) n) (SUC k)))) ⇒
         P' (FOLDR next s (REVERSE (GENLIST ((-) n) (SUC k)))))) ==>
      asserts n next s P Q ==>
      asserts n next' s P' Q`,
  Induct \\ fs[asserts_def]
  \\ rpt gen_tac \\ strip_tac \\ strip_tac
  \\ conj_tac
  >- (
    first_assum(qspec_then`0`mp_tac)
    \\ impl_tac >- fs[]
    \\ first_x_assum(qspec_then`SUC n`mp_tac)
    \\ impl_tac >- fs[]
    \\ rw[] )
  >- (
    first_assum irule
    \\ goal_assum (first_assum o mp_then Any mp_tac)
    \\ ntac 2 strip_tac
    \\ conj_tac
    >- (
      first_assum(qspec_then`k`mp_tac)
      \\ impl_tac >- fs[] \\ rw[] )
    \\ first_assum(qspec_then`SUC k`mp_tac)
    \\ impl_tac >- fs[]
    \\ simp_tac(srw_ss())[GENLIST_CONS, FOLDR_APPEND]
    \\ simp_tac(srw_ss())[o_DEF]
    \\ strip_tac
    \\ first_assum(qspec_then`SUC n`mp_tac)
    \\ impl_tac >- fs[]
    \\ strip_tac \\ fs[] ));

val shift_interfer_def = Define `
  shift_interfer k s =
    s with next_interfer := shift_seq k s.next_interfer`

val shift_interfer_intro = Q.prove(
  `shift_interfer k1 (shift_interfer k2 c) =
    shift_interfer (k1+k2) c`,
  full_simp_tac(srw_ss())[shift_interfer_def,shift_seq_def,ADD_ASSOC]);

val asserts2_def = Define`
  (asserts2 n fi fc ms P =
   if n = 0n then T else
     P ms (fc ms) ∧
     asserts2 (n-1) fi fc (fi n (fc ms)) P)`;

val asserts2_change_interfer = Q.store_thm("asserts2_change_interfer",
  `asserts2 n fi fc ms P  ∧
   (∀k. k ≤ n ⇒ fi k = fi2 k)
  ⇒
   asserts2 n fi2 fc ms P`,
  qid_spec_tac`ms`
  \\ Induct_on`n`
  \\ rw[Once asserts2_def]
  \\ rw[Once asserts2_def]
  \\ first_x_assum match_mp_tac
  \\ rw[]
  \\ METIS_TAC[LESS_OR_EQ]);

val asserts2_first = Q.store_thm("asserts2_first",
  `1 ≤ n ∧ asserts2 n fi fc ms P ⇒ P ms (fc ms)`,
  rw[Once asserts2_def] \\ fs[]);

val evaluate_EQ_evaluate_lemma = Q.prove(
  `!n ms1 c.
      c.target.get_pc ms1 IN c.prog_addresses /\ c.target.state_ok ms1 /\
      (c.prog_addresses = dm) ∧
      interference_ok c.next_interfer (c.target.proj dm) /\
      (!s ms. target_state_rel c.target s ms ==> c.target.state_ok ms) /\
      (!ms1 ms2. (c.target.proj dm ms1 = c.target.proj dm ms2) ==>
           (c.target.state_ok ms1 = c.target.state_ok ms2) /\
           (c.target.get_pc ms1 = c.target.get_pc ms2) /\
           (∀a. a ∈ dm ⇒ c.target.get_byte ms1 a = c.target.get_byte ms2 a)) /\
      (!env.
         interference_ok env (c.target.proj dm) ==>
         asserts n (\k s. env k (c.target.next s)) ms1
           (\ms'. c.target.state_ok ms' /\
                  (∀pc. pc ∈ all_pcs (LENGTH (c.target.config.encode i)) init_pc 0 ⇒
                   c.target.get_byte ms' pc = c.target.get_byte ms1 pc) /\
                  c.target.get_pc ms' ∈
                    all_pcs (LENGTH (c.target.config.encode i)) init_pc c.target.config.code_alignment)
           (\ms'. target_state_rel c.target s2 ms')) /\
      (asserts2 (n+1) (λk. c.next_interfer (n +1 - k)) c.target.next ms1
        (λms1 ms2. ∀x. x ∉ dm ⇒ c.target.get_byte ms1 x = c.target.get_byte ms2 x)) ∧
      (∃k.
        c.target.get_pc ms1 = init_pc + n2w (k * (2 ** c.target.config.code_alignment)) /\
        k * (2 ** c.target.config.code_alignment) < LENGTH (c.target.config.encode i) /\
        bytes_in_memory init_pc (c.target.config.encode i)
          (c.target.get_byte ms1) c.prog_addresses) ==>
      ?ms2.
        !k. (evaluate c io (k + (n + 1)) ms1 =
             evaluate (shift_interfer (n+1) c) io k ms2) /\
            target_state_rel c.target s2 ms2`,
  Induct THEN1
   (full_simp_tac(srw_ss())[] \\ REPEAT STRIP_TAC
    \\ full_simp_tac(srw_ss())[asserts_def,LET_DEF]
    \\ SIMP_TAC std_ss [Once evaluate_def] \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `K (c.next_interfer 0)`)
    \\ full_simp_tac(srw_ss())[interference_ok_def] \\ RES_TAC \\ full_simp_tac(srw_ss())[]
    \\ REPEAT STRIP_TAC \\ RES_TAC \\ full_simp_tac(srw_ss())[shift_interfer_def,apply_oracle_def]
    \\ reverse TOP_CASE_TAC
    >- (
      `F` suffices_by fs[]
      \\ pop_assum mp_tac
      \\ fs[encoded_bytes_in_mem_def]
      \\ asm_exists_tac
      \\ qmatch_goalsub_abbrev_tac`DROP m ls`
      \\ qmatch_goalsub_abbrev_tac`bytes_in_memory _ _ mm dm`
      \\ Q.ISPECL_THEN[`TAKE m ls`,`DROP m ls`,`init_pc`,`mm`,`dm`]mp_tac bytes_in_memory_APPEND
      \\ rfs[] )
    \\ reverse TOP_CASE_TAC
    >- (
      `F` suffices_by fs[]
      \\ pop_assum mp_tac
      \\ fs[Once asserts2_def]
      \\ METIS_TAC[] )
    \\ METIS_TAC [])
  \\ REPEAT STRIP_TAC \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[arithmeticTheory.ADD_CLAUSES]
  \\ SIMP_TAC std_ss [Once evaluate_def] \\ full_simp_tac(srw_ss())[ADD1] \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Q.PAT_ASSUM `!i. bbb`(qspec_then`λi. c.next_interfer 0`mp_tac)
  \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1 (full_simp_tac(srw_ss())[interference_ok_def])
  \\ full_simp_tac(srw_ss())[]
  \\ SIMP_TAC bool_ss [GSYM ADD1,asserts_def] \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ strip_tac
  \\ `c.target.state_ok (c.target.next ms1)` by METIS_TAC [interference_ok_def]
  \\ full_simp_tac(srw_ss())[]
  \\ Q.PAT_X_ASSUM `!ms1 c. bbb ==> ?x. bb`
        (MP_TAC o Q.SPECL [`(c.next_interfer 0 (c.target.next ms1))`,
                    `(c with next_interfer := shift_seq 1 c.next_interfer)`])
  \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
   (full_simp_tac(srw_ss())[]
    \\ conj_tac >- (
      fs[all_pcs_thm,SUBSET_DEF,PULL_EXISTS]
      \\ first_assum(mp_then Any mp_tac (GEN_ALL bytes_in_memory_all_pcs))
      \\ fs[SUBSET_DEF]
      \\ disch_then match_mp_tac
      \\ simp[all_pcs_thm]
      \\ METIS_TAC[] )
    \\ conj_tac THEN1 (full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def])
    \\ conj_tac THEN1 (rpt strip_tac \\ RES_TAC)
    \\ conj_tac >- (
      rpt strip_tac
      \\ FIRST_ASSUM (MP_TAC o Q.SPEC
           `\k. if k = SUC n then c.next_interfer 0 else env k`) \\ full_simp_tac(srw_ss())[]
      \\ MATCH_MP_TAC IMP_IMP
      \\ STRIP_TAC THEN1 (full_simp_tac(srw_ss())[interference_ok_def] \\ srw_tac[][])
      \\ simp[GSYM ADD1, asserts_def]
      \\ MATCH_MP_TAC asserts_WEAKEN
      \\ simp_tac(srw_ss())[FUN_EQ_THM]
      \\ rw[])
    \\ conj_tac >-  (
      qhdtm_x_assum`asserts2`mp_tac
      \\ simp[Once asserts2_def, shift_seq_def]
      \\ rw[]
      \\ irule asserts2_change_interfer
      \\ simp[]
      \\ goal_assum(first_assum o mp_then Any mp_tac)
      \\ simp[] )
    \\ `c.target.proj dm (c.next_interfer 0 (c.target.next ms1)) =
        c.target.proj dm (c.target.next ms1)` by fs[interference_ok_def]
    \\ qpat_x_assum`∀ms1 ms2. _ ⇒ _` drule
    \\ strip_tac \\ fs[]
    \\ rfs[all_pcs_thm]
    \\ qmatch_asmsub_rename_tac`x * _ < _`
    \\ qexists_tac`x` \\ simp[]
    \\ irule bytes_in_memory_change_mem
    \\ goal_assum (first_assum o mp_then Any mp_tac)
    \\ qx_gen_tac`j` \\ strip_tac
    \\ first_x_assum(qspec_then`init_pc + n2w j`mp_tac)
    \\ impl_tac
    >- (
      imp_res_tac bytes_in_memory_all_pcs
      \\ first_x_assum(qspec_then`0`mp_tac)
      \\ fs[all_pcs_thm,SUBSET_DEF,PULL_EXISTS] )
    \\ rw[]
    \\ first_x_assum(qspec_then`λi x. x`mp_tac)
    \\ impl_tac >- fs[interference_ok_def]
    \\ strip_tac
    \\ drule asserts_IMP_FOLDR_COUNT_LIST_LESS
    \\ disch_then(qspec_then`0`mp_tac)
    \\ impl_tac >- fs[]
    \\ simp[]
    \\ strip_tac
    \\ first_x_assum (match_mp_tac o GSYM)
    \\ qexists_tac`j`
    \\ simp[] )
  \\ strip_tac \\ fs[]
  \\ qexists_tac`ms2`
  \\ reverse TOP_CASE_TAC
  >- (
    `F` suffices_by fs[]
    \\ pop_assum mp_tac
    \\ simp[encoded_bytes_in_mem_def]
    \\ qexists_tac`i`
    \\ qmatch_assum_abbrev_tac`k * a < LENGTH bs`
    \\ Q.ISPECL_THEN[`TAKE (k * a) bs`,`DROP (k * a) bs`,`init_pc`]mp_tac bytes_in_memory_APPEND
    \\ simp[]
    \\ METIS_TAC[MULT_COMM] )
  \\ rw[]
  \\ fs[GSYM shift_interfer_def, shift_interfer_intro,apply_oracle_def]
  \\ fs[GSYM ADD1]
  \\ simp[ADD1]
  \\ TOP_CASE_TAC
  \\ `F` suffices_by fs[]
  \\ pop_assum mp_tac \\ simp[]
  \\ imp_res_tac asserts2_first \\ fs[]);

val enc_ok_not_empty = Q.prove(
  `enc_ok c /\ asm_ok w c ==> (c.encode w <> [])`,
  METIS_TAC [listTheory.LENGTH_NIL,enc_ok_def]);

val asm_step_IMP_evaluate_step = Q.store_thm("asm_step_IMP_evaluate_step",
  `!c s1 ms1 io i s2.
      backend_correct c.target /\
      (c.prog_addresses = s1.mem_domain) /\
      interference_ok c.next_interfer (c.target.proj s1.mem_domain) /\
      asm_step c.target.config s1 i s2 /\
      (s2 = asm i (s1.pc + n2w (LENGTH (c.target.config.encode i))) s1) /\
      target_state_rel c.target (s1:'a asm_state) (ms1:'state) ==>
      ?l ms2. !k. (evaluate c io (k + l) ms1 =
                   evaluate (shift_interfer l c) io k ms2) /\
                  target_state_rel c.target s2 ms2 /\ l <> 0`,
  full_simp_tac(srw_ss()) [backend_correct_def, target_ok_def, LET_DEF]
  \\ rw[]
  \\ first_x_assum drule
  \\ disch_then drule
  \\ strip_tac
  \\ qexists_tac`n+1` \\ fs[]
  \\ MATCH_MP_TAC (GEN_ALL evaluate_EQ_evaluate_lemma)
  \\ qexists_tac`s1.pc`
  \\ qexists_tac`i`
  \\ Q.EXISTS_TAC `s1.mem_domain`
  \\ fs[]
  \\ conj_tac
  >- (
    fs[asm_step_def]
    \\ fs[target_state_rel_def]
    \\ imp_res_tac bytes_in_memory_all_pcs
    \\ fs[SUBSET_DEF,all_pcs_thm,PULL_EXISTS]
    \\ first_x_assum(qspec_then`1`mp_tac)
    \\ simp[]
    \\ disch_then(qspec_then`0`mp_tac)
    \\ simp[]
    \\ disch_then irule
    \\ Cases_on`c.target.config.encode i` \\ fs[]
    \\ pop_assum mp_tac \\ simp[]
    \\ match_mp_tac enc_ok_not_empty
    \\ fs[] )
  \\ conj_tac >- fs[target_state_rel_def]
  \\ conj_tac >- fs[target_state_rel_def]
  \\ conj_tac >- METIS_TAC[]
  \\ conj_tac >- (
    ntac 2 strip_tac
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`\k. env (n - k)`])
    \\ simp[]
    \\ impl_tac
    >- fs[interference_ok_def]
    \\ match_mp_tac asserts_WEAKEN
    \\ simp[] )
  \\ conj_tac >- cheat (* extend backend_correct *)
  \\ qexists_tac`0`
  \\ conj_tac >- fs[target_state_rel_def]
  \\ conj_tac >- (
    CCONTR_TAC \\ fs[]
    \\ pop_assum mp_tac
    \\ simp[]
    \\ match_mp_tac enc_ok_not_empty
    \\ fs[asm_step_def] )
  \\ fs[asm_step_def]
  \\ irule bytes_in_memory_change_mem
  \\ goal_assum(first_assum o mp_then Any mp_tac)
  \\ fs[target_state_rel_def]
  \\ rw[]
  \\ first_x_assum (irule o GSYM)
  \\ drule (GEN_ALL bytes_in_memory_all_pcs)
  \\ simp[SUBSET_DEF, all_pcs_thm, PULL_EXISTS]
  \\ disch_then(qspec_then`0`mp_tac) \\ simp[])
  |> SIMP_RULE std_ss [GSYM PULL_FORALL];

(* basic properties *)

val evaluate_add_clock = Q.store_thm("evaluate_add_clock",
  `∀mc_conf ffi k ms k1 r ms1 st1.
    evaluate mc_conf ffi k ms = (r,ms1,st1) /\ r <> TimeOut ==>
    evaluate mc_conf ffi (k + k1) ms = (r,ms1,st1)`,
  ho_match_mp_tac evaluate_ind >> srw_tac[][] >>
  qhdtm_x_assum`evaluate` mp_tac >>
  simp[Once evaluate_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  simp[Once evaluate_def,SimpR``$==>``] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[apply_oracle_def] >- (
    IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
    IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
    first_x_assum(qspec_then`k1`mp_tac) >> simp[] ) >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  IF_CASES_TAC >> fs[] \\
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  (fn g => subterm split_uncurry_arg_tac (#2 g) g) >> full_simp_tac(srw_ss())[] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  first_x_assum(qspec_then`k1`mp_tac) >> simp[]);

val evaluate_io_events_mono = Q.store_thm("evaluate_io_events_mono",
  `∀mc_conf ffi k ms.
     ffi.io_events ≼ (SND(SND(evaluate mc_conf ffi k ms))).io_events`,
  ho_match_mp_tac evaluate_ind >>
  rpt gen_tac >> strip_tac >>
  simp[Once evaluate_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[apply_oracle_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  TRY BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  TRY BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  TRY BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  full_simp_tac(srw_ss())[call_FFI_def] >> every_case_tac >>
  full_simp_tac(srw_ss())[] >>
  rpt var_eq_tac >> full_simp_tac(srw_ss())[] >>
  full_simp_tac(srw_ss())[IS_PREFIX_APPEND]);

val evaluate_add_clock_io_events_mono = Q.store_thm("evaluate_add_clock_io_events_mono",
  `∀mc_conf ffi k ms k'.
   k ≤ k' ⇒
   (SND(SND(evaluate mc_conf ffi k ms))).io_events ≼
   (SND(SND(evaluate mc_conf ffi k' ms))).io_events`,
  ho_match_mp_tac evaluate_ind >>
  rpt gen_tac >> strip_tac >>
  rpt gen_tac >> strip_tac >>
  simp_tac(srw_ss())[Once evaluate_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[]
  >- METIS_TAC[evaluate_io_events_mono] >>
  BasicProvers.TOP_CASE_TAC >> fs [] >>
  TRY BasicProvers.TOP_CASE_TAC >> fs [] >>
  TRY BasicProvers.TOP_CASE_TAC >> fs [] >>
  full_simp_tac(srw_ss())[apply_oracle_def] >>
  TRY BasicProvers.TOP_CASE_TAC >> fs [] >>
  TRY BasicProvers.TOP_CASE_TAC >> fs [] >>
  TRY BasicProvers.TOP_CASE_TAC >> fs [] >>
  TRY BasicProvers.TOP_CASE_TAC >> fs []
  \\ `k ≤ k' + 1` by decide_tac
  \\ res_tac
  \\ CONV_TAC (RAND_CONV (SIMP_CONV std_ss [Once evaluate_def]))
  \\ fs [apply_oracle_def]
  \\ METIS_TAC[evaluate_io_events_mono]);

val _ = export_theory();
