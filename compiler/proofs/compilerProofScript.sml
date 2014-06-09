open HolKernel bossLib boolLib boolSimps listTheory pairTheory rich_listTheory pred_setTheory arithmeticTheory finite_mapTheory relationTheory sortingTheory stringTheory
open miscLib miscTheory bigStepTheory astTheory semanticPrimitivesTheory bigClockTheory replTheory terminationTheory
open bytecodeTheory bytecodeExtraTheory bytecodeEvalTheory bytecodeClockTheory bytecodeLabelsTheory bytecodeTerminationTheory
open modLangTheory conLangTheory decLangTheory exhLangTheory intLangTheory toIntLangTheory toBytecodeTheory compilerTheory intLangExtraTheory modLangProofTheory conLangProofTheory decLangProofTheory exhLangProofTheory patLangProofTheory intLangProofTheory bytecodeProofTheory free_varsTheory printingTheory compilerTerminationTheory

val _ = new_theory"compilerProof"

(* TODO: move *)
val EVERY_sv_every_MAP_map_sv = store_thm("EVERY_sv_every_MAP_map_sv",
  ``∀P f ls. EVERY P (MAP f (store_vs ls)) ⇒ EVERY (sv_every P) (MAP (map_sv f) ls)``,
  rpt gen_tac >>
  simp[EVERY_MAP,EVERY_MEM,store_vs_def,MEM_MAP,PULL_EXISTS,MEM_FILTER] >>
  strip_tac >> Cases >> simp[] >> rw[] >> res_tac >> fs[])

val LIST_REL_store_vs_intro = store_thm("LIST_REL_store_vs_intro",
  ``∀P l1 l2. LIST_REL (sv_rel P) l1 l2 ⇒ LIST_REL P (store_vs l1) (store_vs l2)``,
  gen_tac >>
  Induct >- simp[store_vs_def] >>
  Cases >> simp[PULL_EXISTS,sv_rel_cases] >>
  fs[store_vs_def])

val sv_to_i2_sv_rel = store_thm("sv_to_i2_sv_rel",
  ``∀g. sv_to_i2 g = sv_rel (v_to_i2 g)``,
  rw[FUN_EQ_THM,sv_to_i2_cases,EQ_IMP_THM,sv_rel_cases])

val sv_to_i1_sv_rel = store_thm("sv_to_i1_sv_rel",
  ``∀g. sv_to_i1 g = sv_rel (v_to_i1 g)``,
  rw[FUN_EQ_THM,sv_to_i1_cases,EQ_IMP_THM,sv_rel_cases])

val EVERY_sv_every_EVERY_store_vs = store_thm("EVERY_sv_every",
  ``∀P ls. EVERY (sv_every P ) ls ⇔ EVERY P (store_vs ls)``,
  rw[EVERY_MEM,EQ_IMP_THM,store_vs_def,MEM_MAP,PULL_EXISTS,MEM_FILTER] >>
  res_tac >> TRY(Cases_on`e`) >> TRY(Cases_on`y`) >> fs[])

val EVERY_store_vs_intro = store_thm("EVERY_store_vs_intro",
  ``∀P ls. EVERY (sv_every P) ls ⇒ EVERY P (store_vs ls)``,
  rw[EVERY_MEM,store_vs_def,MEM_MAP,MEM_FILTER] >>
  res_tac >>
  qmatch_assum_rename_tac`sv_every P x`[] >>
  Cases_on`x`>>fs[])

val vs_to_i2_MAP = store_thm("vs_to_i2_MAP",
  ``∀g vs1 vs2. vs_to_i2 g vs1 vs2 ⇔ LIST_REL (v_to_i2 g) vs1 vs2``,
  gen_tac >> Induct >> simp[Once v_to_i2_cases])

val vs_to_i1_MAP = store_thm("vs_to_i1_MAP",
  ``∀g vs1 vs2. vs_to_i1 g vs1 vs2 ⇔ LIST_REL (v_to_i1 g) vs1 vs2``,
  gen_tac >> Induct >> simp[Once v_to_i1_cases])

val map_sv_compose = store_thm("map_sv_compose",
  ``map_sv f (map_sv g x) = map_sv (f o g) x``,
  Cases_on`x`>>simp[])

val Cv_bv_can_Print = save_thm("Cv_bv_can_Print",prove(
  ``(∀Cv bv. Cv_bv pp Cv bv ⇒ IS_SOME (bv_to_string bv)) ∧
    (∀bvs ce env defs. benv_bvs pp bvs ce env defs ⇒ T)``,
  ho_match_mp_tac Cv_bv_ind >> simp[bv_to_string_def,bvs_to_chars_thm] >>
  rw[] >> pop_assum mp_tac >> simp[] >>
  simp[EVERY2_EVERY,EVERY_MEM,FORALL_PROD] >> rw[] >>
  rfs[MEM_ZIP,GSYM LEFT_FORALL_IMP_THM,MEM_EL,EL_MAP])
  |> CONJUNCT1)

val LIST_REL_sv_rel_exh_Cv_syneq_trans = store_thm("LIST_REL_sv_rel_exh_Cv_syneq_trans",
  ``∀vs Cvs Cvs2.
     LIST_REL (sv_rel syneq) Cvs Cvs2 ∧
     LIST_REL (sv_rel exh_Cv) vs Cvs ⇒
     LIST_REL (sv_rel exh_Cv) vs Cvs2``,
  rw[EVERY2_EVERY,EVERY_MEM] >> rfs[MEM_ZIP,PULL_EXISTS] >>
  fs[sv_rel_cases,PULL_EXISTS] >> rw[] >>
  metis_tac[exh_Cv_syneq_trans,store_v_distinct,store_v_11])

(* misc *)

val code_env_cd_append = store_thm("code_env_cd_append",
  ``∀code cd code'. code_env_cd code cd ∧ ALL_DISTINCT (FILTER is_Label (code ++ code')) ⇒ code_env_cd (code ++ code') cd``,
  rw[] >> PairCases_on`cd` >>
  fs[code_env_cd_def] >>
  HINT_EXISTS_TAC>>simp[]>>
  HINT_EXISTS_TAC>>simp[])

val exp_pat_syneq_exp = store_thm("exp_pat_syneq_exp",
  ``∀z1 z2 V e1 e2. exp_pat z1 z2 V e1 e2 ⇒
      set (free_vars_pat e1) ⊆ count z1 ∧
      set (free_vars_pat e2) ⊆ count z2 ∧
      (∀x y. V x y ⇒ (x < z1 ⇔ y < z2) ∧ (z1 ≤ x ⇒ y = x))
      ⇒
      syneq_exp z1 z2 V (exp_to_Cexp e1) (exp_to_Cexp e2)``,
  ho_match_mp_tac exp_pat_strongind >> simp[] >>
  strip_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once syneq_exp_cases] >>
    metis_tac[]) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >>
    simp[Once syneq_exp_cases] >>
    match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_mono_V)) >>
    fs[] >>
    qpat_assum`p ⇒ q`mp_tac >>
    discharge_hyps >- (
      ONCE_REWRITE_TAC[CONJ_ASSOC] >>
      conj_tac >- (
        fsrw_tac[ARITH_ss][SUBSET_DEF,PULL_EXISTS] >>
        rw[] >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
      Cases >> Cases >> simp[bind_pat_def,ADD1] >>
      metis_tac[]) >>
    strip_tac >>
    HINT_EXISTS_TAC >> simp[] >>
    Cases >> Cases >> simp[bind_pat_def]) >>
  strip_tac >- (
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >>
    simp[Once syneq_exp_cases,EVERY2_MAP] >>
    match_mp_tac EVERY2_MEM_MONO >>
    HINT_EXISTS_TAC >>
    imp_res_tac EVERY2_LENGTH >>
    simp[UNCURRY,MEM_ZIP,PULL_EXISTS] >>
    rw[] >> first_x_assum match_mp_tac >>
    fs[SUBSET_DEF,MEM_FLAT,MEM_MAP,PULL_EXISTS] >>
    metis_tac[MEM_EL]) >>
  strip_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >>
    simp[Once syneq_exp_cases] >>
    qexists_tac`λx y. x = 0 ∧ y = 0` >>
    reverse conj_tac >- (
      simp[Once syneq_exp_cases] ) >>
    simp[Once syneq_exp_cases] >>
    simp[syneq_cb_aux_def] >>
    match_mp_tac syneq_exp_shift_both >>
    qpat_assum`p ⇒ q`mp_tac >>
    discharge_hyps_keep >- (
      ONCE_REWRITE_TAC[CONJ_ASSOC] >>
      conj_tac >- (
        fsrw_tac[ARITH_ss][SUBSET_DEF,PULL_EXISTS] >>
        rw[] >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
      Cases >> Cases >> simp[bind_pat_def,ADD1] >>
      metis_tac[]) >>
    strip_tac >>
    first_assum (match_exists_tac o concl) >>
    simp[inv_DEF,O_DEF,PULL_EXISTS] >>
    conj_tac >- (
      ntac 2 gen_tac >> Cases >> Cases >> simp[syneq_cb_V_def,bind_pat_def,ADD1] >>
      rw[] >> CCONTR_TAC >> fs[] >> rw[] >> res_tac >> rw[] >>
      fsrw_tac[ARITH_ss][] ) >>
    fsrw_tac[ARITH_ss][SUBSET_DEF,PULL_EXISTS] >>
    rw[] >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >> fs[] >>
    Cases_on`es1=[]`>>fs[]>-(
      Cases_on`op`>>simp[]>-(
        Cases_on`o'`>>simp[]>>
        simp[Once syneq_exp_cases])>>
      simp[Once syneq_exp_cases])>>
    `∃h1 t1. es1 = h1::t1` by (Cases_on`es1`>>fs[])>> fs[] >>
    Cases_on`t1=[]`>>fs[]>-(
      Cases_on`op`>>simp[]>-(
        Cases_on`o'`>>simp[]>-(
          rw[] >> fs[]>>
          Cases_on`o''`>>simp[]>>
          simp[Once syneq_exp_cases])>>
        rw[]>>fs[]>>
        simp[Once syneq_exp_cases])>>
      rw[]>>fs[]>>
      simp[Once syneq_exp_cases])>>
    `∃h2 t2. t1 = h2::t2` by (Cases_on`t1`>>fs[]) >> fs[] >>
    rw[]>>fs[]>>
    Cases_on`t2=[]`>>fs[]>-(
      Cases_on`op`>>simp[]>-(
        Cases_on`o'`>>simp[]>-(
          Cases_on`o''`>>simp[]>>
          BasicProvers.EVERY_CASE_TAC >>
          simp[Once syneq_exp_cases] >>
          simp[Once syneq_exp_cases] >>
          TRY (
            conj_tac >- (
              match_mp_tac syneq_exp_shift_both >>
              first_assum (match_exists_tac o concl) >> simp[] >>
              fs[SUBSET_DEF] >>
              simp[O_DEF,inv_DEF,PULL_EXISTS] )) >>
          simp[Once syneq_exp_cases] >>
          rpt(simp[Once syneq_exp_cases])) >>
        simp[Once syneq_exp_cases]) >>
      simp[Once syneq_exp_cases]) >>
    `∃h3 t3. t2 = h3::t3` by (Cases_on`t2`>>fs[]) >> fs[]>>
    rw[]>>fs[]>>
    Cases_on`t3=[]`>>fs[]>-(
      Cases_on`op`>>simp[]>-(
        Cases_on`o'`>>simp[]>-(
          Cases_on`o''`>>simp[]>>
          simp[Once syneq_exp_cases] >>
          simp[Once syneq_exp_cases] >>
          conj_tac >- (
            match_mp_tac syneq_exp_shift_both >>
            first_assum (match_exists_tac o concl) >> simp[] >>
            fs[SUBSET_DEF] >>
            simp[O_DEF,inv_DEF,PULL_EXISTS] ) >>
          simp[Once syneq_exp_cases] >>
          conj_tac >- (
            match_mp_tac syneq_exp_shift_both >>
            first_assum (match_exists_tac o concl) >> simp[] >>
            fs[SUBSET_DEF] >>
            simp[O_DEF,inv_DEF,PULL_EXISTS] ) >>
          rpt(simp[Once syneq_exp_cases])) >>
        simp[Once syneq_exp_cases]) >>
      simp[Once syneq_exp_cases]) >>
    `∃h4 t4. t3 = h4::t4` by (Cases_on`t3`>>fs[]) >> fs[]>>
    rw[]>>fs[]>>
    Cases_on`op`>>simp[]>>
    TRY(Cases_on`o'`>>simp[])>>
    TRY(Cases_on`o''`>>simp[])>>
    simp[Once syneq_exp_cases]>>
    simp[EVERY2_MAP] >>
    match_mp_tac EVERY2_MEM_MONO >>
    HINT_EXISTS_TAC >> simp[] >>
    simp[FORALL_PROD] >> rpt gen_tac >>
    strip_tac >>
    first_x_assum match_mp_tac >>
    imp_res_tac LIST_REL_LENGTH >>
    fs[SUBSET_DEF,MEM_FLAT,MEM_MAP,PULL_EXISTS,MEM_ZIP] >>
    metis_tac[MEM_EL]) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >>
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >>
    simp[Once syneq_exp_cases] >>
    match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_mono_V)) >>
    fs[] >>
    qpat_assum`p ⇒ q`mp_tac >>
    discharge_hyps >- (
      ONCE_REWRITE_TAC[CONJ_ASSOC] >>
      conj_tac >- (
        fsrw_tac[ARITH_ss][SUBSET_DEF,PULL_EXISTS] >>
        rw[] >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
      Cases >> Cases >> simp[bind_pat_def,ADD1] >>
      metis_tac[]) >>
    strip_tac >>
    HINT_EXISTS_TAC >> simp[] >>
    Cases >> Cases >> simp[bind_pat_def]) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >>
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    rpt gen_tac >> rpt strip_tac >>
    imp_res_tac EVERY2_LENGTH >>
    qpat_assum`p ⇒ q`mp_tac >>
    discharge_hyps >- (
      fs[SUBSET_DEF,PULL_EXISTS] >>
      conj_tac >- (
        rw[] >>
        reverse(Cases_on`LENGTH es1 ≤ x`) >> simp[] >>
        res_tac >> simp[] ) >>
      conj_tac >- (
        rw[] >>
        reverse(Cases_on`LENGTH es2 ≤ x`) >> simp[] >>
        res_tac >> simp[] ) >>
      simp[bindn_pat_thm] >>
      rpt gen_tac >>
      BasicProvers.CASE_TAC >>
      strip_tac >>
      fsrw_tac[ARITH_ss][] >>
      res_tac >>
      fsrw_tac[ARITH_ss][] ) >>
    strip_tac >>
    simp[Once syneq_exp_cases] >>
    simp[Once syneq_exp_cases] >>
    qexists_tac`λx y. x < LENGTH es1 ∧ x = y` >>
    simp[MAP_MAP_o,EL_MAP] >>
    conj_tac >- (
      simp[syneq_cb_aux_def] >>
      rfs[EVERY2_EVERY,EVERY_MEM] >>
      fs[MEM_ZIP,PULL_EXISTS] >>
      gen_tac >> strip_tac >>
      first_x_assum(fn th => first_assum (mp_tac o MATCH_MP th)) >>
      strip_tac >> pop_assum mp_tac >>
      discharge_hyps >- (
        fs[SUBSET_DEF,PULL_EXISTS,MEM_FLAT,MEM_MAP,ADD1] >>
        conj_tac >- (
          gen_tac >> strip_tac >>
          fsrw_tac[ARITH_ss][AC ADD_ASSOC ADD_COMM] >>
          Cases_on`LENGTH es2 + 1 ≤ x`>>simp[] >>
          metis_tac[MEM_EL] ) >>
        conj_tac >- (
          gen_tac >> strip_tac >>
          fsrw_tac[ARITH_ss][AC ADD_ASSOC ADD_COMM] >>
          Cases_on`LENGTH es2 + 1 ≤ x`>>simp[] >>
          metis_tac[MEM_EL] ) >>
        simp[bindn_pat_thm] >>
        rpt gen_tac >>
        BasicProvers.CASE_TAC >> simp[] >>
        fsrw_tac[ARITH_ss][AC ADD_ASSOC ADD_COMM,NOT_LESS] >>
        strip_tac >> res_tac  >>
        fsrw_tac[ARITH_ss][] ) >>
      strip_tac >>
      match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_mono_V)) >>
      fs[AC ADD_ASSOC ADD_COMM,ADD1] >>
      HINT_EXISTS_TAC >> simp[] >>
      simp[bindn_pat_thm] >>
      simp[syneq_cb_V_def] >>
      rw[] >> simp[]) >>
    match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_mono_V)) >>
    fs[AC ADD_ASSOC ADD_COMM,ADD1] >> rfs[] >>
    HINT_EXISTS_TAC >> simp[] >>
    simp[bindn_pat_thm] >>
    rw[] >> simp[]) >>
  simp[Once syneq_exp_cases] )

