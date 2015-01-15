Require Import LibHypsNaming.
Require Import semantics.
Import STACK.

Functional Scheme update_ind := Induction for update Sort Prop.
Functional Scheme updates_ind := Induction for updates Sort Prop.
Functional Scheme fetch_ind := Induction for fetch Sort Prop.

Ltac rename_hyp1 h th :=
  match th with
    | updates ?sto ?x _ = _ => fresh "heq_updates_" sto "_" x
    | updates ?sto ?x _ = _ => fresh "heq_updates_" sto
    | updates ?sto ?x _ = _ => fresh "heq_updates_" x
    | updates ?sto ?x _ = _ => fresh "heq_updates"
    | update ?frm ?x _ = _ => fresh "heq_update_" frm "_" x
    | update ?frm ?x _ = _ => fresh "heq_update_" frm
    | update ?frm ?x _ = _ => fresh "heq_update_" x
    | update ?frm ?x _ = _ => fresh "heq_update"
    | updateG ?stk ?x _ = _ => fresh "heq_updateG_" stk "_" x
    | updateG ?stk ?x _ = _ => fresh "heq_updateG_" stk
    | updateG ?stk ?x _ = _ => fresh "heq_updateG_" x
    | updateG ?stk ?x _ = _ => fresh "heq_updateG"
    | fetchG ?x ?stk = _ => fresh "heq_fetchG_" x "_" stk
    | fetchG ?x ?stk = _ => fresh "heq_fetchG_" stk
    | fetchG ?x ?stk = _ => fresh "heq_fetchG_" x
    | fetchG ?x ?stk = _ => fresh "heq_fetchG"
    | fetch ?x ?frm = _ => fresh "heq_fetch_" x "_" frm
    | fetch ?x ?frm = _ => fresh "heq_fetch_" frm
    | fetch ?x ?frm = _ => fresh "heq_fetch_" x
    | fetch ?x ?frm = _ => fresh "heq_fetch"
    | fetches ?x ?sto = _ => fresh "heq_fetches_" x "_" sto
    | fetches ?x ?sto = _ => fresh "heq_fetches_" sto
    | fetches ?x ?sto = _ => fresh "heq_fetches_" x
    | fetches ?x ?sto = _ => fresh "heq_fetches"
  end.

Ltac rename_hyp ::= rename_hyp1.


Lemma updates_ok_none : forall sto x v, updates sto x v = None <-> fetches x sto = None.
Proof.
  !intros.
  split;!intro.
  - !functional induction (updates sto x v).
    + discriminate.
    + discriminate.
    + unfold id in *. (* scorie from libhyprenaming *)
      simpl.
      rewrite hbeqnat_false.
      apply IHo.
      assumption.
    + reflexivity.
  - !functional induction (fetches x sto).
    + discriminate.
    + unfold id in *. (* scorie from libhyprenaming *)
      simpl.
      rewrite hbeqnat_false.
      rewrite IHo;auto.
    + reflexivity.
Qed.

(* the none version could be solved by functiona inversion but it is
   ot applicable here due to a bug in Function with functors. *)
Lemma update_ok_none : forall frm x v, update frm x v = None <-> fetch x frm = None.
Proof.
  !intros.
  split.
  - !functional induction (update frm x v);!intro.
    + discriminate.
    + unfold fetch.
      eapply updates_ok_none;eauto.
  - unfold fetch, update.
    !intro.
    rewrite <- updates_ok_none in heq_fetches_x.
    rewrite heq_fetches_x.
    reflexivity.
Qed.


(* the none version could be solved by functiona inversion but it is
   ot applicable here due to a bug in Function with functors. *)
Lemma updateG_ok_none : forall stk x v, updateG stk x v = None <-> fetchG x stk = None.
Proof.
  !intros.
  split.
  - !functional induction (updateG stk x v);!intro.
    + discriminate.
    + discriminate.
    + unfold id in *.
      simpl.
      apply update_ok_none in heq_update_f_x.
      rewrite heq_update_f_x.
      auto.
    + reflexivity.
  - !functional induction (fetchG x stk);!intro.
    + discriminate.
    + simpl.
      rewrite IHo;auto.
      rewrite <- update_ok_none in heq_fetch_x_f;eauto.
      rewrite heq_fetch_x_f;auto.
   + reflexivity.
Qed.

Lemma updates_ok_same: forall sto id v sto',
    updates sto id v = Some sto'
    -> fetches id sto' = Some v.
Proof.
  intros until v.
  !functional induction (updates sto id v);!intros;simpl in *;intros.
  - !invclear heq;simpl.
    rewrite hbeqnat_true.
    reflexivity.
  - !invclear heq;simpl.
    !invclear heq_updates_s'_x;simpl.
    rewrite hbeqnat_false.
    apply IHo.
    assumption.
  - discriminate.
  - discriminate.
Qed.

Lemma update_ok_same: forall frm id v frm',
    update frm id v = Some frm'
    -> fetch id frm' = Some v.
Proof.
  intros until v.
  !functional induction (STACK.update frm id v);!destruct frm;simpl in *;!intros.
  - !invclear heq;simpl.
    apply updates_ok_same in heq_updates_id.
    unfold fetch.
    simpl.
    assumption.
  - discriminate.
Qed.

Lemma updateG_ok_same: forall stk id v stk',
    updateG stk id v = Some stk'
    -> fetchG id stk' = Some v.
