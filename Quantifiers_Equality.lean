open Classical

variable (α : Type) (p q : α → Prop)
variable (r : Prop)

example : (∃ x : α, r) → r :=
    fun h : ∃ x : α, r =>
      Exists.elim h
        fun a : α =>
          fun h : r => h

example (a : α) : r → (∃ x : α, r) :=
    fun h : r => ⟨a, h⟩  

example : (∃ x, p x ∧ r) ↔ (∃ x, p x) ∧ r :=
    Iff.intro
      (fun h1 : ∃ x, p x ∧ r =>
          match h1 with
          | ⟨w, hw⟩ => (
                have expf  := Exists.intro w hw.left
                have rpf   := hw.right
                show (∃ x, p x) ∧ r from ⟨expf, rpf⟩
              )
            )
      (fun h2 : (∃ x, p x) ∧ r =>
        match h2.left with
        | ⟨w, hw⟩ =>  ⟨w, hw, h2.right⟩
      )

example : (∃ x, p x ∨ q x) ↔ (∃ x, p x) ∨ (∃ x, q x) :=
    Iff.intro
      (fun h1 : ∃ x, p x ∨ q x =>
        match h1 with
        | ⟨w, hw⟩ => (
            Or.elim hw
            (fun hpw : p w => Or.inl ⟨w, hpw⟩)
            (fun hqw : q w => Or.inr ⟨w, hqw⟩)
        )  
      )
      (fun h2 : (∃ x, p x) ∨ (∃ x, q x) =>
        Or.elim h2
        (fun hpx : ∃ x, p x =>
          match hpx with
          | ⟨w, hw⟩ => ⟨w, Or.inl hw⟩    
        )
        (fun hqx : ∃ x, q x =>
          match hqx with
          | ⟨w, hw⟩ => ⟨w, Or.inr hw⟩    
        )
      )

example : (∀ x, p x) ↔ ¬ (∃ x, ¬ p x) :=
    Iff.intro
      (fun h1 : ∀ x, p x =>
        (fun hnpx : ∃ x, ¬ p x =>
          match hnpx with
          | ⟨w, hw⟩ => show False from hw (h1 w)  
        )
      )
      (fun h2 : ¬ (∃ x, ¬ p x) =>
        (fun a : α =>
          byContradiction
            fun hcon : ¬ p a => show False from h2 ⟨a, hcon⟩  
        )
      )

example : (∃ x, p x) ↔ ¬ (∀ x, ¬ p x) :=
    Iff.intro
      (fun hex : ∃ x, p x =>
        fun hu : ∀ x, ¬ p x =>
          match hex with
          | ⟨w, hw⟩ => (hu w) hw  
      )
      (fun hnu : ¬ (∀ x, ¬ p x) =>
        byContradiction
        (fun hne : ¬ (∃ x, p x) =>
          have hu := (
            fun a : α =>
              show ¬ p a from (fun hpa : p a => hne ⟨a, hpa⟩) 
           )
           show False from hnu hu
        )
      )

example : (¬ ∃ x, p x) ↔ (∀ x, ¬ p x) :=
    Iff.intro
    (fun h1 : ¬ ∃ x, p x =>
      (fun a : α =>
        fun hpa: p a => show False from h1 ⟨a, hpa⟩ 
      )
    )
    (fun h2 : ∀ x, ¬ p x =>
      (fun hex : ∃ x, p x => 
        match hex with
        | ⟨w, hw⟩ => show False from (h2 w) hw
      )
    )

example : (¬ ∀ x, p x) ↔ (∃ x, ¬ p x) :=
    Iff.intro
    (fun h1 : ¬ ∀ x, p x =>
      byContradiction
      (fun hcon1 : ¬ ∃ x, ¬ p x =>
        have neg_h1 := (fun a : α =>
          byContradiction
          (fun hcon2 : ¬ p a => show False from hcon1 (⟨a, hcon2⟩))
        )
        show False from h1 neg_h1
      )
    )
    (fun h2 : ∃ x, ¬ p x =>
      (fun hxp : ∀ x, p x =>
        match h2 with
        | ⟨w, hw⟩ => show False from hw (hxp w)
      )
    )

example : (∀ x, p x → r) ↔ (∃ x, p x) → r :=
    Iff.intro
    (fun h1 : ∀ x, p x → r =>
      fun hex : ∃ x, p x =>
        match hex with
        | ⟨w, hw⟩ => (h1 w) hw  
    )
    (fun h2 : (∃ x, p x) → r =>
      (fun a : α =>
        (fun hpa : p a => show r from h2 ⟨a, hpa⟩)
      )
    )

-- ugh
example (a : α) : (∃ x, p x → r) ↔ (∀ x, p x) → r :=
    Iff.intro
      (fun h1 : (∃ x, p x → r) =>
        match h1 with
        | ⟨w, hw⟩ => (
          fun hpx : ∀ x, p x =>
            show r from hw (hpx w)
        ) 
      )
      (fun h2: (∀ x, p x) → r =>
        byCases
        (fun hpx : ∀ x, p x => ⟨a, fun hpa : p a => h2 hpx⟩)
        (fun hnpx : ¬ (∀ x, p x) =>
          byContradiction
          (fun hnepx : ¬ (∃ x, p x → r) =>
            have hpx : ∀ x, p x :=
              (fun u : α =>
                byContradiction
                (fun hnpu : ¬ (p u) =>
                  show False from hnepx ⟨u, fun hpu : p u => absurd hpu hnpu⟩ 
                )
              )
            show False from hnpx hpx 
          )
        )
      )

example (a : α) : (∃ x, r → p x) ↔ (r → ∃ x, p x) :=
    Iff.intro
      (fun h1 : ∃ x, r → p x =>
        (fun hr : r =>
          match h1 with
          | ⟨w, hw⟩ => show ∃ x, p x from ⟨w, hw hr⟩
        )
      )
      (fun h2 : r → ∃ x, p x =>
        byCases
        (fun hr : r => 
          match h2 hr with
          | ⟨w, hw⟩ => ⟨w, (fun h2r : r => hw)⟩
        )
        (fun hnr : ¬ r =>
          byContradiction
          (fun hnex : ¬ (∃ x, r → p x) =>
            have rpa : r → p a := (fun hr : r => absurd hr hnr)
            show False from hnex ⟨a, rpa⟩  
          )
        )
      )