val v_pat_syneq = store_thm("v_pat_syneq",
  ``∀v1 v2. v_pat v1 v2 ⇒ closed_pat v1 ∧ closed_pat v2 ⇒ syneq (v_to_Cv v1) (v_to_Cv v2)``,
  ho_match_mp_tac v_pat_ind >> simp[] >>
  strip_tac >- (
    rw[] >>
    simp[Once syneq_cases] >>
    simp[EVERY2_MAP] >>
    match_mp_tac EVERY2_MEM_MONO >>
    HINT_EXISTS_TAC >>
    imp_res_tac EVERY2_LENGTH >>
    simp[UNCURRY,MEM_ZIP,PULL_EXISTS] >>
    rw[] >> first_x_assum match_mp_tac >>
    fs[EVERY_MEM] >> metis_tac[MEM_EL]) >>
  strip_tac >- (
    rw[] >>
    simp[Once syneq_cases] >>
    last_x_assum mp_tac >>
    Q.PAT_ABBREV_TAC`V = env_pat X env1 env2` >>
    strip_tac >>
    qexists_tac`V` >>
    qexists_tac`λx y. x = 0 ∧ y = 0` >>
    simp[Abbr`V`,env_pat_def,EL_MAP] >>
    simp[Once syneq_exp_cases] >>
    simp[syneq_cb_aux_def] >>
    ntac 2 (last_x_assum mp_tac) >>
    simp[Once closed_pat_cases] >>
    simp[Once closed_pat_cases] >>
    ntac 2 strip_tac >>
    conj_tac >- (
      rw[] >>
      first_x_assum match_mp_tac >>
      fs[EVERY_MEM] >>
      metis_tac[MEM_EL] ) >>
    match_mp_tac syneq_exp_shift_both >>
    simp[] >>
    first_assum(mp_tac o MATCH_MP exp_pat_syneq_exp) >>
    discharge_hyps_keep >- (
      simp[ADD1] >>
      Cases >> Cases >> simp[bind_pat_def,ADD1] >>
      simp[env_pat_def] ) >>
    strip_tac >>
    first_assum(match_exists_tac o concl) >>
    simp[] >>
    reverse conj_tac >- (
      fsrw_tac[ARITH_ss][SUBSET_DEF] >>
      rw[] >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    simp[O_DEF,inv_DEF,PULL_EXISTS] >>
    ntac 2 gen_tac >>
    Cases >> Cases >> simp[bind_pat_def,syneq_cb_V_def,ADD1] >>
    simp[env_pat_def] ) >>
  rw[] >>
  simp[Once syneq_cases] >>
  ntac 2 (pop_assum mp_tac) >>
  ntac 2 (simp[Once closed_pat_cases]) >>
  ntac 2 (strip_tac) >>
  last_x_assum mp_tac >>
  Q.PAT_ABBREV_TAC`V = env_pat X env1 env2` >>
  strip_tac >>
  qexists_tac`V` >>
  qexists_tac`λx y. x = y ∧ x < LENGTH funs1 ∧ y < LENGTH funs2` >>
  simp[Abbr`V`,env_pat_def,EL_MAP] >>
  simp[Once syneq_exp_cases,EL_MAP] >>
  simp[syneq_cb_aux_def] >>
  conj_tac >- (
    rw[] >>
    first_x_assum match_mp_tac >>
    fs[EVERY_MEM] >>
    metis_tac[MEM_EL] ) >>
  rw[] >>
  rfs[EVERY2_EVERY,EVERY_MEM] >>
  fs[MEM_ZIP,PULL_EXISTS] >>
  match_mp_tac (MP_CANON exp_pat_syneq_exp) >>
  conj_tac >- (
    match_mp_tac (GEN_ALL (MP_CANON exp_pat_mono)) >>
    ONCE_REWRITE_TAC[CONJ_COMM] >>
    first_x_assum(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    simp[ADD1,AC ADD_COMM ADD_ASSOC] >>
    strip_tac >>
    first_assum(match_exists_tac o concl) >>
    simp[] >>
    simp[bindn_pat_thm,syneq_cb_V_def] >>
    rw[env_pat_def] >> simp[] ) >>
  fs[MEM_EL,PULL_EXISTS] >>
  simp[syneq_cb_V_def] >>
  rw[env_pat_def] >> simp[] )

(* label_closures *)

val label_closures_thm = store_thm("label_closures_thm",
  ``(∀ez j e. (no_labs e) ∧ set (free_vars e) ⊆ count ez ⇒
     let (e',j') = label_closures ez j e in
     (j' = j + (LENGTH (free_labs ez e'))) ∧
     (MAP (FST o FST o SND) (free_labs ez e') = (GENLIST ($+ j) (LENGTH (free_labs ez e')))) ∧
     set (free_vars e') ⊆ set (free_vars e) ∧
     all_labs e' ∧ EVERY good_cd (free_labs ez e') ∧
     syneq_exp ez ez $= e e') ∧
    (∀ez j es.
     (no_labs_list es) ∧ set (free_vars_list es) ⊆ count ez ⇒
     let (es',j') = label_closures_list ez j es in
     (j' = j + LENGTH (free_labs_list ez es')) ∧
     (MAP (FST o FST o SND) (free_labs_list ez es') = (GENLIST ($+ j) (LENGTH (free_labs_list ez es')))) ∧
     set (free_vars_list es') ⊆ set (free_vars_list es) ∧
     all_labs_list es' ∧ EVERY good_cd (free_labs_list ez es') ∧
     EVERY2 (syneq_exp ez ez $=) es es') ∧
    (∀ez j nz k defs ds0 ls0.
     (no_labs_defs (ls0 ++ MAP ($, NONE) defs)) ∧
     set (free_vars_defs nz (MAP ($, NONE) defs)) ⊆ count ez ∧
     (LENGTH ds0 = k) ∧ (LENGTH defs = nz - k) ∧ k ≤ nz ∧ (LENGTH ls0 = k) ∧
     syneq_defs ez ez $= (ls0 ++ MAP ($, NONE) defs) (ds0 ++ MAP ($, NONE) defs) (λv1 v2. v1 < nz ∧ (v2 = v1))
     ⇒
     let (defs',j') = label_closures_defs ez j nz k defs in
     (j' = j + LENGTH (free_labs_defs ez nz k defs')) ∧
     (MAP (FST o FST o SND) (free_labs_defs ez nz k defs') = GENLIST ($+ j) (LENGTH (free_labs_defs ez nz k defs'))) ∧
     set (free_vars_defs nz defs') ⊆ set (free_vars_defs nz (MAP ($, NONE) defs)) ∧
     (LENGTH defs' = LENGTH defs) ∧
     all_labs_defs defs' ∧
     EVERY good_cd (free_labs_defs ez nz k defs') ∧
     syneq_defs ez ez $= (ls0 ++ (MAP ($, NONE) defs)) (ds0 ++ defs') (λv1 v2. v1 < nz ∧ (v2 = v1)))``,
  ho_match_mp_tac label_closures_ind >>
  strip_tac >- (
    rpt gen_tac >> strip_tac >> strip_tac >>
    fs[LET_THM,UNCURRY] >>
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    ntac 2 gen_tac >>
    map_every qx_gen_tac[`e1`,`e2`] >>
    rpt strip_tac >> fs[] >>
    `set (free_vars e2) ⊆ count (ez + 1)` by (
      fsrw_tac[DNF_ss,ARITH_ss][SUBSET_DEF,PRE_SUB1] >>
      Cases>>fsrw_tac[ARITH_ss][] ) >> fs[] >>
    qabbrev_tac`p = label_closures ez j e1` >> PairCases_on`p`>>fs[LET_THM] >>
    qabbrev_tac`q = label_closures (ez+1) (j + LENGTH (free_labs ez p0)) e2` >> PairCases_on`q`>>fs[] >>
    simp[LIST_EQ_REWRITE] >>
    conj_tac >- (
      gen_tac >>
      Cases_on`x<LENGTH (free_labs ez p0)`>>
      lrw[EL_APPEND1,EL_APPEND2] ) >>
    rfs[] >>
    conj_tac >- (
      fsrw_tac[DNF_ss,ARITH_ss][SUBSET_DEF,PRE_SUB1] >>
      Cases >> rw[ADD1] >>
      res_tac >>
      disj2_tac >> HINT_EXISTS_TAC >>
      fsrw_tac[ARITH_ss][] ) >>
    simp[Once syneq_exp_cases] >>
    match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_mono_V)) >>
    HINT_EXISTS_TAC >>
    simp[]) >>
  strip_tac >- (rw[] >> rw[syneq_exp_refl]) >>
  strip_tac >- (rw[] >> rw[syneq_exp_refl]) >>
  strip_tac >- (
    rpt gen_tac >> strip_tac >>
    fs[LET_THM,UNCURRY] >>
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    rw[] >> fs[LET_THM] >>
    rw[Once syneq_exp_cases] >> rfs[]) >>
  strip_tac >- (
    Cases_on`bd` >- (
      ntac 2 gen_tac >>
      map_every qx_gen_tac[`e1`,`e2`] >>
      rpt strip_tac >> fs[] >>
      `set (free_vars e2) ⊆ count (ez + 1)` by (
        fsrw_tac[DNF_ss,ARITH_ss][SUBSET_DEF,PRE_SUB1] >>
        Cases>>fsrw_tac[ARITH_ss][] ) >> fs[] >>
      qabbrev_tac`p = label_closures ez j e1` >> PairCases_on`p`>>fs[LET_THM] >>
      qabbrev_tac`q = label_closures (ez+1) (j + LENGTH (free_labs ez p0)) e2` >> PairCases_on`q`>>fs[] >>
      simp[LIST_EQ_REWRITE] >>
      conj_tac >- (
        gen_tac >>
        Cases_on`x<LENGTH (free_labs ez p0)`>>
        lrw[EL_APPEND1,EL_APPEND2] ) >>
      rfs[] >>
      conj_tac >- (
        fsrw_tac[DNF_ss,ARITH_ss][SUBSET_DEF,PRE_SUB1] >>
        Cases >> rw[ADD1] >>
        res_tac >>
        disj2_tac >> HINT_EXISTS_TAC >>
        fsrw_tac[ARITH_ss][] ) >>
      simp[Once syneq_exp_cases] >>
      match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_mono_V)) >>
      HINT_EXISTS_TAC >>
      simp[]) >>
    simp[] >>
    ntac 2 gen_tac >>
    map_every qx_gen_tac[`e1`,`e2`] >>
    rpt strip_tac >> fs[] >>
    simp[Once syneq_exp_cases] >>
    qabbrev_tac`p = label_closures ez j e1` >>
    PairCases_on`p`>>fs[LET_THM] >>
    qabbrev_tac`q = label_closures ez (j + LENGTH (free_labs ez p0)) e2` >>
    PairCases_on`q`>>fs[LET_THM] >>
    simp[LIST_EQ_REWRITE] >>
    conj_tac >- (
      gen_tac >>
      Cases_on`x<LENGTH (free_labs ez p0)`>>
      lrw[EL_APPEND1,EL_APPEND2] ) >>
    rfs[] >>
    fsrw_tac[DNF_ss,ARITH_ss][SUBSET_DEF,PRE_SUB1] ) >>
  strip_tac >- (
    rpt strip_tac >>
    simp[] >>
    `FILTER (IS_NONE o FST) defs = defs` by (
      simp[FILTER_EQ_ID] >>
      fs[FLAT_EQ_NIL,EVERY_MAP] >>
      fs[EVERY_MEM,FORALL_PROD] >>
      qx_gen_tac`z` >> rpt strip_tac >>
      res_tac >> Cases_on`z`>>fs[] ) >>
    full_simp_tac std_ss [LET_THM] >>
    full_simp_tac std_ss [FILTER_EQ_ID,LENGTH_MAP] >>
    qabbrev_tac`p = label_closures_defs ez j (LENGTH defs) 0 (MAP SND defs)` >>
    PairCases_on`p`>>
    `no_labs e`by fs[] >>
    `set (free_vars e) ⊆ count (ez + LENGTH defs)` by (
      qpat_assum`set (free_vars X) ⊆ Y`mp_tac >>
      rpt (pop_assum kall_tac) >>
      fsrw_tac[DNF_ss,ARITH_ss][SUBSET_DEF,LET_THM] >>
      srw_tac[ARITH_ss][ADD1] >>
      res_tac >> fsrw_tac[ARITH_ss][] ) >>
    full_simp_tac std_ss [] >>
    qabbrev_tac`q = label_closures (ez + LENGTH defs) p1 e` >>
    PairCases_on`q` >>
    full_simp_tac std_ss [] >>
    `MAP ($, NONE) (MAP SND defs) = defs` by (
      fs[EVERY_MEM] >>
      lrw[MAP_MAP_o] >>
      CONV_TAC(RAND_CONV(REWRITE_CONV[Once (CONJUNCT2 (GSYM MAP_ID)),SimpRHS])) >>
      lrw[MAP_EQ_f,FORALL_PROD] >> res_tac >> fs[]) >>
    full_simp_tac std_ss [] >>
    first_x_assum(qspecl_then[`[]`,`[]`]mp_tac) >>
    simp[syneq_defs_refl,EVERY_MAP] >>
    fs[LET_THM] >>
    strip_tac >>
    fsrw_tac[ETA_ss][] >>
    rfs[] >> simp[] >>
    conj_tac >- (
      lrw[LIST_EQ_REWRITE] >>
      Cases_on`x < LENGTH (free_labs_defs ez (LENGTH defs) 0 p0)` >>
      lrw[EL_APPEND1,EL_APPEND2] ) >>
    conj_tac >- (
      fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP,free_vars_defs_MAP] >>
      gen_tac >> strip_tac >>
      disj2_tac >>
      qexists_tac`m` >>
      simp[] ) >>
    simp[Once syneq_exp_cases] >>
    HINT_EXISTS_TAC >> simp[] >>
    match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_mono_V)) >>
    HINT_EXISTS_TAC >>
    simp[]) >>
  strip_tac >- (
    ntac 3 gen_tac >>
    map_every qx_gen_tac[`e`,`es`] >>
    rpt strip_tac >>
    qabbrev_tac`p = label_closures ez j e` >> PairCases_on`p`>>fs[LET_THM] >>
    qabbrev_tac`q = label_closures_list ez (j + LENGTH (free_labs ez p0)) es` >> PairCases_on`q`>>fs[] >>
    fs[] >>
    simp[LIST_EQ_REWRITE] >>
    conj_tac >- (
      gen_tac >>
      Cases_on`x<LENGTH (free_labs ez p0)`>>
      lrw[EL_APPEND1,EL_APPEND2] ) >>
    rfs[] >>
    conj_tac >- (
      fsrw_tac[DNF_ss][SUBSET_DEF] ) >>
    simp[Once syneq_exp_cases]) >>
  strip_tac >- (
    rw[] >> fs[LET_THM] >> rfs[] >>
    simp[Once syneq_exp_cases] ) >>
  strip_tac >- (
    ntac 2 gen_tac >>
    map_every qx_gen_tac[`p2`,`e1`,`e2`] >>
    rpt strip_tac >> fs[] >>
    qabbrev_tac`p = label_closures ez j e1` >> PairCases_on`p`>>fs[LET_THM] >>
    qabbrev_tac`q = label_closures ez (j + LENGTH (free_labs ez p0)) e2` >> PairCases_on`q`>>fs[] >>
    simp[LIST_EQ_REWRITE] >>
    conj_tac >- (
      gen_tac >> strip_tac >>
      Cases_on`x < LENGTH (free_labs ez p0)`>>
      lrw[EL_APPEND1,EL_APPEND2]) >>
    conj_tac >- (
      rfs[] >>
      fsrw_tac[DNF_ss][SUBSET_DEF] ) >>
    simp[Once syneq_exp_cases]) >>
  strip_tac >- (
    ntac 2 gen_tac >>
    map_every qx_gen_tac[`b`,`e1`,`e2`,`e3`] >>
    rpt strip_tac >> fs[] >>
    qabbrev_tac`p = label_closures ez j e1` >> PairCases_on`p`>>fs[LET_THM] >>
    qabbrev_tac`q = label_closures ez (j + LENGTH (free_labs ez p0)) e2` >> PairCases_on`q`>>fs[] >>
    qabbrev_tac`r = label_closures ez (j + LENGTH (free_labs ez p0) + LENGTH (free_labs ez q0)) e3` >> PairCases_on`r`>>fs[] >>
    simp[LIST_EQ_REWRITE] >>
    conj_tac >- (
      gen_tac >> strip_tac >>
      Cases_on`x < LENGTH (free_labs ez p0)`>>
      lrw[EL_APPEND1,EL_APPEND2] >>
      Cases_on`x < LENGTH (free_labs ez p0) + LENGTH (free_labs ez q0)` >>
      lrw[EL_APPEND1,EL_APPEND2] ) >>
    conj_tac >- (
      rfs[] >>
      fsrw_tac[DNF_ss][SUBSET_DEF] ) >>
    simp[Once syneq_exp_cases]) >>
  strip_tac >- (
    ntac 2 gen_tac >>
    map_every qx_gen_tac[`e1`,`e2`,`e3`] >>
    rpt strip_tac >> fs[] >>
    qabbrev_tac`p = label_closures ez j e1` >> PairCases_on`p`>>fs[LET_THM] >>
    qabbrev_tac`q = label_closures ez (j + LENGTH (free_labs ez p0)) e2` >> PairCases_on`q`>>fs[] >>
    qabbrev_tac`r = label_closures ez (j + LENGTH (free_labs ez p0) + LENGTH (free_labs ez q0)) e3` >> PairCases_on`r`>>fs[] >>
    simp[LIST_EQ_REWRITE] >>
    conj_tac >- (
      gen_tac >> strip_tac >>
      Cases_on`x < LENGTH (free_labs ez p0)`>>
      lrw[EL_APPEND1,EL_APPEND2] >>
      Cases_on`x < LENGTH (free_labs ez p0) + LENGTH (free_labs ez q0)` >>
      lrw[EL_APPEND1,EL_APPEND2] ) >>
    conj_tac >- (
      rfs[] >>
      fsrw_tac[DNF_ss,ARITH_ss][SUBSET_DEF,MEM_GENLIST] ) >>
    simp[Once syneq_exp_cases]) >>
  strip_tac >- (
    simp[] >> simp[Once syneq_exp_cases] ) >>
  strip_tac >- simp[] >>
  strip_tac >- (
    rpt strip_tac >>
    fs[] >>
    qabbrev_tac`p = label_closures ez j e` >>
    PairCases_on`p`>>fs[LET_THM] >>
    qabbrev_tac`q = label_closures_list ez (j + LENGTH (free_labs ez p0)) es` >>
    PairCases_on`q`>>fs[] >> simp[] >> rfs[] >>
    conj_tac >- (
      lrw[LIST_EQ_REWRITE] >>
      Cases_on`x < LENGTH (free_labs ez p0)`>>
      lrw[EL_APPEND1,EL_APPEND2] ) >>
    conj_tac >- (
      fsrw_tac[DNF_ss][SUBSET_DEF] ) >>
    fsrw_tac[DNF_ss][SUBSET_DEF] ) >>
  strip_tac >- (
    simp[] >> rw[FUNION_FEMPTY_2] >>
    fs[LENGTH_NIL]) >>
  rpt gen_tac >> rpt strip_tac >>
  full_simp_tac (std_ss++ARITH_ss) [] >>
  last_x_assum mp_tac >>
  last_x_assum mp_tac >>
  simp[] >> ntac 2 strip_tac >>
  Q.PAT_ABBREV_TAC`r = bind_fv X Y Z` >>
  PairCases_on`r`>>fs[] >>
  Q.PAT_ABBREV_TAC`ezz:num = az + (X + (Y + 1))` >>
  qabbrev_tac`p = label_closures ezz (j+1) r3` >>
  PairCases_on`p` >> full_simp_tac std_ss [] >>
  qabbrev_tac`q = label_closures_defs ez p1 nz (k+1) defs` >>
  PairCases_on`q` >> full_simp_tac std_ss [] >>
  `no_labs r3` by (
    fs[bind_fv_def,LET_THM,markerTheory.Abbrev_def] ) >>
  `set (free_vars r3) ⊆ count ezz` by (
    fs[bind_fv_def,LET_THM,markerTheory.Abbrev_def] >>
    first_x_assum(qspec_then`[]`kall_tac) >>
    qpat_assum`P⇒Q`kall_tac >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    srw_tac[ARITH_ss][] >- (
      qho_match_abbrev_tac`(the n (find_index x ls n)) < y` >>
      qho_match_abbrev_tac`P (the n (find_index x ls n))` >>
      ho_match_mp_tac the_find_index_suff >>
      simp[Abbr`P`,Abbr`x`,Abbr`ls`,MEM_FILTER,ADD1,MEM_GENLIST,Abbr`n`,Abbr`y`] >>
      rw[] >>
      qmatch_abbrev_tac`m < A + B` >>
      Cases_on`m=A`>>fsrw_tac[ARITH_ss][]>>
      Cases_on`B=0`>>fsrw_tac[ARITH_ss][]>>
      fs[LENGTH_NIL_SYM,FILTER_EQ_NIL,EVERY_MEM,QSORT_MEM,markerTheory.Abbrev_def] >>
      res_tac >> fsrw_tac[ARITH_ss][]) >>
    qho_match_abbrev_tac`(the 0 (find_index x ls n)) < y` >>
    qho_match_abbrev_tac`P (the 0 (find_index x ls n))` >>
    ho_match_mp_tac the_find_index_suff >>
    `n ≤ nz` by (
      unabbrev_all_tac >>
      simp[GSYM ADD1] >>
      simp[GSYM LESS_EQ] >>
      qmatch_abbrev_tac`LENGTH (FILTER P ls) < nz` >>
      `nz = LENGTH ls` by rw[Abbr`ls`] >> pop_assum SUBST1_TAC >>
      match_mp_tac LENGTH_FILTER_LESS >>
      simp[Abbr`P`,Abbr`ls`,EXISTS_MEM,MEM_GENLIST] >>
      qexists_tac`LENGTH ls0` >>
      simp[] ) >>
    reverse conj_tac >- (
      unabbrev_all_tac >>
      simp[MEM_MAP,MEM_FILTER,sortingTheory.QSORT_MEM] >>
      qexists_tac`v` >> simp[] ) >>
    simp[Abbr`P`,Abbr`y`] >>
    qx_gen_tac`m`>>strip_tac >>
    qmatch_abbrev_tac`m + n < l1 + l2` >>
    `l2 = LENGTH ls + 1` by rw[Abbr`l2`,Abbr`ls`] >> rw[] >>
    qsuff_tac`n ≤ l1 + 1` >- DECIDE_TAC >>
    simp[Abbr`n`]) >>
  full_simp_tac std_ss [LET_THM] >>
  Q.PAT_ABBREV_TAC`cd:def = (SOME X,az,p0)` >>
  last_x_assum(qspecl_then[`ds0++[cd]`,`ls0++[(NONE,az,b)]`]mp_tac) >>
  discharge_hyps >- (
    simp[] >>
    rator_x_assum`syneq_defs`mp_tac >>
    simp[Once syneq_exp_cases] >>
    simp[EVERY_MAP] >> strip_tac >>
    simp[Once syneq_exp_cases,EVERY_MAP] >>
    qx_gen_tac`v` >> strip_tac >>
    first_x_assum(qspec_then`v`mp_tac) >> simp[] >>
    REWRITE_TAC[GSYM APPEND_ASSOC] >>
    Cases_on`v < k`>>simp[EL_APPEND1,EL_APPEND2,ADD1,EL_MAP] >- (
      strip_tac >>
      ntac 2 (first_x_assum (mp_tac o SYM)) >>
      ntac 2 strip_tac >>
      fsrw_tac[ARITH_ss][ADD1] ) >>
    Cases_on`v=k` >- (
      simp[Abbr`cd`] >> strip_tac >>
      simp[syneq_cb_aux_def] >>
      fsrw_tac[ARITH_ss][ADD1] >>
      simp[syneq_cb_aux_def] >>
      conj_asm1_tac >- (
        fs[bind_fv_def,LET_THM,markerTheory.Abbrev_def] >>
        simp[EVERY_MEM,MEM_MAP,MEM_FILTER,QSORT_MEM,MEM_FILTER,MEM_GENLIST] >>
        simp[GSYM LEFT_FORALL_IMP_THM] >>
        qpat_assum`Y ⊆ count ez` mp_tac >>
        qpat_assum`Y ⊆ count ez` mp_tac >>
        simp[SUBSET_DEF,GSYM LEFT_FORALL_IMP_THM] >>
        srw_tac[DNF_ss,ARITH_ss][NOT_LESS] >>
        metis_tac[] ) >>
      qmatch_abbrev_tac`syneq_exp z1 ezz V b p0` >>
      qsuff_tac`syneq_exp z1 ezz V b r3` >- (
        strip_tac >>
        `V = $= O V` by metis_tac[Id_O] >> pop_assum SUBST1_TAC >>
        match_mp_tac (MP_CANON (CONJUNCT1 syneq_exp_trans)) >>
        PROVE_TAC[] ) >>
      qpat_assum`Abbrev(X = bind_fv A Y Z)`mp_tac >>
      simp[bind_fv_def,markerTheory.Abbrev_def] >> rw[] >>
      match_mp_tac mkshift_thm >>
      simp[Abbr`z1`,Abbr`ezz`] >>
      conj_tac >- simp[Abbr`V`,syneq_cb_V_def] >>
      reverse conj_tac >- (
        qpat_assum`Y ⊆ count ez`mp_tac >>
        qpat_assum`Y ⊆ count ez`mp_tac >>
        simp[SUBSET_DEF,GSYM LEFT_FORALL_IMP_THM] >>
        srw_tac[DNF_ss,ARITH_ss][NOT_LESS] >>
        Cases_on`az + nz ≤ x`>>simp[]) >>
      gen_tac >> strip_tac >>
      reverse conj_tac >- (
        rw[] >- (
          qho_match_abbrev_tac`the 0 (find_index a w c) < X` >>
          qunabbrev_tac`X` >>
          qho_match_abbrev_tac`P (the c (find_index a w c))` >>
          match_mp_tac the_find_index_suff >>
          reverse conj_tac >- (
            unabbrev_all_tac >>
            fs[SUBSET_DEF] >>
            simp[MEM_FILTER,MEM_GENLIST] ) >>
          simp[Abbr`w`,Abbr`c`,Abbr`P`]) >>
        qho_match_abbrev_tac`the 0 (find_index a w c) < X` >>
        qunabbrev_tac`X` >>
        qho_match_abbrev_tac`P (the 0 (find_index a w c))` >>
        match_mp_tac the_find_index_suff >>
        reverse conj_tac >- (
          unabbrev_all_tac >>
          simp[MEM_MAP,MEM_FILTER,QSORT_MEM] >>
          qexists_tac`x`>>simp[]) >>
        simp[Abbr`w`,Abbr`c`,Abbr`P`]) >>
      Q.PAT_ABBREV_TAC`envs:num list = MAP X (FILTER Y Z)` >>
      `¬(x < az + nz) ⇒ MEM (x-(az+nz)) envs` by (
        simp[Abbr`envs`,MEM_MAP,MEM_FILTER,QSORT_MEM] >>
        strip_tac >>
        qexists_tac`x` >> simp[] ) >>
      Q.PAT_ABBREV_TAC`recs = LENGTH ls0::X` >>
      `x < az + nz ⇒ MEM (x - az) recs` by (
        simp[Abbr`recs`,MEM_FILTER,MEM_GENLIST] ) >>
      simp[Abbr`V`] >>
      reverse(rw[]) >- (
        fs[] >>
        simp[syneq_cb_V_def] >>
        Q.PAT_ABBREV_TAC`rz = LENGTH (FILTER X Y) + 1` >>
        Q.ISPECL_THEN[`envs`,`x-(az+nz)`,`rz`]mp_tac find_index_MEM >>
        simp[] >> disch_then strip_assume_tac >> simp[] >>
        simp[Abbr`rz`] ) >>
      simp[syneq_cb_V_def] >> fs[] >>
      Q.ISPECL_THEN[`recs`,`x-az`,`0:num`]mp_tac find_index_MEM >>
      simp[] >> disch_then strip_assume_tac >> simp[] >>
      Cases_on`i=0` >- (
        simp[] >> fs[Abbr`recs`]) >>
      simp[] >>
      qpat_assum`EL X Y = x - def0`mp_tac >>
      simp[Abbr`recs`,EL_CONS,PRE_SUB1] >>
      fsrw_tac[ARITH_ss][]) >>
    lrw[EL_CONS] >>
    ntac 2 (qpat_assum`X = Y`(mp_tac o SYM)) >>
    simp[PRE_SUB1,EL_MAP] >>
    Q.PAT_ABBREV_TAC`p = EL X defs` >>
    PairCases_on`p` >>
    simp[syneq_cb_aux_def] >>
    ntac 2 strip_tac >>
    fsrw_tac[ARITH_ss][] >> rw[] >> fs[] >>
    fsrw_tac[ARITH_ss][ADD1] >>
    `LENGTH defs + (LENGTH ls0 + 1) = nz` by simp[] >>
    pop_assum SUBST1_TAC >>
    match_mp_tac (MP_CANON(CONJUNCT1 syneq_exp_mono_V)) >>
    HINT_EXISTS_TAC >>
    simp[]) >>
  simp[] >> strip_tac >>
  simp[Abbr`cd`,ADD1]>>
  conj_tac >- (
    fsrw_tac[ARITH_ss][] >>
    lrw[LIST_EQ_REWRITE,EL_CONS,ADD1] >>
    Cases_on`x=0` >> lrw[EL_CONS,PRE_SUB1] >>
    Cases_on`x < LENGTH (free_labs ezz p0)` >>
    lrw[EL_APPEND1,EL_APPEND2] >>
    Cases_on `x-1 < LENGTH (free_labs ezz p0)` >>
    lrw[EL_APPEND1,EL_APPEND2]) >>
  conj_tac >- (
    rev_full_simp_tac std_ss [] >>
    fsrw_tac[DNF_ss][SUBSET_DEF] ) >>
  reverse conj_tac >- (
    metis_tac[CONS_APPEND,APPEND_ASSOC] ) >>
  simp[good_cd_def] >>
  conj_tac >- (
    fs[bind_fv_def,LET_THM,markerTheory.Abbrev_def] >>
    simp[EVERY_MAP,EVERY_FILTER] >>
    simp[EVERY_MEM,QSORT_MEM] >>
    qpat_assum`Y ⊆ count ez` mp_tac >>
    qpat_assum`Y ⊆ count ez` mp_tac >>
    srw_tac[DNF_ss][SUBSET_DEF] >>
    res_tac >> fsrw_tac[ARITH_ss][] ) >>
  conj_tac >- (
    fs[bind_fv_def,LET_THM,markerTheory.Abbrev_def] >>
    qpat_assum`set (free_vars p0) ⊆ X`mp_tac >>
    simp[SUBSET_DEF] >> strip_tac >>
    gen_tac >> strip_tac >>
    first_x_assum(qspec_then`x`mp_tac) >>
    simp[] >> strip_tac >>
    Cases_on`v<az`>>fsrw_tac[ARITH_ss][]>>
    Cases_on`v<az+nz`>>fsrw_tac[ARITH_ss][]>- (
      qho_match_abbrev_tac`the 0 (find_index a ls n) < X` >>
      qho_match_abbrev_tac`P (the n (find_index a ls n))` >>
      match_mp_tac the_find_index_suff >>
      simp[Abbr`ls`,Abbr`P`,Abbr`X`,MEM_FILTER,MEM_GENLIST,Abbr`n`,Abbr`a`,MEM_MAP,QSORT_MEM] ) >>
    rw[] >>
    qho_match_abbrev_tac`the 0 (find_index a ls n) < X` >>
    qho_match_abbrev_tac`P (the 0 (find_index a ls n))` >>
    match_mp_tac the_find_index_suff >>
    simp[Abbr`ls`,Abbr`P`,Abbr`X`,MEM_FILTER,MEM_GENLIST,Abbr`n`,Abbr`a`,MEM_MAP,QSORT_MEM] >>
    HINT_EXISTS_TAC >> simp[] ) >>
  map_every qexists_tac[`b`,`r3`] >>
  simp[])

(* compile_code_env *)

