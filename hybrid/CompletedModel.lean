import Hybrid.ProofUtils
import Hybrid.Truth
import Hybrid.Soundness
-- Interface for proofs to be filled
-- about renaming bound vars:
import Hybrid.RenameBound

open Classical

theorem truths_set_cons : (truths_set M s g).consistent := by
  intro habs
  have habs := Soundness habs
  rw [Entails] at habs
  have habs := habs M s g (by simp [truths_set])
  exact habs

def restrict_by : (Set Form → Prop) → (Set Form → Set Form → Prop) → (Set Form → Set Form → Prop) :=
  λ restriction => λ R => λ Γ => λ Δ => restriction Γ ∧ restriction Δ ∧ R Γ Δ

theorem path_conj {R : α → Prop} : path (λ a b => R a ∧ R b) a b n → (R a → R b) := by
  cases n with
  | zero =>
      unfold path; intro; simp [*]
  | succ n =>
      unfold path
      intro ⟨_, h⟩ _
      exact h.1.2

theorem path_restr : path (restrict_by R₁ R₂) Γ Δ n → path R₂ Γ Δ n := by
  simp only [restrict_by]
  induction n generalizing Δ with
  | zero => simp only [path, imp_self]
  | succ n ih =>
      simp only [path]
      intro ⟨Θ, ⟨⟨_, _, h1⟩, h2⟩⟩
      exists Θ
      apply And.intro 
      assumption
      apply ih
      assumption

theorem path_restr' : path (restrict_by R₁ R₂) Γ Δ n → (R₁ Γ → R₁ Δ) := by
  simp only [restrict_by]
  cases n with
  | zero =>
      unfold path; intro; simp [*]
  | succ n =>
      unfold path
      intro ⟨_, h⟩ _
      exact h.1.2.1

structure GeneralModel where
  W : Type    
  R : W → W → Prop
  Vₚ: PROP → Set W
  Vₙ: NOM  → Set W

def GeneralI (W : Type) := SVAR → Set W

def Canonical : GeneralModel where
  W := Set Form
  R := restrict_by Set.MCS (λ Γ => λ Δ => (∀ {φ : Form}, □φ ∈ Γ → φ ∈ Δ))
--  R := λ Γ => λ Δ => Γ.MCS ∧ Δ.MCS ∧ (∀ φ : Form, □φ ∈ Γ → φ ∈ Δ)
  Vₚ:= λ p => {Γ | Γ.MCS ∧ ↑p ∈ Γ}
  Vₙ:= λ i => {Γ | Γ.MCS ∧ ↑i ∈ Γ}

def CanonicalI : SVAR → Set (Set Form) := λ x => {Γ | Γ.MCS ∧ ↑x ∈ Γ}

instance : Membership Form Canonical.W := ⟨Set.Mem⟩  

theorem R_nec : □φ ∈ Γ → Canonical.R Γ Δ → φ ∈ Δ := by
  intro h1 h2
  simp only [Canonical, restrict_by] at h2
  apply h2.right.right
  assumption

theorem R_pos : Canonical.R Γ Δ ↔ (Γ.MCS ∧ Δ.MCS ∧ ∀ {φ}, (φ ∈ Δ → ◇φ ∈ Γ)) := by
  simp only [Canonical, restrict_by]
  apply Iff.intro
  . intro ⟨h1, h2, h3⟩
    simp only [*, true_and]
    intro φ φ_mem
    rw [←(@not_not (◇φ ∈ Γ))]
    intro habs
    have habs := h1.right habs
    rw [←Proof.Deduction, ←Form.neg, Form.diamond] at habs
    have habs : ∼φ ∈ Δ := by
      apply h3
      apply Proof.MCS_pf h1
      apply Proof.Γ_mp
      apply Proof.Γ_theorem
      apply Proof.tautology
      apply dne
      assumption
    unfold Set.MCS Set.consistent at h1 h2
    apply h2.left
    apply Proof.Γ_mp
    repeat (apply Proof.Γ_premise; assumption)
  . intro ⟨h1, h2, h3⟩
    simp only [*, true_and]
    intro φ φ_mem
    rw [←(@not_not (φ ∈ Δ))]
    intro habs
    have habs := h2.right habs
    rw [←Proof.Deduction, ←Form.neg] at habs
    have habs : ◇∼φ ∈ Γ := by
      apply h3
      apply Proof.MCS_pf h2
      assumption
    unfold Set.MCS Set.consistent at h1 h2
    apply h1.left
    apply Proof.Γ_mp
    apply Proof.Γ_premise
    assumption
    apply Proof.Γ_mp
    apply Proof.Γ_theorem
    apply Proof.mp
    apply Proof.tautology
    apply iff_elim_l
    apply Proof.dn_nec
    apply Proof.Γ_premise
    assumption

