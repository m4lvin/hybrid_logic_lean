import Hybrid.Form
import Hybrid.Proof
import Hybrid.Truth
import Hybrid.Util
open Classical

section Lemmas
  theorem generalize_not_free (h1 : is_free v φ = false) : ⊨ (φ ⟶ (all v, φ)) := by
    intro M s g
    intro h2
    match φ with
    | Form.bttm   => exact False.elim h2
    | Form.prop p =>
        simp at h2
        rw [Sat]
        intros
        exact h2
    | Form.svar x =>
        simp only [is_free, beq_eq_false_iff_ne, ne_eq] at h1 
        intro _ var
        exact Eq.trans h2 (Eq.symm (var x h1))
    | Form.nom _ =>
        intro _ _
        exact h2
    | Form.impl ψ χ =>
        rw [Sat]
        simp only [is_free, Bool.or_eq_false_eq_eq_false_and_eq_false] at h1 
        rw [Sat] at h2
        intros g' variant antecedent
        have sym_variant := is_variant_symm.mp variant
        -- apply the induction hypothesis:
        have by_ind_hyp := generalize_not_free h1.left M s g' antecedent
        have by_mp_ind  := generalize_not_free h1.right M s g (h2 (by_ind_hyp g sym_variant))
        exact by_mp_ind g' variant
    | Form.box ψ    =>
        rw [is_free] at h1
        intros g' variant s' is_neigh
        exact generalize_not_free h1 M s' g (h2 s' is_neigh) g' variant
    | Form.bind u ψ =>
        simp only [is_free, Bool.and_eq_false_eq_eq_false_or_eq_false] at h1  
        apply Or.elim h1
        . intro u_is_v
          simp only [bne, Bool.not_eq_false', beq_iff_eq] at u_is_v 
          rw [u_is_v]
          rw [u_is_v] at h2
          intros g' variant1 g'' variant2
          have variant3 := is_variant_trans variant2 variant1
          exact h2 g'' variant3
        . intro nfree_in_ψ
          rw [bind_comm]
          intros g' variant_u
          exact generalize_not_free nfree_in_ψ M s g' (h2 g' variant_u)

  theorem svar_substitution {φ : Form} {x y : SVAR} {M : Model} {s : M.W} {g g' : I M.W} 
  (h_subst : is_substable φ y x) (h_var : is_variant g g' x) (h_which_var : g' x = g y) :
  (((M,s,g) ⊨ φ[y // x]) ↔ (M,s,g') ⊨ φ) := by
    induction φ generalizing s g g' with
    | svar z   =>
        apply Iff.intro
        . intro h
          by_cases z_x : z = x
          . rw [show z[y//x] = y by rw[z_x, subst_svar, if_pos (Eq.refl x)], Sat] at h
            rw [z_x, Sat, h_which_var]
            exact h
          . rw [show z[y//x] = z by rw[subst_svar, if_neg (Ne.symm (Ne.intro z_x))], Sat] at h
            rw [Sat, ←(h_var z (Ne.symm z_x))]
            exact h
        . intro h
          by_cases z_x : z = x
          . rw [z_x, show x[y//x] = y by rw[subst_svar, if_pos (Eq.refl x)], Sat, ←h_which_var]
            rw [Sat, z_x] at h
            exact h
          . rw [show z[y//x] = z by rw[subst_svar, if_neg (Ne.symm (Ne.intro z_x))], Sat]
            rw [Sat, ←(h_var z (Ne.symm z_x))] at h
            exact h
    | impl ψ χ ind_hyp_1 ind_hyp_2 =>
        simp only [is_substable, Bool.and_eq_true] at h_subst 
        have by_ind_hyp_1 := (@ind_hyp_1 s g) h_subst.left h_var h_which_var
        have by_ind_hyp_2 := (@ind_hyp_2 s g) h_subst.right h_var h_which_var
        apply Iff.intro
        . simp [-implication_disjunction]
          intro h1 h2
          exact by_ind_hyp_2.mp (h1 (by_ind_hyp_1.mpr h2))
        . intro h1 h2
          exact by_ind_hyp_2.mpr (h1 (by_ind_hyp_1.mp h2))
    | box  ψ ind_hyp                   =>
        apply Iff.intro
        . intro h1 s' s_R_s'
          have by_ind_hyp := (@ind_hyp s' g) h_subst h_var h_which_var
          exact by_ind_hyp.mp (h1 s' s_R_s')
        . intro h1 s' s_R_s'
          have by_ind_hyp := (@ind_hyp s' g) h_subst h_var h_which_var
          exact by_ind_hyp.mpr (h1 s' s_R_s')
    | bind v ψ ind_hyp =>
        cases x_free : is_free x ψ with
        | true =>
            by_cases x_v : x = v
            . -- all x, ψ             and       x is free in ψ
              have x_nfree : is_free x (all v, ψ) = false := by
                simp only [is_free, x_v, bne_self_eq_false, Bool.false_and]
              apply Iff.intro
              . intro h1
                rw [(subst_notfree_var x_nfree).left] at h1
                exact (generalize_not_free x_nfree M s g h1) g' (is_variant_symm.mp h_var)
              . intro h1
                conv => rhs ; rw [(subst_notfree_var x_nfree).left, ←x_v]
                rw [←x_v] at h1
                rw [←x_v] at x_nfree
                exact (generalize_not_free x_nfree M s g' h1) g h_var
            . by_cases y_v : y = v
              . -- all y, ψ          and       x is free in ψ
                -- contradiction with h_subst:
                simp only [is_substable, x_free, beq_iff_eq, y_v,
                  bne_self_eq_false, Bool.false_and, ite_false] at h_subst   
              . --  all v, ψ  (v ≠ x and v ≠ y) and x is free in ψ
                simp only [is_substable, x_free, beq_iff_eq, bne, ite_false, Bool.and_eq_true, Bool.not_eq_true',
                  beq_eq_false_iff_ne, ne_eq, Ne.symm y_v, not_false_eq_true, true_and] at h_subst 
                -- proof:
                apply Iff.intro
                . intro h1
                  -- step one: turn
                  --  (M,s,g)⊨(all v, ψ)[y//x] into
                  --  (M,s,g)⊨all v, ψ[y//x]
                  simp only [subst_svar, if_neg x_v] at h1
                  -- step two
                  intro f' f'_var_g'_v
                  -- Here's the fun part. We're going to apply the
                  --  variant mirror property to f' and g', to obtain
                  --  an interpretation f that is a v-variant of g and 
                  --  also an x-variant of f'.
                  -- Since f is a v-variant of g and we have (M,s,g)⊨all v, ψ[y//x],
                  --  we'll obtain (M,s,f)⊨ψ[y//x].
                  -- From there, we'll apply the induction hypothesis to f and f'
                  --  and prove the goal.
                  have exists_mirror := variant_mirror_property g g' f' h_var (is_variant_symm.mp f'_var_g'_v)
                  match exists_mirror with
                  | ⟨f, f_var_g_v, f_var_f'_x⟩ =>
                      have t1 : f' x = f y := by
                        rw [show f y = g y from Eq.symm (f_var_g_v y (Ne.symm (Ne.intro y_v)))]
                        rw [show f' x = g' x from f'_var_g'_v x (Ne.symm (Ne.intro x_v))]
                        assumption
                      have t2 : (M,s,f) ⊨ ψ[y//x] := h1 f (is_variant_symm.mpr f_var_g_v)
                      exact (@ind_hyp s f f' h_subst f_var_f'_x t1).mp t2
                . intro h1
                  -- do the same thing backwards, basically
                  simp only [subst_svar, if_neg x_v]
                  intro f f_var_g_v
                  have exists_mirror := variant_mirror_property f g g' f_var_g_v h_var
                  match exists_mirror with
                  | ⟨f', f_var_f'_x, f'_var_g'_v⟩ =>
                    have t1 : f' x = f y := by
                        rw [show f y = g y from f_var_g_v y (Ne.symm (Ne.intro y_v))]
                        rw [show f' x = g' x from f'_var_g'_v x (Ne.symm (Ne.intro x_v))]
                        assumption
                    have t2 : (M,s,f') ⊨ ψ := h1 f' f'_var_g'_v
                    exact (@ind_hyp s f f' h_subst f_var_f'_x t1).mpr t2
        | false =>
            have x_nfree : is_free x (all v, ψ) = false := preserve_notfree x v x_free
            apply Iff.intro
            . intro h2 g'' v_variant
              conv at h2 => rhs ; rw [(subst_notfree_var x_nfree).left]
              exact ((generalize_not_free x_nfree M s g h2) g' (is_variant_symm.mp h_var)) g'' v_variant
            . intro h2
              conv => rhs ; rw [(subst_notfree_var x_nfree).left]
              exact (generalize_not_free x_nfree M s g' h2) g h_var
    | _        => simp

    theorem nom_substitution {φ : Form} {x : SVAR} {i : NOM} {M : Model} {s : M.W} {g g' : I M.W}
    (h_var : is_variant g g' x) (h_which_var : g' x = M.Vₙ i) :
    (((M,s,g) ⊨ φ[i // x]) ↔ ((M,s,g') ⊨ φ)) := by
      induction φ generalizing s g g' with
      | svar y =>
          by_cases x_y : x = y
          . apply Iff.intro
            . intro h1
              rw [subst_nom, if_pos x_y] at h1
              rw [Sat, ←x_y, h_which_var]
              exact h1
            . intro h2
              rw [Sat, ←x_y, h_which_var] at h2
              rw [subst_nom, if_pos x_y]
              exact h2
          . apply Iff.intro
            . intro h1
              rw [subst_nom, if_neg x_y] at h1
              rw [Sat, ←(h_var y x_y)]
              exact h1
            . intro h2
              rw [subst_nom, if_neg x_y]
              rw [Sat, ←(h_var y x_y)] at h2
              exact h2
      | impl ψ χ ih_1 ih_2 =>
          have ih_1 := @ih_1 s g g' h_var h_which_var
          have ih_2 := @ih_2 s g g' h_var h_which_var
          conv => lhs
                  rhs
                  rw [subst_nom]
          apply Iff.intro
          . intro h1 antecedent
            exact ih_2.mp (h1 (ih_1.mpr antecedent))
          . intro h2 antecedent
            exact ih_2.mpr (h2 (ih_1.mp antecedent))
      | box ψ ih =>
          conv => lhs
                  rhs
                  rw [subst_nom]
          apply Iff.intro
          . intro h1 s' s_R_s'
            have ih := @ih s' g g' h_var h_which_var
            exact ih.mp (h1 s' s_R_s')
          . intro h2 s' s_R_s'
            have ih := @ih s' g g' h_var h_which_var
            exact ih.mpr (h2 s' s_R_s')
      | bind y ψ ih =>
          conv => lhs
                  rhs
                  rw [subst_nom]
          by_cases x_y : x = y
          . rw [if_pos x_y]
            apply Iff.intro
            . intro h1
              intro f f_var_g'_y
              rw [←x_y, is_variant_symm] at f_var_g'_y
              have f_var_g_x := is_variant_trans h_var f_var_g'_y
              rw [x_y] at f_var_g_x
              exact h1 f (is_variant_symm.mp f_var_g_x)
            . intro h2
              intro f f_var_g_y
              rw [←x_y, is_variant_symm] at f_var_g_y
              have f_var_g'_x := is_variant_trans (is_variant_symm.mp f_var_g_y) h_var
              rw [x_y] at f_var_g'_x
              exact h2 f f_var_g'_x
          . rw [if_neg x_y]
            apply Iff.intro
            . intro h1
              intro f' f'_var_g'_y
              have t1 : f' x = Model.Vₙ M i := Eq.trans (f'_var_g'_y x (Ne.symm x_y)) h_which_var
              have exists_mirror := variant_mirror_property g g' f' h_var (is_variant_symm.mp f'_var_g'_y)
              match exists_mirror with
              | ⟨f, g_var_f_y, f_var_f'_x⟩ =>
                  have t2 : (M,s,f) ⊨ ψ[i//x] := h1 f (is_variant_symm.mp g_var_f_y)
                  exact (@ih s f f' f_var_f'_x t1).mp t2
            . intro h2
              intro f f_var_g_y
              have exists_mirror := variant_mirror_property g' g f (is_variant_symm.mp h_var) (is_variant_symm.mp f_var_g_y)
              match exists_mirror with
              | ⟨f', g'_var_f'_y, f'_var_f_x⟩ =>
                  have t1 : f' x = Model.Vₙ M i := by
                    rw [← g'_var_f'_y x (Ne.symm x_y), h_which_var]
                  have t2 : (M,s,f') ⊨ ψ := h2 f' (is_variant_symm.mp g'_var_f'_y)
                  exact (@ih s f f' (is_variant_symm.mp f'_var_f_x) t1).mpr t2
      | _ => simp

  theorem sat_iterated_nec {φ : Form} {n : Nat} {M : Model} {s : M.W} {g : I M.W} :
  ((M,s,g) ⊨ iterate_nec n φ) ↔ (∀ s' : M.W, (path M.R s s' n) → (M,s',g) ⊨ φ) := by
    induction n generalizing φ with
    | zero   =>
        rw [iterate_nec, iterate_nec.loop]
        unfold path
        apply Iff.intro
        . intro _ _ s_s'
          rw [←s_s']
          assumption
        . intro h
          exact h s (Eq.refl s)
    | succ m ih =>
        apply Iff.intro
        . intro h1
          rw [iter_nec_succ] at h1
          intro s' ex_path1
          unfold path at ex_path1
          match ex_path1 with
          | ⟨i, i_R_s', ex_path2⟩ =>
              exact ih.mp h1 i ex_path2 s' i_R_s'
        . intro h2
          rw [iter_nec_succ, ih]
          intro i ex_path2 s' i_R_s'
          have ex_path1 : path M.R s s' (Nat.succ m) := ⟨i, i_R_s', ex_path2⟩
          exact h2 s' ex_path1

  theorem sat_iterated_pos {φ : Form} {n : Nat} {M : Model} {s : M.W} {g : I M.W} :
  ((M,s,g) ⊨ iterate_pos n φ) ↔ (∃ s' : M.W, (path M.R s s' n) ∧ (M,s',g) ⊨ φ) := by
    induction n generalizing φ with
    | zero   =>
        rw [iterate_pos, iterate_pos.loop]
        unfold path
        apply Iff.intro
        . intro h
          let s' := s
          exists s'
        . intro h
          match h with
          | ⟨s', s_s', s'_sat_φ⟩ => rw [s_s'] ; exact s'_sat_φ
    | succ m ih =>
        apply Iff.intro
        . intro h1
          rw [iter_pos_succ] at h1
          have by_ih := ih.mp h1
          match by_ih with
          | ⟨s', ex_path1, s'_pos_φ⟩ => 
            rw [pos_sat] at s'_pos_φ
            match s'_pos_φ with
              | ⟨s'', s'_R_s'', s''_φ⟩ => 
                exists s''
                exact ⟨⟨s', s'_R_s'', ex_path1⟩, s''_φ⟩
        . intro h2
          rw [iter_pos_succ]
          unfold path at h2
          match h2 with
          | ⟨s', exist, s'_φ⟩ =>
            match exist with
            | ⟨s'', s''_R_s', ex_path2⟩ =>
              have s''_pos_φ : (M,s'',g) ⊨ ◇ φ := by rw [pos_sat] ; exists s'
              have premise : ∃ s'', path M.R s s'' m ∧ (M,s'',g)⊨◇ φ := ⟨s'', ⟨ex_path2, s''_pos_φ⟩⟩
              exact ih.mpr premise

  theorem svar_unique_state {v : SVAR} {M : Model} {s : M.W} {g : I M.W} :
  (((M,s,g) ⊨ Form.svar v) → (∀ r : M.W, ((M,r,g) ⊨ Form.svar v) → r = s)) := by
    intro h1 r h2
    rw [h2, h1]
end Lemmas

section Tautologies
  -- Todo: find a a proof of soundness for tautologies that doesn't rely
  -- on Sat's decidability.  
  noncomputable def model_val_func (M : Model) (s : M.W) (g : I M.W) : Form → Bool
    | Form.bttm     => false
    | Form.prop p   => ite ((M,s,g) ⊨ p) true false
    | Form.nom  i   => ite ((M,s,g) ⊨ i) true false
    | Form.svar x   => ite ((M,s,g) ⊨ x) true false
    | Form.impl ψ χ => ¬(model_val_func M s g ψ = true) ∨ model_val_func M s g χ = true
    | Form.box ψ    => ite ((M,s,g) ⊨ □ψ) true false
    | Form.bind x ψ => ite ((M,s,g) ⊨ all x, ψ) true false

  noncomputable def model_eval (M : Model) (s : M.W) (g : I M.W) : Eval :=
      let f := model_val_func M s g
      have p1 : f ⊥ = false := by simp [model_val_func]
      have p2 : ∀ φ ψ : Form, (f (φ ⟶ ψ) = true) ↔ (¬(f φ) = true ∨ (f ψ) = true) := λ φ ψ : Form => by simp [model_val_func] 
      ⟨f, p1, p2⟩

  theorem model_eval_equiv (M : Model) (s : M.W) (g : I M.W) (f : Form → Bool) (h : f = model_val_func M s g) : ∀ φ : Form, ((M,s,g) ⊨ φ) ↔ f φ = true := by
    intro φ
    induction φ with
    | impl _ _ ih1 ih2 =>
        simp [h, model_val_func] at ih1
        simp [h, model_val_func] at ih2
        simp [h, model_val_func, ih1, ih2]
    | box _ ih  =>
        simp [h, model_val_func] at ih
        simp [h, model_val_func, ih, -Sat]
    | bind _ _ ih  =>
        simp [h, model_val_func] at ih
        simp [h, model_val_func, ih, -Sat]
    | _  =>
        simp [h, model_val_func]

  theorem taut_sound : Tautology φ → ⊨ φ := by
    rw [contraposition (Tautology φ) (⊨ φ), Valid, Tautology]
    conv =>
      rw [negated_universal, negated_universal]
      congr
      . rhs; intro M; rw [negated_universal]; rhs; intro s; rw [negated_universal]; rhs; intro g; rw [←neg_sat]
      . rhs; intro e; rw [Bool.not_eq_true, ←e_neg]
    intro h
    match h with
    | ⟨M, s, g, hw⟩ =>
        let eval := model_eval M s g
        exists eval
        have : (eval.f) = (model_val_func M s g) := by simp [model_eval]
        have equiv := model_eval_equiv M s g eval.f this (∼φ)
        rw [←equiv]
        exact hw
end Tautologies

theorem WeakSoundness : (⊢ φ) → (⊨ φ) := by
  intro pf
  induction pf with

  | tautology h => exact taut_sound h

  | ax_k =>
      intro (M : Model) (s : M.W) (g : I M.W)
      unfold Sat
      intro nec_impl nec_phi (s' : M.W) (rel : M.R s s')
      exact (nec_impl s' rel) (nec_phi  s' rel)

  | ax_q1 _ _ p =>
      intro M s g h1 h2 g' variant
      exact (h1 g' variant) ((generalize_not_free p M s g h2) g' variant)

  | ax_q2_svar _ x y h_subst =>
      intro (M : Model) (s : M.W) (g : I M.W)
      intro h
      -- let's build an explicit x-variant of g, named g'
      let g' : I M.W := λ v => ite (v ≠ x) (g v) (g y)
      have h_var : is_variant g g' x := by
        intro v x_not_v
        simp [Ne.symm x_not_v]
      have h_which_var : g' x = g y := by simp
      -- this exact g' can be used in the substitution lemma we proved
      rw [svar_substitution h_subst h_var h_which_var]
      -- now the goal becomes immediately provable
      exact h g' (is_variant_symm.mp h_var)
  
  | ax_q2_nom _ x i =>
      intro (M : Model) (s : M.W) (g : I M.W)
      intro h
      let g' : I M.W := λ v => ite (v ≠ x) (g v) (M.Vₙ i)
      have h_var : is_variant g g' x := by
        intro v x_not_v
        simp [Ne.symm x_not_v]
      have h_which_var : g' x = M.Vₙ i := by simp
      rw [nom_substitution h_var h_which_var]
      exact h g' (is_variant_symm.mp h_var)
  
  | ax_name v =>
      intro (M : Model) (s : M.W) (g : I M.W)
      rw [ex_sat]
      let g' : I M.W := λ x => ite (v = x) s (g x)
      apply Exists.intro
      . apply And.intro
        . exact show is_variant g' g v by
            rw [is_variant]
            intro y v_not_y
            simp [v_not_y]
        . simp

  | ax_nom n m =>
      intro _ _ _ _ _ h
      rw [sat_iterated_pos] at h
      rw [sat_iterated_nec]
      intro s'' _ s''_sat_v
      match h with
      | ⟨s', _, s'_sat⟩ =>
          rw [and_sat] at s'_sat
          have s'_sat_v := s'_sat.left
          have s'_sat_φ := s'_sat.right
          have s''_is_s' := svar_unique_state s'_sat_v s'' s''_sat_v
          rw [s''_is_s']
          exact s'_sat_φ
  
  | @ax_brcn φ v =>
      intro M s g (h : (M,s,g) ⊨ all v, □φ) s' sRs' g' g_var_g'_v
      exact (h g' g_var_g'_v) s' sRs'

  | general _ _ ih =>
      intro M s _ g' _
      exact ih M s g'

  | necess _ _ ih =>
      intro M _ g s' _
      exact ih M s' g

  | mp _ _ ih_maj ih_min =>
      intro M s g
      exact (ih_maj M s g) (ih_min M s g)

theorem Soundness : (Γ ⊢ φ) → (Γ ⊨ φ) := by
  rw [SyntacticConsequence]
  intro h
  apply SetEntailment
  match h with
  | ⟨L, conseq⟩ =>
    have := (@WeakSoundness (conjunction Γ L⟶φ)) conseq
    exact ⟨L, this⟩

#print axioms Soundness
#check propext
#check Classical.choice
#check Quot.sound