val FOLDL_cce_aux_thm = store_thm("FOLDL_cce_aux_thm",
  ``∀c s. let s' = FOLDL cce_aux s c in
     ALL_DISTINCT (MAP (FST o FST) c) ∧
     EVERY (combin$C $< s.next_label) (MAP (FST o FST) c)
      ⇒
     ∃code.
     (s'.out = REVERSE code ++ s.out) ∧
     (s.next_label ≤ s'.next_label) ∧
     ALL_DISTINCT (FILTER is_Label code) ∧
     EVERY (λn. MEM n (MAP (FST o FST) c) ∨ between s.next_label s'.next_label n)
       (MAP dest_Label (FILTER is_Label code)) ∧
     (EVERY all_labs (MAP (SND o SND) c) ⇒ ∀l. uses_label code l ⇒
       MEM (Label l) code ∨ MEM l (MAP (FST o FST o SND) (FLAT (MAP (λ(p,p3,p4). free_labs (LENGTH (FST(SND p))) p4) c)))) ∧
     (∀l. MEM l (MAP (FST o FST) c) ⇒ MEM (Label l) code) ∧
     ∃cs.
     ∀i. i < LENGTH c ⇒ let ((l,ccenv,ce),(az,body)) = EL i c in
         s.next_label ≤ (cs i).next_label ∧
         (∀j. j < i ⇒ (cs j).next_label ≤ (cs i).next_label) ∧
         ∃cc. ((compile (MAP CTEnv ccenv) (TCTail az 0) 0 (cs i) body).out = cc ++ (cs i).out) ∧
              l < (cs i).next_label ∧
              ∃bc0 bc1. (code = bc0 ++ Label l::REVERSE cc ++ bc1) ∧
                        EVERY (combin$C $< (cs i).next_label o dest_Label)
                          (FILTER is_Label bc0)``,
   Induct >- ( simp[Once SWAP_REVERSE] ) >>
   simp[] >>
   qx_gen_tac`p`>> PairCases_on`p` >>
   rpt gen_tac >>
   simp[cce_aux_def] >>
   strip_tac >>
   Q.PAT_ABBREV_TAC`s0 = s with out := X::y` >>
   qspecl_then[`MAP CTEnv p1`,`TCTail p3 0`,`0`,`s0`,`p4`]
     strip_assume_tac(CONJUNCT1 compile_append_out) >>
   Q.PAT_ABBREV_TAC`s1 = compile X Y Z A B` >>
   first_x_assum(qspecl_then[`s1`]mp_tac) >>
   simp[] >>
   discharge_hyps >- (
     fsrw_tac[ARITH_ss][EVERY_MEM,Abbr`s0`] >>
     rw[] >> res_tac >> DECIDE_TAC ) >>
   disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
   simp[Abbr`s0`] >>
   simp[Once SWAP_REVERSE] >>
   fs[] >> simp[] >>
   simp[FILTER_APPEND,FILTER_REVERSE,MEM_FILTER,ALL_DISTINCT_REVERSE,ALL_DISTINCT_APPEND] >>
   conj_tac >- (
     rfs[FILTER_APPEND] >>
     fs[EVERY_MAP,EVERY_FILTER,EVERY_REVERSE,between_def] >>
     fsrw_tac[DNF_ss,ARITH_ss][EVERY_MEM,MEM_MAP] >>
     rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][]
       >- metis_tac[] >>
     res_tac >> fsrw_tac[ARITH_ss][] ) >>
   conj_tac >- (
     fs[EVERY_MAP,EVERY_REVERSE,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM] >>
     fsrw_tac[DNF_ss][EVERY_MEM,between_def] >>
     rw[] >> spose_not_then strip_assume_tac >> res_tac >>
     fsrw_tac[ARITH_ss][] ) >>
   conj_tac >- (
     rw[] >>
     Cases_on`l=p0`>>rw[]>>
     Cases_on`MEM (Label l)c0`>>rw[]>>
     Cases_on`MEM (Label l)bc`>>rw[]>>
     fs[uses_label_thm,EXISTS_REVERSE] >>
     metis_tac[] ) >>
   conj_tac >- metis_tac[] >>
   qexists_tac`λi. if i = 0 then (s with out := Label p0::s.out) else cs (i-1)` >>
   Cases >> simp[] >- (
     map_every qexists_tac[`[]`,`c0`] >> simp[] ) >>
   strip_tac >>
   first_x_assum(qspec_then`n`mp_tac) >>
   simp[UNCURRY] >> strip_tac >>
   simp[] >>
   conj_asm1_tac >- ( Cases >> simp[] ) >>
   qexists_tac`Label p0::(REVERSE bc ++ bc0)` >>
   simp[FILTER_APPEND,FILTER_REVERSE,EVERY_REVERSE,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM] >>
   qpat_assum`EVERY X (FILTER is_Label bc0)`mp_tac >>
   qpat_assum`EVERY X (MAP Y (FILTER is_Label bc))`mp_tac >>
   simp[EVERY_FILTER,EVERY_MAP,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM,between_def] >>
   asm_simp_tac(srw_ss()++ARITH_ss++DNF_ss)[EVERY_MEM] >>
   rw[] >> res_tac >> DECIDE_TAC)

val compile_code_env_thm = store_thm("compile_code_env_thm",
  ``∀ez s e. let s' = compile_code_env s e in
      ALL_DISTINCT (MAP (FST o FST o SND) (free_labs ez e)) ∧
      EVERY (combin$C $< s.next_label) (MAP (FST o FST o SND) (free_labs ez e)) ∧
      EVERY good_cd (free_labs ez e)
      ⇒
      ∃code.
      (s'.out = REVERSE code ++ s.out) ∧
      (s.next_label < s'.next_label) ∧
      ALL_DISTINCT (FILTER is_Label code) ∧
      EVERY (λn. MEM n (MAP (FST o FST o SND) (free_labs ez e)) ∨ between s.next_label s'.next_label n)
        (MAP dest_Label (FILTER is_Label code)) ∧
      (EVERY all_labs (MAP (SND o SND o SND) (free_labs ez e)) ⇒
       ∀l. uses_label code l ⇒ MEM (Label l) code ∨
         MEM l (MAP (FST o FST o SND)
           (FLAT (MAP (λ(p,p3,p4). free_labs (LENGTH (FST (SND p))) p4) (MAP SND (free_labs ez e)))))) ∧
      (∀l. MEM l (MAP (FST o FST o SND) (free_labs ez e)) ⇒ MEM (Label l) code) ∧
      ∀bs bc0 bc1.
        (bs.code = bc0 ++ code ++ bc1) ∧
        (bs.pc = next_addr bs.inst_length bc0) ∧
        ALL_DISTINCT (FILTER is_Label bc0) ∧
        (∀l1 l2. MEM l1 (MAP dest_Label (FILTER is_Label bc0)) ∧ ((l2 = s.next_label) ∨ MEM l2 (MAP (FST o FST o SND) (free_labs ez e))) ⇒ l1 < l2)
        ⇒
        EVERY (code_env_cd (bc0++code)) (free_labs ez e) ∧
        bc_next bs (bs with pc := next_addr bs.inst_length (bc0++code))``,
  rw[compile_code_env_def] >> rw[] >>
  `MAP SND (free_labs 0 e) = MAP SND (free_labs ez e)` by metis_tac[MAP_SND_free_labs_any_ez] >>
  fs[] >>
  Q.ISPECL_THEN[`MAP SND (free_labs ez e)`,`s''`]mp_tac FOLDL_cce_aux_thm >>
  simp[Abbr`s''`] >>
  discharge_hyps >- (
    fsrw_tac[ARITH_ss][EVERY_MEM,MAP_MAP_o] >>
    rw[] >> res_tac >> DECIDE_TAC ) >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  simp[Once SWAP_REVERSE,Abbr`s''''`] >>
  conj_tac >- (
    simp[ALL_DISTINCT_APPEND,FILTER_APPEND,MEM_FILTER] >>
    fs[EVERY_MAP,EVERY_FILTER] >> fs[EVERY_MEM] >>
    spose_not_then strip_assume_tac >> res_tac >>
    fsrw_tac[ARITH_ss][between_def,MEM_MAP,MAP_MAP_o] >>
    res_tac >> rw[] >> DECIDE_TAC ) >>
  conj_tac >- (
    fs[EVERY_MAP,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM,between_def] >>
    reverse conj_tac >- (disj2_tac >> DECIDE_TAC) >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_MAP,FORALL_PROD,EXISTS_PROD] >>
    rw[] >> res_tac >>
    TRY(metis_tac[]) >>
    disj2_tac >> DECIDE_TAC ) >>
  conj_tac >- (
    rw[] >>
    fs[MAP_MAP_o] >>
    fs[uses_label_thm] >>
    metis_tac[] ) >>
  conj_tac >- fs[MAP_MAP_o] >>
  rpt gen_tac >>
  strip_tac >>
  conj_tac >- (
    fs[EVERY_MEM] >>
    qx_gen_tac`z` >>
    PairCases_on`z` >> strip_tac >>
    simp[code_env_cd_def] >>
    qmatch_assum_abbrev_tac`MEM cd (free_labs ez e)` >>
    `∃i. i < LENGTH (free_labs ez e) ∧ (EL i (free_labs ez e) = cd)` by metis_tac[MEM_EL] >>
    qpat_assum`∀i. P ⇒ Q`(qspec_then`i`mp_tac) >>
    simp[EL_MAP] >>
    simp[Abbr`cd`] >> strip_tac >>
    qexists_tac`cs i`>>simp[] >>
    qexists_tac`bc0++Jump (Lab s.next_label)::bc0'` >>
    simp[] >>
    fs[EVERY_MEM,MEM_MAP,FILTER_APPEND] >>
    fsrw_tac[DNF_ss][] >- (
      rpt strip_tac >> res_tac >> DECIDE_TAC) >>
    rpt strip_tac >> res_tac >> DECIDE_TAC) >>
  `bc_fetch bs = SOME (Jump (Lab s.next_label))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0` >> simp[] ) >>
  simp[bc_eval1_thm,bc_eval1_def,bc_state_component_equality,bc_find_loc_def] >>
  match_mp_tac bc_find_loc_aux_append_code >>
  match_mp_tac bc_find_loc_aux_ALL_DISTINCT >>
  qexists_tac`LENGTH bc0 + 1 + LENGTH c0` >>
  simp[EL_APPEND2,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER] >>
  fs[EVERY_MAP,EVERY_FILTER,between_def] >>
  fsrw_tac[DNF_ss][EVERY_MEM,is_Label_rwt,MEM_MAP,EXISTS_PROD,FORALL_PROD,MEM_FILTER] >>
  rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] >>
  res_tac >> fsrw_tac[ARITH_ss][])

(* compile_Cexp *)

val compile_Cexp_thm = store_thm("compile_Cexp_thm",
  ``∀renv rsz cs exp.
      set (free_vars exp) ⊆ count (LENGTH renv)
    ∧ no_labs exp
    ⇒
    let cs' = compile_Cexp renv rsz cs exp in
    ∃c0 code. cs'.out = REVERSE code ++ REVERSE c0 ++ cs.out ∧ between_labels (code++c0) cs.next_label cs'.next_label ∧
    code_labels_ok (c0++code) ∧
    ∀s env res rd csz bs bc0 bc00.
      Cevaluate s env exp res
    ∧ closed_vlabs env s bc0
    ∧ Cenv_bs rd s env renv rsz (bs with code := bc00)
    ∧ (bc00 = bc0 ∨ bc00 = bc0 ++ c0)
    ∧ bs.code = bc0 ++ c0 ++ code
    ∧ bs.pc = next_addr bs.inst_length bc0
    ∧ bs.clock = SOME (FST (FST s))
    ∧ good_labels cs.next_label bc0
    ⇒
    case SND res of
    | Rval v =>
        ∃s' w. syneq v w ∧
        csg_rel syneq (FST res) s' ∧
        closed_vlabs env s' (bc0++c0) ∧
        all_vlabs w ∧ (∀cd. cd ∈ vlabs w ⇒ code_env_cd (bc0++c0) cd) ∧
        code_for_push rd bs (bc0++c0) bc0 (c0++code) s' env [w] renv rsz
    | Rerr (Rraise err) =>
      ∀st hdl sp ig.
        bs.stack = ig++StackPtr sp::CodePtr hdl::st
      ∧ bs.handler = LENGTH st + 1
      ⇒
        ∃s' w. syneq err w ∧
         csg_rel syneq (FST res) s' ∧
         closed_vlabs env s' (bc0++c0) ∧
         code_for_return rd bs (bc0++c0) st hdl sp w s'
    | Rerr Rtimeout_error =>
      ∃bs'. bc_next^* bs bs' ∧ bs'.clock = SOME 0 ∧ bc_fetch bs' = SOME Tick ∧ bs'.output = bs.output
    | _ => T``,
  rw[compile_Cexp_def] >>
  qspecl_then[`LENGTH renv`,`cs.next_label`,`exp`]mp_tac (CONJUNCT1 label_closures_thm) >>
  simp[] >> strip_tac >>
  qspecl_then[`LENGTH renv`,`cs with next_label := nl`,`Ce`]mp_tac compile_code_env_thm >>
  simp[] >>
  discharge_hyps >- (
    simp[ALL_DISTINCT_GENLIST,EVERY_GENLIST] ) >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  qspecl_then[`renv`,`TCNonTail`,`rsz`,`cs'`,`Ce`]mp_tac(CONJUNCT1 compile_append_out) >>
  disch_then(Q.X_CHOOSE_THEN`c1`strip_assume_tac) >>
  simp[Abbr`cs''`] >>
  qexists_tac`c0` >> simp[Once SWAP_REVERSE] >>
  conj_tac >- (
    simp[between_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND,FILTER_REVERSE,ALL_DISTINCT_REVERSE] >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_FILTER,MEM_MAP,is_Label_rwt,between_def] >>
    rw[] >> spose_not_then strip_assume_tac >>
    fsrw_tac[DNF_ss][MEM_GENLIST] >>
    res_tac >> DECIDE_TAC ) >>
  conj_tac >- (
    rfs[code_labels_ok_def,uses_label_thm,EXISTS_REVERSE] >>
    qmatch_assum_abbrev_tac`P ⇒ Q` >>
    `P` by (
      simp[Abbr`P`] >>
      imp_res_tac all_labs_free_labs >>
      fs[all_labs_list_MAP] ) >>
    qunabbrev_tac`P`>>fs[Abbr`Q`] >>
    reverse(rw[])>- metis_tac[] >>
    last_x_assum(qspec_then`l`mp_tac) >>
    simp[] >> strip_tac >> fs[] >>
    qsuff_tac`MEM l (MAP (FST o FST o SND) (free_labs (LENGTH renv) Ce))`>-metis_tac[] >>
    qmatch_assum_abbrev_tac`MEM l a` >>
    qmatch_abbrev_tac`MEM l b` >>
    qsuff_tac`set a ⊆ set b`>-rw[SUBSET_DEF]>>
    unabbrev_all_tac >>
    simp[LIST_TO_SET_FLAT,MAP_MAP_o,LIST_TO_SET_MAP,GSYM IMAGE_COMPOSE] >>
    simp[combinTheory.o_DEF,LAMBDA_PROD] >>
    metis_tac[SIMP_RULE(srw_ss())[combinTheory.o_DEF,LAMBDA_PROD](CONJUNCT1 free_labs_free_labs)] ) >>
  rpt gen_tac >>
  Q.PAT_ABBREV_TAC`bc00A = (X ∨ Y)` >>
  strip_tac >>
  first_x_assum(qspecl_then[`bs`,`bc0`]mp_tac) >>
  simp[] >>
  discharge_hyps >- (
    simp[MEM_MAP,MEM_GENLIST,MEM_FILTER,is_Label_rwt] >>
    simp_tac(srw_ss()++DNF_ss)[] >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_FILTER,is_Label_rwt,good_labels_def] >>
    rw[] >> res_tac >> DECIDE_TAC ) >>
  strip_tac >>
  `LENGTH renv = LENGTH env` by (
    fs[Cenv_bs_def,env_renv_def,EVERY2_EVERY] ) >>
  fs[] >>
  qmatch_assum_abbrev_tac`bc_next bs bs0` >>
  qspecl_then[`s`,`env`,`exp`,`res`]mp_tac (CONJUNCT1 Cevaluate_syneq) >>
  simp[] >>
  disch_then(qspecl_then[`$=`,`s`,`env`,`Ce`]mp_tac) >>
  simp[] >>
  disch_then(Q.X_CHOOSE_THEN`Cres`strip_assume_tac) >>
  qspecl_then[`s`,`env`,`Ce`,`Cres`]mp_tac(CONJUNCT1 compile_val) >>
  PairCases_on`Cres`>>simp[]>>
  disch_then(qspecl_then[`rd`,`cs'`,`renv`,`rsz`,`bs0`,`bc0 ++ c0`,`REVERSE c1`,`bc0 ++ c0`,`REVERSE c1`,`[]`]mp_tac) >>
  discharge_hyps >- (
    simp[Abbr`bs0`] >>
    simp[CONJ_ASSOC] >>
    qmatch_abbrev_tac`(A ∧ B) ∧ C` >>
    `B ∧ C` by (
      simp[Abbr`A`,Abbr`B`,Abbr`C`,FILTER_APPEND,ALL_DISTINCT_APPEND] >>
      fsrw_tac[DNF_ss][EVERY_MEM,MEM_FILTER,is_Label_rwt,MEM_MAP,MEM_GENLIST,between_def,good_labels_def] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> DECIDE_TAC ) >>
    simp[Abbr`A`,Abbr`B`,Abbr`C`,GSYM CONJ_ASSOC] >>
    fs[closed_vlabs_def,vlabs_csg_def] >>
    conj_tac >- metis_tac[code_env_cd_append] >>
    conj_tac >- metis_tac[code_env_cd_append] >>
    conj_tac >- metis_tac[code_env_cd_append] >>
    conj_tac >- metis_tac[SUBSET_TRANS] >>
    match_mp_tac Cenv_bs_with_irr >>
    qexists_tac`bs with code := bc0 ++ c0` >> simp[] >>
    Cases_on`bc00 = bc0` >- (
      match_mp_tac Cenv_bs_append_code >>
      HINT_EXISTS_TAC >>
      simp[bc_state_component_equality] ) >>
    `bc0 ++ c0 = bc00` by metis_tac[] >>
    pop_assum SUBST1_TAC >>
    simp[] ) >>
  PairCases_on`res`>>fs[]>>
  strip_tac >>
  Cases_on`res3`>>fs[]>>rfs[]>-(
    rpt HINT_EXISTS_TAC >>
    simp[] >>
    qspecl_then[`s`,`env`,`Ce`,`(((Cres0,Cres1),Cres2),Cres3)`,`bc0++c0`]mp_tac Cevaluate_closed_vlabs >>
    simp[] >>
    discharge_hyps >- (
      fs[EVERY_MEM] >>
      fs[closed_vlabs_def] >>
      `ALL_DISTINCT (FILTER is_Label (bc0 ++ c0))` by (
        simp[FILTER_APPEND,ALL_DISTINCT_APPEND] >>
        fsrw_tac[DNF_ss][good_labels_def,MEM_FILTER,is_Label_rwt,MEM_MAP,MEM_GENLIST,between_def,EVERY_MEM] >>
        rw[] >> spose_not_then strip_assume_tac >> res_tac >> DECIDE_TAC ) >>
      metis_tac[code_env_cd_append] ) >>
    simp[] >> strip_tac >>
    conj_tac >- (
      fs[closed_vlabs_def,SUBSET_DEF] >>
      fs[EVERY_MEM] >>
      rw[] >> res_tac >> TRY(metis_tac[]) >>
      match_mp_tac code_env_cd_append >>
      simp[FILTER_APPEND,ALL_DISTINCT_APPEND] >>
      fsrw_tac[DNF_ss][good_labels_def,MEM_FILTER,is_Label_rwt,MEM_MAP,MEM_GENLIST,between_def,EVERY_MEM] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> DECIDE_TAC ) >>
    rw[] >>
    ntac 4 (pop_assum kall_tac) >>
    pop_assum mp_tac >>
    simp[code_for_push_def] >>
    simp_tac(srw_ss()++DNF_ss)[]>>
    simp[Abbr`bs0`] >>
    map_every qx_gen_tac [`rf`,`rd'`,`ck`,`gv`,`bv`] >>
    strip_tac >>
    map_every qexists_tac [`rf`,`rd'`,`ck`,`gv`,`bv`] >>
    simp[] >>
    simp[Once RTC_CASES1] >>
    disj2_tac >>
    HINT_EXISTS_TAC >>
    simp[] ) >>
  rw[] >>
  reverse BasicProvers.CASE_TAC >> fs[] >- (
    first_x_assum(qspec_then`TCNonTail`mp_tac) >>
    simp[Abbr`bs0`] >>
    metis_tac[RTC_SUBSET,RTC_TRANSITIVE,transitive_def] ) >>
  rpt gen_tac >> strip_tac >>
  rpt HINT_EXISTS_TAC >>
  fs[] >>
  qmatch_assum_abbrev_tac`Cevaluate s env Ce Cres` >>
  qspecl_then[`s`,`env`,`Ce`,`Cres`,`bc0++c0`]mp_tac Cevaluate_closed_vlabs >>
  simp[] >>
  discharge_hyps >- (
    fs[EVERY_MEM] >>
    fs[closed_vlabs_def] >>
    `ALL_DISTINCT (FILTER is_Label (bc0 ++ c0))` by (
      simp[FILTER_APPEND,ALL_DISTINCT_APPEND] >>
      fsrw_tac[DNF_ss][good_labels_def,MEM_FILTER,is_Label_rwt,MEM_MAP,MEM_GENLIST,between_def,EVERY_MEM] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> DECIDE_TAC ) >>
    metis_tac[code_env_cd_append] ) >>
  rw[Abbr`Cres`] >>
  first_x_assum(qspec_then`TCNonTail`mp_tac) >>
  simp[Abbr`bs0`] >>
  disch_then(qspec_then`ig`mp_tac) >>
  simp[] >>
  simp[code_for_return_def] >>
  simp_tac(srw_ss()++DNF_ss)[]>>
  map_every qx_gen_tac [`bv`,`rf`,`rd'`,`gv`,`ck`] >>
  strip_tac >>
  map_every qexists_tac [`bv`,`rf`,`rd'`,`gv`,`ck`] >>
  simp[] >>
  simp[Once RTC_CASES1] >>
  disj2_tac >>
  HINT_EXISTS_TAC >>
  simp[] )

(* env_rs *)

val env_rs_def = Define`
  env_rs ((envM,envC,envE):all_env) (((cnt,s),tids,mods)) (genv,gtagenv,rd)
    (rs:compiler_state) (bs:bc_state)
  ⇔
    good_labels rs.rnext_label bs.code ∧
    rs.next_global = LENGTH genv ∧
    bs.stack = [] ∧
    EVERY (sv_every closed) s ∧
    EVERY closed (MAP SND envE) ∧
    EVERY closed (MAP SND (FLAT (MAP SND envM))) ∧
    EVERY (OPTION_EVERY closed_i1) genv ∧
    ∃s1 s2 genv2 Cs Cg.
      to_i1_invariant
        genv (FST rs.globals_env) (SND rs.globals_env)
        envM envE (cnt,s) (cnt,s1) mods ∧
      to_i2_invariant
        mods tids envC rs.exh rs.contags_env gtagenv
        (cnt,s1) (cnt,s2) genv genv2 ∧
      LIST_REL (sv_rel (exh_Cv O v_to_exh rs.exh)) s2 Cs ∧
      LIST_REL (OPTREL (exh_Cv O v_to_exh rs.exh)) genv2 Cg ∧
      closed_vlabs [] ((cnt,Cs),Cg) bs.code ∧
      Cenv_bs rd ((cnt,Cs),Cg) [] [] 0 bs`

val env_rs_empty = store_thm("env_rs_empty",
  ``∀envs s cs genv mods tids gtagenv rd grd bs ck.
    bs.stack = [] ∧ bs.globals = [] ∧ FILTER is_Label bs.code = [] ∧
    (∀n. bs.clock = SOME n ⇒ n = ck) ∧ envs = ([],init_envC,[]) ∧ s = ((ck,[]),tids,mods) ∧
    grd = ([],gtagenv,rd) ∧
    rd.sm = [] ∧ rd.cls = FEMPTY ∧ cs = init_compiler_state ⇒
    env_rs envs s grd cs bs``,
  rpt gen_tac >>
  simp[env_rs_def,to_i1_invariant_def,to_i2_invariant_def] >>
  strip_tac >>
  conj_tac >- (EVAL_TAC >> simp[]) >>
  conj_tac >- (EVAL_TAC >> simp[]) >>
  rw[init_compiler_state_def,get_tagenv_def,cenv_inv_def] >>
  rw[Once v_to_i1_cases] >> rw[Once v_to_i1_cases] >>
  rw[Once s_to_i1_cases] >> rw[Once v_to_i1_cases] >>
  simp[Once s_to_i2_cases] >> simp[Once v_to_i2_cases] >>
  simp[Cenv_bs_def,env_renv_def,s_refs_def,good_rd_def,FEVERY_ALL_FLOOKUP] >>
  simp[all_vlabs_csg_def,vlabs_csg_def,closed_vlabs_def] >>
  simp[store_vs_def] >>
  cheat)