theorem R_iter_nec (n : ℕ) : (iterate_nec n φ) ∈ Γ → path Canonical.R Γ Δ n → φ ∈ Δ := by
  intro h1 h2
  induction n generalizing φ Δ with
  | zero =>
      simp only [iterate_nec, iterate_nec.loop, path] at h1 h2
      rw [←h2]
      assumption
  | succ n ih =>
      simp only [path, iter_nec_succ] at ih h1 h2
      have ⟨Κ, hk1, hk2⟩ := h2
      apply R_nec
      exact (ih h1 hk2)
      assumption

theorem R_iter_pos (n : ℕ) : path Canonical.R Γ Δ n → ∀ {φ}, (φ ∈ Δ → (iterate_pos n φ) ∈ Γ) := by
  intro h1 φ h2
  induction n generalizing φ Δ with
  | zero =>
      simp [path, iterate_pos, iterate_pos.loop] at h1 ⊢
      rw [h1]
      assumption
  | succ n ih =>
      simp only [path, iter_pos_succ] at ih h1 ⊢
      have ⟨Κ, hk1, hk2⟩ := h1
      rw [R_pos] at hk1
      apply ih hk2
      exact hk1.right.right h2

theorem restrict_R_iter_nec {n : ℕ} : (iterate_nec n φ) ∈ Γ → path (restrict_by R Canonical.R) Γ Δ n → φ ∈ Δ := by
  intro h1 h2
  apply R_iter_nec
  assumption
  apply path_restr
  assumption

theorem restrict_R_iter_pos {n : ℕ} : path (restrict_by R Canonical.R) Γ Δ n → ∀ {φ}, (φ ∈ Δ → (iterate_pos n φ) ∈ Γ) := by
  intro h1 φ h2
  apply R_iter_pos
  apply path_restr
  repeat assumption

-- implicitly we mean generated submodels *of the canonical model*
def Set.GeneratedSubmodel (Θ : Set Form) (restriction : Set Form → Prop) : GeneralModel where
  W := Set Form
  R := λ Γ => λ Δ =>
    (∃ n, path (restrict_by restriction Canonical.R) Θ Γ n) ∧
    (∃ m, path (restrict_by restriction Canonical.R) Θ Δ m) ∧
    Canonical.R Γ Δ
  Vₚ:= λ p => {Γ | (∃ n, path (restrict_by restriction Canonical.R) Θ Γ n) ∧ Γ ∈ Canonical.Vₚ p}
  Vₙ:= λ i => {Γ | (∃ n, path (restrict_by restriction Canonical.R) Θ Γ n) ∧ Γ ∈ Canonical.Vₙ i}

def Set.GeneratedSubI (Θ : Set Form) (restriction : Set Form → Prop) : GeneralI (Set Form) := λ x =>
  {Γ | (∃ n, path (restrict_by restriction Canonical.R) Θ Γ n) ∧ Γ ∈ CanonicalI x}

theorem submodel_canonical_path (Θ : Set Form) (r : Set Form → Prop) (rt : r Θ) : path (Θ.GeneratedSubmodel r).R Γ Δ n → path (restrict_by r Canonical.R) Γ Δ n := by
  intro h
  induction n generalizing Γ Δ with
  | zero =>
      simp [path] at h ⊢
      exact h
  | succ n ih =>
      have ⟨Η, ⟨h1, h2⟩⟩ := h
      have := ih h2
      clear h h2
      exists Η 
      apply And.intro
      . simp [Set.GeneratedSubmodel] at h1
        have ⟨⟨n, l1⟩, ⟨⟨m, l2⟩, l3⟩⟩ := h1 
        simp [restrict_by, l3]
        apply And.intro <;>
        . apply path_restr'
          repeat assumption
      . exact this

theorem path_root (Θ : Set Form) (r : Set Form → Prop) : path (restrict_by r Canonical.R) Θ Γ n → path (Θ.GeneratedSubmodel r).R Θ Γ n := by
  induction n generalizing Θ Γ with
  | zero => simp [path]
  | succ n ih =>
      simp only [path]
      intro ⟨Δ, ⟨h1, h2⟩⟩  
      exists Δ
      apply And.intro 
      . simp [Set.GeneratedSubmodel]
        apply And.intro
        . exists n
        . apply And.intro
          . exists (n+1)
            simp [path]
            exists Δ
          . exact h1.2.2
      . apply ih
        exact h2

def WitnessedModel {Θ : Set Form} (_ : Θ.MCS) (_ : Θ.witnessed) : GeneralModel := Θ.GeneratedSubmodel Set.witnessed
def WitnessedI {Θ : Set Form} (_ : Θ.MCS) (_ : Θ.witnessed) : GeneralI (Set Form) := Θ.GeneratedSubI Set.witnessed

