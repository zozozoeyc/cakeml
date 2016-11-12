open preamble exhLangTheory

val _ = new_theory"exh_reorder";

val is_const_con_def = Define`
  (is_const_con (Pcon tag plist) = (plist = [])) /\
  (is_const_con _  = F)`

val isPvar_def = Define`
  (isPvar (Pvar _) = T) /\
  isPvar _ = F`

val isPcon_def = Define`
  (isPcon (Pcon _ _) = T) /\
  isPcon _ = F`

val _ = export_rewrites ["isPvar_def","isPcon_def", "is_const_con_def"]

val const_cons_sep_def=Define `
  (const_cons_sep [] a const_cons = (const_cons,a) ) /\
  (const_cons_sep (b::c) a const_cons=
      if (isPvar (FST b)) then
          (const_cons,(b::a))
      else if (is_const_con (FST b)) then
              if MEM (FST b) (MAP FST const_cons) then
                   const_cons_sep c a const_cons
              else const_cons_sep c a (b::const_cons)
      else if isPcon (FST b) then
          const_cons_sep c (b::a) const_cons
      else (const_cons, REVERSE (b::c)++a))`

val const_cons_fst_def = Define`
    const_cons_fst pes =
        let (const_cons, a) = const_cons_sep pes [] []
        in const_cons ++ REVERSE a`

val const_cons_sep_MEM= Q.store_thm("const_cons_sep_MEM",
  `! y z. ¬ (MEM x y ) /\ ¬ (MEM x z) /\
          MEM x ((\(a,b). a ++ REVERSE b) (const_cons_sep pes y z)) ==> MEM x pes`,
  Induct_on `pes`
  \\ rw [const_cons_sep_def] \\ METIS_TAC [MEM])

val const_cons_fst_MEM = Q.store_thm("const_cons_fst_MEM",
  `MEM x (const_cons_fst pes) ==> MEM x pes`,
  rw [const_cons_fst_def]
  \\ METIS_TAC [MEM, const_cons_sep_MEM])

(*
 example:
 n.b. the constant constructors come in reverse order
 to fix this, const_cons_fst could REVERSE the const_cons accumulator
EVAL ``
const_cons_fst [
  (Pcon 1 [Pvar "x"], e1);
  (Pcon 3 [], e3);
  (Pvar "z", ez);
  (Pcon 2 [Pvar "y"], e2);
  (Pcon 4 [], e4)]``;
*)

val compile_def = tDefine "compile" `
    (compile [] = []) /\
    (compile [Raise e] = [Raise (HD (compile [e]))]) /\
    (compile [Handle e pes] =  [Handle (HD (compile [e])) (MAP (λ(p,e). (p,HD (compile [e]))) (const_cons_fst pes))]) /\
    (compile [Lit l] = [Lit l]) /\
    (compile [Con n es] = [Con n (compile es)] ) /\
    (compile [Var_local v] = [Var_local v]) /\
    (compile [Var_global n] = [Var_global n]) /\
    (compile [Fun v e] = [Fun v (HD (compile [e]))]) /\
    (compile [App op es] = [App op (compile es)]) /\
    (compile [Mat e pes] =  [Mat (HD (compile [e])) (MAP (λ(p,e). (p,HD (compile [e]))) (const_cons_fst pes))]) /\
    (compile [Let vo e1 e2] = [Let vo (HD (compile [e1])) (HD (compile [e2]))]) /\
    (compile [Letrec funs e] =
        [Letrec (MAP (\(a, b, e). (a,b, HD (compile [e]))) funs) (HD (compile [e]))]) /\
    (compile [Extend_global n] = [Extend_global n]) /\
    (compile (x::y::xs) = compile [x] ++ compile (y::xs))`
(
  WF_REL_TAC `measure exp6_size`
  \\ simp []
  \\ conj_tac
  >- (
     gen_tac
     \\ Induct_on `funs`
     \\ rw [exp_size_def]
     \\ rw [exp_size_def]
     \\ res_tac \\ rw []
  )
  >- (
     rpt strip_tac
     \\ imp_res_tac const_cons_fst_MEM
     \\ last_x_assum kall_tac
     \\ Induct_on `pes`
     \\ rw [exp_size_def]
     \\ rw [exp_size_def]
     \\ res_tac \\ rw []
  )
)

val compile_ind = theorem"compile_ind";

val compile_length = Q.store_thm ("compile_length[simp]",
  `! es. LENGTH (compile es) = LENGTH es`,
  ho_match_mp_tac compile_ind
  \\ rw [compile_def])

val compile_sing = Q.store_thm ("compile_sing",
  `! e. ?e2. compile [e] = [e2]`,
  rw []
  \\ qspec_then `[e]` mp_tac compile_length
  \\ simp_tac(std_ss++listSimps.LIST_ss)[LENGTH_EQ_NUM_compute])

val compile_nil = save_thm ("compile_nil[simp]", EVAL ``exh_reorder$compile []``);

val compile_cons = Q.store_thm ("compile_cons",
  `! e es. compile (e::es) = HD (compile [e]) :: (compile es)`,
  rw []
  \\ Cases_on `es`
  \\ rw [compile_def]
  \\ METIS_TAC [compile_sing, HD])

val () = export_theory();