(*
(* TODO: move *)
val to_i1_invariant_change_clock = store_thm("to_i1_invariant_change_clock",
  ``to_i1_invariant genv mods tops menv env s s_i1 mod_names ∧
    SND s' = SND s ∧ SND s_i1' = SND s_i1 ∧ FST s' = FST s_i1'
    ⇒
    to_i1_invariant genv mods tops menv env s' s_i1' mod_names``,
  simp[to_i1_invariant_def] >>
  rw[Once s_to_i1_cases] >>
  rw[Once s_to_i1_cases] >>
  metis_tac[pair_CASES,PAIR_EQ,SND,FST])

(* TODO: move *)
val to_i2_invariant_change_clock = store_thm("to_i2_invariant_change_clock",
  ``to_i2_invariant tids envC exh tagenv_st gtagenv s s_i2 genv genv_i2 ∧
    SND s' = SND s ∧ SND s_i2' = SND s_i2 ∧ FST s' = FST s_i2'
    ⇒
    to_i2_invariant tids envC exh tagenv_st gtagenv s' s_i2' genv genv_i2``,
  simp[to_i2_invariant_def] >>
  rw[Once s_to_i2_cases] >>
  rw[Once s_to_i2_cases] >>
  metis_tac[pair_CASES,PAIR_EQ,SND,FST])

val env_rs_change_clock = store_thm("env_rs_change_clock",
   ``∀env cs grd rs bs cs' ck' bs' new_clock.
     env_rs env cs grd rs bs ∧ cs' = (ck',SND cs) ∧
     (bs' = bs with clock := new_clock) ∧
     (new_clock = NONE ∨ new_clock = SOME ck')
     ⇒
     env_rs env cs' grd rs bs'``,
  qx_gen_tac`p` >> PairCases_on`p` >>
  qx_gen_tac`q` >> PairCases_on`q` >>
  qx_gen_tac`r` >> PairCases_on`r` >>
  simp[env_rs_def] >>
  rpt gen_tac >>
  Q.PAT_ABBREV_TAC`d = (a ∨ b)` >>
  strip_tac >>
  map_every qexists_tac[`s1`] >>
  simp[RIGHT_EXISTS_AND_THM] >>
  conj_tac >- (
    metis_tac[to_i1_invariant_change_clock,FST,SND] ) >>
  map_every qexists_tac[`s2`,`genv2`] >>
  conj_tac >- (
    metis_tac[to_i2_invariant_change_clock,FST,SND] ) >>
  simp[PULL_EXISTS] >>
  rpt HINT_EXISTS_TAC >>
  simp[] >>
  conj_tac >- (
    fs[all_vlabs_csg_def,vlabs_csg_def,closed_vlabs_def] >>
    metis_tac[] ) >>
  match_mp_tac Cenv_bs_change_store >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  simp[bc_state_component_equality] >>
  fs[Cenv_bs_def,s_refs_def,Abbr`d`,good_rd_def])
*)

(*
val env_rs_change_store = store_thm("env_rs_change_store",
  ``∀env cs rs rd bs rd' cs' Cs' bs' ck' rf'.
    env_rs env cs rs rd bs ∧
    (IS_SOME ck' ⇒ ck' = SOME (FST cs')) ∧
    bs' = bs with <| refs := rf'; clock := ck'|> ∧
    LENGTH (SND cs) ≤ LENGTH (SND cs') ∧
    s_refs rd' (FST cs',Cs') bs' ∧
    LIST_REL syneq (vs_to_Cvs (MAP FST o_f rs.rmenv) (cmap rs.contab) (SND cs')) Cs' ∧
    DRESTRICT bs.refs (COMPL (set rd.sm)) ⊑ DRESTRICT rf' (COMPL (set rd'.sm)) ∧
    rd.sm ≼ rd'.sm ∧ rd.cls ⊑ rd'.cls ∧
    EVERY all_vlabs Cs' ∧
    (∀cd. cd ∈ vlabs_list Cs' ⇒ code_env_cd (MAP SND o_f rs.rmenv) bs.code cd)
    ⇒
    env_rs env cs' rs rd' bs'``,
  rw[] >>
  fs[env_rs_def,LET_THM] >> rfs[] >> fs[] >>
  rpt HINT_EXISTS_TAC >> simp[] >>
  qexists_tac`Cs'` >>
  fs[vs_to_Cvs_MAP] >>
  simp[CONJ_ASSOC] >>
  reverse conj_tac >- (
    match_mp_tac bytecodeProofTheory.Cenv_bs_change_store >>
    map_every qexists_tac[`rd`,`(FST cs,Cs)`,`bs`,`rf'`,`ck'`] >>
    simp[bytecodeTheory.bc_state_component_equality] ) >>
  fs[closed_Clocs_def,closed_vlabs_def] >>
  fs[EVERY2_EVERY] >>
  full_simp_tac pure_ss [SUBSET_DEF,IN_COUNT] >>
  metis_tac[LESS_LESS_EQ_TRANS])
*)

val env_rs_with_bs_irr = store_thm("env_rs_with_bs_irr",
  ``∀env cs grd rs bs bs'.
    env_rs env cs grd rs bs
    ∧ bs'.globals = bs.globals
    ∧ bs'.stack = bs.stack
    ∧ bs'.refs = bs.refs
    ∧ bs'.clock = bs.clock
    ∧ bs'.code = bs.code
    ∧ bs'.inst_length = bs.inst_length
    ⇒
    env_rs env cs grd rs bs'``,
  simp[FORALL_PROD] >> rw[env_rs_def] >>
  rpt(first_assum(match_exists_tac o concl) >> simp[]) >>
  match_mp_tac Cenv_bs_with_irr >>
  HINT_EXISTS_TAC >> rfs[])

val env_rs_append_code = store_thm("env_rs_append_code",
  ``∀env cs grd rs bs bs' rs' c nl.
    env_rs env cs grd rs bs ∧
    bs' = bs with code := bs.code ++ c ∧
    rs' = rs with rnext_label := nl ∧
    good_labels nl bs'.code
    ⇒
    env_rs env cs grd rs' bs'``,
  simp[FORALL_PROD] >>
  simp[env_rs_def] >>
  rpt gen_tac >> strip_tac  >>
  rpt(first_assum(match_exists_tac o concl) >> simp[]) >>
  conj_tac >- (
    fs[closed_vlabs_def] >> rw[]>>
    match_mp_tac code_env_cd_append >>
    fs[good_labels_def]) >>
  match_mp_tac Cenv_bs_append_code >>
  metis_tac[])

(*
val env_rs_can_Print = store_thm("env_rs_can_Print",
  ``∀env cs grd rs bs n v.
    env_rs env cs grd rs bs ∧
    EL n bs.globals = SOME v ∧
    n ∈ (FRANGE (SND rs.globals_env) ∪
         BIGUNION (IMAGE FRANGE (FRANGE (FST rs.globals_env))))
    ⇒
    can_Print v``,
  simp_tac std_ss [FORALL_PROD] >>
  rpt gen_tac >>
  Q.PAT_ABBREV_TAC`ss:num set = x ∪ y` >>
  rw[env_rs_def,Cenv_bs_def,s_refs_def] >>
  rfs[EVERY2_EVERY] >>
  fs[EVERY_MEM,MEM_ZIP,PULL_EXISTS,optionTheory.OPTREL_def] >>
  fs[good_globals_def] >>
  `n < LENGTH bs.globals` by (
    fs[Abbr`ss`] >> res_tac >> fs[] >> metis_tac[] ) >>
  match_mp_tac (GEN_ALL Cv_bv_can_Print) >>
  metis_tac[optionTheory.NOT_SOME_NONE,optionTheory.SOME_11])
*)

(* compile_top *)

val compile_top_labels = store_thm("compile_top_labels",
  ``∀types rs top.
      FV_top top ⊆ global_dom rs.globals_env
      ⇒
      (FST(SND(compile_top types rs top))).rnext_label = (FST(compile_top types rs top)).rnext_label ∧
      between_labels (SND(SND(compile_top types rs top))) rs.rnext_label (FST(compile_top types rs top)).rnext_label ∧
      code_labels_ok (SND(SND(compile_top types rs top)))``,
   simp[compile_top_def,UNCURRY,pair_CASE_def] >>
   rpt gen_tac >> strip_tac >>
   specl_args_of_then``compile_Cexp``compile_Cexp_thm mp_tac >>
   discharge_hyps >- (
     simp[] >>
     qmatch_abbrev_tac`x = []` >>
     qsuff_tac`set x ⊆ {}` >- rw[] >>
     qunabbrev_tac`x` >>
     specl_args_of_then``exp_to_pat``(CONJUNCT1 free_vars_pat_exp_to_pat)mp_tac >>
     match_mp_tac(METIS_PROVE[]``(p ∧ (p ∧ q ⇒ r)) ⇒ ((p ⇒ q) ⇒ r)``) >>
     conj_tac >- (
       simp[] >>
       Q.PAT_ABBREV_TAC`p = prompt_to_i3 X Y Z A` >>
       PairCases_on`p` >> fs[markerTheory.Abbrev_def] >>
       pop_assum(ASSUME_TAC o SYM) >>
       imp_res_tac free_vars_i2_prompt_to_i3 >> simp[] >>
       Q.PAT_ABBREV_TAC`p = prompt_to_i2 X A` >>
       PairCases_on`p` >> fs[markerTheory.Abbrev_def] >>
       pop_assum(ASSUME_TAC o SYM) >>
       imp_res_tac free_vars_prompt_to_i2 >> simp[] >>
       Q.PAT_ABBREV_TAC`p = top_to_i1 A B C D` >>
       PairCases_on`p` >> fs[markerTheory.Abbrev_def] >>
       pop_assum(ASSUME_TAC o SYM) >>
       imp_res_tac FV_top_to_i1 >>
       simp[Once EXTENSION] >> fs[SUBSET_DEF] >>
       Cases_on`rs.globals_env`>> fs[global_dom_def] >>
       rw[] >> CCONTR_TAC >> fs[] >> res_tac >> fs[] ) >>
     strip_tac >> rfs[] ) >>
   Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
   simp[] >> strip_tac >>
   specl_args_of_then``compile_print_top``compile_print_top_thm mp_tac >>
   simp[] >> strip_tac >>
   simp[] >>
   pop_assum kall_tac >>
   conj_tac >- (
     rpt(rator_x_assum`between_labels`mp_tac) >>
     rpt(rator_x_assum`code_labels_ok`mp_tac) >>
     rpt (pop_assum kall_tac) >>
     simp[between_labels_def,FILTER_APPEND,FILTER_REVERSE,ALL_DISTINCT_APPEND,ALL_DISTINCT_REVERSE,MAP_REVERSE,EVERY_REVERSE] >>
     simp[EVERY_MAP,EVERY_FILTER,is_Label_rwt,PULL_EXISTS] >>
     simp[EVERY_MEM,MEM_FILTER,is_Label_rwt,PULL_EXISTS] >>
     rw[] >> res_tac >> fsrw_tac[ARITH_ss][between_def] >>
     spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
   REWRITE_TAC[GSYM APPEND_ASSOC] >>
   match_mp_tac code_labels_ok_append >>
   simp[code_labels_ok_REVERSE] >>
   REWRITE_TAC[GSYM REVERSE_APPEND] >>
   simp[code_labels_ok_REVERSE] )

val tac1 =
  simp[store_to_exh_def] >>
  conj_tac >>
  match_mp_tac (MP_CANON (GEN_ALL EVERY2_mono)) >>
  HINT_EXISTS_TAC >>
  simp[sv_to_exh_sv_rel] >>
  metis_tac[optionTheory.OPTREL_MONO,v_to_exh_extend_disjoint,FUNION_COMM,sv_rel_mono]

val tac2 =
  conj_asm1_tac >- (
    specl_args_of_then``exp_to_pat``(CONJUNCT1 free_vars_pat_exp_to_pat)mp_tac >>
    simp[] >> disch_then match_mp_tac >>
    imp_res_tac free_vars_i2_prompt_to_i3 >>
    imp_res_tac free_vars_prompt_to_i2 >>
    imp_res_tac FV_top_to_i1 >>
    simp[] >>
    fs[closed_top_def,all_env_dom_def,SUBSET_DEF,PULL_EXISTS] >>
    simp[EXTENSION] >> rw[] >>
    CCONTR_TAC >> fs[] >> res_tac >> fs[] >> rw[] >>
    fs[to_i1_invariant_def] >>
    imp_res_tac global_env_inv_inclusion >>
    fs[SUBSET_DEF]) >>
  simp[csg_closed_pat_def,map_count_store_genv_def,store_to_exh_def] >>
  conj_tac >- (
    match_mp_tac EVERY_sv_every_MAP_map_sv >>
    (v_to_pat_closed |> CONJUNCT2 |> SIMP_RULE(srw_ss())[] |> match_mp_tac) >>
    (v_to_exh_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
    fs[store_to_exh_def] >>
    simp[vs_to_exh_MAP] >>
    imp_res_tac LIST_REL_store_vs_intro >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[to_i2_invariant_def] >>
    fs[Once s_to_i2_cases,sv_to_i2_sv_rel] >>
    (v_to_i2_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
    simp[vs_to_i2_MAP] >>
    imp_res_tac LIST_REL_store_vs_intro >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
    fs[to_i1_invariant_def] >>
    fs[Once s_to_i1_cases,sv_to_i1_sv_rel] >>
    simp[vs_to_i1_MAP] >>
    imp_res_tac LIST_REL_store_vs_intro >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    match_mp_tac EVERY_store_vs_intro >> simp[]) >>
  match_mp_tac genv_to_pat_closed >>
  match_mp_tac genv_to_exh_closed >>
  fs[store_to_exh_def] >>
  ONCE_REWRITE_TAC[CONJ_COMM] >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  fs[to_i2_invariant_def] >>
  match_mp_tac (MP_CANON genv_to_i2_closed) >>
  first_assum(match_exists_tac o concl) >> simp[]>>
  first_assum(match_exists_tac o concl) >> simp[]

val tac3=
  simp[syneq_exp_refl] >>
  fs[store_to_exh_def] >>
  simp[Abbr`Csg`,map_count_store_genv_def,csg_rel_def] >>
  simp[MAP_MAP_o,optionTheory.OPTION_MAP_COMPOSE,combinTheory.o_DEF,map_sv_compose] >>
  simp[EVERY2_MAP] >>
  conj_tac >>
  match_mp_tac EVERY2_MEM_MONO >>
  HINT_EXISTS_TAC >>
  simp[exh_Cv_def,optionTheory.OPTREL_def,UNCURRY] >- (
    rw[] >> rw[] >> fs[sv_rel_cases] >>
    fs[exh_Cv_def] >>
    first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
    discharge_hyps >- (
      simp[] >>
      fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM,map_count_store_genv_def] >>
      imp_res_tac MEM_ZIP_MEM_MAP >>
      imp_res_tac EVERY2_LENGTH >> fs[] >>
      fs[MEM_MAP,PULL_EXISTS] >>
      first_x_assum(fn th => first_x_assum(mp_tac o MATCH_MP th)) >>
      simp[]) >>
    metis_tac[syneq_trans] ) >>
  rw[] >> rw[] >>
  first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
  discharge_hyps >- (
    simp[] >>
    fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM] >>
    first_x_assum(qspec_then`OPTION_MAP v_to_pat (FST x)`mp_tac) >>
    simp[map_count_store_genv_def] >>
    disch_then match_mp_tac >>
    simp[MEM_MAP,PULL_EXISTS] >>
    metis_tac[MEM_ZIP_MEM_MAP,EVERY2_LENGTH,FST,SND] ) >>
  metis_tac[syneq_trans]

val tac4=
  PairCases_on`s''`>>fs[csg_rel_unpair,map_count_store_genv_def] >>
  rpt BasicProvers.VAR_EQ_TAC >>
  first_assum(mp_tac o MATCH_MP(ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]Cenv_bs_append_code)) >>
  disch_then(qspec_then`code ++ bcp`mp_tac o CONV_RULE SWAP_FORALL_CONV) >> simp[] >>
  disch_then(mp_tac o MATCH_MP(ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]Cenv_bs_with_irr)) >>
  disch_then(qspec_then`bs1 with <| output := bs2.output; pc := bs2.pc|>`mp_tac) >> simp[] >>
  disch_then(mp_tac o MATCH_MP
    (REWRITE_RULE[Once(GSYM AND_IMP_INTRO),ADD]
     (Q.SPEC`0`(CONV_RULE(RESORT_FORALL_CONV(sort_vars["rsz"]))Cenv_bs_imp_decsz)))) >>
  disch_then(qspec_then`bs2`mp_tac) >>
  simp[Abbr`bs1`,bc_state_component_equality,Abbr`bs2`] >>
  strip_tac >>
  rator_x_assum`closed_vlabs`mp_tac >>
  simp[closed_vlabs_def] >> rw[] >>
  res_tac >>
  imp_res_tac code_env_cd_append >>
  first_x_assum(qspec_then`code ++ bcp`mp_tac) >>
  simp[] >> disch_then match_mp_tac >>
  rator_x_assum`good_labels`mp_tac >> simp[] >>
  simp[good_labels_def]

fun tac5() =
  simp[print_result_def,Abbr`bs2`] >>
  qmatch_rename_tac`THE(bv_to_string bv) = print_v a`[] >>
  `THE (bv_to_string bv) = print_bv "" bv` by (
    simp[print_bv_def] ) >>
  pop_assum SUBST1_TAC >>
  match_mp_tac (MP_CANON print_bv_print_v) >> simp[] >>
  fs[result_to_i1_cases,result_to_i2_cases] >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  rpt BasicProvers.VAR_EQ_TAC >> fs[] >> BasicProvers.VAR_EQ_TAC >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  REWRITE_TAC[Once CONJ_COMM] >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  simp[exh_Cv_def] >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  reverse conj_tac >- metis_tac[syneq_trans] >>
  first_x_assum(mp_tac o MATCH_MP (CONJUNCT1 evaluate_pat_closed)) >>
  simp[csg_closed_pat_def]

val tac6=
  qexists_tac`rd'` >>
  PairCases_on`s'` >>
  fs[store_to_exh_def,sv_to_exh_sv_rel] >>
  rpt BasicProvers.VAR_EQ_TAC >>
  simp[sv_rel_O,OPTREL_O,LIST_REL_O,PULL_EXISTS] >>
  simp[Once(GSYM CONJ_ASSOC)] >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  simp[Once CONJ_COMM] >>
  simp[Once(GSYM CONJ_ASSOC)] >>
  simp[Once(GSYM CONJ_ASSOC)] >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  qho_match_abbrev_tac`∃B A. P A ∧ R A B ∧ Q B` >>
  qsuff_tac`∃A B. (P A ∧ Q B) ∧ R A B` >- metis_tac[] >>
  map_every qunabbrev_tac[`P`,`Q`,`R`] >> simp[] >>
  qexists_tac`SND s''` >>
  qexists_tac`SND(FST s'')`

val tac7=
  rpt(rator_x_assum`csg_rel`mp_tac) >>
  simp[map_count_store_genv_def,csg_rel_unpair] >>
  rpt (disch_then strip_assume_tac) >>
  conj_tac >- (
    match_mp_tac LIST_REL_OPTREL_exh_Cv_syneq_trans >>
    HINT_EXISTS_TAC >> simp[] >>
    match_mp_tac LIST_REL_OPTREL_exh_Cv_syneq_trans >>
    HINT_EXISTS_TAC >> simp[] >>
    match_mp_tac LIST_REL_OPTREL_exh_Cv_syneq_trans >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[EVERY2_MAP] >>
    match_mp_tac EVERY2_MEM_MONO >>
    HINT_EXISTS_TAC >> simp[] >>
    simp[UNCURRY,optionTheory.OPTREL_def] >>
    rw[exh_Cv_def] >> rw[] >>
    HINT_EXISTS_TAC >> simp[] >>
    first_x_assum(mp_tac o MATCH_MP (CONJUNCT1 evaluate_pat_closed)) >>
    simp[csg_closed_pat_def] >>
    simp[EVERY_MEM] >>
    imp_res_tac EVERY2_LENGTH >>
    imp_res_tac MEM_ZIP_MEM_MAP >>
    rfs[] >>
    metis_tac[OPTION_EVERY_def]) >>
  match_mp_tac LIST_REL_sv_rel_exh_Cv_syneq_trans >>
  HINT_EXISTS_TAC >> simp[] >>
  match_mp_tac LIST_REL_sv_rel_exh_Cv_syneq_trans >>
  HINT_EXISTS_TAC >> simp[] >>
  match_mp_tac LIST_REL_sv_rel_exh_Cv_syneq_trans >>
  first_assum(match_exists_tac o concl) >> simp[] >>
  fs[EVERY2_MAP] >>
  match_mp_tac EVERY2_MEM_MONO >>
  HINT_EXISTS_TAC >> simp[] >>
  simp[FORALL_PROD] >>
  Cases >> Cases >> simp[sv_rel_cases] >>
  rw[exh_Cv_def] >> rw[] >>
  HINT_EXISTS_TAC >> simp[] >>
  first_x_assum(mp_tac o MATCH_MP (CONJUNCT1 evaluate_pat_closed)) >>
  simp[csg_closed_pat_def] >>
  simp[EVERY_MEM] >>
  imp_res_tac EVERY2_LENGTH >>
  imp_res_tac MEM_ZIP_MEM_MAP >>
  rfs[] >>
  metis_tac[sv_every_def]

val compile_top_thm = store_thm("compile_top_thm",
  ``∀ck env stm top res. evaluate_top ck env stm top res ⇒
     ∀rs types grd rss rsf bc bs bc0.
      env_rs env stm grd rs (bs with code := bc0) ∧
      (compile_top types rs top = (rss,rsf,bc)) ∧
      (IS_SOME types ⇒ set (new_top_vs top) ⊆ FDOM (THE types)) ∧
      (case (SND(SND res)) of
       | Rval(_,envE) => IS_SOME types ⇒ good_type_string_env (THE types) envE
       | Rerr(Rraise v) => ∀l. v ≠ Litv l
       | _ => T) ∧
      closed_top env top ∧
      (bs.code = bc0 ++ REVERSE bc) ∧
      (bs.pc = next_addr bs.inst_length bc0) ∧
      ck ∧ IS_SOME bs.clock ∧
      SND(SND res) ≠ Rerr Rtype_error ∧
      SND(SND res) ≠ Rerr Rtimeout_error
      ⇒
      case res of (s,envC,env_or_err) =>
        ∃bs' grd'.
        bc_next^* bs bs' ∧
        let (new_env,rs',success,str) =
          case env_or_err of Rval(envM,envE) =>
            ((envM++FST env,merge_envC envC (FST(SND env)),envE ++ (SND(SND env))),rss,T,
             (case types of NONE => "" | SOME types =>
              print_result types top envC env_or_err))
          | Rerr(Rraise _) =>
            (env,rsf,F,
             print_result (THE types) top envC env_or_err) in
        bc_fetch bs' = SOME (Stop success) ∧
        bs'.output = bs.output ++ str ∧
        env_rs new_env s grd' rs' bs'``,
  ho_match_mp_tac evaluate_top_ind >>
  strip_tac >- (
    simp[] >>
    rpt gen_tac >> strip_tac >>
    rpt gen_tac >>
    simp[compile_top_def] >>
    Q.PAT_ABBREV_TAC`non = (none_tag,(X:tid_or_exn option))` >>
    Q.PAT_ABBREV_TAC`som = (some_tag,(X:tid_or_exn option))` >>
    strip_tac >>
    `∃m10 m20. rs.globals_env = (m10,m20)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    qspecl_then[`m10`,`m20`,`Tdec d`]mp_tac top_to_i1_correct >>
    PairCases_on`grd`>>PairCases_on`env`>>PairCases_on`s1`>>fs[env_rs_def] >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    `∃v m1 m2 p1. top_to_i1 rs.next_global m10 m20 (Tdec d) = (v,m1,m2,p1)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    simp[Once evaluate_top_cases] >>
    simp_tac(srw_ss()++DNF_ss)[] >>
    disch_then(mp_tac o CONJUNCT1) >> rfs[] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    disch_then(qx_choosel_then[`s2_i1`,`new_genv`]strip_assume_tac) >>
    `∃c exh p. prompt_to_i2 rs.contags_env p1 = (c,exh,p)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      CONV_RULE (
        ONCE_REWRITE_CONV[CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[CONJ_COMM] THENC
        ONCE_REWRITE_CONV[GSYM CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[GSYM AND_IMP_INTRO]) prompt_to_i2_correct))) >>
    REWRITE_TAC[Once EQ_SYM_EQ] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    simp[] >>
    discharge_hyps >- (
      fs[top_to_i1_def,LET_THM,UNCURRY] >>
      rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
      simp[dec_to_i1_def] >>
      BasicProvers.CASE_TAC >> simp[not_mod_decs_def] ) >>
    disch_then(qx_choosel_then[`new_genv_i2`,`s2_i2`,`gtagenv2`]strip_assume_tac) >>
    `∃n e. prompt_to_i3 non som (LENGTH grd0) p = (n,e)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
        prompt_to_i3_correct))) >>
    simp[] >>
    `LENGTH genv2 = LENGTH grd0` by (
      fs[to_i2_invariant_def] >>
      imp_res_tac EVERY2_LENGTH >>
      fs[] ) >>
    simp[] >>
    simp[Once result_to_i3_cases] >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_exh_correct)) >>
    simp[] >> simp[env_to_exh_MAP] >>
    fs[LIST_REL_O,OPTREL_O,sv_rel_O] >>
    qmatch_assum_rename_tac`LIST_REL (sv_rel (v_to_exh rs.exh)) s20 sh`[] >>
    qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
    `store_to_exh (exh ⊌ rs.exh) ((s10,s20),genv2) ((s10,sh),gh)` by tac1 >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    simp[Once result_to_exh_cases] >>
    disch_then(qspec_then`exh ⊌ rs.exh`mp_tac) >> simp[] >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_pat_correct)) >>
    simp[] >>
    disch_then(qx_choosel_then[`res4`]strip_assume_tac) >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
    simp[] >>
    discharge_hyps_keep >- tac2 >>
    disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
    qpat_assum`X = bc`mp_tac >>
    specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
    simp[] >> strip_tac >>
    first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
    simp[] >>
    Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
    qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
    disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
    discharge_hyps >- tac3 >>
    strip_tac >>
    first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    specl_args_of_then``compile_print_top``compile_print_top_thm mp_tac >>
    simp[] >>
    disch_then(qx_choose_then`bcp`strip_assume_tac) >>
    disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
    discharge_hyps >- (
      simp[Abbr`Csg`] >>
      fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
    strip_tac >>
    rator_x_assum`v_to_exh`mp_tac >>
    simp[Once v_to_exh_cases,vs_to_exh_MAP] >>
    strip_tac >> BasicProvers.VAR_EQ_TAC >>
    rator_x_assum`v_pat`mp_tac >>
    simp[Once v_pat_cases] >>
    strip_tac >> BasicProvers.VAR_EQ_TAC >>
    rpt (
      qpat_assum`syneq (X Y) Z`mp_tac >>
      simp[Once syneq_cases] >> strip_tac >>
      BasicProvers.VAR_EQ_TAC ) >>
    strip_tac >>
    rator_x_assum`code_for_push`mp_tac >>
    simp[code_for_push_def,PULL_EXISTS] >>
    rpt gen_tac >> strip_tac >>
    rator_x_assum`Cv_bv`mp_tac >>
    simp[Once Cv_bv_cases] >> strip_tac >>
    BasicProvers.VAR_EQ_TAC >>
    qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
    `bc_next^* bs (bs1 with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs0`,`bs1`] >>
      simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] >>
      rw[] ) >>
    first_x_assum(qspec_then`bs1 with code := bs.code`mp_tac) >>
    simp[] >> BasicProvers.VAR_EQ_TAC >> simp[] >>
    simp[Abbr`bs1`] >>
    simp[Abbr`non`] >>
    qabbrev_tac`bvs = MAP (λv. THE (EL (m2 ' v) gv)) (new_dec_vs d)` >>
    disch_then(qspec_then`bvs`mp_tac) >>
    ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
    discharge_hyps_keep >- (
      fs[good_labels_def,between_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND
        ,MEM_FILTER,is_Label_rwt,PULL_EXISTS,EVERY_FILTER,EVERY_MEM,PULL_FORALL
        ,MEM_MAP,between_def] >>
      rw[] >> res_tac >> fsrw_tac[ARITH_ss][] >>
      spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    qmatch_abbrev_tac`((P ⇒ Q) ⇒ R) ⇒ Z` >>
    `(P ⇒ Q) ∧
      LIST_REL (v_bv (grd0 ++ new_genv, gtagenv2, rs.exh ⊌ exh, mk_pp rd' (bs with code := bc0 ++ c0)))
                  (MAP SND new_env) bvs` by (
      simp[Abbr`Q`,Abbr`R`,Abbr`Z`,Abbr`P`] >>
      last_x_assum mp_tac >>
      Cases_on`d`>>fs[] >>
      simp[Once evaluate_dec_cases,PULL_EXISTS] >>
      simp[libTheory.emp_def,FST_triple] >>
      simp[build_rec_env_MAP] >>
      rpt gen_tac >> strip_tac >>
      `LENGTH bvs = LENGTH new_env` by (
        simp[Abbr`bvs`] >>
        imp_res_tac pmatch_dom >> fs[] >>
        metis_tac[LENGTH_MAP] ) >>
      rfs[Abbr`bvs`] >>
      simp[EVERY2_EVERY,EVERY_MEM,MEM_ZIP,PULL_EXISTS,EL_MAP] >>
      simp[FLOOKUP_DEF,compilerLibTheory.el_check_def] >>
      simp[GSYM RIGHT_FORALL_IMP_THM] >>
      simp[Once(PROVE[]``(P ==> q ==> r) <=> (q ==> P ==> r)``)] >>
      simp[GSYM FORALL_AND_THM,GSYM IMP_CONJ_THM] >>
      rpt BasicProvers.VAR_EQ_TAC >>
      qx_gen_tac`n` >> strip_tac >>
      rator_x_assum`to_i1_invariant`mp_tac >>
      simp[to_i1_invariant_def] >>
      simp[Once v_to_i1_cases] >>
      simp[Once v_to_i1_cases] >>
      fs[libTheory.emp_def] >>
      simp[libPropsTheory.lookup_append] >>
      (Q.PAT_ABBREV_TAC`pv:string = EL n X` ORELSE
       Q.PAT_ABBREV_TAC`pv:string = FST(EL n X)`) >>
      disch_then(qspec_then`pv`mp_tac o CONJUNCT1 o CONJUNCT1 o CONJUNCT2) >>
      (BasicProvers.CASE_TAC >- (
         imp_res_tac libPropsTheory.lookup_notin >>
         imp_res_tac pmatch_dom >>
         fs[MAP_MAP_o,combinTheory.o_DEF,UNCURRY,ETA_AX,MEM_MAP,PULL_EXISTS] >>
         metis_tac[MEM_EL,EL_MAP,LENGTH_MAP] )) >>
      simp[FLOOKUP_DEF] >> strip_tac >> simp[] >>
      `LENGTH gv = LENGTH grd0 + LENGTH new_genv` by (
        fs[gvrel_def,Cenv_bs_def,s_refs_def] >>
        fs[Abbr`Csg`,store_to_exh_csg_rel,csg_rel_unpair,map_count_store_genv_def] >>
        imp_res_tac EVERY2_LENGTH >> fs[] >> rw[] >>
        rator_x_assum`to_i2_invariant`mp_tac >>
        simp[to_i2_invariant_def] >> strip_tac >>
        imp_res_tac EVERY2_LENGTH >> fs[] >>
        metis_tac[] ) >>
      simp[] >>
      simp[v_bv_def] >>
      fs[gvrel_def,Cenv_bs_def,s_refs_def] >>
      qpat_assum`LIST_REL R X gv`mp_tac >>
      simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
      simp[optionTheory.OPTREL_def] >> strip_tac >>
      disch_then(qspec_then`m2 ' pv`mp_tac) >> simp[] >>
      (reverse strip_tac >- (
         simp[] >>
         simp[RIGHT_EXISTS_AND_THM] >>
         conj_tac >- (
           simp[Once IS_SOME_EXISTS] >> strip_tac >>
           conj_tac >- metis_tac[Cv_bv_can_Print] >>
           fs[] >>
           rator_x_assum`good_type_string_env`mp_tac >>
           simp[good_type_string_env_def,EVERY_MEM] >>
           imp_res_tac libPropsTheory.lookup_in3 >>
           disch_then(fn th => first_x_assum (mp_tac o MATCH_MP th)) >>
           simp[] >> rw[] >> fs[Once v_to_i1_cases] >>
           rator_x_assum`to_i2_invariant`mp_tac >>
           simp[to_i2_invariant_def,LIST_REL_EL_EQN] >> rw[] >>
           first_x_assum(qspec_then`m2 ' pv`mp_tac) >>
           simp[optionTheory.OPTREL_def,Once v_to_i2_cases] >> rw[] >>
           rator_x_assum`store_to_exh`mp_tac >>
           simp[store_to_exh_csg_rel,csg_rel_unpair,LIST_REL_EL_EQN] >> strip_tac >>
           first_x_assum(qspec_then`m2 ' pv`mp_tac) >>
           simp[optionTheory.OPTREL_def] >> strip_tac >>
           fs[csg_rel_unpair,map_count_store_genv_def] >>
           qsuff_tac`x0 = (CLitv (Word8 w))` >- (
             fs[Once Cv_bv_cases] ) >>
           qsuff_tac`EL (m2 ' pv) (SND s'') = SOME (CLitv (Word8 w))`>-rw[] >>
           qpat_assum`LIST_REL P X (SND s'')`mp_tac >>
           simp[LIST_REL_EL_EQN] >> strip_tac >>
           first_x_assum(qspec_then`m2 ' pv`mp_tac) >>
           simp[optionTheory.OPTREL_def] >> strip_tac >>
           qpat_assum`LIST_REL P X (SND (FST res2))`mp_tac >>
           simp[LIST_REL_EL_EQN] >> strip_tac >>
           first_x_assum(qspec_then`m2 ' pv`mp_tac) >>
           simp[optionTheory.OPTREL_def] >> strip_tac >>
           qpat_assum`LIST_REL P X (SND (FST Cres0))`mp_tac >>
           simp[LIST_REL_EL_EQN] >> strip_tac >>
           first_x_assum(qspec_then`m2 ' pv`mp_tac) >>
           simp[optionTheory.OPTREL_def] >> strip_tac >>
           qpat_assum`LIST_REL P X (SND (FST res4))`mp_tac >>
           simp[LIST_REL_EL_EQN] >> strip_tac >>
           first_x_assum(qspec_then`m2 ' pv`mp_tac) >>
           simp[optionTheory.OPTREL_def,EL_MAP] >> strip_tac >>
           rfs[EL_MAP] >>
           rpt BasicProvers.VAR_EQ_TAC >> fs[] >>
           rpt BasicProvers.VAR_EQ_TAC >> fs[]) >>
         imp_res_tac pmatch_dom >> fs[] >>
         TRY (pop_assum(assume_tac o SYM)) >>
         qpat_assum`n < LENGTH new_env`assume_tac >>
         fs[EL_MAP] >>
         qmatch_assum_abbrev_tac`lookup pv new_env = SOME x` >>
         `MEM (pv, SND (EL n new_env)) new_env` by (
           TRY( simp[Abbr`new_env`,EL_MAP,MEM_MAP,UNCURRY,Abbr`pv`] ) >>
           metis_tac[MEM_EL,PAIR] ) >>
         `ALL_DISTINCT (MAP FST new_env)` by (
           simp[] >>
           simp[Abbr`new_env`,MAP_MAP_o,combinTheory.o_DEF,UNCURRY,ETA_AX] ) >>
         imp_res_tac libPropsTheory.lookup_all_distinct >> fs[] >>
         rpt BasicProvers.VAR_EQ_TAC >>
         TRY (
           Q.PAT_ABBREV_TAC`vv:v = SND (X (EL n l))` >>
           `vv = SND (EL n new_env)` by (
             simp[Abbr`vv`,Abbr`new_env`,EL_MAP] ) >>
           qunabbrev_tac`vv` >>
           pop_assum SUBST1_TAC ) >>
         HINT_EXISTS_TAC >> simp[] >>
         rator_x_assum`to_i2_invariant`mp_tac >>
         simp[to_i2_invariant_def] >> strip_tac >>
         rator_x_assum`LIST_REL` mp_tac >>
         simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
         simp[optionTheory.OPTREL_def] >> strip_tac >>
         disch_then(qspec_then`m2 ' pv`mp_tac) >> simp[] >>
         strip_tac >> HINT_EXISTS_TAC >> simp[] >>
         rator_x_assum`store_to_exh`mp_tac >>
         simp[store_to_exh_csg_rel,csg_rel_unpair] >> strip_tac >>
         pop_assum mp_tac >>
         simp[Once FUNION_COMM] >>
         simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
         simp[optionTheory.OPTREL_def] >> strip_tac >>
         disch_then(qspec_then`m2 ' pv`mp_tac) >> simp[] >>
         strip_tac >> HINT_EXISTS_TAC >> simp[] >>
         simp[exh_Cv_def,PULL_EXISTS] >>
         HINT_EXISTS_TAC >> simp[] >>
         rator_x_assum`csg_rel`mp_tac >>
         simp[csg_rel_unpair] >> strip_tac >> pop_assum mp_tac >>
         simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
         simp[optionTheory.OPTREL_def] >> strip_tac >>
         disch_then(qspec_then`m2 ' pv`mp_tac) >> simp[] >>
         strip_tac >>
         rator_x_assum`csg_rel`mp_tac >>
         simp[csg_rel_unpair] >> strip_tac >> pop_assum mp_tac >>
         simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
         simp[optionTheory.OPTREL_def] >> strip_tac >>
         disch_then(qspec_then`m2 ' pv`mp_tac) >> simp[] >>
         strip_tac >>
         rator_x_assum`csg_rel`mp_tac >>
         simp[csg_rel_unpair] >> strip_tac >> pop_assum mp_tac >>
         simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
         simp[optionTheory.OPTREL_def,map_count_store_genv_def] >> strip_tac >>
         disch_then(qspec_then`m2 ' pv`mp_tac) >> simp[EL_MAP] >>
         strip_tac >> BasicProvers.VAR_EQ_TAC >>
         qmatch_assum_rename_tac`syneq (v_to_Cv vp) zz`[] >>
         qexists_tac`vp` >>
         `closed_pat vp` by (
           first_x_assum(mp_tac o MATCH_MP (CONJUNCT1 evaluate_pat_closed)) >>
           simp[csg_closed_pat_def] >>
           simp[EVERY_MEM,MEM_EL,PULL_EXISTS] >>
           disch_then(qspec_then`m2 ' pv`mp_tac o CONJUNCT2) >>
           simp[] ) >>
         simp[] >>
         reverse conj_tac >- metis_tac[syneq_trans] >>
         rator_x_assum`csg_rel`mp_tac >>
         simp[csg_rel_unpair] >> strip_tac >> pop_assum mp_tac >>
         simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
         simp[optionTheory.OPTREL_def,map_count_store_genv_def] >>
         disch_then(qspec_then`m2 ' pv`mp_tac) >> simp[EL_MAP])) >>
      fs[csg_rel_unpair,map_count_store_genv_def] >>
      qsuff_tac`F`>-rw[]>>
      pop_assum kall_tac >> pop_assum mp_tac >> simp[] >>
      qmatch_abbrev_tac`EL nn l2 ≠ NONE` >>
      imp_res_tac EVERY2_LENGTH >> fs[store_to_exh_csg_rel] >>
      qpat_assum`LIST_REL R X l2`mp_tac >>
      simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
      simp[optionTheory.OPTREL_def] >>
      disch_then(qspec_then`nn`mp_tac) >> simp[] >>
      reverse strip_tac >> simp[] >>
      pop_assum kall_tac >> pop_assum mp_tac >> simp[Abbr`l2`] >>
      qmatch_abbrev_tac`EL nn l2 ≠ NONE` >>
      qpat_assum`LIST_REL R X l2`mp_tac >>
      simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
      simp[optionTheory.OPTREL_def] >>
      disch_then(qspec_then`nn`mp_tac) >> simp[] >>
      reverse strip_tac >> simp[] >>
      pop_assum kall_tac >> pop_assum mp_tac >> simp[Abbr`l2`] >>
      qmatch_abbrev_tac`EL nn l2 ≠ NONE` >>
      qpat_assum`LIST_REL R X l2`mp_tac >>
      simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
      simp[optionTheory.OPTREL_def] >>
      disch_then(qspec_then`nn`mp_tac) >> simp[] >>
      reverse strip_tac >> simp[] >>
      pop_assum kall_tac >> pop_assum mp_tac >> simp[Abbr`l2`] >>
      simp[EL_MAP] >>
      qmatch_abbrev_tac`EL nn l2 ≠ NONE` >>
      qpat_assum`LIST_REL R X l2`mp_tac >>
      simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
      simp[optionTheory.OPTREL_def] >>
      disch_then(qspec_then`nn`mp_tac) >> simp[] >>
      reverse strip_tac >> simp[] >>
      pop_assum kall_tac >> pop_assum mp_tac >> simp[Abbr`l2`] >>
      simp[EL_MAP] >>
      qmatch_abbrev_tac`EL nn l2 ≠ NONE` >>
      fs[csg_rel_unpair] >>
      qpat_assum`LIST_REL R X l2`mp_tac >>
      simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
      simp[optionTheory.OPTREL_def] >> strip_tac >>
      disch_then(qspec_then`nn`mp_tac) >> simp[] >>
      reverse strip_tac >> simp[] >>
      pop_assum kall_tac >> pop_assum mp_tac >> simp[Abbr`l2`] >>
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >> strip_tac >>
      rator_x_assum`LIST_REL` mp_tac >>
      simp[EVERY2_EVERY,GSYM AND_IMP_INTRO,EVERY_MEM,MEM_ZIP,PULL_EXISTS] >>
      simp[optionTheory.OPTREL_def] >>
      disch_then(qspec_then`nn`mp_tac) >> simp[] >>
      strip_tac >> simp[] ) >>
    simp[Abbr`P`,Abbr`Q`,Abbr`R`,Abbr`Z`] >>
    strip_tac >>
    qmatch_assum_abbrev_tac`bc_next^* bs bs1` >>
    qmatch_assum_abbrev_tac`bc_next^* bs1' bs2` >>
    `bs1' = bs1` by (
      simp[Abbr`bs1`,Abbr`bs1'`] >>
      simp[REVERSE_APPEND] ) >>
    qexists_tac`bs2` >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_tac >- metis_tac[RTC_TRANSITIVE,transitive_def] >>
    conj_tac >- (
      simp[Abbr`bs2`] >>
      simp[optionTheory.option_case_compute] >>
      simp[print_result_def] >>
      Q.PAT_ABBREV_TAC`b = IS_SOME Z` >>
      Cases_on`b = F` >> simp[] >>
      qunabbrev_tac`b` >>
      fs[GSYM quantHeuristicsTheory.IS_SOME_EQ_NOT_NONE,IS_SOME_EXISTS] >>
      last_x_assum mp_tac >>
      BasicProvers.CASE_TAC >>
      simp[Once evaluate_dec_cases] >>
      simp[libTheory.emp_def] >> strip_tac >>
      simp[print_envC_def,Q.SPECL[`X`,`[]`]print_envE_def,libTheory.bind_def] >>
      match_mp_tac print_bv_list_print_envE >>
      rpt BasicProvers.VAR_EQ_TAC >>
      HINT_EXISTS_TAC >>
      imp_res_tac pmatch_dom >> fs[] >>
      qpat_assum`X ⊆ y`mp_tac >> simp[new_top_vs_def] >>
      simp[build_rec_env_MAP,MAP_MAP_o,combinTheory.o_DEF,UNCURRY,ETA_AX]) >>
    simp[EXISTS_PROD,libTheory.emp_def,merge_envC_def,libTheory.merge_def] >>
    PairCases_on`s2` >> simp[env_rs_def] >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_asm1_tac >- (
      rpt (rator_x_assum`good_labels`mp_tac) >> simp[Abbr`bs2`] >>
      rpt (rator_x_assum`between_labels`mp_tac) >>
      rpt (BasicProvers.VAR_EQ_TAC) >>
      rpt (pop_assum kall_tac) >>
      simp[good_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,PULL_EXISTS
          ,EVERY_FILTER,between_labels_def,EVERY_MAP,EVERY_MEM,between_def,PULL_FORALL] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    qexists_tac`grd0 ++ new_genv` >>
    conj_tac >- (
      rpt(BasicProvers.VAR_EQ_TAC) >> simp[] >>
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >> strip_tac >>
      imp_res_tac EVERY2_LENGTH >> rfs[] ) >>
    conj_tac >- simp[Abbr`bs2`] >>
    ONCE_REWRITE_TAC[CONJ_ASSOC] >>
    conj_tac >- (
      first_x_assum(mp_tac o MATCH_MP evaluate_dec_closed) >>
      fs[closed_top_def,all_env_closed_def]) >>
    conj_tac >- (
      simp[EVERY_APPEND] >>
      first_x_assum(mp_tac o MATCH_MP evaluate_prompt_i1_closed) >> simp[] >>
      REWRITE_TAC[IMP_CONJ_THM] >> strip_tac >> first_x_assum match_mp_tac >> pop_assum kall_tac >>
      fs[to_i1_invariant_def] >>
      fs[Once s_to_i1_cases] >>
      reverse conj_tac >- (
        fs[EVERY_sv_every_EVERY_store_vs] >>
        (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
        simp[vs_to_i1_MAP] >>
        fs[sv_to_i1_sv_rel] >>
        imp_res_tac LIST_REL_store_vs_intro >>
        first_assum(match_exists_tac o concl) >> simp[]) >>
      first_x_assum(strip_assume_tac o MATCH_MP FV_top_to_i1) >>
      fs[closed_top_def,all_env_dom_def] >>
      simp[EXTENSION] >> rw[] >>
      CCONTR_TAC >> fs[] >> res_tac >> fs[] >> rw[] >>
      imp_res_tac global_env_inv_inclusion >>
      fs[SUBSET_DEF] >>
      res_tac >> fs[]) >>
    rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
    fs[libTheory.emp_def] >>
    `FST s2_i1 = s20'` by (
      rator_x_assum`to_i1_invariant`mp_tac >>
      simp[to_i1_invariant_def] >>
      simp[Once s_to_i1_cases,PULL_EXISTS] ) >>
    first_assum(split_pair_match o concl) >> fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[merge_envC_def,libTheory.merge_def] >>
    `FST s2_i2 = s20'` by (
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >>
      simp[Once s_to_i2_cases,PULL_EXISTS] ) >>
    PairCases_on`s2_i2`>>fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    PairCases_on`s'` >>
    fs[store_to_exh_def,sv_to_exh_sv_rel] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    simp[sv_rel_O,OPTREL_O,LIST_REL_O,PULL_EXISTS] >>
    simp[Once(GSYM CONJ_ASSOC)] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    simp[Once CONJ_COMM] >>
    simp[Once(GSYM CONJ_ASSOC)] >>
    simp[Once(GSYM CONJ_ASSOC)] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    qexists_tac`rd'` >>
    qho_match_abbrev_tac`∃B A. P A ∧ R A B ∧ Q B` >>
    qsuff_tac`∃A B. (P A ∧ Q B) ∧ R A B` >- metis_tac[] >>
    map_every qunabbrev_tac[`P`,`Q`,`R`] >> simp[] >>
    qexists_tac`SND s''` >>
    qexists_tac`SND(FST s'')` >>
    conj_tac >- tac7 >>
    tac4) >>
  strip_tac >- (
    simp[] >>
    rpt gen_tac >> strip_tac >>
    rpt gen_tac >>
    simp[compile_top_def] >>
    Q.PAT_ABBREV_TAC`non = (none_tag,(X:tid_or_exn option))` >>
    Q.PAT_ABBREV_TAC`som = (some_tag,(X:tid_or_exn option))` >>
    strip_tac >>
    `∃m10 m20. rs.globals_env = (m10,m20)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    qspecl_then[`m10`,`m20`,`Tdec d`]mp_tac top_to_i1_correct >>
    PairCases_on`grd`>>PairCases_on`env`>>PairCases_on`s1`>>fs[env_rs_def] >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    `∃v m1 m2 p1. top_to_i1 rs.next_global m10 m20 (Tdec d) = (v,m1,m2,p1)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    simp[Once evaluate_top_cases] >>
    simp_tac(srw_ss()++DNF_ss)[] >>
    disch_then(mp_tac o CONJUNCT2) >> rfs[] >>
    ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    discharge_hyps >- simp[] >>
    disch_then(qx_choosel_then[`s2_i1`,`new_genv`,`err_i1`]strip_assume_tac) >>
    `∃c exh p. prompt_to_i2 rs.contags_env p1 = (c,exh,p)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      CONV_RULE (
        ONCE_REWRITE_CONV[CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[CONJ_COMM] THENC
        ONCE_REWRITE_CONV[GSYM CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[GSYM AND_IMP_INTRO]) prompt_to_i2_correct))) >>
    REWRITE_TAC[Once EQ_SYM_EQ] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    simp[] >>
    discharge_hyps >- (
      fs[result_to_i1_cases] >> fs[] >>
      fs[top_to_i1_def,LET_THM,UNCURRY] >>
      rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
      simp[dec_to_i1_def] >>
      BasicProvers.CASE_TAC >> simp[not_mod_decs_def] ) >>
    disch_then(qx_choosel_then[`new_genv_i2`,`s2_i2`,`res_i2`,`gtagenv2`]strip_assume_tac) >>
    `∃n e. prompt_to_i3 non som (LENGTH grd0) p = (n,e)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
        prompt_to_i3_correct))) >>
    simp[] >>
    `LENGTH genv2 = LENGTH grd0` by (
      fs[to_i2_invariant_def] >>
      imp_res_tac EVERY2_LENGTH >>
      fs[] ) >>
    simp[] >>
    simp[Once result_to_i3_cases] >>
    discharge_hyps >- (
      fs[result_to_i2_cases,result_to_i1_cases] >> fs[] ) >>
    reverse strip_tac >- (
      fs[result_to_i2_cases,result_to_i1_cases] >> fs[] ) >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_exh_correct)) >>
    simp[] >> simp[env_to_exh_MAP] >>
    fs[LIST_REL_O,OPTREL_O,sv_rel_O] >>
    qmatch_assum_rename_tac`LIST_REL (sv_rel (v_to_exh rs.exh)) s20 sh`[] >>
    qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
    `store_to_exh (exh ⊌ rs.exh) ((s10,s20),genv2) ((s10,sh),gh)` by tac1 >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    simp[Once result_to_exh_cases] >>
    disch_then(qspec_then`exh ⊌ rs.exh`mp_tac) >> simp[] >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_pat_correct)) >>
    simp[] >>
    disch_then(qx_choosel_then[`res4`]strip_assume_tac) >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
    simp[] >>
    discharge_hyps_keep >- tac2 >>
    disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
    qpat_assum`X = bc`mp_tac >>
    specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
    simp[] >> strip_tac >>
    first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
    simp[] >>
    Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
    qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
    disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
    discharge_hyps >- tac3 >>
    strip_tac >>
    first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    specl_args_of_then``compile_print_top``compile_print_top_thm mp_tac >>
    simp[] >>
    disch_then(qx_choose_then`bcp`strip_assume_tac) >>
    disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
    discharge_hyps >- (
      simp[Abbr`Csg`] >>
      fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
    strip_tac >>
    rator_x_assum`v_to_exh`mp_tac >>
    simp[Once v_to_exh_cases,vs_to_exh_MAP] >>
    strip_tac >> ntac 2 BasicProvers.VAR_EQ_TAC >>
    rator_x_assum`v_pat`mp_tac >>
    simp[Once v_pat_cases] >>
    strip_tac >> ntac 2 BasicProvers.VAR_EQ_TAC >>
    fs[] >>
    rpt (
      qpat_assum`syneq (CConv X Y) Z`mp_tac >>
      simp[Once syneq_cases] >> strip_tac >>
      ntac 2 BasicProvers.VAR_EQ_TAC ) >>
    strip_tac >>
    rator_x_assum`code_for_push`mp_tac >>
    simp[code_for_push_def,PULL_EXISTS] >>
    rpt gen_tac >> strip_tac >>
    rator_x_assum`Cv_bv`mp_tac >>
    simp[Once Cv_bv_cases] >> strip_tac >>
    ntac 2 BasicProvers.VAR_EQ_TAC >>
    qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
    `bc_next^* bs (bs1 with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs0`,`bs1`] >>
      simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] >>
      rw[] ) >>
    first_x_assum(qspec_then`bs1 with code := bs.code`mp_tac) >>
    simp[] >> BasicProvers.VAR_EQ_TAC >> simp[] >>
    simp[Abbr`bs1`] >>
    simp[Abbr`som`] >>
    `some_tag ≠ none_tag` by EVAL_TAC >> simp[] >>
    discharge_hyps_keep >- (
      reverse conj_tac >- metis_tac[Cv_bv_can_Print] >>
      fs[good_labels_def,between_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND
        ,MEM_FILTER,is_Label_rwt,PULL_EXISTS,EVERY_FILTER,EVERY_MEM,PULL_FORALL
        ,MEM_MAP,between_def] >>
      rw[] >> res_tac >> fsrw_tac[ARITH_ss][] >>
      spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    qmatch_assum_abbrev_tac`bc_next^* bs bs1` >>
    strip_tac >>
    qmatch_assum_abbrev_tac`bc_next^* bs1' bs2` >>
    `bs1' = bs1` by (
      simp[Abbr`bs1`,Abbr`bs1'`,bc_state_component_equality] ) >>
    qexists_tac`bs2` >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_tac >- metis_tac[RTC_TRANSITIVE,transitive_def] >>
    Cases_on`err`>>fs[] >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_tac >- tac5() >>
    PairCases_on`s2` >> simp[env_rs_def,EXISTS_PROD] >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_asm1_tac >- (
      rpt (rator_x_assum`good_labels`mp_tac) >> simp[Abbr`bs2`] >>
      rpt (rator_x_assum`between_labels`mp_tac) >>
      rpt (BasicProvers.VAR_EQ_TAC) >>
      rpt (pop_assum kall_tac) >>
      simp[good_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,PULL_EXISTS
          ,EVERY_FILTER,between_labels_def,EVERY_MAP,EVERY_MEM,between_def,PULL_FORALL] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    qexists_tac`grd0 ++ new_genv` >>
    conj_tac >- (
      rpt(BasicProvers.VAR_EQ_TAC) >> simp[] >>
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >> strip_tac >>
      imp_res_tac EVERY2_LENGTH >> rfs[] ) >>
    conj_tac >- simp[Abbr`bs2`] >>
    ONCE_REWRITE_TAC[CONJ_ASSOC] >>
    conj_tac >- (
      simp[EVERY_APPEND] >>
      first_x_assum(mp_tac o MATCH_MP evaluate_prompt_i1_closed) >> simp[] >>
      discharge_hyps >- (
        fs[to_i1_invariant_def] >>
        fs[Once s_to_i1_cases] >>
        reverse conj_tac >- (
          fs[EVERY_sv_every_EVERY_store_vs] >>
          (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
          simp[vs_to_i1_MAP] >>
          fs[sv_to_i1_sv_rel] >>
          imp_res_tac LIST_REL_store_vs_intro >>
          first_assum(match_exists_tac o concl) >> simp[]) >>
        first_x_assum(strip_assume_tac o MATCH_MP FV_top_to_i1) >>
        fs[closed_top_def,all_env_dom_def] >>
        simp[EXTENSION] >> rw[] >>
        CCONTR_TAC >> fs[] >> res_tac >> fs[] >> rw[] >>
        imp_res_tac global_env_inv_inclusion >>
        fs[SUBSET_DEF] >>
        res_tac >> fs[]) >>
      simp[] >> strip_tac >>
      first_x_assum(mp_tac o MATCH_MP evaluate_dec_closed) >>
      fs[closed_top_def,all_env_closed_def]) >>
    rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
    fs[libTheory.emp_def] >>
    `FST s2_i1 = s20'` by (
      rator_x_assum`to_i1_invariant`mp_tac >>
      simp[to_i1_invariant_def] >>
      simp[Once s_to_i1_cases,PULL_EXISTS] ) >>
    first_assum(split_pair_match o concl) >> fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[merge_envC_def,libTheory.merge_def] >>
    `FST s2_i2 = s20'` by (
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >>
      simp[Once s_to_i2_cases,PULL_EXISTS] ) >>
    PairCases_on`s2_i2`>>fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    tac6 >>
    conj_tac >- tac7 >>
    tac4) >>
  strip_tac >- (
    simp[] >>
    rpt gen_tac >> strip_tac >>
    rpt gen_tac >>
    simp[compile_top_def] >>
    Q.PAT_ABBREV_TAC`non = (none_tag,(X:tid_or_exn option))` >>
    Q.PAT_ABBREV_TAC`som = (some_tag,(X:tid_or_exn option))` >>
    strip_tac >>
    `∃m10 m20. rs.globals_env = (m10,m20)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    qspecl_then[`m10`,`m20`,`Tmod mn specs ds`]mp_tac top_to_i1_correct >>
    PairCases_on`grd`>>PairCases_on`env`>>PairCases_on`s1`>>fs[env_rs_def] >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    `∃v m1 m2 p1. top_to_i1 rs.next_global m10 m20 (Tmod mn specs ds) = (v,m1,m2,p1)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    simp[Once evaluate_top_cases] >>
    simp_tac(srw_ss()++DNF_ss)[] >>
    disch_then(mp_tac o CONJUNCT1) >> rfs[] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    disch_then(qx_choosel_then[`s2_i1`,`new_genv`]strip_assume_tac) >>
    `∃c exh p. prompt_to_i2 rs.contags_env p1 = (c,exh,p)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      CONV_RULE (
        ONCE_REWRITE_CONV[CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[CONJ_COMM] THENC
        ONCE_REWRITE_CONV[GSYM CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[GSYM AND_IMP_INTRO]) prompt_to_i2_correct))) >>
    REWRITE_TAC[Once EQ_SYM_EQ] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    simp[] >>
    discharge_hyps >- (
      fs[top_to_i1_def,LET_THM,UNCURRY] >>
      rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
      MATCH_ACCEPT_TAC mod_decs_decs_to_i1) >>
    disch_then(qx_choosel_then[`new_genv_i2`,`s2_i2`,`gtagenv2`]strip_assume_tac) >>
    `∃n e. prompt_to_i3 non som (LENGTH grd0) p = (n,e)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
        prompt_to_i3_correct))) >>
    simp[] >>
    `LENGTH genv2 = LENGTH grd0` by (
      fs[to_i2_invariant_def] >>
      imp_res_tac EVERY2_LENGTH >>
      fs[] ) >>
    simp[] >>
    simp[Once result_to_i3_cases] >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_exh_correct)) >>
    simp[] >> simp[env_to_exh_MAP] >>
    fs[LIST_REL_O,OPTREL_O,sv_rel_O] >>
    qmatch_assum_rename_tac`LIST_REL (sv_rel (v_to_exh rs.exh)) s20 sh`[] >>
    qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
    `store_to_exh (exh ⊌ rs.exh) ((s10,s20),genv2) ((s10,sh),gh)` by tac1 >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    simp[Once result_to_exh_cases] >>
    disch_then(qspec_then`exh ⊌ rs.exh`mp_tac) >> simp[] >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_pat_correct)) >>
    simp[] >>
    disch_then(qx_choosel_then[`res4`]strip_assume_tac) >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
    simp[] >>
    discharge_hyps_keep >- tac2 >>
    disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
    qpat_assum`X = bc`mp_tac >>
    specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
    simp[] >> strip_tac >>
    first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
    simp[] >>
    Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
    qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
    disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
    discharge_hyps >- tac3 >>
    strip_tac >>
    first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    specl_args_of_then``compile_print_top``compile_print_top_thm mp_tac >>
    simp[] >>
    disch_then(qx_choose_then`bcp`strip_assume_tac) >>
    disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
    discharge_hyps >- (
      simp[Abbr`Csg`] >>
      fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
    strip_tac >>
    rator_x_assum`v_to_exh`mp_tac >>
    simp[Once v_to_exh_cases,vs_to_exh_MAP] >>
    strip_tac >> BasicProvers.VAR_EQ_TAC >>
    rator_x_assum`v_pat`mp_tac >>
    simp[Once v_pat_cases] >>
    strip_tac >> BasicProvers.VAR_EQ_TAC >>
    rpt (
      qpat_assum`syneq (X Y) Z`mp_tac >>
      simp[Once syneq_cases] >> strip_tac >>
      BasicProvers.VAR_EQ_TAC ) >>
    strip_tac >>
    rator_x_assum`code_for_push`mp_tac >>
    simp[code_for_push_def,PULL_EXISTS] >>
    rpt gen_tac >> strip_tac >>
    rator_x_assum`Cv_bv`mp_tac >>
    simp[Once Cv_bv_cases] >> strip_tac >>
    BasicProvers.VAR_EQ_TAC >>
    qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
    `bc_next^* bs (bs1 with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs0`,`bs1`] >>
      simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] >>
      rw[] ) >>
    first_x_assum(qspec_then`bs1 with code := bs.code`mp_tac) >>
    simp[] >> BasicProvers.VAR_EQ_TAC >> simp[] >>
    simp[Abbr`bs1`] >>
    simp[Abbr`non`] >>
    discharge_hyps_keep >- (
      fs[good_labels_def,between_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND
        ,MEM_FILTER,is_Label_rwt,PULL_EXISTS,EVERY_FILTER,EVERY_MEM,PULL_FORALL
        ,MEM_MAP,between_def] >>
      rw[] >> res_tac >> fsrw_tac[ARITH_ss][] >>
      spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    strip_tac >>
    qmatch_assum_abbrev_tac`bc_next^* bs bs1` >>
    qmatch_assum_abbrev_tac`bc_next^* bs1' bs2` >>
    `bs1' = bs1` by (
      simp[Abbr`bs1`,Abbr`bs1'`] >>
      simp[REVERSE_APPEND] ) >>
    qexists_tac`bs2` >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_tac >- metis_tac[RTC_TRANSITIVE,transitive_def] >>
    conj_tac >- (
      simp[Abbr`bs2`] >>
      simp[optionTheory.option_case_compute] >>
      simp[print_result_def] ) >>
    simp[EXISTS_PROD,libTheory.emp_def,merge_envC_def,libTheory.merge_def] >>
    PairCases_on`s2` >> simp[env_rs_def] >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_asm1_tac >- (
      rpt (rator_x_assum`good_labels`mp_tac) >> simp[Abbr`bs2`] >>
      rpt (rator_x_assum`between_labels`mp_tac) >>
      rpt (BasicProvers.VAR_EQ_TAC) >>
      rpt (pop_assum kall_tac) >>
      simp[good_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,PULL_EXISTS
          ,EVERY_FILTER,between_labels_def,EVERY_MAP,EVERY_MEM,between_def,PULL_FORALL] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    qexists_tac`grd0 ++ new_genv` >>
    conj_tac >- (
      rpt(BasicProvers.VAR_EQ_TAC) >> simp[] >>
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >> strip_tac >>
      imp_res_tac EVERY2_LENGTH >> rfs[] ) >>
    conj_tac >- simp[Abbr`bs2`] >>
    ONCE_REWRITE_TAC[CONJ_ASSOC] >>
    conj_tac >- (
      first_x_assum(mp_tac o MATCH_MP evaluate_decs_closed) >>
      fs[closed_top_def,all_env_closed_def]) >>
    conj_tac >- (
      simp[EVERY_APPEND] >>
      first_x_assum(mp_tac o MATCH_MP evaluate_prompt_i1_closed) >> simp[] >>
      REWRITE_TAC[IMP_CONJ_THM] >> strip_tac >> first_x_assum match_mp_tac >> pop_assum kall_tac >>
      fs[to_i1_invariant_def] >>
      fs[Once s_to_i1_cases] >>
      reverse conj_tac >- (
        fs[EVERY_sv_every_EVERY_store_vs] >>
        (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
        simp[vs_to_i1_MAP] >>
        fs[sv_to_i1_sv_rel] >>
        imp_res_tac LIST_REL_store_vs_intro >>
        first_assum(match_exists_tac o concl) >> simp[]) >>
      first_x_assum(strip_assume_tac o MATCH_MP FV_top_to_i1) >>
      fs[closed_top_def,all_env_dom_def] >>
      simp[EXTENSION] >> rw[] >>
      CCONTR_TAC >> fs[] >> res_tac >> fs[] >> rw[] >>
      imp_res_tac global_env_inv_inclusion >>
      fs[SUBSET_DEF] >>
      res_tac >> fs[]) >>
    rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
    fs[libTheory.emp_def] >>
    `FST s2_i1 = s20'` by (
      rator_x_assum`to_i1_invariant`mp_tac >>
      simp[to_i1_invariant_def] >>
      simp[Once s_to_i1_cases,PULL_EXISTS] ) >>
    first_assum(split_pair_match o concl) >> fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[merge_envC_def,libTheory.merge_def] >>
    `FST s2_i2 = s20'` by (
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >>
      simp[Once s_to_i2_cases,PULL_EXISTS] ) >>
    PairCases_on`s2_i2`>>fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    tac6 >>
    conj_tac >- tac7 >>
    tac4) >>
  strip_tac >- (
    simp[] >>
    rpt gen_tac >> strip_tac >>
    rpt gen_tac >>
    simp[compile_top_def] >>
    Q.PAT_ABBREV_TAC`non = (none_tag,(X:tid_or_exn option))` >>
    Q.PAT_ABBREV_TAC`som = (some_tag,(X:tid_or_exn option))` >>
    strip_tac >>
    `∃m10 m20. rs.globals_env = (m10,m20)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    qspecl_then[`m10`,`m20`,`Tmod mn specs ds`]mp_tac top_to_i1_correct >>
    PairCases_on`grd`>>PairCases_on`env`>>PairCases_on`s1`>>fs[env_rs_def] >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    `∃v m1 m2 p1. top_to_i1 rs.next_global m10 m20 (Tmod mn specs ds) = (v,m1,m2,p1)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    simp[Once evaluate_top_cases] >>
    simp_tac(srw_ss()++DNF_ss)[] >>
    disch_then(mp_tac o CONJUNCT2) >> rfs[] >>
    ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    discharge_hyps >- simp[] >>
    disch_then(qx_choosel_then[`s2_i1`,`new_genv`,`err_i1`]strip_assume_tac) >>
    `∃c exh p. prompt_to_i2 rs.contags_env p1 = (c,exh,p)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      CONV_RULE (
        ONCE_REWRITE_CONV[CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[CONJ_COMM] THENC
        ONCE_REWRITE_CONV[GSYM CONJ_ASSOC] THENC
        ONCE_REWRITE_CONV[GSYM AND_IMP_INTRO]) prompt_to_i2_correct))) >>
    REWRITE_TAC[Once EQ_SYM_EQ] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    REWRITE_TAC[Once CONJ_COMM] >>
    REWRITE_TAC[Once (GSYM CONJ_ASSOC)] >>
    REWRITE_TAC[Once (GSYM AND_IMP_INTRO)] >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
    simp[] >>
    discharge_hyps >- (
      fs[result_to_i1_cases] >> fs[] >>
      fs[top_to_i1_def,LET_THM,UNCURRY] >>
      rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
      MATCH_ACCEPT_TAC mod_decs_decs_to_i1) >>
    disch_then(qx_choosel_then[`new_genv_i2`,`s2_i2`,`res_i2`,`gtagenv2`]strip_assume_tac) >>
    `∃n e. prompt_to_i3 non som (LENGTH grd0) p = (n,e)` by simp[GSYM EXISTS_PROD] >> fs[] >>
    first_assum (mp_tac o (MATCH_MP (
      ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
        prompt_to_i3_correct))) >>
    simp[] >>
    `LENGTH genv2 = LENGTH grd0` by (
      fs[to_i2_invariant_def] >>
      imp_res_tac EVERY2_LENGTH >>
      fs[] ) >>
    simp[] >>
    simp[Once result_to_i3_cases] >>
    discharge_hyps >- (
      fs[result_to_i2_cases,result_to_i1_cases] >> fs[] ) >>
    reverse strip_tac >- (
      fs[result_to_i2_cases,result_to_i1_cases] >> fs[] ) >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_exh_correct)) >>
    simp[] >> simp[env_to_exh_MAP] >>
    fs[LIST_REL_O,OPTREL_O,sv_rel_O] >>
    qmatch_assum_rename_tac`LIST_REL (sv_rel (v_to_exh rs.exh)) s20 sh`[] >>
    qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
    `store_to_exh (exh ⊌ rs.exh) ((s10,s20),genv2) ((s10,sh),gh)` by tac1 >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    simp[Once result_to_exh_cases] >>
    disch_then(qspec_then`exh ⊌ rs.exh`mp_tac) >> simp[] >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_pat_correct)) >>
    simp[] >>
    disch_then(qx_choosel_then[`res4`]strip_assume_tac) >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
    simp[] >>
    discharge_hyps_keep >- tac2 >>
    disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
    qpat_assum`X = bc`mp_tac >>
    specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
    simp[] >> strip_tac >>
    first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
    simp[] >>
    Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
    qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
    disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
    discharge_hyps >- tac3 >>
    strip_tac >>
    first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    specl_args_of_then``compile_print_top``compile_print_top_thm mp_tac >>
    simp[] >>
    disch_then(qx_choose_then`bcp`strip_assume_tac) >>
    disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
    discharge_hyps >- (
      simp[Abbr`Csg`] >>
      fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
    strip_tac >>
    rator_x_assum`v_to_exh`mp_tac >>
    simp[Once v_to_exh_cases,vs_to_exh_MAP] >>
    strip_tac >> ntac 2 BasicProvers.VAR_EQ_TAC >>
    rator_x_assum`v_pat`mp_tac >>
    simp[Once v_pat_cases] >>
    strip_tac >> ntac 2 BasicProvers.VAR_EQ_TAC >>
    fs[] >>
    rpt (
      qpat_assum`syneq (CConv X Y) Z`mp_tac >>
      simp[Once syneq_cases] >> strip_tac >>
      ntac 2 BasicProvers.VAR_EQ_TAC ) >>
    strip_tac >>
    rator_x_assum`code_for_push`mp_tac >>
    simp[code_for_push_def,PULL_EXISTS] >>
    rpt gen_tac >> strip_tac >>
    rator_x_assum`Cv_bv`mp_tac >>
    simp[Once Cv_bv_cases] >> strip_tac >>
    ntac 2 BasicProvers.VAR_EQ_TAC >>
    qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
    `bc_next^* bs (bs1 with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs0`,`bs1`] >>
      simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] >>
      rw[] ) >>
    first_x_assum(qspec_then`bs1 with code := bs.code`mp_tac) >>
    simp[] >> BasicProvers.VAR_EQ_TAC >> simp[] >>
    simp[Abbr`bs1`] >>
    simp[Abbr`som`] >>
    `some_tag ≠ none_tag` by EVAL_TAC >> simp[] >>
    discharge_hyps_keep >- (
      reverse conj_tac >- metis_tac[Cv_bv_can_Print] >>
      fs[good_labels_def,between_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND
        ,MEM_FILTER,is_Label_rwt,PULL_EXISTS,EVERY_FILTER,EVERY_MEM,PULL_FORALL
        ,MEM_MAP,between_def] >>
      rw[] >> res_tac >> fsrw_tac[ARITH_ss][] >>
      spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    qmatch_assum_abbrev_tac`bc_next^* bs bs1` >>
    strip_tac >>
    qmatch_assum_abbrev_tac`bc_next^* bs1' bs2` >>
    `bs1' = bs1` by (
      simp[Abbr`bs1`,Abbr`bs1'`,bc_state_component_equality] ) >>
    qexists_tac`bs2` >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_tac >- metis_tac[RTC_TRANSITIVE,transitive_def] >>
    Cases_on`err`>>fs[] >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_tac >- tac5() >>
    PairCases_on`s2` >> simp[env_rs_def,EXISTS_PROD] >>
    simp[RIGHT_EXISTS_AND_THM] >>
    conj_asm1_tac >- (
      rpt (rator_x_assum`good_labels`mp_tac) >> simp[Abbr`bs2`] >>
      rpt (rator_x_assum`between_labels`mp_tac) >>
      rpt (BasicProvers.VAR_EQ_TAC) >>
      rpt (pop_assum kall_tac) >>
      simp[good_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,PULL_EXISTS
          ,EVERY_FILTER,between_labels_def,EVERY_MAP,EVERY_MEM,between_def,PULL_FORALL] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    qexists_tac`grd0 ++ new_genv` >>
    conj_tac >- (
      rpt(BasicProvers.VAR_EQ_TAC) >> simp[] >>
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >> strip_tac >>
      imp_res_tac EVERY2_LENGTH >> rfs[] ) >>
    conj_tac >- simp[Abbr`bs2`] >>
    ONCE_REWRITE_TAC[CONJ_ASSOC] >>
    conj_tac >- (
      simp[EVERY_APPEND] >>
      first_x_assum(mp_tac o MATCH_MP evaluate_prompt_i1_closed) >> simp[] >>
      discharge_hyps >- (
        fs[to_i1_invariant_def] >>
        fs[Once s_to_i1_cases] >>
        reverse conj_tac >- (
          fs[EVERY_sv_every_EVERY_store_vs] >>
          (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
          simp[vs_to_i1_MAP] >>
          fs[sv_to_i1_sv_rel] >>
          imp_res_tac LIST_REL_store_vs_intro >>
          first_assum(match_exists_tac o concl) >> simp[]) >>
        first_x_assum(strip_assume_tac o MATCH_MP FV_top_to_i1) >>
        fs[closed_top_def,all_env_dom_def] >>
        simp[EXTENSION] >> rw[] >>
        CCONTR_TAC >> fs[] >> res_tac >> fs[] >> rw[] >>
        imp_res_tac global_env_inv_inclusion >>
        fs[SUBSET_DEF] >>
        res_tac >> fs[]) >>
      simp[] >> strip_tac >>
      first_x_assum(mp_tac o MATCH_MP evaluate_decs_closed) >>
      fs[closed_top_def,all_env_closed_def]) >>
    rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
    fs[libTheory.emp_def] >>
    `FST s2_i1 = s20'` by (
      rator_x_assum`to_i1_invariant`mp_tac >>
      simp[to_i1_invariant_def] >>
      simp[Once s_to_i1_cases,PULL_EXISTS] ) >>
    first_assum(split_pair_match o concl) >> fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[merge_envC_def,libTheory.merge_def] >>
    `FST s2_i2 = s20'` by (
      rator_x_assum`to_i2_invariant`mp_tac >>
      simp[to_i2_invariant_def] >>
      simp[Once s_to_i2_cases,PULL_EXISTS] ) >>
    PairCases_on`s2_i2`>>fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    tac6 >>
    conj_tac >- tac7 >>
    tac4) >>
  strip_tac >- simp[] >>
  simp[])

val compile_top_divergence = store_thm("compile_top_divergence",
  ``∀env stm top rs grd types bc0 bs ss sf code.
      (∀res. ¬evaluate_top F env stm top res) ∧
      closed_top env top ∧
      env_rs env stm grd rs (bs with code := bc0) ∧
      (compile_top types rs top = (ss,sf,code)) ∧
      bs.code = bc0 ++ REVERSE code ∧
      bs.pc = next_addr bs.inst_length bc0 ∧
      IS_SOME bs.clock
      ⇒
      ∃bs'. bc_next^* bs bs' ∧ bc_fetch bs' = SOME Tick ∧ bs'.clock = SOME 0 ∧ bs'.output = bs.output``,
  rw[closed_top_def] >>
  imp_res_tac not_evaluate_top_timeout >>
  fs[compile_top_def,LET_THM] >>
  first_assum (split_applied_pair_tac o lhs o concl) >> fs[] >>
  first_assum (split_pair_case_tac o lhs o concl) >> fs[] >>
  first_assum (split_applied_pair_tac o lhs o concl) >> fs[] >>
  first_assum (split_applied_pair_tac o lhs o concl) >> fs[] >>
  PairCases_on`env` >>
  PairCases_on`stm` >>
  PairCases_on`r` >>
  (top_to_i1_correct
   |> CONV_RULE
     ((lift_conjunct_conv(equal``evaluate_top`` o fst o strip_comb))
      |> LAND_CONV |> STRIP_QUANT_CONV)
   |> ONCE_REWRITE_RULE [GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  PairCases_on`grd`>>fs[env_rs_def] >> rfs[] >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  strip_tac >>
  (prompt_to_i2_correct
   |> ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_i1_cases] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  ONCE_REWRITE_TAC[EQ_SYM_EQ] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  discharge_hyps >- (
    Cases_on`top`>>fs[top_to_i1_def,LET_THM,UNCURRY] >>
    rpt BasicProvers.VAR_EQ_TAC >> simp[] >>
    TRY (MATCH_ACCEPT_TAC mod_decs_decs_to_i1) >>
    simp[dec_to_i1_def] >>
    BasicProvers.CASE_TAC >> simp[not_mod_decs_def] ) >>
  strip_tac >>
  (prompt_to_i3_correct
   |> ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_i2_cases] >>
  rpt BasicProvers.VAR_EQ_TAC >>
  simp[] >>
  ONCE_REWRITE_TAC[EQ_SYM_EQ] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  `LENGTH genv2 = LENGTH grd0` by (
    fs[to_i2_invariant_def] >>
    imp_res_tac EVERY2_LENGTH >>
    fs[] ) >>
  simp[] >>
  strip_tac >>
  (exp_to_exh_correct
   |> CONJUNCT1
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_i3_cases] >>
  simp[env_to_exh_MAP] >>
  fs[LIST_REL_O,OPTREL_O,sv_rel_O] >>
  qmatch_assum_rename_tac`LIST_REL (sv_rel (v_to_exh rs.exh)) s20 sh`[] >>
  qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
  `store_to_exh (exh ⊌ rs.exh) ((stm0,s20),genv2) ((stm0,sh),gh)` by tac1 >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
  disch_then(qspec_then`exh ⊌ rs.exh`mp_tac) >> simp[] >>
  strip_tac >>
  (exp_to_pat_correct
   |> CONJUNCT1
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_exh_cases] >>
  strip_tac >>
  first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
  simp[] >>
  discharge_hyps_keep >- tac2 >>
  disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
  qpat_assum`bs.code = X`mp_tac >>
  specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
  simp[] >> strip_tac >>
  first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
  simp[] >>
  Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
  qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
  disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
  discharge_hyps >- tac3 >>
  strip_tac >>
  first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
  specl_args_of_then``compile_print_top``compile_print_top_thm mp_tac >>
  simp[] >>
  disch_then(qx_choose_then`bcp`strip_assume_tac) >>
  disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
  discharge_hyps >- (
    simp[Abbr`Csg`] >>
    fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
  strip_tac >>
  strip_tac >>
  imp_res_tac RTC_bc_next_preserves >>
  qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
  `bc_next^* bs (bs1 with code := bs.code)` by (
    match_mp_tac RTC_bc_next_append_code >>
    map_every qexists_tac[`bs0`,`bs1`] >>
    simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] >>
    rw[] ) >>
  `bc_fetch (bs1 with code := bs.code) = SOME Tick` by (
    first_assum(mp_tac o (MATCH_MP (GEN_ALL bc_fetch_append_code))) >>
    simp[Abbr`bs0`,REVERSE_APPEND] ) >>
  HINT_EXISTS_TAC >>
  simp[Abbr`bs0`])

(* compile_prog *)

val compile_Cexp_code_ok_thm = prove(
  ``∀renv rsz cs exp cs'.
    (compile_Cexp renv rsz cs exp = cs') ⇒
    set (free_vars exp) ⊆ count (LENGTH renv) ∧
    no_labs exp ∧ (cs.out = []) ⇒
    code_labels_ok cs'.out``,
  rw[] >>
  qspecl_then[`renv`,`rsz`,`cs`,`exp`]mp_tac compile_Cexp_thm >>
  simp[] >> strip_tac >> simp[] >>
  PROVE_TAC[REVERSE_APPEND,code_labels_ok_REVERSE])

val compile_print_err_code_ok_thm = prove(
  ``∀cs cs'. (compile_print_err cs = cs') ⇒
             code_labels_ok cs.out ⇒
             code_labels_ok cs'.out``,
  rw[] >>
  qspec_then`cs`mp_tac compile_print_err_thm >>
  simp[] >> strip_tac >> simp[] >>
  match_mp_tac code_labels_ok_append >>
  simp[code_labels_ok_REVERSE])

val compile_prog_code_labels_ok = store_thm("compile_prog_code_labels_ok",
  ``∀prog code.
      (compile_prog prog = code) ∧ closed_prog prog ⇒
      code_labels_ok code``,
    rw[compile_prog_def] >>
    `∃a b c d. prog_to_i1 n m1 m2 prog = (a,b,c,d)` by simp[GSYM EXISTS_PROD] >>simp[] >>
    `∃e f g. prog_to_i2 init_compiler_state.contags_env d = (e,f,g)` by simp[GSYM EXISTS_PROD] >>simp[] >>
    (fn(g as (_,w)) => split_pair_case_tac (rand w) g) >> simp[] >>
    match_mp_tac code_labels_ok_append >>
    reverse conj_tac >- (match_mp_tac code_labels_ok_cons >> simp[]) >>
    simp[code_labels_ok_REVERSE] >>
    BasicProvers.CASE_TAC >> simp[] >>
    rpt(match_mp_tac code_labels_ok_cons >> simp[]) >>
    match_mp_tac (MP_CANON compile_print_err_code_ok_thm) >>
    (fn(g as (_,w)) => exists_tac (w |> dest_exists |> snd |> dest_conj |> fst |> rhs |> rand) g) >>
    simp[] >>
    match_mp_tac (MP_CANON compile_Cexp_code_ok_thm) >>
    (fn(g as (_,w)) => map_every exists_tac (w |> strip_exists |> snd |> dest_conj |> fst |> rhs |> strip_comb |> snd) g) >>
    simp[] >>
    specl_args_of_then``exp_to_pat``(CONJUNCT1 free_vars_pat_exp_to_pat)mp_tac >>
    simp[] >> disch_then match_mp_tac >>
    imp_res_tac free_vars_i2_prog_to_i3 >>
    imp_res_tac free_vars_prog_to_i2 >>
    imp_res_tac FV_prog_to_i1 >>
    simp[] >>
    fs[closed_prog_def,all_env_dom_def,SUBSET_DEF,PULL_EXISTS])

val compile_prog_thm = store_thm("compile_prog_thm",
  ``∀ck env stm prog res. evaluate_prog ck env stm prog res ⇒
     ∀grd rss rsf bc bs bc0.
      env_rs env stm grd init_compiler_state (bs with code := bc0) ∧
      closed_prog prog ∧
      (∀p. "it" ∈ FDOM (FST(SND(SND(prog_to_i1 0 FEMPTY FEMPTY prog)))) ∧
           SND(SND(res)) = Rval p ⇒ lookup "it" (SND p) ≠ NONE) ∧
      (bs.code = bc0 ++ compile_prog prog) ∧
      (bs.pc = next_addr bs.inst_length bc0) ∧
      ck ∧ IS_SOME bs.clock ∧
      SND(SND res) ≠ Rerr Rtype_error ∧
      SND(SND res) ≠ Rerr Rtimeout_error
      ⇒
      case res of (s,envC,env_or_err) =>
        ∃bs' grd'.
        bc_next^* bs bs' ∧
        let (success,str) =
          case env_or_err of Rval(envM,envE) =>
            (T,(case lookup "it" envE of NONE => "" | SOME v => (print_v v)++"\n"))
          | Rerr(Rraise v) =>
            (F,"raise "++(print_v v)++"\n") in
        bc_fetch bs' = SOME (Stop success) ∧
        bs'.output = bs.output ++ str``,
  simp[compile_prog_def] >> rw[] >>
  fs[init_compiler_state_def] >>
  `∃v1 v2 m2 p0. prog_to_i1 0 FEMPTY FEMPTY prog = (v1,v2,m2,p0)` by simp[GSYM EXISTS_PROD] >> fs[] >>
  `∃v exh p. prog_to_i2 init_tagenv_state p0 = (v,exh,p)` by simp[GSYM EXISTS_PROD] >> fs[] >>
  first_assum (split_pair_case_tac o rand o rhs o concl) >> fs[] >>
  PairCases_on`res`>>fs[] >>
  PairCases_on`stm` >> PairCases_on`env` >>
  (prog_to_i1_correct
   |> ONCE_REWRITE_RULE[CONJ_COMM]
   |> ONCE_REWRITE_RULE[GSYM CONJ_ASSOC]
   |> ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  ONCE_REWRITE_TAC[GSYM CONJ_ASSOC] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  PairCases_on`grd` >> fs[env_rs_def] >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  qpat_assum`0:num = X`(assume_tac o SYM) >> fs[] >>
  strip_tac >>
  first_assum(mp_tac o MATCH_MP prog_to_i2_correct) >>
  simp[] >>
  ONCE_REWRITE_TAC[CONJ_COMM] >>
  ONCE_REWRITE_TAC[GSYM CONJ_ASSOC] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  fs[init_tagenv_state_def] >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  fs[GSYM init_tagenv_state_def] >>
  PairCases_on`v`>>simp[] >>
  discharge_hyps >- (
    Cases_on`res6`>>TRY(PairCases_on`a`)>>fs[result_to_i1_cases] >> rw[] ) >>
  strip_tac >>
  (prog_to_i3_correct
   |> ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  `LENGTH genv2 = 0` by (
    fs[to_i2_invariant_def] >>
    imp_res_tac EVERY2_LENGTH >>
    fs[] ) >>
  simp[] >>
  (discharge_hyps >- (
     simp[FLOOKUP_FUNION,FLOOKUP_UPDATE] >>
     BasicProvers.CASE_TAC >>
     fs[IN_DISJOINT,FLOOKUP_DEF] >>
     fs[result_to_i2_cases,result_to_i1_cases] >> rw[] >>
     Cases_on`res6`>>fs[GSYM FORALL_PROD])) >>
  simp[result_to_i3_cases] >- (
    rw[] >> Cases_on`res6` >> fs[] >>
    PairCases_on`a`>>fs[]>>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_exh_correct)) >>
    simp[env_to_exh_MAP] >>
    fs[LIST_REL_O,OPTREL_O] >>
    qmatch_assum_rename_tac`LIST_REL (v_to_exh X) s2 sh`["X"] >>
    qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
    Q.PAT_ABBREV_TAC`rsexh:exh_ctors_env = FEMPTY |+ X` >>
    `store_to_exh (exh ⊌ rsexh) ((stm0,s2),genv2) ((stm0,sh),gh)` by (
      simp[store_to_exh_def] >>
      `FDOM rsexh = {Short "option"}` by simp[Abbr`rsexh`] >>
      conj_tac >>
      match_mp_tac (MP_CANON (GEN_ALL EVERY2_mono)) >>
      HINT_EXISTS_TAC >>
      metis_tac[optionTheory.OPTREL_MONO,v_to_exh_extend_disjoint,FUNION_COMM]) >>
    disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    disch_then(qspec_then`exh ⊌ rsexh`mp_tac) >> simp[] >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_pat_correct)) >>
    discharge_hyps >- ( fs[result_to_exh_cases] ) >>
    strip_tac >>
    first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
    simp[] >>
    discharge_hyps_keep >- (
      conj_asm1_tac >- (
        specl_args_of_then``exp_to_pat``(CONJUNCT1 free_vars_pat_exp_to_pat)mp_tac >>
        simp[] >> disch_then match_mp_tac >>
        imp_res_tac free_vars_i2_prog_to_i3 >>
        imp_res_tac free_vars_prog_to_i2 >>
        imp_res_tac FV_prog_to_i1 >>
        simp[] >>
        fs[closed_prog_def,all_env_dom_def,SUBSET_DEF,PULL_EXISTS]) >>
      fs[result_to_exh_cases] >> BasicProvers.VAR_EQ_TAC >> fs[] >>
      simp[csg_closed_pat_def,map_count_store_genv_def,store_to_exh_def] >>
      conj_tac >- (
        (v_to_pat_closed |> CONJUNCT2 |> SIMP_RULE(srw_ss())[] |> match_mp_tac) >>
        (v_to_exh_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
        fs[store_to_exh_def] >>
        simp[vs_to_exh_MAP] >>
        first_assum(match_exists_tac o concl) >> simp[] >>
        fs[to_i2_invariant_def] >>
        fs[Once s_to_i2_cases] >>
        fs[Once s_to_i2'_cases] >>
        (v_to_i2_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
        first_assum(match_exists_tac o concl) >> simp[] >>
        (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
        fs[to_i1_invariant_def] >>
        fs[Once s_to_i1_cases] >>
        fs[Once s_to_i1'_cases] >>
        first_assum(match_exists_tac o concl) >> simp[]) >>
      match_mp_tac genv_to_pat_closed >>
      match_mp_tac genv_to_exh_closed >>
      fs[store_to_exh_def] >>
      ONCE_REWRITE_TAC[CONJ_COMM] >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      fs[to_i2_invariant_def] >>
      match_mp_tac (MP_CANON genv_to_i2_closed) >>
      first_assum(match_exists_tac o concl) >> simp[]>>
      first_assum(match_exists_tac o concl) >> simp[]) >>
    disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
    qpat_assum`bs.code = X`mp_tac >>
    specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
    simp[] >> strip_tac >>
    first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
    simp[] >>
    Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
    qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
    disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
    discharge_hyps >- (
      simp[syneq_exp_refl] >>
      fs[store_to_exh_def] >>
      simp[Abbr`Csg`,map_count_store_genv_def,csg_rel_def] >>
      simp[MAP_MAP_o,optionTheory.OPTION_MAP_COMPOSE,combinTheory.o_DEF] >>
      simp[EVERY2_MAP] >>
      conj_tac >>
      match_mp_tac EVERY2_MEM_MONO >>
      HINT_EXISTS_TAC >>
      simp[exh_Cv_def,optionTheory.OPTREL_def,UNCURRY] >- (
        rw[] >> rw[] >>
        first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
        discharge_hyps >- (
          simp[] >>
          fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM] >>
          first_x_assum match_mp_tac >>
          simp[map_count_store_genv_def,MEM_MAP] >>
          qexists_tac`FST x` >> simp[] >>
          imp_res_tac MEM_ZIP_MEM_MAP >>
          imp_res_tac EVERY2_LENGTH >> fs[] ) >>
        metis_tac[syneq_trans] ) >>
      rw[] >> rw[] >>
      first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
      discharge_hyps >- (
        simp[] >>
        fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM] >>
        first_x_assum(qspec_then`OPTION_MAP v_to_pat (FST x)`mp_tac) >>
        simp[map_count_store_genv_def] >>
        disch_then match_mp_tac >>
        simp[MEM_MAP,PULL_EXISTS] >>
        metis_tac[MEM_ZIP_MEM_MAP,EVERY2_LENGTH,FST,SND] ) >>
      metis_tac[syneq_trans] ) >>
    strip_tac >>
    first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
    disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
    discharge_hyps >- (
      simp[Abbr`Csg`] >>
      fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
    fs[result_to_exh_cases] >>
    rpt BasicProvers.VAR_EQ_TAC >> fs[] >> rfs[] >> rfs[] >>
    strip_tac >>
    specl_args_of_then``compile_print_err``compile_print_err_thm mp_tac >>
    simp[] >>
    disch_then(qx_choose_then`bcp`strip_assume_tac) >>
    simp[] >>
    rator_x_assum`code_for_push`mp_tac >>
    simp[code_for_push_def,PULL_EXISTS] >>
    rpt gen_tac >> strip_tac >>
    qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
    `bc_next^* (bs0 with code := bs0.code++bcp) (bs1 with code := bs1.code++bcp)` by (
      metis_tac[RTC_bc_next_append_code] ) >>
    rator_x_assum`v_to_exh`mp_tac >>
    simp[Once v_to_exh_cases,vs_to_exh_MAP] >>
    strip_tac >> BasicProvers.VAR_EQ_TAC >>
    rator_x_assum`v_pat`mp_tac >>
    simp[Once v_pat_cases] >>
    strip_tac >> BasicProvers.VAR_EQ_TAC >>
    rpt (
      qpat_assum`syneq (X Y) Z`mp_tac >>
      simp[Once syneq_cases] >> strip_tac >>
      BasicProvers.VAR_EQ_TAC ) >>
    rator_x_assum`Cv_bv`mp_tac >>
    simp[Once Cv_bv_cases] >> strip_tac >>
    BasicProvers.VAR_EQ_TAC >>
    first_x_assum(qspec_then`bs1 with code := bs1.code++bcp`mp_tac) >>
    simp[Abbr`bs1`] >>
    discharge_hyps >- (
      rpt (rator_x_assum`good_labels`mp_tac) >>
      rpt (rator_x_assum`between_labels`mp_tac) >>
      rpt (BasicProvers.VAR_EQ_TAC) >>
      rpt (pop_assum kall_tac) >>
      simp[good_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,PULL_EXISTS
          ,EVERY_FILTER,between_labels_def,EVERY_MAP,EVERY_MEM,between_def,PULL_FORALL] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
    strip_tac >>
    BasicProvers.CASE_TAC >> simp[] >- (
      strip_tac >>
      qmatch_assum_abbrev_tac`bc_next^* bs2 bs3` >>
      `bc_next^* (bs2 with code := bs.code) (bs3 with code := bs.code)` by (
        match_mp_tac RTC_bc_next_append_code >>
        first_assum(match_exists_tac o concl) >>
        simp[Abbr`bs2`,Abbr`bs3`,bc_state_component_equality] ) >>
      fs[Abbr`bs0`] >>
      qmatch_assum_abbrev_tac`bc_next^* bs1 bs2` >>
      `bc_next^* (bs1 with code := bs.code) (bs2 with code := bs.code)` by (
        match_mp_tac RTC_bc_next_append_code >>
        map_every qexists_tac[`bs1`,`bs2`] >>
        simp[Abbr`bs1`,Abbr`bs2`,bc_state_component_equality] ) >>
      qexists_tac`bs3 with code := bs.code` >>
      reverse conj_tac >- (
        `bs1 with code := bs.code = bs` by (
          simp[Abbr`bs1`,bc_state_component_equality] ) >>
        metis_tac[RTC_TRANSITIVE,transitive_def] ) >>
      simp[Abbr`bs3`] >>
      conj_tac >- (
        match_mp_tac bc_fetch_next_addr >>
        simp[] >>
        CONV_TAC SWAP_EXISTS_CONV >> qexists_tac`[]` >>
        simp[] ) >>
      BasicProvers.CASE_TAC >>
      rator_x_assum`to_i1_invariant`mp_tac >>
      simp[to_i1_invariant_def] >>
      CCONTR_TAC >> fs[] >>
      imp_res_tac global_env_inv_inclusion >>
      imp_res_tac libPropsTheory.lookup_in2 >>
      fs[FLOOKUP_DEF,SUBSET_DEF]) >>
    strip_tac >>
    qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
    qmatch_assum_abbrev_tac`bc_next^* bs2 bs3` >>
    `bc_next^* (bs2 with code := bs.code) (bs3 with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      first_assum(match_exists_tac o concl) >>
      simp[Abbr`bs2`,Abbr`bs3`,bc_state_component_equality] ) >>
    `bc_next^* (bs0 with code := bs.code) (bs1 with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs0`,`bs1`] >>
      simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] ) >>
    `bs0 with code := bs.code = bs` by (
      simp[Abbr`bs0`,bc_state_component_equality] ) >>
    qabbrev_tac`bs4 = bs3 with code := bs.code` >>
    `bc_fetch bs4 = SOME (Gread x)` by (
      match_mp_tac bc_fetch_next_addr >>
      simp[Abbr`bs4`] >>
      qexists_tac`bc0++c0++code++bcp` >>
      simp[Abbr`bs3`] ) >>
    ONCE_REWRITE_TAC[CONJ_COMM] >>
    qho_match_abbrev_tac`∃bs3. bc_next^* bs bs3 ∧ P bs3` >>
    qsuff_tac`∃bs5. bc_next^* bs bs4 ∧ NRC bc_next (SUC(SUC(SUC(0)))) bs4 bs5 ∧ P bs5` >- (
      metis_tac[NRC_RTC,RTC_TRANSITIVE,transitive_def] ) >>
    simp[NRC,PULL_EXISTS] >>
    simp[GSYM CONJ_ASSOC,RIGHT_EXISTS_AND_THM] >>
    `bs1 with code := bs.code = bs2 with code := bs.code` by (
      simp[Abbr`bs1`,Abbr`bs2`] ) >>
    conj_tac >- metis_tac[RTC_TRANSITIVE,transitive_def] >>
    simp[Once bc_eval1_thm] >>
    simp[bc_eval1_def,bump_pc_def] >>
    simp[Abbr`bs4`,Abbr`bs3`] >>
    rator_x_assum`to_i1_invariant`mp_tac >>
    simp[to_i1_invariant_def] >> strip_tac >>
    rator_x_assum`global_env_inv`mp_tac >>
    simp[Once v_to_i1_cases] >> strip_tac >>
    rator_x_assum`global_env_inv_flat`mp_tac >>
    simp[Once v_to_i1_cases] >>
    disch_then(qspec_then`"it"`mp_tac) >>
    simp[] >>
    rator_x_assum`to_i1_invariant`mp_tac >>
    simp[to_i1_invariant_def] >>
    simp[Once v_to_i1_cases] >>
    simp[Once v_to_i1_cases] >> strip_tac >>
    simp[libPropsTheory.lookup_append] >>
    BasicProvers.CASE_TAC >> fs[] >- fs[FLOOKUP_DEF] >>
    strip_tac >> Cases_on`grd0`>>fs[] >>
    rator_x_assum`to_i2_invariant`mp_tac >>
    simp[to_i2_invariant_def] >> strip_tac >>
    rfs[EVERY2_EVERY] >> fs[EVERY_MEM] >>
    Cases_on`genv2`>>fs[] >>
    fs[MEM_ZIP,PULL_EXISTS] >>
    first_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
    simp[optionTheory.OPTREL_def] >> strip_tac >>
    rator_x_assum`store_to_exh`mp_tac >>
    simp[store_to_exh_csg_rel,csg_rel_unpair] >>
    strip_tac >>
    rfs[EVERY2_EVERY] >> fs[EVERY_MEM] >>
    fs[MEM_ZIP,PULL_EXISTS] >>
    first_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
    simp[optionTheory.OPTREL_def] >> strip_tac >>
    rpt(rator_x_assum`csg_rel`mp_tac) >>
    simp[csg_rel_unpair] >> rpt strip_tac >>
    rfs[EVERY2_EVERY] >> fs[EVERY_MEM,map_count_store_genv_def] >>
    fs[MEM_ZIP,PULL_EXISTS] >>
    last_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
    simp[EL_MAP,optionTheory.OPTREL_def] >> strip_tac >>
    fs[Cenv_bs_def,s_refs_def] >>
    last_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
    simp[EL_MAP,optionTheory.OPTREL_def] >> strip_tac >>
    last_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
    simp[EL_MAP,optionTheory.OPTREL_def] >> strip_tac >>
    last_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
    simp[EL_MAP,optionTheory.OPTREL_def] >> strip_tac >>
    rator_x_assum`LIST_REL`mp_tac >>
    simp[EVERY2_EVERY,EVERY_MEM] >> strip_tac >>
    rfs[MEM_ZIP,PULL_EXISTS] >> fs[] >>
    first_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
    simp[optionTheory.OPTREL_def] >> strip_tac >> simp[] >>
    qunabbrev_tac`bs1` >>
    qho_match_abbrev_tac`∃bs4 bs3. bc_next bs1 bs3 ∧ bc_next bs3 bs4 ∧ P bs4` >>
    `bc_fetch bs1 = SOME Print` by (
      match_mp_tac bc_fetch_next_addr >>
      simp[Abbr`bs1`] >>
      qexists_tac`bc0++c0++code++bcp++[Gread x]` >>
      simp[SUM_APPEND,FILTER_APPEND] ) >>
    simp[Once bc_eval1_thm] >> simp[bc_eval1_def,bump_pc_def] >>
    simp[Abbr`bs1`,RIGHT_EXISTS_AND_THM] >>
    conj_tac >- metis_tac[Cv_bv_can_Print] >>
    qho_match_abbrev_tac`∃bs4. bc_next bs1 bs4 ∧ P bs4` >>
    `bc_fetch bs1 = SOME (PrintC #"\n")` by (
      match_mp_tac bc_fetch_next_addr >>
      simp[Abbr`bs1`] >>
      qexists_tac`bc0++c0++code++bcp++[Gread x;Print]` >>
      simp[SUM_APPEND,FILTER_APPEND] ) >>
    simp[Once bc_eval1_thm] >> simp[bc_eval1_def,bump_pc_def] >>
    simp[Abbr`bs1`,IMPLODE_EXPLODE_I,Abbr`P`] >>
    conj_tac >- (
      match_mp_tac bc_fetch_next_addr >> simp[] >>
      CONV_TAC SWAP_EXISTS_CONV >> qexists_tac`[]` >>
      simp[SUM_APPEND,FILTER_APPEND] ) >>
    first_x_assum(mp_tac o MATCH_MP Cv_bv_ov) >>
    disch_then(SUBST1_TAC o SYM) >>
    match_mp_tac (MP_CANON print_v_ov) >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    rpt BasicProvers.VAR_EQ_TAC >> fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    simp[exh_Cv_def] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    reverse conj_tac >- metis_tac[syneq_trans] >>
    first_x_assum(mp_tac o MATCH_MP (CONJUNCT1 evaluate_pat_closed)) >>
    simp[csg_closed_pat_def] >>
    simp[EVERY_MEM,MEM_EL,PULL_EXISTS] >>
    metis_tac[OPTION_EVERY_def] ) >>
  Cases_on`res6`>>
  fs[result_to_i2_cases,result_to_i1_cases,GSYM FORALL_PROD] >>
  fs[] >> rw[] >>
  first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_exh_correct)) >>
  simp[env_to_exh_MAP] >>
  fs[LIST_REL_O,OPTREL_O] >>
  qmatch_assum_rename_tac`LIST_REL (v_to_exh X) s2 sh`["X"] >>
  qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
  Q.PAT_ABBREV_TAC`rsexh:exh_ctors_env = FEMPTY |+ X` >>
  `store_to_exh (exh ⊌ rsexh) ((stm0,s2),genv2) ((stm0,sh),gh)` by (
    simp[store_to_exh_def] >>
    `FDOM rsexh = {Short "option"}` by simp[Abbr`rsexh`] >>
    conj_tac >>
    match_mp_tac (MP_CANON (GEN_ALL EVERY2_mono)) >>
    HINT_EXISTS_TAC >>
    metis_tac[optionTheory.OPTREL_MONO,v_to_exh_extend_disjoint,FUNION_COMM]) >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
  disch_then(qspec_then`exh ⊌ rsexh`mp_tac) >> simp[] >>
  strip_tac >>
  first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_pat_correct)) >>
  discharge_hyps >- ( fs[result_to_exh_cases] ) >>
  strip_tac >>
  first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
  simp[] >>
  discharge_hyps_keep >- (
    conj_asm1_tac >- (
      specl_args_of_then``exp_to_pat``(CONJUNCT1 free_vars_pat_exp_to_pat)mp_tac >>
      simp[] >> disch_then match_mp_tac >>
      imp_res_tac free_vars_i2_prog_to_i3 >>
      imp_res_tac free_vars_prog_to_i2 >>
      imp_res_tac FV_prog_to_i1 >>
      simp[] >>
      fs[closed_prog_def,all_env_dom_def,SUBSET_DEF,PULL_EXISTS]) >>
    fs[result_to_exh_cases] >> BasicProvers.VAR_EQ_TAC >> fs[] >>
    simp[csg_closed_pat_def,map_count_store_genv_def,store_to_exh_def] >>
    conj_tac >- (
      (v_to_pat_closed |> CONJUNCT2 |> SIMP_RULE(srw_ss())[] |> match_mp_tac) >>
      (v_to_exh_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
      fs[store_to_exh_def] >>
      simp[vs_to_exh_MAP] >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      fs[to_i2_invariant_def] >>
      fs[Once s_to_i2_cases] >>
      fs[Once s_to_i2'_cases] >>
      (v_to_i2_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
      fs[to_i1_invariant_def] >>
      fs[Once s_to_i1_cases] >>
      fs[Once s_to_i1'_cases] >>
      first_assum(match_exists_tac o concl) >> simp[]) >>
    match_mp_tac genv_to_pat_closed >>
    match_mp_tac genv_to_exh_closed >>
    fs[store_to_exh_def] >>
    ONCE_REWRITE_TAC[CONJ_COMM] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[to_i2_invariant_def] >>
    match_mp_tac (MP_CANON genv_to_i2_closed) >>
    first_assum(match_exists_tac o concl) >> simp[]>>
    first_assum(match_exists_tac o concl) >> simp[]) >>
  disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
  qpat_assum`bs.code = X`mp_tac >>
  specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
  simp[] >> strip_tac >>
  first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
  simp[] >>
  Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
  qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
  disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
  discharge_hyps >- (
    simp[syneq_exp_refl] >>
    fs[store_to_exh_def] >>
    simp[Abbr`Csg`,map_count_store_genv_def,csg_rel_def] >>
    simp[MAP_MAP_o,optionTheory.OPTION_MAP_COMPOSE,combinTheory.o_DEF] >>
    simp[EVERY2_MAP] >>
    conj_tac >>
    match_mp_tac EVERY2_MEM_MONO >>
    HINT_EXISTS_TAC >>
    simp[exh_Cv_def,optionTheory.OPTREL_def,UNCURRY] >- (
      rw[] >> rw[] >>
      first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
      discharge_hyps >- (
        simp[] >>
        fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM] >>
        first_x_assum match_mp_tac >>
        simp[map_count_store_genv_def,MEM_MAP] >>
        qexists_tac`FST x` >> simp[] >>
        imp_res_tac MEM_ZIP_MEM_MAP >>
        imp_res_tac EVERY2_LENGTH >> fs[] ) >>
      metis_tac[syneq_trans] ) >>
    rw[] >> rw[] >>
    first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
    discharge_hyps >- (
      simp[] >>
      fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM] >>
      first_x_assum(qspec_then`OPTION_MAP v_to_pat (FST x)`mp_tac) >>
      simp[map_count_store_genv_def] >>
      disch_then match_mp_tac >>
      simp[MEM_MAP,PULL_EXISTS] >>
      metis_tac[MEM_ZIP_MEM_MAP,EVERY2_LENGTH,FST,SND] ) >>
    metis_tac[syneq_trans] ) >>
  strip_tac >>
  first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
  disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
  discharge_hyps >- (
    simp[Abbr`Csg`] >>
    fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
  fs[result_to_exh_cases] >>
  rpt BasicProvers.VAR_EQ_TAC >> fs[] >> rfs[] >> rfs[] >>
  strip_tac >>
  specl_args_of_then``compile_print_err``compile_print_err_thm mp_tac >>
  simp[] >>
  disch_then(qx_choose_then`bcp`strip_assume_tac) >>
  simp[] >>
  rator_x_assum`code_for_push`mp_tac >>
  simp[code_for_push_def,PULL_EXISTS] >>
  rpt gen_tac >> strip_tac >>
  qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
  `bc_next^* (bs0 with code := bs0.code++bcp) (bs1 with code := bs1.code++bcp)` by (
    metis_tac[RTC_bc_next_append_code] ) >>
  rator_x_assum`v_to_exh`mp_tac >>
  simp[Once v_to_exh_cases,vs_to_exh_MAP] >>
  strip_tac >> rpt BasicProvers.VAR_EQ_TAC >>
  rator_x_assum`v_pat`mp_tac >>
  simp[Once v_pat_cases] >>
  strip_tac >> rpt BasicProvers.VAR_EQ_TAC >> fs[] >>
  rpt (
    qpat_assum`syneq (CConv X Y) Z`mp_tac >>
    simp[Once syneq_cases] >> strip_tac >>
    rpt BasicProvers.VAR_EQ_TAC ) >>
  rator_x_assum`Cv_bv`mp_tac >>
  simp[Once Cv_bv_cases] >> strip_tac >>
  rpt BasicProvers.VAR_EQ_TAC >>
  first_x_assum(qspec_then`bs1 with code := bs1.code++bcp`mp_tac) >>
  `some_tag ≠ none_tag` by EVAL_TAC >>
  simp[Abbr`bs1`] >>
  discharge_hyps >- (
    reverse conj_tac >- metis_tac[Cv_bv_can_Print] >>
    rpt (rator_x_assum`good_labels`mp_tac) >>
    rpt (rator_x_assum`between_labels`mp_tac) >>
    rpt (BasicProvers.VAR_EQ_TAC) >>
    rpt (pop_assum kall_tac) >>
    simp[good_labels_def,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,PULL_EXISTS
        ,EVERY_FILTER,between_labels_def,EVERY_MAP,EVERY_MEM,between_def,PULL_FORALL] >>
    rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
  strip_tac >>
  strip_tac >>
  qmatch_assum_abbrev_tac`bc_fetch bs4 = SOME (Stop F)` >>
  qexists_tac`bs4 with code := bs.code` >>
  conj_tac >- (
    conj_tac >- (
      first_x_assum(mp_tac o MATCH_MP(GEN_ALL bc_fetch_append_code)) >>
      simp[Abbr`bs4`,bc_fetch_def] >>
      BasicProvers.CASE_TAC >> simp[REVERSE_APPEND] >>
      metis_tac[APPEND_ASSOC] ) >>
    simp[Abbr`bs4`] >>
    first_x_assum(mp_tac o MATCH_MP Cv_bv_ov) >>
    disch_then(SUBST1_TAC o SYM) >>
    match_mp_tac (MP_CANON print_v_ov) >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    rpt BasicProvers.VAR_EQ_TAC >> fs[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    simp[exh_Cv_def] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    reverse conj_tac >- metis_tac[syneq_trans] >>
    first_x_assum(mp_tac o MATCH_MP (CONJUNCT1 evaluate_pat_closed)) >>
    simp[csg_closed_pat_def] ) >>
  qmatch_assum_abbrev_tac`bc_next^* bs3 bs4` >>
  qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
  `bs = bs0 with code := bs.code` by (
    simp[Abbr`bs0`,bc_state_component_equality] ) >>
  `bs1 with code := bs.code = bs3 with code := bs.code` by (
    simp[Abbr`bs1`,Abbr`bs3`,bc_state_component_equality] ) >>
  `bc_next^* bs (bs1 with code := bs.code)` by (
    match_mp_tac RTC_bc_next_append_code >>
    map_every qexists_tac[`bs0`,`bs1`] >>
    simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] >>
    BasicProvers.CASE_TAC >> simp[] ) >>
  `bc_next^* (bs1 with code := bs.code) (bs4 with code := bs.code)` by (
    match_mp_tac RTC_bc_next_append_code >>
    map_every qexists_tac[`bs3`,`bs4`] >>
    simp[Abbr`bs3`,Abbr`bs4`,Abbr`bs1`,bc_state_component_equality] >>
    BasicProvers.CASE_TAC >> simp[] ) >>
  metis_tac[RTC_TRANSITIVE,transitive_def])

val compile_prog_divergence = store_thm("compile_prog_divergence",
  ``∀env stm prog rs grd types bc0 bs.
      (∀res. ¬evaluate_prog F env stm prog res) ∧
      closed_prog prog ∧
      env_rs env stm grd init_compiler_state (bs with code := bc0) ∧
      bs.code = bc0 ++ compile_prog prog ∧
      bs.pc = next_addr bs.inst_length bc0 ∧
      IS_SOME bs.clock
      ⇒
      ∃bs'. bc_next^* bs bs' ∧ bc_fetch bs' = SOME Tick ∧ bs'.clock = SOME 0 ∧ bs'.output = bs.output``,
  rw[closed_prog_def] >>
  imp_res_tac not_evaluate_prog_timeout >>
  fs[compile_prog_def,LET_THM] >>
  fs[init_compiler_state_def] >>
  `∃v1 v2 m2 p0. prog_to_i1 0 FEMPTY FEMPTY prog = (v1,v2,m2,p0)` by simp[GSYM EXISTS_PROD] >> fs[] >>
  `∃v exh p. prog_to_i2 init_tagenv_state p0 = (v,exh,p)` by simp[GSYM EXISTS_PROD] >> fs[] >>
  first_assum (split_pair_case_tac o rand o rhs o concl) >> fs[] >>
  PairCases_on`env` >>
  PairCases_on`stm` >>
  PairCases_on`r` >>
  (prog_to_i1_correct
   |> CONV_RULE
     ((lift_conjunct_conv(equal``evaluate_prog`` o fst o strip_comb))
      |> LAND_CONV |> STRIP_QUANT_CONV)
   |> ONCE_REWRITE_RULE [GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  PairCases_on`grd`>>fs[env_rs_def] >> rfs[] >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  strip_tac >>
  (prog_to_i2_correct
   |> ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_i1_cases] >>
  ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO] >>
  fs[init_tagenv_state_def] >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP th)) >>
  fs[GSYM init_tagenv_state_def] >>
  PairCases_on`v`>>simp[]>>
  strip_tac >>
  (prog_to_i3_correct
   |> ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_i2_cases] >>
  simp[FLOOKUP_UPDATE,FLOOKUP_FUNION] >>
  reverse BasicProvers.CASE_TAC >- (
    fs[IN_DISJOINT,FLOOKUP_DEF] ) >>
  rpt BasicProvers.VAR_EQ_TAC >>
  `LENGTH genv2 = LENGTH grd0` by (
    fs[to_i2_invariant_def] >>
    imp_res_tac EVERY2_LENGTH >>
    fs[] ) >>
  simp[] >>
  strip_tac >>
  (exp_to_exh_correct
   |> CONJUNCT1
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_i3_cases] >>
  simp[env_to_exh_MAP] >>
  fs[LIST_REL_O,OPTREL_O] >>
  qmatch_assum_abbrev_tac`LIST_REL (v_to_exh rsexh) s20 sh` >>
  qmatch_assum_rename_tac`LIST_REL R genv2 gh`["R"] >>
  `store_to_exh (exh ⊌ rsexh) ((stm0,s20),genv2) ((stm0,sh),gh)` by (
    simp[store_to_exh_def] >>
    conj_tac >>
    match_mp_tac (MP_CANON (GEN_ALL EVERY2_mono)) >>
    HINT_EXISTS_TAC >>
    `DISJOINT  (FDOM exh) (FDOM rsexh)` by simp[Abbr`rsexh`] >>
    metis_tac[optionTheory.OPTREL_MONO,v_to_exh_extend_disjoint,FUNION_COMM]) >>
  disch_then(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
  disch_then(qspec_then`exh ⊌ rsexh`mp_tac) >> simp[] >>
  strip_tac >>
  (exp_to_pat_correct
   |> CONJUNCT1
   |> (fn th => first_assum (mp_tac o MATCH_MP th))) >>
  fs[result_to_exh_cases] >>
  strip_tac >>
  first_assum (mp_tac o MATCH_MP (CONJUNCT1 exp_to_Cexp_correct)) >>
  simp[] >>
  discharge_hyps_keep >- (
    Cases_on`grd0`>>fs[]>>
    conj_asm1_tac >- (
      specl_args_of_then``exp_to_pat``(CONJUNCT1 free_vars_pat_exp_to_pat)mp_tac >>
      simp[] >> disch_then match_mp_tac >>
      imp_res_tac free_vars_i2_prog_to_i3 >>
      imp_res_tac free_vars_prog_to_i2 >>
      imp_res_tac FV_prog_to_i1 >>
      simp[] >>
      fs[closed_prog_def,all_env_dom_def,SUBSET_DEF,PULL_EXISTS]) >>
    simp[csg_closed_pat_def,map_count_store_genv_def,store_to_exh_def] >>
    conj_tac >- (
      (v_to_pat_closed |> CONJUNCT2 |> SIMP_RULE(srw_ss())[] |> match_mp_tac) >>
      (v_to_exh_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
      fs[store_to_exh_def] >>
      simp[vs_to_exh_MAP] >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      fs[to_i2_invariant_def] >>
      fs[Once s_to_i2_cases] >>
      fs[Once s_to_i2'_cases] >>
      (v_to_i2_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      (v_to_i1_closed |> CONJUNCT2 |> CONJUNCT1 |> MP_CANON |> match_mp_tac) >>
      fs[to_i1_invariant_def] >>
      fs[Once s_to_i1_cases] >>
      fs[Once s_to_i1'_cases] >>
      first_assum(match_exists_tac o concl) >> simp[]) >>
    match_mp_tac genv_to_pat_closed >>
    match_mp_tac genv_to_exh_closed >>
    fs[store_to_exh_def] >>
    ONCE_REWRITE_TAC[CONJ_COMM] >>
    first_assum(match_exists_tac o concl) >> simp[] >>
    fs[to_i2_invariant_def] >>
    match_mp_tac (MP_CANON genv_to_i2_closed) >>
    first_assum(match_exists_tac o concl) >> simp[]>>
    first_assum(match_exists_tac o concl) >> simp[]) >>
  disch_then(qx_choosel_then[`Cres0`]strip_assume_tac) >>
  qpat_assum`bs.code = X`mp_tac >>
  specl_args_of_then``compile_Cexp`` compile_Cexp_thm mp_tac >>
  simp[] >> strip_tac >>
  first_assum(mp_tac o MATCH_MP (CONJUNCT1 Cevaluate_syneq)) >>
  simp[] >>
  Q.PAT_ABBREV_TAC`Cexp = exp_to_Cexp Z` >>
  qmatch_assum_abbrev_tac`closed_vlabs [] Csg bc0` >>
  disch_then(qspecl_then[`$=`,`Csg`,`[]`,`Cexp`]mp_tac) >>
  discharge_hyps >- (
    simp[syneq_exp_refl] >>
    fs[store_to_exh_def] >>
    simp[Abbr`Csg`,map_count_store_genv_def,csg_rel_def] >>
    simp[MAP_MAP_o,optionTheory.OPTION_MAP_COMPOSE,combinTheory.o_DEF] >>
    simp[EVERY2_MAP] >>
    conj_tac >>
    match_mp_tac EVERY2_MEM_MONO >>
    HINT_EXISTS_TAC >>
    simp[exh_Cv_def,optionTheory.OPTREL_def,UNCURRY] >- (
      rw[] >> rw[] >>
      first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
      discharge_hyps >- (
        simp[] >>
        fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM] >>
        first_x_assum match_mp_tac >>
        simp[map_count_store_genv_def,MEM_MAP] >>
        qexists_tac`FST x` >> simp[] >>
        imp_res_tac MEM_ZIP_MEM_MAP >>
        imp_res_tac EVERY2_LENGTH >> fs[] ) >>
      metis_tac[syneq_trans] ) >>
    rw[] >> rw[] >>
    first_x_assum(mp_tac o MATCH_MP v_pat_syneq) >>
    discharge_hyps >- (
      simp[] >>
      fs[csg_closed_pat_def,EVERY_MAP,EVERY_MEM] >>
      first_x_assum(qspec_then`OPTION_MAP v_to_pat (FST x)`mp_tac) >>
      simp[map_count_store_genv_def] >>
      disch_then match_mp_tac >>
      simp[MEM_MAP,PULL_EXISTS] >>
      metis_tac[MEM_ZIP_MEM_MAP,EVERY2_LENGTH,FST,SND] ) >>
    metis_tac[syneq_trans] ) >>
  strip_tac >>
  first_x_assum(fn th => first_assum (mp_tac o MATCH_MP (ONCE_REWRITE_RULE[GSYM AND_IMP_INTRO]th))) >>
  specl_args_of_then``compile_print_err``compile_print_err_thm mp_tac >>
  simp[] >>
  disch_then(qx_choose_then`bcp`strip_assume_tac) >>
  simp[] >>
  disch_then(qspecl_then[`grd2`,`bs with code := bc0 ++ c0 ++ code`,`bc0`,`bc0`]mp_tac) >>
  discharge_hyps >- (
    simp[Abbr`Csg`] >>
    fs[Cenv_bs_def,s_refs_def,IS_SOME_EXISTS] ) >>
  strip_tac >>
  strip_tac >>
  imp_res_tac RTC_bc_next_preserves >>
  qmatch_assum_abbrev_tac`bc_next^* bs0 bs1` >>
  `bc_next^* bs (bs1 with code := bs.code)` by (
    match_mp_tac RTC_bc_next_append_code >>
    map_every qexists_tac[`bs0`,`bs1`] >>
    simp[Abbr`bs0`,Abbr`bs1`,bc_state_component_equality] >>
    BasicProvers.CASE_TAC >> rw[] ) >>
  `bc_fetch (bs1 with code := bs.code) = SOME Tick` by (
    first_assum(mp_tac o (MATCH_MP (GEN_ALL bc_fetch_append_code))) >>
    simp[Abbr`bs0`,REVERSE_APPEND] >>
    BasicProvers.CASE_TAC >> rw[REVERSE_APPEND] >>
    metis_tac[APPEND_ASSOC]) >>
  HINT_EXISTS_TAC >>
  simp[Abbr`bs0`])

val _ = export_theory()