def CompletedModel {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : GeneralModel where
  W := Set Form
  R := λ Γ => λ Δ => ((WitnessedModel mcs wit).R Γ Δ) ∨ (Γ = {Form.bttm} ∧ Δ = Θ)
  Vₚ:= λ p => (WitnessedModel mcs wit).Vₚ p
  Vₙ:= λ i => if (WitnessedModel mcs wit).Vₙ i ≠ ∅
              then  (WitnessedModel mcs wit).Vₙ i
              else { {Form.bttm} }
def CompletedI {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : GeneralI (Set Form) := λ x =>
  if (WitnessedI mcs wit) x ≠ ∅
              then  (WitnessedI mcs wit) x
              else { {Form.bttm} }

-- Lemma 3.11, Blackburn 1998, pg. 637
lemma subsingleton_valuation : ∀ {Θ : Set Form} {R : Set Form → Prop} (i : NOM), Θ.MCS → ((Θ.GeneratedSubmodel R).Vₙ i).Subsingleton := by
  -- the hypothesis Θ.MCS is not necessary
  --  but to prove the theorem without it would complicate
  --  the code, and anyway, we'll only ever use MCS-generated submodels
  simp only [Set.Subsingleton, Set.GeneratedSubmodel]
  intro Θ restr i Θ_MCS Γ ⟨⟨n, h1⟩, ⟨Γ_MCS, Γ_i⟩⟩  Δ ⟨⟨m, h2⟩, ⟨Δ_MCS, Δ_i⟩⟩
  simp only [Set.GeneratedSubmodel] at Γ Δ ⊢
  rw [←(@not_not (Γ = Δ))]
  simp only [Set.ext_iff, not_forall, iff_iff_implies_and_implies,
      implication_disjunction, not_and, negated_disjunction, not_not, conj_comm]
  intro ⟨φ, h⟩
  apply Or.elim h
  . clear h
    intro ⟨h3, h4⟩
    apply h4
    have := restrict_R_iter_pos h1 ((Proof.MCS_conj Γ_MCS i φ).mp ⟨Γ_i, h3⟩)
    have := Proof.MCS_mp Θ_MCS (Proof.MCS_thm Θ_MCS (@Proof.ax_nom_instance φ i n m)) this
    have := restrict_R_iter_nec this h2
    apply Proof.MCS_mp
    repeat assumption
  . clear h
    intro ⟨h3, h4⟩
    apply h3
    have := restrict_R_iter_pos h2 ((Proof.MCS_conj Δ_MCS i φ).mp ⟨Δ_i, h4⟩)
    have := Proof.MCS_mp Θ_MCS (Proof.MCS_thm Θ_MCS (@Proof.ax_nom_instance φ i m n)) this
    have := restrict_R_iter_nec this h1
    apply Proof.MCS_mp
    repeat assumption

lemma subsingleton_i : ∀ {Θ : Set Form} {R : Set Form → Prop} (x : SVAR), Θ.MCS → ((Θ.GeneratedSubI R) x).Subsingleton := by
  simp only [Set.Subsingleton, Set.GeneratedSubmodel]
  intro Θ restr x Θ_MCS Γ ⟨⟨n, h1⟩, ⟨Γ_MCS, Γ_i⟩⟩  Δ ⟨⟨m, h2⟩, ⟨Δ_MCS, Δ_i⟩⟩
  simp only [Set.GeneratedSubmodel] at Γ Δ ⊢
  rw [←(@not_not (Γ = Δ))]
  simp only [Set.ext_iff, not_forall, iff_iff_implies_and_implies,
      implication_disjunction, not_and, negated_disjunction, not_not, conj_comm]
  intro ⟨φ, h⟩
  apply Or.elim h
  . clear h
    intro ⟨h3, h4⟩
    apply h4
    have := restrict_R_iter_pos h1 ((Proof.MCS_conj Γ_MCS x φ).mp ⟨Γ_i, h3⟩)
    have := Proof.MCS_mp Θ_MCS (Proof.MCS_thm Θ_MCS (@Proof.ax_nom_instance' φ x n m)) this
    have := restrict_R_iter_nec this h2
    apply Proof.MCS_mp
    repeat assumption
  . clear h
    intro ⟨h3, h4⟩
    apply h3
    have := restrict_R_iter_pos h2 ((Proof.MCS_conj Δ_MCS x φ).mp ⟨Δ_i, h4⟩)
    have := Proof.MCS_mp Θ_MCS (Proof.MCS_thm Θ_MCS (@Proof.ax_nom_instance' φ x m n)) this
    have := restrict_R_iter_nec this h1
    apply Proof.MCS_mp
    repeat assumption

lemma wit_subsingleton_valuation {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) (i : NOM) : ((WitnessedModel mcs wit).Vₙ i).Subsingleton := by
  rw [WitnessedModel]
  apply subsingleton_valuation
  assumption

lemma wit_subsingleton_i {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) (x : SVAR) : ((WitnessedI mcs wit) x).Subsingleton := by
  rw [WitnessedI]
  apply subsingleton_i
  assumption

lemma completed_singleton_valuation {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) (i : NOM) : ∃ Γ : Set Form, (CompletedModel mcs wit).Vₙ i = {Γ} := by
  simp [CompletedModel]
  split
  . simp
  . next h =>
      rw [←ne_eq, ←Set.nonempty_iff_ne_empty, Set.nonempty_def] at h
      match h with
      | ⟨Γ, h⟩ =>   
          exists Γ
          apply (Set.subsingleton_iff_singleton h).mp
          apply wit_subsingleton_valuation
          assumption

lemma completed_singleton_i {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) (x : SVAR) : ∃ Γ : Set Form, (CompletedI mcs wit) x = {Γ} := by
  simp [CompletedI]
  split
  . simp
  . next h =>
      rw [←ne_eq, ←Set.nonempty_iff_ne_empty, Set.nonempty_def] at h
      match h with
      | ⟨Γ, h⟩ =>   
          exists Γ
          apply (Set.subsingleton_iff_singleton h).mp
          apply wit_subsingleton_i
          assumption

def Set.MCS_in (Γ : Set Form) {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : Prop := ∃ n, path (WitnessedModel mcs wit).R Θ Γ n

theorem mcs_in_prop {Γ Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : Γ.MCS_in mcs wit → (Γ.MCS ∧ Γ.witnessed) := by
  intro ⟨n, h⟩
  cases n with
  | zero =>
      simp [path] at h
      simp [←h, mcs, wit]
  | succ n =>
      have ⟨Δ, h1, h2⟩ := h
      clear h2
      simp [WitnessedModel, Set.GeneratedSubmodel, Canonical] at h1
      have ⟨h3, ⟨m, h4⟩, h5⟩ := h1
      clear h1 h3
      simp [h5.2.1]
      apply path_restr' h4
      exact wit

theorem mcs_in_wit {Γ Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : Γ.MCS_in mcs wit → (∃ n, path (restrict_by Set.witnessed Canonical.R) Θ Γ n) := by
  intro ⟨n, h⟩
  exists n
  cases n with 
  | zero =>
      simp [path] at h ⊢
      exact h
  | succ n =>
      simp [path]
      have ⟨Δ, h1, h2⟩ := h
      exists Δ
      apply And.intro
      . apply submodel_canonical_path
        repeat assumption 
      . have ⟨⟨_, l⟩, ⟨⟨_, r1⟩, r2⟩⟩ := h1
        simp [restrict_by, r2]
        apply And.intro <;>
        . apply path_restr'
          repeat assumption

def needs_dummy {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) := (∃ i, ((CompletedModel mcs wit).Vₙ i) = { (Set.singleton Form.bttm) }) ∨
                                                                                 (∃ x, ((CompletedI mcs wit) x) = { (Set.singleton Form.bttm) })

def Set.is_dummy (Γ : Set Form) {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) := needs_dummy mcs wit ∧ Γ = {Form.bttm}


theorem choose_subtype {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed)  : ((completed_singleton_valuation mcs wit i).choose.MCS_in mcs wit) ∨ (completed_singleton_valuation mcs wit i).choose.is_dummy mcs wit := by
  apply choice_intro (λ Γ => (Set.MCS_in Γ mcs wit) ∨ (Set.is_dummy Γ mcs wit))
  intro Γ h
  simp [CompletedModel, WitnessedModel, Set.GeneratedSubmodel] at h
  split at h
  . next c =>
      apply Or.inr
      apply And.intro
      . apply Or.inl
        exists i
        simp [CompletedModel, WitnessedModel, Set.GeneratedSubmodel, c]
        apply Eq.refl
      . apply Eq.symm
        simp at h
        exact h
  . apply Or.inl
    have Γ_mem : Γ ∈ {Γ | (∃ n, path (restrict_by Set.witnessed Canonical.R) Θ Γ n) ∧ Γ ∈ GeneralModel.Vₙ Canonical i} := by simp [h]
    simp at Γ_mem
    have ⟨⟨n, pth⟩, _⟩ := Γ_mem
    simp [Set.MCS_in, WitnessedModel]
    exists n
    apply path_root
    exact pth

theorem choose_subtype' {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : ((completed_singleton_i mcs wit i).choose.MCS_in mcs wit) ∨ (completed_singleton_i mcs wit i).choose.is_dummy mcs wit := by
  apply choice_intro (λ Γ => (Set.MCS_in Γ mcs wit) ∨ (Set.is_dummy Γ mcs wit))
  intro Γ h
  simp [CompletedI, WitnessedI, Set.GeneratedSubI] at h
  split at h
  . next c =>
      apply Or.inr
      apply And.intro
      . apply Or.inr
        exists i
        simp [CompletedI, WitnessedI, Set.GeneratedSubI, c]
        apply Eq.refl
      . apply Eq.symm
        simp at h
        exact h
  . apply Or.inl
    have Γ_mem : Γ ∈ {Γ | (∃ n, path (restrict_by Set.witnessed Canonical.R) Θ Γ n) ∧ Γ ∈ CanonicalI i} := by simp [h]
    simp at Γ_mem
    have ⟨⟨n, pth⟩, _⟩ := Γ_mem
    simp [Set.MCS_in, WitnessedModel]
    exists n
    apply path_root
    exact pth


-- pg. 638: "we only glue on a dummy state when we are forced to"
--    we define the set of states as Γ.MCS_in ∨ Γ.is_dummy
--    where is_dummy contains the assumption that we are *forced*
--    to glue a dummy
noncomputable def StandardCompletedModel {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : Model :=
    ⟨{Γ : Set Form // Γ.MCS_in mcs wit ∨ Γ.is_dummy mcs wit},
      λ Γ => λ Δ => (CompletedModel mcs wit).R Γ.1 Δ.1,
      λ p => {Γ | Γ.1 ∈ ((CompletedModel mcs wit).Vₚ p)},
      λ i => ⟨(completed_singleton_valuation mcs wit i).choose, choose_subtype mcs wit⟩⟩

noncomputable def StandardCompletedI {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : I (StandardCompletedModel mcs wit).W :=
    λ x => ⟨(completed_singleton_i mcs wit x).choose, choose_subtype' mcs wit⟩

theorem sat_dual_all_ex : ((M,s,g) ⊨ (all x, φ)) ↔ (M,s,g) ⊨ ∼(ex x, ∼φ) := by
  apply Iff.intro
  . intro h; simp only [Form.bind_dual, neg_sat, not_not] at *
    intro g' var
    simp only [Form.bind_dual, neg_sat, not_not] at *
    apply h
    repeat assumption
  . intro h; simp only [Form.bind_dual, neg_sat, not_not] at *
    intro g' var
    have := h g' var
    simp only [Form.bind_dual, neg_sat, not_not] at this
    exact this

theorem sat_dual_nec_pos : ((M,s,g) ⊨ (□ φ)) ↔ (M,s,g) ⊨ ∼(◇ ∼φ) := by
  apply Iff.intro
  . intro h; simp only [Form.diamond, neg_sat, not_not] at *
    intro _ _
    simp only [neg_sat, not_not] at *
    apply h
    repeat assumption
  . intro h; simp only [Form.diamond, neg_sat, not_not] at *
    intro s' r
    have := h s' r
    simp only [neg_sat, not_not] at this
    exact this

@[simp]
def coe (Δ : Set Form) {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) (h : Δ.MCS_in mcs wit) : (StandardCompletedModel mcs wit).W := ⟨Δ, Or.inl h⟩

def statement (φ : Form) {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) := ∀ {Δ : Set Form}, (h : Δ.MCS_in mcs wit) → φ ∈ Δ ↔ (StandardCompletedModel mcs wit, coe Δ mcs wit h, StandardCompletedI mcs wit) ⊨ φ 


lemma truth_bttm : ∀ {Θ : Set Form}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (statement ⊥ mcs wit) := by
  intro _ mcs' wit' Δ h
  have := (mcs_in_prop mcs' wit' h).1
  simp [←Proof.MCS_pf_iff this]
  exact this.1

lemma truth_prop : ∀ {Θ : Set Form} {p : PROP}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (statement p mcs wit) := by
  intro Θ  _ mcs wit Δ h
  have ⟨D_mcs, _⟩ := (mcs_in_prop mcs wit h)
  apply Iff.intro
  . intro hl
    apply And.intro
    . apply mcs_in_wit
      exact h
      exact wit
    . simp [Canonical, hl, D_mcs]
  . simp [StandardCompletedModel, CompletedModel, WitnessedModel, Set.GeneratedSubmodel, restrict_by, Canonical, -implication_disjunction]
    intros
    assumption

lemma truth_nom_help : ∀ {Θ : Set Form} {i : NOM}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → ∀ {Δ : Set Form}, Δ.MCS_in mcs wit → (↑i ∈ Δ ↔ ((StandardCompletedModel mcs wit).Vₙ ↑i).1 = Δ) := by
  intro Θ i mcs wit Δ h_in
  have ⟨D_mcs, _⟩ := (mcs_in_prop mcs wit h_in)
  simp [StandardCompletedModel, CompletedModel, WitnessedModel]
  apply Iff.intro
  . intro h
    apply choice_intro (λ Γ : Set Form => Γ = Δ)
    intro Η eta_eq
    have delta_mem : Δ ∈ (Θ.GeneratedSubmodel Set.witnessed).Vₙ i := by
      simp [Set.GeneratedSubmodel, WitnessedModel] at h_in ⊢
      apply And.intro
      . have ⟨n, h_in⟩ := h_in
        exists n
        exact submodel_canonical_path Θ Set.witnessed wit h_in
      . simp [Canonical, h, D_mcs]
    split at eta_eq
    . next fls =>
        exfalso
        rw [←@not_not (((Θ.GeneratedSubmodel Set.witnessed).Vₙ i) = ∅), ←Ne,
          ←Set.nonempty_iff_ne_empty, Set.nonempty_def, not_exists] at fls
        apply fls Δ 
        exact delta_mem
    . have eta_mem : Η ∈ (Θ.GeneratedSubmodel Set.witnessed).Vₙ i := by simp [eta_eq]
      apply subsingleton_valuation i mcs
      exact eta_mem
      exact delta_mem
  . intro h
    rw [←h] at h_in D_mcs ⊢
    clear h
    simp [StandardCompletedModel, CompletedModel, WitnessedModel] at h_in D_mcs ⊢
    apply choice_intro (λ Γ : Set Form => ↑i ∈ Γ)
    intro Η eta_eq
    split at eta_eq
    . next fls =>
        exfalso
        apply D_mcs.left
        apply choice_intro (λ Γ => Γ ⊢ ⊥)
        intro _ a
        simp [fls, Set.eq_singleton_iff_unique_mem] at a
        apply Proof.Γ_premise
        exact a.left.left
    . have eta_mem : Η ∈ (Θ.GeneratedSubmodel Set.witnessed).Vₙ i := by simp [eta_eq]
      simp [Set.GeneratedSubmodel, Canonical] at eta_mem
      exact eta_mem.left.left

lemma truth_svar_help : ∀ {Θ : Set Form} {i : SVAR}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → ∀ {Δ : Set Form}, Δ.MCS_in mcs wit → (↑i ∈ Δ ↔ (StandardCompletedI mcs wit ↑i).1 = Δ) := by
  intro Θ i mcs wit Δ h_in
  have ⟨D_mcs, _⟩ := (mcs_in_prop mcs wit h_in)
  simp [StandardCompletedI, CompletedI, WitnessedI]
  apply Iff.intro
  . intro h
    apply choice_intro (λ Γ : Set Form => Γ = Δ)
    intro Η eta_eq
    have delta_mem : Δ ∈ Θ.GeneratedSubI Set.witnessed i := by
      simp [Set.GeneratedSubI, WitnessedI] at h_in ⊢
      apply And.intro
      . have ⟨n, h_in⟩ := h_in
        exists n
        exact submodel_canonical_path Θ Set.witnessed wit h_in
      . simp [CanonicalI, h, D_mcs]
    split at eta_eq
    . next fls =>
        exfalso
        rw [←@not_not ((Θ.GeneratedSubI Set.witnessed i) = ∅), ←Ne,
          ←Set.nonempty_iff_ne_empty, Set.nonempty_def, not_exists] at fls
        apply fls Δ 
        exact delta_mem
    . have eta_mem : Η ∈ Θ.GeneratedSubI Set.witnessed i := by simp [eta_eq]
      apply subsingleton_i i mcs
      exact eta_mem
      exact delta_mem
  . intro h
    rw [←h] at h_in D_mcs ⊢
    clear h
    simp [StandardCompletedI, CompletedI, WitnessedI] at h_in D_mcs ⊢
    apply choice_intro (λ Γ : Set Form => ↑i ∈ Γ)
    intro Η eta_eq
    split at eta_eq
    . next fls =>
        exfalso
        apply D_mcs.left
        apply choice_intro (λ Γ => Γ ⊢ ⊥)
        intro _ a
        simp [fls, Set.eq_singleton_iff_unique_mem] at a
        apply Proof.Γ_premise
        exact a.left.left
    . have eta_mem : Η ∈ Θ.GeneratedSubI Set.witnessed i := by simp [eta_eq]
      simp [Set.GeneratedSubI, CanonicalI] at eta_mem
      exact eta_mem.2.1

lemma truth_nom : ∀ {Θ : Set Form} {i : NOM}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (statement i mcs wit) := by
  intro Θ i mcs wit Δ h_in
  apply Iff.intro
  . intro h
    simp only [Sat, coe]
    apply Subtype.eq
    simp only
    apply Eq.symm
    apply (truth_nom_help mcs wit h_in).mp
    exact h
  . simp only [coe, Sat]
    intro h
    apply (truth_nom_help mcs wit h_in).mpr
    rw [Subtype.coe_eq_iff]
    exists (Or.inl h_in)
    apply Eq.symm
    exact h

lemma truth_svar : ∀ {Θ : Set Form} {i : SVAR}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (statement i mcs wit) := by
  intro Θ i mcs wit Δ h_in
  apply Iff.intro
  . intro h
    simp only [Sat, coe]
    apply Subtype.eq
    simp only
    apply Eq.symm
    apply (truth_svar_help mcs wit h_in).mp
    exact h
  . simp only [coe, Sat]
    intro h
    apply (truth_svar_help mcs wit h_in).mpr
    rw [Subtype.coe_eq_iff]
    exists (Or.inl h_in)
    apply Eq.symm
    exact h

lemma truth_impl : ∀ {Θ : Set Form}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (statement φ mcs wit) → (statement ψ mcs wit) → statement (φ ⟶ ψ) mcs wit := by
  intro Θ mcs wit ih_φ ih_ψ Δ h_in
  have ⟨D_mcs, _⟩ := (mcs_in_prop mcs wit h_in)
  apply Iff.intro
  . intro h1 h2
    apply (ih_ψ h_in).mp
    apply Proof.MCS_mp
    repeat assumption
    exact (ih_φ h_in).mpr h2
  . intro sat_φ_ψ
    unfold statement at ih_φ ih_ψ
    rw [Sat, ←ih_φ, ←ih_ψ, Proof.MCS_impl] at sat_φ_ψ
    repeat assumption

lemma has_state_symbol (s : (StandardCompletedModel mcs wit).W) : (∃ i, (StandardCompletedModel mcs wit).Vₙ i = s) ∨ (∃ x, StandardCompletedI mcs wit x = s) := by
  apply Or.elim s.2
  . intro s_in
    apply Or.inl
    have ⟨s_mcs, s_wit⟩ := (mcs_in_prop mcs wit s_in)
    have ⟨i, sat_i⟩ := Proof.MCS_rich s_mcs s_wit
    simp [truth_nom mcs wit s_in] at sat_i
    exists i
    apply Eq.symm
    exact sat_i
  -- absolutely unnecesarily ugly, but at least it works
  . intro ⟨needs_dummy, s_is_dummy⟩
    have : s.1 = Set.singleton Form.bttm := by simp [s_is_dummy]; apply Eq.refl
    rw [needs_dummy, ←this] at needs_dummy
    clear this
    apply Or.elim needs_dummy
    . intro ⟨i, h⟩ 
      apply Or.inl
      exists i
      simp [StandardCompletedModel]
      apply Subtype.eq
      apply choice_intro (λ Γ => Γ = s.1)
      rw [h,]
      intro s' eq
      rw [←Set.singleton_eq_singleton_iff]
      apply Eq.symm
      exact eq
    . intro ⟨i, h⟩ 
      apply Or.inr
      exists i
      simp [StandardCompletedI]
      apply Subtype.eq
      apply choice_intro (λ Γ => Γ = s.1)
      rw [h]
      intro s' eq
      rw [←Set.singleton_eq_singleton_iff]
      apply Eq.symm
      exact eq

lemma truth_ex : ∀ {Θ : Set Form}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (∀ {χ : Form}, χ.depth < (ex x, ψ).depth → statement χ mcs wit) → statement (ex x, ψ) mcs wit := by
  intro Θ mcs wit ih
  intro Δ Δ_in
  have ⟨Δ_mcs, Δ_wit⟩ := (mcs_in_prop mcs wit Δ_in)
  apply Iff.intro
  . intro h
    have ⟨i, mem⟩ := Δ_wit h
    have ih_s := @ih (ψ[i//x]) subst_depth''
    rw [ih_s Δ_in] at mem
    apply WeakSoundness (@Proof.ax_q2_contrap ψ i x)
    exact mem
  . simp only [ex_sat]
    intro ⟨g', g'_var, g'_ψ⟩
    let s := g' x
    apply Or.elim (has_state_symbol s)
    . intro ⟨i, sat_i⟩
      have ih_s := @ih (ψ[i//x]) subst_depth''
      simp at sat_i
      have := @nom_substitution ψ x i (StandardCompletedModel mcs wit) (coe Δ mcs wit Δ_in) (StandardCompletedI mcs wit) g' (is_variant_symm.mp g'_var) (Eq.symm sat_i)
      rw [←this, ←ih_s, ←Proof.MCS_pf_iff Δ_mcs] at g'_ψ
      clear this g'_var sat_i
      rw [←Proof.MCS_pf_iff Δ_mcs]
      apply Proof.Γ_mp
      . apply Proof.Γ_theorem
        apply Proof.ax_q2_contrap
        exact i
      . exact g'_ψ
    . intro ⟨y, sat_y⟩
      simp at sat_y
      have := rename_all_bound ψ y (StandardCompletedModel mcs wit) (coe Δ mcs wit Δ_in) g'
      rw [iff_sat] at this
      rw [this] at g'_ψ
      clear this
      rw [←svar_substitution (substable_after_replace ψ) (is_variant_symm.mp g'_var) (Eq.symm sat_y)] at g'_ψ
      have r_ih := @ih ((ψ.replace_bound y)[y//x]) replace_bound_depth'
      rw [←r_ih] at g'_ψ
      have := Proof.MCS_with_svar_witness (substable_after_replace ψ) Δ_mcs g'_ψ
      apply Proof.MCS_mp Δ_mcs; apply Proof.MCS_thm Δ_mcs
      exact @exists_replace x ψ y
      exact this

/-
lemma ohfuck (i : NOM) {Θ Θ' : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) (mcs' : Θ'.MCS) (wit' : Θ'.witnessed) : (StandardCompletedModel mcs wit).Vₙ i = (StandardCompletedModel mcs' wit').Vₙ i := by
  simp [StandardCompletedModel, CompletedModel, WitnessedModel, Set.GeneratedSubmodel, Canonical]
  apply choice_elim
  intro Γ h1 
  apply choice_elim (λ x => x = Γ)
  intro Δ h2
  split at h1 <;> split at h2 <;> rw [←Set.singleton_eq_singleton_iff, ←h1, ←h2]
  . 
    admit
  . admit
  . admit

lemma truth_ex : ∀ {Θ : Set Form}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (∀ (i : NOM) {Θ' : Set Form} (mcs' : Θ'.MCS) (wit' : Θ'.witnessed), statement i mcs' wit') → (∀ {i : NOM} {x : SVAR}, statement (φ[i//x]) mcs wit) → statement (ex x, φ) mcs wit := by
  intro Θ mcs wit ih_nom ih
  apply Iff.intro
  . intro h
    rw [ex_sat, coe]
    have := wit h
    simp at this
    have ⟨i, hw⟩ := this
    -- can also be done by using the Soundness theorem and Ax. Q2
    let g' : I (StandardCompletedModel mcs wit).W := λ v => if (v ≠ x) then StandardCompletedI mcs wit v else (StandardCompletedModel mcs wit).Vₙ i
    have which : g' x = (StandardCompletedModel mcs wit).Vₙ i := by simp
    have var : is_variant g' (StandardCompletedI mcs wit) x := by intro y h; simp [Ne.symm h]
    exists g'
    apply And.intro
    . exact var
    . have := @nom_substitution φ x i (StandardCompletedModel mcs wit) (coe mcs wit) (StandardCompletedI mcs wit) g' (is_variant_symm.mp var) which
      rw [←coe, ←this]
      clear which var
      apply ih.mp
      assumption
  . -- might also be doable using Extended Lindenbaum
    intro h
    rw [ex_sat] at h
    have ⟨g', var, sat⟩ := h
    clear h
    let s := g' x
    apply Or.elim s.2
    . intro ⟨s_mcs, s_wit⟩
      have ⟨i, s_mem⟩ := testy s_mcs s_wit
      have := ih_nom i s_mcs s_wit
      unfold statement at this
      rw [this] at s_mem
      clear this
      simp [Sat, coe, ohfuck i s_mcs s_wit mcs wit] at s_mem
      have := @nom_substitution φ x i (StandardCompletedModel mcs wit) (coe mcs wit) (StandardCompletedI mcs wit) g' (is_variant_symm.mp var) s_mem
      rw [←this] at sat
      admit
    . admit

lemma truth_pos : ∀ {Θ : Set Form}, (mcs : Θ.MCS) → (wit : Θ.witnessed) → (statement φ mcs wit) → statement (◇ φ) mcs wit := by
  admit

theorem TruthLemma {Θ : Set Form} (mcs : Θ.MCS) (wit : Θ.witnessed) : statement φ mcs wit := by
  --unfold statement
  cases φ with
  | bttm =>
      apply truth_bttm mcs wit
  | prop p =>
      apply truth_prop mcs wit
  | nom i =>
      apply truth_nom mcs wit
  | svar x =>
      apply truth_svar mcs wit
  | impl ψ χ =>
      apply truth_impl mcs wit
      apply @TruthLemma ψ Θ mcs wit
      apply @TruthLemma χ Θ mcs wit
  | box ψ =>
      rw [statement, Proof.MCS_rw mcs Proof.nec_dual, sat_dual_nec_pos]
      apply truth_impl
      apply truth_pos
      apply truth_impl
      apply TruthLemma
      repeat apply truth_bttm mcs wit
  | bind x ψ =>
      rw [statement, Proof.MCS_rw mcs Proof.bind_dual, sat_dual_all_ex]
      apply truth_impl
      apply truth_ex mcs wit
      . intros
        apply truth_nom
      . intro i x
        exact @TruthLemma (∼(ψ[i//x])) Θ mcs wit
      apply truth_bttm mcs wit
  termination_by _ φ Θ wit mcs => φ.depth
  decreasing_by
    simp_wf
    simp [Form.depth, subst_depth, Nat.lt] <;> (
        apply Nat.lt_of_lt_of_le
        apply Nat.lt_add_of_pos_left
        have : 0 < 1 := by simp only
        exact this
        simp only [le_add_iff_nonneg_right, zero_le]
    )
-/
/-
def Canonical : GeneralModel where
  W := {Γ : Set Form // Γ.MCS}
  R := λ Γ => λ Δ => (∀ φ : Form, □φ ∈ Γ.1 → φ ∈ Δ.1)
  Vₚ:= λ p => {Γ | ↑p ∈ Γ.1}
  Vₙ:= λ i => {Γ | ↑i ∈ Γ.1}

def Set.generate : Set Form → (Set Form → Set Form → Prop) →  (Set Form → Set Form → Prop) :=
  λ Θ => λ R => λ Γ => λ Δ => sorry

def WitnessedModel {Θ : Set Form} (hmcs : Θ.MCS) (hw : Θ.witnessed) : GeneralModel where
  W := {Γ : Canonical.W // Γ.1.witnessed}
  R := λ Γ => λ Δ => (∀ φ : Form, □φ ∈ Γ.1.1 → φ ∈ Δ.1.1)
  Vₚ:= λ p => sorry
  Vₙ:= λ i => sorry
-/