Proof.
  intros until v.
  !functional induction (updateG stk id v);simpl;!intros.
  - !invclear heq;simpl.
    apply update_ok_same in heq_update_f_x.
    rewrite heq_update_f_x.
    reflexivity.
  - !invclear heq;simpl.
    specialize (IHo _ heq_updateG_s'_x).
    destruct (fetch x f) eqn:h.
    + apply update_ok_none in heq_update_f_x.
      rewrite heq_update_f_x in h;discriminate.
    + assumption.
  - discriminate.
  - discriminate.
Qed.



Lemma updates_ok_others: forall sto id v sto',
    updates sto id v = Some sto' ->
    forall id', id<>id' -> fetches id' sto = fetches id' sto'.
Proof.
  intros until v.
  !functional induction (updates sto id v);!intros;simpl in *;intros.
  - !invclear heq;simpl.
    rewrite -> NPeano.Nat.eqb_eq in hbeqnat_true.
    subst.
    apply NPeano.Nat.neq_sym in hneq.
    rewrite <- NPeano.Nat.eqb_neq in hneq.
    rewrite hneq in *.
    reflexivity.
  - !invclear heq;simpl.
    destruct (NPeano.Nat.eq_dec id' y).
    + subst.
      rewrite NPeano.Nat.eqb_refl in *.
      reflexivity.
    + rewrite <- NPeano.Nat.eqb_neq in n.
      rewrite n in *.
      eapply IHo;eauto.
  - discriminate.
  - discriminate.
Qed.

(* xxx + Name hypothesis. *)
Lemma update_ok_others: forall frm id v frm',
    update frm id v = Some frm' ->
    forall id', id<>id' -> fetch id' frm = fetch id' frm'.
Proof.
  intros until v.
  !functional induction (STACK.update frm id v);!destruct frm;simpl in *;!intros.
  - !invclear heq;simpl.
    eapply updates_ok_others in heq_updates_id;eauto.
  - discriminate.
Qed.

Lemma updateG_ok_others: forall stk id v stk',
    updateG stk id v = Some stk' ->
    forall id', id<>id' -> fetchG id' stk = fetchG id' stk'.
Proof.
  intros until v.
  !functional induction (updateG stk id v);simpl;!intros.
  - !invclear heq;simpl.
    !! (destruct (fetch id' f) eqn:h).
    + erewrite update_ok_others in heq_fetch_id'_f;eauto.
      rewrite heq_fetch_id'_f.
      reflexivity.
    + erewrite update_ok_others in heq_fetch_id'_f;eauto.
      rewrite heq_fetch_id'_f.
      reflexivity.
  - !invclear heq;simpl.
    !! (destruct (fetch id' f) eqn:h).
    + reflexivity.
    + eapply IHo;eauto.
  - discriminate.
  - discriminate.
Qed.


Lemma storeUpdate_id_ok_others: forall ast_num stbl stk id v stk',
    storeUpdate stbl stk (E_Identifier ast_num id) v (Normal stk') ->
    forall id', id<>id' -> fetchG id' stk = fetchG id' stk'.
Proof.
  !intros.
  !invclear H.
  eapply updateG_ok_others;eauto.
Qed.

(* Should be somewhere in stdlib, but not in ZArith. *)
Lemma Zeq_bool_neq_iff : forall x y : Z, Zeq_bool x y = false <-> x <> y.
Proof.
  !intros.
  split;!intro.
  - apply Zeq_bool_neq.
    assumption.
  - destruct (Zeq_bool x y) eqn:h.
    + apply Zeq_bool_eq in h.
      contradiction.
    + reflexivity.
Qed.


Lemma updateIndexedComp_id_ok_others: forall arr k v arr',
    arr' = updateIndexedComp arr k v
    -> forall k', k<>k' -> array_select arr' k' = array_select arr k'.
Proof.
  intros until v.
  !functional induction (updateIndexedComp arr k v);!intros;subst;simpl in *.
  - apply Zeq_bool_eq in heq_Z_true;subst;simpl.
    apply Zeq_bool_neq_iff in hneq.
    rewrite hneq.
    reflexivity.
  - specialize (IHl (updateIndexedComp a1 i v) eq_refl _ hneq).
    rewrite IHl.
    reflexivity.
  - apply Zeq_bool_neq_iff in hneq.
    rewrite hneq.
    reflexivity.
Qed.

Lemma updateIndexedComp_id_ok_same: forall arr k v arr',
    arr' = updateIndexedComp arr k v
    -> array_select arr' k = Some v.
Proof.
  intros until v.
  !functional induction (updateIndexedComp arr k v);!intros;subst;simpl in *.
  - rewrite heq_Z_true.
    reflexivity.
  - rewrite heq_Z_false.
    apply IHl;auto.
  - replace (Zeq_bool i i) with true;auto.
    symmetry.
    apply Zeq_is_eq_bool.
    reflexivity.
Qed.


Lemma storeUpdatearrayUpdate_id_ok_others: forall arr k v arr',
    arrayUpdate (ArrayV arr) k v = Some (ArrayV arr')
    -> forall k', k<>k' -> array_select arr' k' = array_select arr k'.
Proof.
  !intros.
  simpl in *.
  !invclear heq.
  eapply updateIndexedComp_id_ok_others;eauto.
Qed.


(* xxx
Lemma storeUpdate_ok_others:
  forall stbl s nme arrObj (arr:list (arrindex * value)) id v stk',
    eval_name stbl s nme (Normal arrObj) ->
    arrayUpdate arrObj i v = Some (ArrayV a1) ->
    storeUpdate stbl s nme (ArrayV a1) s1 ->

    eval_name stbl s1 nme (Normal arrObj') ->
    
    
    storeUpdate stbl stk (E_Indexed_Component ast_num nme id) v (Normal stk') ->
    forall id', id<>id' -> fetchG id' stk = fetchG id' stk'.
Proof.
  !intros.
  !invclear H.
  eapply updateG_ok_others;eauto.
Qed.
*)
