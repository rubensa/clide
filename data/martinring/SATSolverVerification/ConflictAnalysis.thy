theory ConflictAnalysis
imports AssertLiteral
begin

(******************************************************************************)
(*           A P P L Y    C O N F L I C T                                     *)
(******************************************************************************)

lemma clauseFalseInPrefixToLastAssertedLiteral:
  assumes 
  "isLastAssertedLiteral l (oppositeLiteralList c) (elements M)" and
  "clauseFalse c (elements M)" and 
  "uniq (elements M)"
  shows "clauseFalse c (elements (prefixToLevel (elementLevel l M) M))"
proof-
  {
    fix l'::Literal
    assume "l' el c"
    hence "literalFalse l' (elements M)"
      using `clauseFalse c (elements M)`
      by (simp add: clauseFalseIffAllLiteralsAreFalse)
    hence "literalTrue (opposite l') (elements M)"
      by simp

    have "opposite l' el oppositeLiteralList c"
      using `l' el c`
      using literalElListIffOppositeLiteralElOppositeLiteralList[of "l'" "c"]
      by simp

    have "elementLevel (opposite l') M \<le> elementLevel l M"
      using lastAssertedLiteralHasHighestElementLevel[of "l" "oppositeLiteralList c" "M"]
      using `isLastAssertedLiteral l (oppositeLiteralList c) (elements M)`
      using `uniq (elements M)`
      using `opposite l' el oppositeLiteralList c`
      using `literalTrue (opposite l') (elements M)`
      by auto
    hence "opposite l' el (elements (prefixToLevel (elementLevel l M) M))"
      using elementLevelLtLevelImpliesMemberPrefixToLevel[of "opposite l'" "M" "elementLevel l M"]
      using `literalTrue (opposite l') (elements M)`
      by simp
  } thus ?thesis
    by (simp add: clauseFalseIffAllLiteralsAreFalse)
qed
  

lemma InvariantNoDecisionsWhenConflictEnsuresCurrentLevelCl:
assumes 
  "InvariantNoDecisionsWhenConflict F M (currentLevel M)"
  "clause el F"
  "clauseFalse clause (elements M)"
  "uniq (elements M)"
  "currentLevel M > 0"
shows
  "clause \<noteq> [] \<and> 
   (let Cl = getLastAssertedLiteral (oppositeLiteralList clause) (elements M) in 
           InvariantClCurrentLevel Cl M)"
proof-
  have "clause \<noteq> []"
  proof-
    { 
      assume "\<not> ?thesis"
      hence "clauseFalse clause (elements (prefixToLevel ((currentLevel M) - 1) M))"
        by simp
      hence False
        using `InvariantNoDecisionsWhenConflict F M (currentLevel M)`
        using `currentLevel M > 0`
        using `clause el F`
        unfolding InvariantNoDecisionsWhenConflict_def
        by (simp add: formulaFalseIffContainsFalseClause)
    } thus ?thesis
      by auto
  qed
  moreover
  let ?Cl = "getLastAssertedLiteral (oppositeLiteralList clause) (elements M)"
  have "elementLevel ?Cl M = currentLevel M"
  proof-
    have "elementLevel ?Cl M \<le> currentLevel M"
      using elementLevelLeqCurrentLevel[of "?Cl" "M"]
      by simp
    moreover
    have "elementLevel ?Cl M \<ge> currentLevel M"
    proof-
      {
        assume "elementLevel ?Cl M < currentLevel M"
        have "isLastAssertedLiteral ?Cl (oppositeLiteralList clause) (elements M)"
          using getLastAssertedLiteralCharacterization[of "clause" "elements M"]
          using `uniq (elements M)`
          using `clauseFalse clause (elements M)`
          using `clause \<noteq> []`
          by simp
        hence "clauseFalse clause (elements (prefixToLevel (elementLevel ?Cl M) M))"
          using clauseFalseInPrefixToLastAssertedLiteral[of "?Cl" "clause" "M"]
          using `clauseFalse clause (elements M)`
          using `uniq (elements M)`
          by simp
        hence "False"
          using `clause el F`
          using `InvariantNoDecisionsWhenConflict F M (currentLevel M)`
          using `currentLevel M > 0`
          unfolding InvariantNoDecisionsWhenConflict_def
          using `elementLevel ?Cl M < currentLevel M`
          by (simp add: formulaFalseIffContainsFalseClause)
      } thus ?thesis
        by force
    qed
    ultimately
    show ?thesis
      by simp
  qed
  ultimately
  show ?thesis
    unfolding InvariantClCurrentLevel_def
    by (simp add: Let_def)
qed

lemma InvariantsClAfterApplyConflict:
assumes
  "getConflictFlag state"
  "InvariantUniq (getM state)"
  "InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))"
  "InvariantEquivalentZL (getF state) (getM state) F0"
  "InvariantConflictClauseCharacterization (getConflictFlag state) (getConflictClause state) (getF state) (getM state)"
  "currentLevel (getM state) > 0"
shows
  "let state' = applyConflict state in 
          InvariantCFalse (getConflictFlag state') (getM state') (getC state') \<and> 
          InvariantCEntailed (getConflictFlag state') F0 (getC state') \<and> 
          InvariantClCharacterization (getCl state') (getC state') (getM state') \<and> 
          InvariantClCurrentLevel (getCl state') (getM state') \<and> 
          InvariantCnCharacterization (getCn state') (getC state') (getM state') \<and> 
          InvariantUniqC (getC state')"
proof-
  let ?M0 = "elements (prefixToLevel 0 (getM state))"
  let ?oppM0 = "oppositeLiteralList ?M0"

  let ?clause' = "nth (getF state) (getConflictClause state)"
  let ?clause'' = "list_diff ?clause' ?oppM0"
  let ?clause = "remdups ?clause''"
  let ?l = "getLastAssertedLiteral (oppositeLiteralList ?clause') (elements (getM state))"

  have "clauseFalse ?clause' (elements (getM state))" "?clause' el (getF state)"
    using `getConflictFlag state`
    using `InvariantConflictClauseCharacterization (getConflictFlag state) (getConflictClause state) (getF state) (getM state)`
    unfolding InvariantConflictClauseCharacterization_def
    by (auto simp add: Let_def)

  have "?clause' \<noteq> []" "elementLevel ?l (getM state) = currentLevel (getM state)"
    using InvariantNoDecisionsWhenConflictEnsuresCurrentLevelCl[of "getF state" "getM state" "?clause'"]
    using `?clause' el (getF state)`
    using `clauseFalse ?clause' (elements (getM state))`
    using `InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))`
    using `currentLevel (getM state) > 0`
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    unfolding InvariantClCurrentLevel_def
    by (auto simp add: Let_def)


  have "isLastAssertedLiteral ?l (oppositeLiteralList ?clause') (elements (getM state))"
    using `?clause' \<noteq> []`
    using `clauseFalse ?clause' (elements (getM state))`
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    using getLastAssertedLiteralCharacterization[of "?clause'" "elements (getM state)"]
    by simp
  hence "?l el (oppositeLiteralList ?clause')"
    unfolding isLastAssertedLiteral_def
    by simp
  hence "opposite ?l el ?clause'"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?l" "?clause'"]
    by auto

  have "\<not> ?l el ?M0"
  proof-
    {
      assume "\<not> ?thesis"
      hence "elementLevel ?l (getM state) = 0"
        using prefixToLevelElementsElementLevel[of "?l" "0" "getM state"]
        by simp
      hence False
        using `elementLevel ?l (getM state) = currentLevel (getM state)`
        using `currentLevel (getM state) > 0`
        by simp
    }
    thus ?thesis
      by auto
  qed

  hence "\<not> opposite ?l el ?oppM0"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "?l" "elements (prefixToLevel 0 (getM state))"]
    by simp

  have "opposite ?l el ?clause''"
    using `opposite ?l el ?clause'`
    using `\<not> opposite ?l el ?oppM0`
    using listDiffIff[of "opposite ?l" "?clause'" "?oppM0"]
    by simp
  hence "?l el (oppositeLiteralList ?clause'')"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?l" "?clause''"]
    by simp

  have "set (oppositeLiteralList ?clause'') \<subseteq> set (oppositeLiteralList ?clause')"
  proof
    fix x
    assume "x \<in> set (oppositeLiteralList ?clause'')"
    thus "x \<in> set (oppositeLiteralList ?clause')"
      using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite x" "?clause''"]
      using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite x" "?clause'"]
      using listDiffIff[of "opposite x" "?clause'" "oppositeLiteralList (elements (prefixToLevel 0 (getM state)))"]
      by auto
  qed

  have "isLastAssertedLiteral ?l (oppositeLiteralList ?clause'') (elements (getM state))"
    using `?l el (oppositeLiteralList ?clause'')`
    using `set (oppositeLiteralList ?clause'') \<subseteq> set (oppositeLiteralList ?clause')`
    using `isLastAssertedLiteral ?l (oppositeLiteralList ?clause') (elements (getM state))`
    using isLastAssertedLiteralSubset[of "?l" "oppositeLiteralList ?clause'" "elements (getM state)" "oppositeLiteralList ?clause''"]
    by auto
  moreover
  have "set (oppositeLiteralList ?clause) = set (oppositeLiteralList ?clause'')"
    unfolding oppositeLiteralList_def
    by simp
  ultimately
  have "isLastAssertedLiteral ?l (oppositeLiteralList ?clause) (elements (getM state))"
    unfolding isLastAssertedLiteral_def
    by auto

  hence "?l el (oppositeLiteralList ?clause)"
    unfolding isLastAssertedLiteral_def
    by simp
  hence "opposite ?l el ?clause"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?l" "?clause"]
    by simp
  hence "?clause \<noteq> []"
    by auto

  have "clauseFalse ?clause'' (elements (getM state))"
  proof-
    {
      fix l::Literal
      assume "l el ?clause''"
      hence "l el ?clause'"
        using listDiffIff[of "l" "?clause'" "?oppM0"]
        by simp
      hence "literalFalse l (elements (getM state))"
        using `clauseFalse ?clause' (elements (getM state))`
        by (simp add: clauseFalseIffAllLiteralsAreFalse)
    }
    thus ?thesis
      by (simp add: clauseFalseIffAllLiteralsAreFalse)
  qed
  hence "clauseFalse ?clause (elements (getM state))"
    by (simp add: clauseFalseIffAllLiteralsAreFalse)

  let ?l' = "getLastAssertedLiteral (oppositeLiteralList ?clause) (elements (getM state))"
  have "isLastAssertedLiteral ?l' (oppositeLiteralList ?clause) (elements (getM state))"
    using `?clause \<noteq> []`
    using `clauseFalse ?clause (elements (getM state))`
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    using getLastAssertedLiteralCharacterization[of "?clause" "elements (getM state)"]
    by simp
  with `isLastAssertedLiteral ?l (oppositeLiteralList ?clause) (elements (getM state))`
  have "?l = ?l'"
    using lastAssertedLiteralIsUniq
    by simp

  have "formulaEntailsClause (getF state) ?clause'"
    using `?clause' el (getF state)`
    by (simp add: formulaEntailsItsClauses)

  let ?F0 = "(getF state) @ val2form ?M0"

  have "formulaEntailsClause ?F0 ?clause'"
    using `formulaEntailsClause (getF state) ?clause'`
    by (simp add: formulaEntailsClauseAppend)
  
  hence "formulaEntailsClause ?F0 ?clause''"
    using `formulaEntailsClause (getF state) ?clause'`
    using formulaEntailsClauseRemoveEntailedLiteralOpposites[of "?F0" "?clause'" "?M0"]
    using val2formIsEntailed[of "getF state" "?M0" "[]"]
    by simp
  hence "formulaEntailsClause ?F0 ?clause"
    unfolding formulaEntailsClause_def
    by (simp add: clauseTrueIffContainsTrueLiteral)

  hence "formulaEntailsClause F0 ?clause"
    using `InvariantEquivalentZL (getF state) (getM state) F0`
    unfolding InvariantEquivalentZL_def
    unfolding formulaEntailsClause_def
    unfolding equivalentFormulae_def
    by auto
  
  show ?thesis
    using `isLastAssertedLiteral ?l' (oppositeLiteralList ?clause) (elements (getM state))`
    using `?l = ?l'`
    using `elementLevel ?l (getM state) = currentLevel (getM state)`
    using `clauseFalse ?clause (elements (getM state))`
    using `formulaEntailsClause F0 ?clause`
    unfolding applyConflict_def
    unfolding setConflictAnalysisClause_def
    unfolding InvariantClCharacterization_def
    unfolding InvariantClCurrentLevel_def
    unfolding InvariantCFalse_def
    unfolding InvariantCEntailed_def
    unfolding InvariantCnCharacterization_def
    unfolding InvariantUniqC_def
    by (auto simp add: findLastAssertedLiteral_def countCurrentLevelLiterals_def Let_def uniqDistinct distinct_remdups_id)
qed

(******************************************************************************)
(*           A P P L Y    E X P L A I N                                       *)
(******************************************************************************)

lemma CnEqual1IffUIP:
assumes
"InvariantClCharacterization (getCl state) (getC state) (getM state)"
"InvariantClCurrentLevel (getCl state) (getM state)"
"InvariantCnCharacterization (getCn state) (getC state) (getM state)"
shows
"(getCn state = 1) = isUIP (opposite (getCl state)) (getC state) (getM state)"
proof-
  let ?clls = "filter  (\<lambda> l. elementLevel (opposite l) (getM state) = currentLevel (getM state)) (remdups (getC state))"
  let ?Cl = "getCl state"

  have "isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state)) (elements (getM state))"
    using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
    unfolding InvariantClCharacterization_def
    .
  hence "literalTrue ?Cl (elements (getM state))" "?Cl el (oppositeLiteralList (getC state))"
    unfolding isLastAssertedLiteral_def
    by auto
  hence "opposite ?Cl el getC state"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?Cl" "getC state"]
    by simp
  
  hence "opposite ?Cl el ?clls"
    using `InvariantClCurrentLevel (getCl state) (getM state)`
    unfolding InvariantClCurrentLevel_def
    by auto
  hence "?clls \<noteq> []"
    by force
  hence "length ?clls > 0"
    by simp

  have "uniq ?clls"
    by (simp add: uniqDistinct)

  {
    assume "getCn state \<noteq> 1"
    hence "length ?clls > 1"
      using assms
      using `length ?clls > 0`
      unfolding InvariantCnCharacterization_def
      by (simp (no_asm))
    then obtain literal1::Literal and literal2::Literal
      where "literal1 el ?clls" "literal2 el ?clls" "literal1 \<noteq> literal2"
      using `uniq ?clls`
      using `?clls \<noteq> []`
      using lengthGtOneTwoDistinctElements[of "?clls"]
      by auto
    then obtain literal::Literal
      where "literal el ?clls" "literal \<noteq> opposite ?Cl"
      using `opposite ?Cl el ?clls`
      by auto
    hence "\<not> isUIP (opposite ?Cl) (getC state) (getM state)"
      using `opposite ?Cl el ?clls`
      unfolding isUIP_def
      by auto
  }
  moreover
  {
    assume "getCn state = 1"
    hence "length ?clls = 1"
      using `InvariantCnCharacterization (getCn state) (getC state) (getM state)`
      unfolding InvariantCnCharacterization_def
      by auto
    {
      fix literal::Literal
      assume "literal el (getC state)" "literal \<noteq> opposite ?Cl"
      have "elementLevel (opposite literal) (getM state) < currentLevel (getM state)"
      proof-
        have "elementLevel (opposite literal) (getM state) \<le> currentLevel (getM state)"
          using elementLevelLeqCurrentLevel[of "opposite literal" "getM state"]
          by simp
        moreover
        have "elementLevel (opposite literal) (getM state) \<noteq> currentLevel (getM state)"
        proof-
          {
            assume "\<not> ?thesis"
            with `literal el (getC state)`
            have "literal el ?clls"
              by simp
            hence "False"
              using `length ?clls = 1`
              using `opposite ?Cl el ?clls`
              using `literal \<noteq> opposite ?Cl`
              using lengthOneImpliesOnlyElement[of "?clls" "opposite ?Cl"]
              by auto
          }
          thus ?thesis
            by auto
        qed
        ultimately
        show ?thesis
          by simp
      qed
    }
    hence "isUIP (opposite ?Cl) (getC state) (getM state)"
      using `isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state)) (elements (getM state))`
      using `opposite ?Cl el ?clls`
      unfolding isUIP_def
      by auto
  }
  ultimately
  show ?thesis
    by auto
qed


lemma InvariantsClAfterApplyExplain:
assumes
  "InvariantUniq (getM state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "InvariantClCharacterization (getCl state) (getC state) (getM state)"
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)"
  "InvariantCnCharacterization (getCn state) (getC state) (getM state)"
  "InvariantEquivalentZL (getF state) (getM state) F0"
  "InvariantGetReasonIsReason (getReason state) (getF state) (getM state) (set (getQ state))"
  "getCn state \<noteq> 1"
  "getConflictFlag state"
  "currentLevel (getM state) > 0"
shows
  "let state' = applyExplain (getCl state) state in 
      InvariantCFalse (getConflictFlag state') (getM state') (getC state') \<and> 
      InvariantCEntailed (getConflictFlag state') F0 (getC state') \<and> 
      InvariantClCharacterization (getCl state') (getC state') (getM state') \<and> 
      InvariantClCurrentLevel (getCl state') (getM state') \<and> 
      InvariantCnCharacterization (getCn state') (getC state') (getM state') \<and> 
      InvariantUniqC (getC state')"
proof-
  let ?Cl = "getCl state"
  let ?oppM0 = "oppositeLiteralList (elements (prefixToLevel 0 (getM state)))"

  have "isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state)) (elements (getM state))"
    using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
    unfolding InvariantClCharacterization_def
    .
  hence "literalTrue ?Cl (elements (getM state))" "?Cl el (oppositeLiteralList (getC state))"
    unfolding isLastAssertedLiteral_def
    by auto
  hence "opposite ?Cl el getC state"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?Cl" "getC state"]
    by simp


  have "clauseFalse (getC state) (elements (getM state))"
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    unfolding InvariantCFalse_def
    by simp

  have "\<not> isUIP (opposite ?Cl) (getC state) (getM state)"
    using CnEqual1IffUIP[of "state"]
    using assms
    by simp
    

  have "\<not> ?Cl el (decisions (getM state))"
  proof-
    {
      assume "\<not> ?thesis"
      hence "isUIP (opposite ?Cl) (getC state) (getM state)"
        using `InvariantUniq (getM state)`
        using `isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state)) (elements (getM state))`
        using `clauseFalse (getC state) (elements (getM state))`
        using lastDecisionThenUIP[of "getM state" "opposite ?Cl" "getC state"]
        unfolding InvariantUniq_def
        by simp
      with `\<not> isUIP (opposite ?Cl) (getC state) (getM state)`
      have "False"
        by simp
    } thus ?thesis
      by auto
  qed

  have "elementLevel ?Cl (getM state) = currentLevel (getM state)"
    using `InvariantClCurrentLevel (getCl state) (getM state)`
    unfolding InvariantClCurrentLevel_def
    by simp
  hence "elementLevel ?Cl (getM state) > 0"
    using `currentLevel (getM state) > 0`
    by simp

  obtain reason
    where "isReason (nth (getF state) reason) ?Cl (elements (getM state))"
    "getReason state ?Cl = Some reason" "0 \<le> reason \<and> reason < length (getF state)"
    using `InvariantGetReasonIsReason (getReason state) (getF state) (getM state) (set (getQ state))`
    unfolding InvariantGetReasonIsReason_def
    using `literalTrue ?Cl (elements (getM state))`
    using `\<not> ?Cl el (decisions (getM state))`
    using `elementLevel ?Cl (getM state) > 0`
    by auto

  let ?res = "resolve (getC state) (getF state ! reason) (opposite ?Cl)"

  obtain ol::Literal
    where "ol el (getC state)" 
          "ol \<noteq> opposite ?Cl" 
          "elementLevel (opposite ol) (getM state) \<ge> elementLevel ?Cl (getM state)"
    using `isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state)) (elements (getM state))`
    using `\<not> isUIP (opposite ?Cl) (getC state) (getM state)`
    unfolding isUIP_def
    by auto
  hence "ol el ?res"
    unfolding resolve_def
    by simp
  hence "?res \<noteq> []"
    by auto
  have "opposite ol el (oppositeLiteralList ?res)"
    using `ol el ?res`
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "ol" "?res"]
    by simp

  have "opposite ol el (oppositeLiteralList (getC state))"
    using `ol el (getC state)`
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "ol" "getC state"]
    by simp

  have "literalFalse ol (elements (getM state))"
    using `clauseFalse (getC state) (elements (getM state))`
    using `ol el getC state`
    by (simp add: clauseFalseIffAllLiteralsAreFalse)

  have "elementLevel (opposite ol) (getM state) = elementLevel ?Cl (getM state)"
    using `elementLevel (opposite ol) (getM state) \<ge> elementLevel ?Cl (getM state)`
    using `isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state)) (elements (getM state))`
    using lastAssertedLiteralHasHighestElementLevel[of "?Cl" "oppositeLiteralList (getC state)" "getM state"]
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    using `opposite ol el (oppositeLiteralList (getC state))`
    using `literalFalse ol (elements (getM state))`
    by auto
  hence "elementLevel (opposite ol) (getM state) = currentLevel (getM state)"
    using `elementLevel ?Cl (getM state) = currentLevel (getM state)`
    by simp
  
  have "InvariantCFalse (getConflictFlag state) (getM state) ?res"
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    using InvariantCFalseAfterExplain[of "getConflictFlag state" 
      "getM state" "getC state" "?Cl" "nth (getF state) reason" "?res"]
    using `isReason (nth (getF state) reason) ?Cl (elements (getM state))`
    using `opposite ?Cl el (getC state)`
    by simp
  hence "clauseFalse ?res (elements (getM state))"
    using `getConflictFlag state`
    unfolding InvariantCFalse_def
    by simp

  let ?rc = "nth (getF state) reason"
  let ?M0 = "elements (prefixToLevel 0 (getM state))"
  let ?F0 = "(getF state) @ (val2form ?M0)"
  let ?C' = "list_diff ?res ?oppM0"
  let ?C = "remdups ?C'"
  
  have "formulaEntailsClause (getF state) ?rc"
    using `0 \<le> reason \<and> reason < length (getF state)`
    using nth_mem[of "reason" "getF state"]
    by (simp add: formulaEntailsItsClauses)
  hence "formulaEntailsClause ?F0 ?rc"
    by (simp add: formulaEntailsClauseAppend)

  hence "formulaEntailsClause F0 ?rc"
    using `InvariantEquivalentZL (getF state) (getM state) F0`
    unfolding InvariantEquivalentZL_def
    unfolding formulaEntailsClause_def
    unfolding equivalentFormulae_def
    by simp

  hence "formulaEntailsClause F0 ?res"
    using `getConflictFlag state`
    using `InvariantCEntailed (getConflictFlag state) F0 (getC state)`
    using InvariantCEntailedAfterExplain[of "getConflictFlag state" "F0" "getC state" "nth (getF state) reason" "?res" "getCl state"]
    unfolding InvariantCEntailed_def
    by auto
  hence "formulaEntailsClause ?F0 ?res"
    using `InvariantEquivalentZL (getF state) (getM state) F0`
    unfolding InvariantEquivalentZL_def
    unfolding formulaEntailsClause_def
    unfolding equivalentFormulae_def
    by simp
    
  hence "formulaEntailsClause ?F0 ?C"
    using formulaEntailsClauseRemoveEntailedLiteralOpposites[of "?F0" "?res" "?M0"]
    using val2formIsEntailed[of "getF state" "?M0" "[]"]
    unfolding formulaEntailsClause_def
    by (auto simp add: clauseTrueIffContainsTrueLiteral)

  hence "formulaEntailsClause F0 ?C"
    using `InvariantEquivalentZL (getF state) (getM state) F0`
    unfolding InvariantEquivalentZL_def
    unfolding formulaEntailsClause_def
    unfolding equivalentFormulae_def
    by simp

  let ?ll = "getLastAssertedLiteral (oppositeLiteralList ?res) (elements (getM state))"
  have "isLastAssertedLiteral ?ll (oppositeLiteralList ?res) (elements (getM state))"
    using `?res \<noteq> []`
    using `clauseFalse ?res (elements (getM state))`
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    using getLastAssertedLiteralCharacterization[of "?res" "elements (getM state)"]
    by simp

  hence "elementLevel (opposite ol) (getM state) \<le> elementLevel ?ll (getM state)"
    using `opposite ol el (oppositeLiteralList (getC state))`
    using lastAssertedLiteralHasHighestElementLevel[of "?ll" "oppositeLiteralList ?res" "getM state"]
    using `InvariantUniq (getM state)`
    using `opposite ol el (oppositeLiteralList ?res)`
    using `literalFalse ol (elements (getM state))`
    unfolding InvariantUniq_def
    by simp
  hence "elementLevel ?ll (getM state) = currentLevel (getM state)"
    using `elementLevel (opposite ol) (getM state) = currentLevel (getM state)`
    using elementLevelLeqCurrentLevel[of "?ll" "getM state"]
    by simp

  have "?ll el (oppositeLiteralList ?res)"
    using `isLastAssertedLiteral ?ll (oppositeLiteralList ?res) (elements (getM state))`
    unfolding isLastAssertedLiteral_def
    by simp
  hence "opposite ?ll el ?res"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?ll" "?res"]
    by simp

  have "\<not> ?ll el (elements (prefixToLevel 0 (getM state)))"
  proof-
    {
      assume "\<not> ?thesis"
      hence "elementLevel ?ll (getM state) = 0"
        using prefixToLevelElementsElementLevel[of "?ll" "0" "getM state"]
        by simp
      hence False
        using `elementLevel ?ll (getM state) = currentLevel (getM state)`
        using `currentLevel (getM state) > 0`
        by simp
    }
    thus ?thesis
      by auto
  qed
  hence "\<not> opposite ?ll el ?oppM0"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "?ll" "elements (prefixToLevel 0 (getM state))"]
    by simp

  have "opposite ?ll el ?C'"
    using `opposite ?ll el ?res`
    using `\<not> opposite ?ll el ?oppM0`
    using listDiffIff[of "opposite ?ll" "?res" "?oppM0"]
    by simp
  hence "?ll el (oppositeLiteralList ?C')"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?ll" "?C'"]
    by simp

  have "set (oppositeLiteralList ?C') \<subseteq> set (oppositeLiteralList ?res)"
  proof
    fix x
    assume "x \<in> set (oppositeLiteralList ?C')"
    thus "x \<in> set (oppositeLiteralList ?res)"
      using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite x" "?C'"]
      using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite x" "?res"]
      using listDiffIff[of "opposite x" "?res" "?oppM0"]
      by auto
  qed

  have "isLastAssertedLiteral ?ll (oppositeLiteralList ?C') (elements (getM state))"
    using `?ll el (oppositeLiteralList ?C')`
    using `set (oppositeLiteralList ?C') \<subseteq> set (oppositeLiteralList ?res)`
    using `isLastAssertedLiteral ?ll (oppositeLiteralList ?res) (elements (getM state))`
    using isLastAssertedLiteralSubset[of "?ll" "oppositeLiteralList ?res" "elements (getM state)" "oppositeLiteralList ?C'"]
    by auto
  moreover
  have "set (oppositeLiteralList ?C) = set (oppositeLiteralList ?C')"
    unfolding oppositeLiteralList_def
    by simp
  ultimately
  have "isLastAssertedLiteral ?ll (oppositeLiteralList ?C) (elements (getM state))"
    unfolding isLastAssertedLiteral_def
    by auto

  hence "?ll el (oppositeLiteralList ?C)"
    unfolding isLastAssertedLiteral_def
    by simp
  hence "opposite ?ll el ?C"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?ll" "?C"]
    by simp
  hence "?C \<noteq> []"
    by auto

  have "clauseFalse ?C' (elements (getM state))"
  proof-
    {
      fix l::Literal
      assume "l el ?C'"
      hence "l el ?res"
        using listDiffIff[of "l" "?res" "?oppM0"]
        by simp
      hence "literalFalse l (elements (getM state))"
        using `clauseFalse ?res (elements (getM state))`
        by (simp add: clauseFalseIffAllLiteralsAreFalse)
    }
    thus ?thesis
      by (simp add: clauseFalseIffAllLiteralsAreFalse)
  qed
  hence "clauseFalse ?C (elements (getM state))"
    by (simp add: clauseFalseIffAllLiteralsAreFalse)

  let ?l' = "getLastAssertedLiteral (oppositeLiteralList ?C) (elements (getM state))"
  have "isLastAssertedLiteral ?l' (oppositeLiteralList ?C) (elements (getM state))"
    using `?C \<noteq> []`
    using `clauseFalse ?C (elements (getM state))`
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    using getLastAssertedLiteralCharacterization[of "?C" "elements (getM state)"]
    by simp
  with `isLastAssertedLiteral ?ll (oppositeLiteralList ?C) (elements (getM state))`
  have "?ll = ?l'"
    using lastAssertedLiteralIsUniq
    by simp

  show ?thesis
    using `isLastAssertedLiteral ?l' (oppositeLiteralList ?C) (elements (getM state))`
    using `?ll = ?l'`
    using `elementLevel ?ll (getM state) = currentLevel (getM state)`
    using `getReason state ?Cl = Some reason`
    using `clauseFalse ?C (elements (getM state))`
    using `formulaEntailsClause F0 ?C`
    unfolding applyExplain_def
    unfolding InvariantCFalse_def
    unfolding InvariantCEntailed_def
    unfolding InvariantClCharacterization_def
    unfolding InvariantClCurrentLevel_def
    unfolding InvariantCnCharacterization_def
    unfolding InvariantUniqC_def
    unfolding setConflictAnalysisClause_def
    by (simp add: findLastAssertedLiteral_def countCurrentLevelLiterals_def Let_def uniqDistinct distinct_remdups_id)
qed

(******************************************************************************)
(*           A P P L Y    E X P L A I N    U I P                              *)
(******************************************************************************)

definition 
"multLessState = {(state1, state2). (getM state1 = getM state2) \<and> (getC state1, getC state2) \<in> multLess (getM state1)}"

lemma ApplyExplainUIPTermination:
assumes
"InvariantUniq (getM state)"
"InvariantGetReasonIsReason (getReason state) (getF state) (getM state) (set (getQ state))"
"InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
"InvariantClCurrentLevel (getCl state) (getM state)"
"InvariantClCharacterization (getCl state) (getC state) (getM state)"
"InvariantCnCharacterization (getCn state) (getC state) (getM state)"
"InvariantCEntailed (getConflictFlag state) F0 (getC state)"
"InvariantEquivalentZL (getF state) (getM state) F0"
"getConflictFlag state"
"currentLevel (getM state) > 0"
shows
"applyExplainUIP_dom state"
using assms
proof (induct rule: wf_induct[of "multLessState"])
  case 1
  thus ?case
    unfolding wf_eq_minimal
  proof-
    show "\<forall>Q (state::State). state \<in> Q \<longrightarrow> (\<exists> stateMin \<in> Q. \<forall>state'. (state', stateMin) \<in> multLessState \<longrightarrow> state' \<notin> Q)"
    proof-
      {
        fix Q :: "State set" and state :: State
        assume "state \<in> Q"
        let ?M = "(getM state)"
        let ?Q1 = "{C::Clause. \<exists> state. state \<in> Q \<and> (getM state) = ?M \<and> (getC state) = C}"
        from `state \<in> Q` 
        have "getC state \<in> ?Q1"
          by auto   
        with wfMultLess[of "?M"]
        obtain Cmin where "Cmin \<in> ?Q1" "\<forall>C'. (C', Cmin) \<in> multLess ?M \<longrightarrow> C' \<notin> ?Q1"
          unfolding wf_eq_minimal
          apply (erule_tac x="?Q1" in allE)
          apply (erule_tac x="getC state" in allE)
          by auto
        from `Cmin \<in> ?Q1` obtain stateMin
          where "stateMin \<in> Q" "(getM stateMin) = ?M" "getC stateMin = Cmin"
          by auto
        have "\<forall>state'. (state', stateMin) \<in> multLessState \<longrightarrow> state' \<notin> Q"
        proof
          fix state'
          show "(state', stateMin) \<in> multLessState \<longrightarrow> state' \<notin> Q"
          proof
            assume "(state', stateMin) \<in> multLessState"
            with `getM stateMin = ?M`
            have "getM state' = getM stateMin" "(getC state', getC stateMin) \<in> multLess ?M"
              unfolding multLessState_def
              by auto
            from `\<forall>C'. (C', Cmin) \<in> multLess ?M \<longrightarrow> C' \<notin> ?Q1`
              `(getC state', getC stateMin) \<in> multLess ?M` `getC stateMin = Cmin`
            have "getC state' \<notin> ?Q1"
              by simp
            with `getM state' = getM stateMin` `getM stateMin = ?M`
            show "state' \<notin> Q"
              by auto
          qed
        qed
        with `stateMin \<in> Q` 
        have "\<exists> stateMin \<in> Q. (\<forall>state'. (state', stateMin) \<in> multLessState \<longrightarrow> state' \<notin> Q)"
          by auto
      }
      thus ?thesis
        by auto
    qed
  qed
next
  case (2 state')
  note ih = this
  show ?case
  proof (cases "getCn state' = 1")
    case True
    show ?thesis
      apply (rule applyExplainUIP_dom.intros)
      using True
      by simp
  next
    case False
    let ?state'' = "applyExplain (getCl state') state'"
    have "InvariantGetReasonIsReason (getReason ?state'') (getF ?state'') (getM ?state'') (set (getQ ?state''))"
      "InvariantUniq (getM ?state'')"
      "InvariantEquivalentZL (getF ?state'') (getM ?state'') F0"
      "getConflictFlag ?state''"
      "currentLevel (getM ?state'') > 0"
      using ih
      unfolding applyExplain_def
      unfolding setConflictAnalysisClause_def
      by (auto split: option.split simp add: findLastAssertedLiteral_def countCurrentLevelLiterals_def Let_def)
    moreover
    have "InvariantCFalse (getConflictFlag ?state'') (getM ?state'') (getC ?state'')"
      "InvariantClCharacterization (getCl ?state'') (getC ?state'') (getM ?state'')"
      "InvariantCnCharacterization (getCn ?state'') (getC ?state'') (getM ?state'')"
      "InvariantClCurrentLevel (getCl ?state'') (getM ?state'')"
      "InvariantCEntailed (getConflictFlag ?state'') F0 (getC ?state'')"
      using InvariantsClAfterApplyExplain[of "state'" "F0"]
      using ih
      using False
      by (auto simp add:Let_def)
    moreover
    have "(?state'', state') \<in> multLessState"
    proof-
      have "getM ?state'' = getM state'"
        unfolding applyExplain_def
        unfolding setConflictAnalysisClause_def
        by (auto split: option.split simp add: findLastAssertedLiteral_def countCurrentLevelLiterals_def Let_def)

      let ?Cl = "getCl state'"
      let ?oppM0 = "oppositeLiteralList (elements (prefixToLevel 0 (getM state')))"

      have "isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state')) (elements (getM state'))"
        using ih
        unfolding InvariantClCharacterization_def
        by simp
      hence "literalTrue ?Cl (elements (getM state'))" "?Cl el (oppositeLiteralList (getC state'))"
        unfolding isLastAssertedLiteral_def
        by auto
      hence "opposite ?Cl el getC state'"
        using literalElListIffOppositeLiteralElOppositeLiteralList[of "opposite ?Cl" "getC state'"]
        by simp

      have "clauseFalse (getC state') (elements (getM state'))"
        using ih
        unfolding InvariantCFalse_def
        by simp

      have "\<not> ?Cl el (decisions (getM state'))"
      proof-
        {
          assume "\<not> ?thesis"
          hence "isUIP (opposite ?Cl) (getC state') (getM state')"
            using ih 
            using `isLastAssertedLiteral ?Cl (oppositeLiteralList (getC state')) (elements (getM state'))`
            using `clauseFalse (getC state') (elements (getM state'))`
            using lastDecisionThenUIP[of "getM state'" "opposite ?Cl" "getC state'"]
            unfolding InvariantUniq_def
            unfolding isUIP_def
            by simp
          with `getCn state' \<noteq> 1`
          have "False"
            using CnEqual1IffUIP[of "state'"]
            using ih
            by simp
        } thus ?thesis
          by auto
      qed

      have "elementLevel ?Cl (getM state') = currentLevel (getM state')"
        using ih
        unfolding InvariantClCurrentLevel_def
        by simp
      hence "elementLevel ?Cl (getM state') > 0"
        using ih
        by simp

      obtain reason
        where "isReason (nth (getF state') reason) ?Cl (elements (getM state'))"
        "getReason state' ?Cl = Some reason" "0 \<le> reason \<and> reason < length (getF state')"
        using ih
        unfolding InvariantGetReasonIsReason_def
        using `literalTrue ?Cl (elements (getM state'))`
        using `\<not> ?Cl el (decisions (getM state'))`
        using `elementLevel ?Cl (getM state') > 0`
        by auto

      let ?res = "resolve (getC state') (getF state' ! reason) (opposite ?Cl)"

      have "getC ?state'' = (remdups (list_diff ?res ?oppM0))"
        unfolding applyExplain_def
        unfolding setConflictAnalysisClause_def
        using `getReason state' ?Cl = Some reason`
        by (simp add: Let_def findLastAssertedLiteral_def countCurrentLevelLiterals_def)

      have "(?res, getC state') \<in> multLess (getM state')"
        using multLessResolve[of "?Cl" "getC state'" "nth (getF state') reason" "getM state'"]
        using `opposite ?Cl el (getC state')`
        using `isReason (nth (getF state') reason) ?Cl (elements (getM state'))`
        by simp
      hence "(list_diff ?res ?oppM0, getC state') \<in> multLess (getM state')"
        by (simp add: multLessListDiff)

      have "(remdups (list_diff ?res ?oppM0), getC state') \<in> multLess (getM state')"
        using `(list_diff ?res ?oppM0, getC state') \<in> multLess (getM state')`
        by (simp add: multLessRemdups)
      thus ?thesis
        using `getC ?state'' = (remdups (list_diff ?res ?oppM0))`
        using `getM ?state'' = getM state'`
        unfolding multLessState_def
        by simp
    qed
    ultimately
    have "applyExplainUIP_dom ?state''"
      using ih
      by auto
    thus ?thesis
      using applyExplainUIP_dom.intros[of "state'"]
      using False
      by simp
  qed
qed
  

lemma ApplyExplainUIPPreservedVariables:
assumes
  "applyExplainUIP_dom state"
shows
  "let state' = applyExplainUIP state in 
        (getM state' = getM state) \<and>
        (getF state' = getF state) \<and>
        (getQ state' = getQ state) \<and>
        (getWatch1 state' = getWatch1 state) \<and>
        (getWatch2 state' = getWatch2 state) \<and>
        (getWatchList state' = getWatchList state) \<and>
        (getConflictFlag state' = getConflictFlag state) \<and> 
        (getConflictClause state' = getConflictClause state) \<and> 
        (getSATFlag state' = getSATFlag state) \<and> 
        (getReason state' = getReason state)" 
  (is "let state' = applyExplainUIP state in ?p state state'")
using assms
proof(induct state rule: applyExplainUIP_dom.induct)
  case (step state')
  note ih = this
  show ?case
  proof (cases "getCn state' = 1")
    case True
    with applyExplainUIP.simps[of "state'"]
    have "applyExplainUIP state' = state'"
      by simp
    thus ?thesis
      by (auto simp only: Let_def)
  next
    case False
    let ?state' = "applyExplainUIP (applyExplain (getCl state') state')"
    from applyExplainUIP.simps[of "state'"] False
    have "applyExplainUIP state' = ?state'"
      by (simp add: Let_def)
    have "?p state' (applyExplain (getCl state') state')"
      unfolding applyExplain_def
      unfolding setConflictAnalysisClause_def
      by (auto split: option.split simp add: findLastAssertedLiteral_def countCurrentLevelLiterals_def Let_def)
    thus ?thesis
      using ih
      using False
      using `applyExplainUIP state' = ?state'`
      by (simp add: Let_def)
  qed
qed

lemma isUIPApplyExplainUIP:
  assumes "applyExplainUIP_dom state"
  "InvariantUniq (getM state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)"
  "InvariantClCharacterization (getCl state) (getC state) (getM state)"
  "InvariantCnCharacterization (getCn state) (getC state) (getM state)"
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantGetReasonIsReason (getReason state) (getF state) (getM state) (set (getQ state))"
  "InvariantEquivalentZL (getF state) (getM state) F0"
  "getConflictFlag state"
  "currentLevel (getM state) > 0"
  shows "let state' = (applyExplainUIP state) in
           isUIP (opposite (getCl state')) (getC state') (getM state')"
using assms
proof(induct state rule: applyExplainUIP_dom.induct)
  case (step state')
  note ih = this
  show ?case
  proof (cases "getCn state' = 1")
    case True
    with applyExplainUIP.simps[of "state'"]
    have "applyExplainUIP state' = state'"
      by simp
    thus ?thesis
      using ih
      using CnEqual1IffUIP[of "state'"]
      using True
      by (simp add: Let_def)
  next
    case False
    let ?state'' = "applyExplain (getCl state') state'"
    let ?state' = "applyExplainUIP ?state''"
    from applyExplainUIP.simps[of "state'"] False
    have "applyExplainUIP state' = ?state'"
      by (simp add: Let_def)
    moreover
    have "InvariantUniq (getM ?state'')"
      "InvariantGetReasonIsReason (getReason ?state'') (getF ?state'') (getM ?state'') (set (getQ ?state''))"
      "InvariantEquivalentZL (getF ?state'') (getM ?state'') F0"
      "getConflictFlag ?state''"
      "currentLevel (getM ?state'') > 0"
      using ih
      unfolding applyExplain_def
      unfolding setConflictAnalysisClause_def
      by (auto split: option.split simp add: findLastAssertedLiteral_def countCurrentLevelLiterals_def Let_def)
    moreover
    have "InvariantCFalse (getConflictFlag ?state'') (getM ?state'') (getC ?state'')"
      "InvariantCEntailed (getConflictFlag ?state'') F0 (getC ?state'')"
      "InvariantClCharacterization (getCl ?state'') (getC ?state'') (getM ?state'')"
      "InvariantCnCharacterization (getCn ?state'') (getC ?state'') (getM ?state'')"
      "InvariantClCurrentLevel (getCl ?state'') (getM ?state'')"
      using False
      using ih
      using InvariantsClAfterApplyExplain[of "state'" "F0"]
      by (auto simp add: Let_def)
    ultimately
    show ?thesis
      using ih(2)
      using False
      by (simp add: Let_def)
  qed
qed


lemma InvariantsClAfterExplainUIP:
assumes
  "applyExplainUIP_dom state"
  "InvariantUniq (getM state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)"
  "InvariantClCharacterization (getCl state) (getC state) (getM state)"
  "InvariantCnCharacterization (getCn state) (getC state) (getM state)"
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantUniqC (getC state)"
  "InvariantGetReasonIsReason (getReason state) (getF state) (getM state) (set (getQ state))"
  "InvariantEquivalentZL (getF state) (getM state) F0"
  "getConflictFlag state"
  "currentLevel (getM state) > 0"
shows
  "let state' = applyExplainUIP state in 
      InvariantCFalse (getConflictFlag state') (getM state') (getC state') \<and> 
      InvariantCEntailed (getConflictFlag state') F0 (getC state') \<and> 
      InvariantClCharacterization (getCl state') (getC state') (getM state') \<and> 
      InvariantCnCharacterization (getCn state') (getC state') (getM state') \<and> 
      InvariantClCurrentLevel (getCl state') (getM state') \<and> 
      InvariantUniqC (getC state')"
using assms
proof(induct state rule: applyExplainUIP_dom.induct)
  case (step state')
  note ih = this
  show ?case
  proof (cases "getCn state' = 1")
    case True
    with applyExplainUIP.simps[of "state'"]
    have "applyExplainUIP state' = state'"
      by simp
    thus ?thesis
      using assms
      using ih
      by (auto simp only: Let_def)
  next
    case False
    let ?state'' = "applyExplain (getCl state') state'"
    let ?state' = "applyExplainUIP ?state''"
    from applyExplainUIP.simps[of "state'"] False
    have "applyExplainUIP state' = ?state'"
      by (simp add: Let_def)
    moreover
    have "InvariantUniq (getM ?state'')"
      "InvariantGetReasonIsReason (getReason ?state'') (getF ?state'') (getM ?state'') (set (getQ ?state''))"
      "InvariantEquivalentZL (getF ?state'') (getM ?state'') F0"
      "getConflictFlag ?state''"
      "currentLevel (getM ?state'') > 0"
      using ih
      unfolding applyExplain_def
      unfolding setConflictAnalysisClause_def
      by (auto split: option.split simp add: findLastAssertedLiteral_def countCurrentLevelLiterals_def Let_def)
    moreover
    have "InvariantCFalse (getConflictFlag ?state'') (getM ?state'') (getC ?state'')"
      "InvariantCEntailed (getConflictFlag ?state'') F0 (getC ?state'')"
      "InvariantClCharacterization (getCl ?state'') (getC ?state'') (getM ?state'')"
      "InvariantCnCharacterization (getCn ?state'') (getC ?state'') (getM ?state'')"
      "InvariantClCurrentLevel (getCl ?state'') (getM ?state'')"
      "InvariantUniqC (getC ?state'')"
      using False
      using ih
      using InvariantsClAfterApplyExplain[of "state'" "F0"]
      by (auto simp add: Let_def)
    ultimately
    show ?thesis
      using False
      using ih(2)
      by simp
  qed
qed

(******************************************************************************)
(*           G E T     B A C K J U M P   L E V E L                            *)
(******************************************************************************)

lemma oneElementSetCharacterization:
shows 
"(set l = {a}) = ((remdups l) = [a])"
proof (induct l)
  case Nil
  thus ?case
    by simp
next
  case (Cons a' l')
  show ?case
  proof (cases "l' = []")
    case True
    thus ?thesis
      by simp
  next
    case False
    then obtain b
      where "b \<in> set l'"
      by force
    show ?thesis
    proof
      assume "set (a' # l') = {a}"
      hence "a' = a" "set l' \<subseteq> {a}"
        by auto
      hence "b = a"
        using `b \<in> set l'`
        by auto
      hence "{a} \<subseteq> set l'"
        using `b \<in> set l'`
        by auto
      hence "set l' = {a}"
        using `set l' \<subseteq> {a}`
        by auto
      thus "remdups (a' # l') = [a]"
        using `a' = a`
        using Cons
        by simp
    next
      assume "remdups (a' # l') = [a]"
      thus "set (a' # l') = {a}"
        using set_remdups[of "a' # l'"]
        by auto
    qed
  qed
qed

lemma uniqOneElementCharacterization:
assumes
  "uniq l"
shows
  "(l = [a]) = (set l = {a})"
using assms
using uniqDistinct[of "l"]
using oneElementSetCharacterization[of "l" "a"]
using distinct_remdups_id[of "l"]
by auto

lemma isMinimalBackjumpLevelGetBackjumpLevel: 
assumes
  "InvariantUniq (getM state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "InvariantClCharacterization (getCl state) (getC state) (getM state)"
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)"
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantUniqC (getC state)"

  "getConflictFlag state"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"
shows
  "isMinimalBackjumpLevel (getBackjumpLevel state) (opposite (getCl state)) (getC state) (getM state)"
proof-
  let ?oppC = "oppositeLiteralList (getC state)"
  let ?Cl = "getCl state"
    
  have "isLastAssertedLiteral ?Cl ?oppC (elements (getM state))"
    using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
    unfolding InvariantClCharacterization_def
    by simp

  have "elementLevel ?Cl (getM state) > 0"
    using `InvariantClCurrentLevel (getCl state) (getM state)`
    using `currentLevel (getM state) > 0`
    unfolding InvariantClCurrentLevel_def
    by simp

  have "clauseFalse (getC state) (elements (getM state))"
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    unfolding InvariantCFalse_def
    by simp

  show ?thesis
  proof (cases "getC state = [opposite ?Cl]")
    case True
    thus ?thesis
      using backjumpLevelZero[of "opposite ?Cl" "oppositeLiteralList ?oppC" "getM state"]
      using `isLastAssertedLiteral ?Cl ?oppC (elements (getM state))`
      using True
      using `elementLevel ?Cl (getM state) > 0`
      unfolding getBackjumpLevel_def
      unfolding isMinimalBackjumpLevel_def
      by (simp add: Let_def)
  next
    let ?Cll = "getCll state" 
    case False
    with `InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)`
    `InvariantUniqC (getC state)`
    have "isLastAssertedLiteral ?Cll (removeAll ?Cl ?oppC) (elements (getM state))"
      unfolding InvariantCllCharacterization_def
      unfolding InvariantUniqC_def
      using uniqOneElementCharacterization[of "getC state" "opposite ?Cl"]
      by simp
    hence "?Cll el ?oppC" "?Cll \<noteq> ?Cl"
      unfolding isLastAssertedLiteral_def
      by auto
    hence "opposite ?Cll el (getC state)"
      using literalElListIffOppositeLiteralElOppositeLiteralList[of "?Cll" "?oppC"]
      by auto

    show ?thesis
      using backjumpLevelLastLast[of "opposite ?Cl" "getC state" "getM state" "opposite ?Cll"]
      using `isUIP (opposite (getCl state)) (getC state) (getM state)`
      using `clauseFalse (getC state) (elements (getM state))`
      using `isLastAssertedLiteral ?Cll (removeAll ?Cl ?oppC) (elements (getM state))`
      using `InvariantUniq (getM state)`
      using `InvariantUniqC (getC state)`
      using uniqOneElementCharacterization[of "getC state" "opposite ?Cl"]
      unfolding InvariantUniqC_def
      unfolding InvariantUniq_def
      using False
      using `opposite ?Cll el (getC state)`
      unfolding getBackjumpLevel_def
      unfolding isMinimalBackjumpLevel_def
      by (auto simp add: Let_def)
  qed
qed


(******************************************************************************)
(*           A P P L Y    L E A R N                                           *)
(******************************************************************************)

lemma applyLearnPreservedVariables:
"let state' = applyLearn state in 
    getM state' = getM state \<and> 
    getQ state' = getQ state \<and> 
    getC state' = getC state \<and> 
    getCl state' = getCl state \<and>
    getConflictFlag state' = getConflictFlag state \<and> 
    getConflictClause state' = getConflictClause state \<and> 
    getF state' = (if getC state = [opposite (getCl state)] then 
                               getF state 
                     else 
                            (getF state @ [getC state])
                    )"
proof (cases "getC state = [opposite (getCl state)]")
  case True
  thus ?thesis
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    by (simp add:Let_def)
next
  case False
  thus ?thesis
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    by (simp add:Let_def)
qed

lemma WatchInvariantsAfterApplyLearn:
assumes
  "InvariantUniq (getM state)" and
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and 
  "InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)" and 
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)" and 
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "InvariantUniqC (getC state)"
shows
  "let state' = (applyLearn state) in
     InvariantWatchesEl (getF state') (getWatch1 state') (getWatch2 state') \<and> 
     InvariantWatchesDiffer (getF state') (getWatch1 state') (getWatch2 state') \<and> 
     InvariantWatchCharacterization (getF state') (getWatch1 state') (getWatch2 state') (getM state') \<and> 
     InvariantWatchListsContainOnlyClausesFromF (getWatchList state') (getF state') \<and> 
     InvariantWatchListsUniq (getWatchList state') \<and> 
     InvariantWatchListsCharacterization (getWatchList state') (getWatch1 state') (getWatch2 state')"
proof (cases "getC state \<noteq> [opposite (getCl state)]")
  case False
  thus ?thesis
    using assms
    unfolding applyLearn_def
    unfolding InvariantCllCharacterization_def
    by (simp add: Let_def)
next
  case True

  let ?oppC = "oppositeLiteralList (getC state)"
  let ?l = "getCl state"
  let ?ll = "getLastAssertedLiteral (removeAll ?l ?oppC) (elements (getM state))"

  have "clauseFalse (getC state) (elements (getM state))"
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    unfolding InvariantCFalse_def
    by simp


  from True
  have "set (getC state) \<noteq> {opposite ?l}"
    using `InvariantUniqC (getC state)`
    using uniqOneElementCharacterization[of "getC state" "opposite ?l"]
    unfolding InvariantUniqC_def
    by (simp add: Let_def)

  
  have "isLastAssertedLiteral ?l ?oppC (elements (getM state))"
    using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
    unfolding InvariantClCharacterization_def
    by simp

  have "opposite ?l el (getC state)"
    using `isLastAssertedLiteral ?l ?oppC (elements (getM state))`
    unfolding isLastAssertedLiteral_def
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "?l" "?oppC"]
    by simp

  have "removeAll ?l ?oppC \<noteq> []"
  proof-
    { 
      assume "\<not> ?thesis"
      hence "set ?oppC \<subseteq> {?l}"
        using set_removeAll[of "?l" "?oppC"]
        by auto
      have "set (getC state) \<subseteq> {opposite ?l}"
      proof
        fix x
        assume "x \<in> set (getC state)"
        hence "opposite x \<in> set ?oppC"
          using literalElListIffOppositeLiteralElOppositeLiteralList[of "x" "getC state"]
          by simp
        hence "opposite x \<in> {?l}"
          using `set ?oppC \<subseteq> {?l}`
          by auto
        thus "x \<in> {opposite ?l}"
          using oppositeSymmetry[of "x" "?l"]
          by force
      qed
      hence False
        using `set (getC state) \<noteq> {opposite ?l}`
        using `opposite ?l el getC state`
        by (auto simp add: Let_def)
    } thus ?thesis
      by auto
  qed

  have "clauseFalse (oppositeLiteralList (removeAll ?l ?oppC)) (elements (getM state))"
    using `clauseFalse (getC state) (elements (getM state))`
    using oppositeLiteralListRemove[of "?l" "?oppC"]
    by (simp add: clauseFalseIffAllLiteralsAreFalse)
  moreover 
  have "oppositeLiteralList (removeAll ?l ?oppC) \<noteq> []"
    using `removeAll ?l ?oppC \<noteq> []`
    using oppositeLiteralListNonempty
    by simp
  ultimately
  have "isLastAssertedLiteral ?ll (removeAll ?l ?oppC) (elements (getM state))"
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    using getLastAssertedLiteralCharacterization[of "oppositeLiteralList (removeAll ?l ?oppC)" "elements (getM state)"]
    by auto
  hence "?ll el (removeAll ?l ?oppC)"
    unfolding isLastAssertedLiteral_def
    by auto
  hence "?ll el ?oppC" "?ll \<noteq> ?l"
    by auto 
  hence "opposite ?ll el (getC state)"
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "?ll" "?oppC"]
    by auto

  let ?state' = "applyLearn state"

  have "InvariantWatchesEl (getF ?state') (getWatch1 ?state') (getWatch2 ?state')"
  proof-
    {
      fix clause::nat
      assume "0 \<le> clause \<and> clause < length (getF ?state')"
      have  "\<exists>w1 w2. getWatch1 ?state' clause = Some w1 \<and>
                     getWatch2 ?state' clause = Some w2 \<and>
                     w1 el (getF ?state' ! clause) \<and> w2 el (getF ?state' ! clause)"
      proof (cases "clause < length (getF state)")
        case True
        thus ?thesis
          using `InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)`
          unfolding InvariantWatchesEl_def
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add:Let_def nth_append)
      next
        case False
        with  `0 \<le> clause \<and> clause < length (getF ?state')`
        have "clause = length (getF state)"
          using `getC state \<noteq> [opposite ?l]`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        moreover
        have "getWatch1 ?state' clause = Some (opposite ?l)" "getWatch2 ?state' clause = Some (opposite ?ll)"
          using `clause = length (getF state)`
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        moreover
        have "getF ?state' ! clause = (getC state)"
          using `clause = length (getF state)`
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        ultimately
        show ?thesis
          using `opposite ?l el (getC state)` `opposite ?ll el (getC state)`
          by force
      qed
    } thus ?thesis
      unfolding InvariantWatchesEl_def
      by auto
  qed
  moreover
  have "InvariantWatchesDiffer (getF ?state') (getWatch1 ?state') (getWatch2 ?state')"
  proof-
    {
      fix clause::nat
      assume "0 \<le> clause \<and> clause < length (getF ?state')"
      have  "getWatch1 ?state' clause \<noteq> getWatch2 ?state' clause"
      proof (cases "clause < length (getF state)")
        case True
        thus ?thesis
          using `InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)`
          unfolding InvariantWatchesDiffer_def
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add:Let_def nth_append)
      next
        case False
        with  `0 \<le> clause \<and> clause < length (getF ?state')`
        have "clause = length (getF state)"
          using `getC state \<noteq> [opposite ?l]`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        moreover
        have "getWatch1 ?state' clause = Some (opposite ?l)" "getWatch2 ?state' clause = Some (opposite ?ll)"
          using `clause = length (getF state)`
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        moreover
        have "getF ?state' ! clause = (getC state)"
          using `clause = length (getF state)`
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        ultimately
        show ?thesis
          using `?ll \<noteq> ?l`
          by force
      qed
    } thus ?thesis
      unfolding InvariantWatchesDiffer_def
      by auto
  qed
  moreover
  have "InvariantWatchCharacterization (getF ?state') (getWatch1 ?state') (getWatch2 ?state') (getM ?state')"
  proof-
    {
      fix clause::nat and w1::Literal and w2::Literal
      assume *: "0 \<le> clause \<and> clause < length (getF ?state')"
      assume **: "Some w1 = getWatch1 ?state' clause" "Some w2 = getWatch2 ?state' clause"
      have "watchCharacterizationCondition w1 w2 (getM ?state') (getF ?state' ! clause) \<and> 
            watchCharacterizationCondition w2 w1 (getM ?state') (getF ?state' ! clause)"
      proof (cases "clause < length (getF state)")
        case True
        thus ?thesis
          using `InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)`
          unfolding InvariantWatchCharacterization_def
          using `set (getC state) \<noteq> {opposite ?l}`
          using **
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add:Let_def nth_append)
      next
        case False
        with  `0 \<le> clause \<and> clause < length (getF ?state')`
        have "clause = length (getF state)"
          using `getC state \<noteq> [opposite ?l]`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        moreover
        have "getWatch1 ?state' clause = Some (opposite ?l)" "getWatch2 ?state' clause = Some (opposite ?ll)"
          using `clause = length (getF state)`
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        moreover
        have "\<forall> l. l el (getC state) \<and> l \<noteq> opposite ?l \<and> l \<noteq> opposite ?ll \<longrightarrow> 
                   elementLevel (opposite l) (getM state) \<le> elementLevel ?l (getM state) \<and> 
                   elementLevel (opposite l) (getM state) \<le> elementLevel ?ll (getM state)"
        proof-
          { 
            fix l
            assume "l el (getC state)" "l \<noteq> opposite ?l" "l \<noteq> opposite ?ll"
            hence "opposite l el ?oppC" 
              using literalElListIffOppositeLiteralElOppositeLiteralList[of "l" "getC state"]
              by simp
            moreover
            from `l \<noteq> opposite ?l`
            have "opposite l \<noteq> ?l"
              using oppositeSymmetry[of "l" "?l"]
              by blast
            ultimately
            have "opposite l el (removeAll ?l ?oppC)"
              by simp
              
            from `clauseFalse (getC state) (elements (getM state))`
            have "literalFalse l (elements (getM state))"
              using `l el (getC state)`
              by (simp add: clauseFalseIffAllLiteralsAreFalse)
            hence "elementLevel (opposite l) (getM state) \<le> elementLevel ?l (getM state) \<and> 
              elementLevel (opposite l) (getM state) \<le> elementLevel ?ll (getM state)"
              using `InvariantUniq (getM state)`
              unfolding InvariantUniq_def
              using `isLastAssertedLiteral ?l ?oppC (elements (getM state))`
              using lastAssertedLiteralHasHighestElementLevel[of "?l" "?oppC" "getM state"]
              using `isLastAssertedLiteral ?ll (removeAll ?l ?oppC) (elements (getM state))`
              using lastAssertedLiteralHasHighestElementLevel[of "?ll" "(removeAll ?l ?oppC)" "getM state"]
              using `opposite l el ?oppC` `opposite l el (removeAll ?l ?oppC)`
              by simp
          }
          thus ?thesis
            by simp
        qed
        moreover
        have "getF ?state' ! clause = (getC state)"
          using `clause = length (getF state)`
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        moreover
        have "getM ?state' = getM state"
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add: Let_def)
        ultimately
        show ?thesis
          using `clauseFalse (getC state) (elements (getM state))`
          using **
          unfolding watchCharacterizationCondition_def
          by (auto simp add: clauseFalseIffAllLiteralsAreFalse)
      qed
    } thus ?thesis
      unfolding InvariantWatchCharacterization_def
      by auto
  qed
  moreover
  have "InvariantWatchListsContainOnlyClausesFromF (getWatchList ?state') (getF ?state')"
  proof-
    {
      fix clause::nat and literal::Literal
      assume "clause \<in> set (getWatchList ?state' literal)"
      have "clause < length (getF ?state')"
      proof(cases "clause \<in> set (getWatchList state literal)")
        case True
        thus ?thesis
          using `InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)`
          unfolding InvariantWatchListsContainOnlyClausesFromF_def
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add:Let_def nth_append) (force)+
      next
        case False
        with `clause \<in> set (getWatchList ?state' literal)`
        have "clause = length (getF state)"
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add:Let_def nth_append split: split_if_asm)
        thus ?thesis
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add:Let_def nth_append)
      qed
    } thus ?thesis
      unfolding InvariantWatchListsContainOnlyClausesFromF_def
      by simp
  qed
  moreover
  have "InvariantWatchListsUniq (getWatchList ?state')"
    unfolding InvariantWatchListsUniq_def
  proof
    fix l::Literal
    show "uniq (getWatchList ?state' l)"
    proof(cases "l = opposite ?l \<or> l = opposite ?ll")
      case True
      hence "getWatchList ?state' l = (length (getF state)) # getWatchList state l"
        using `set (getC state) \<noteq> {opposite ?l}`
        unfolding applyLearn_def
        unfolding setWatch1_def
        unfolding setWatch2_def
        using `?ll \<noteq> ?l`
        by (auto simp add:Let_def nth_append)
      moreover
      have "length (getF state) \<notin> set (getWatchList state l)"
        using `InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)`
        unfolding InvariantWatchListsContainOnlyClausesFromF_def
        by auto
      ultimately
      show ?thesis
        using `InvariantWatchListsUniq (getWatchList state)`
        unfolding InvariantWatchListsUniq_def
        by (simp add: uniqAppendIff)
    next
      case False
      hence "getWatchList ?state' l = getWatchList state l"
        using `set (getC state) \<noteq> {opposite ?l}`
        unfolding applyLearn_def
        unfolding setWatch1_def
        unfolding setWatch2_def
        by (auto simp add:Let_def nth_append)
      thus ?thesis
        using `InvariantWatchListsUniq (getWatchList state)`
        unfolding InvariantWatchListsUniq_def
        by simp
    qed
  qed
  moreover
  have "InvariantWatchListsCharacterization (getWatchList ?state') (getWatch1 ?state') (getWatch2 ?state')"
  proof-
    {
      fix c::nat and l::Literal
      have "(c \<in> set (getWatchList ?state' l)) = (Some l = getWatch1 ?state' c \<or> Some l = getWatch2 ?state' c)"
      proof (cases "c = length (getF state)")
        case False
        thus ?thesis
          using `InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)`
          unfolding InvariantWatchListsCharacterization_def
          using `set (getC state) \<noteq> {opposite ?l}`
          unfolding applyLearn_def
          unfolding setWatch1_def
          unfolding setWatch2_def
          by (auto simp add:Let_def nth_append)
      next
        case True
        have "length (getF state) \<notin> set (getWatchList state l)"
          using `InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)`
          unfolding InvariantWatchListsContainOnlyClausesFromF_def
          by auto
        thus ?thesis
          using `c = length (getF state)`
        using `InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)`
        unfolding InvariantWatchListsCharacterization_def
        using `set (getC state) \<noteq> {opposite ?l}`
        unfolding applyLearn_def
        unfolding setWatch1_def
        unfolding setWatch2_def
        by (auto simp add:Let_def nth_append)
    qed
  } thus ?thesis
    unfolding InvariantWatchListsCharacterization_def
    by simp
  qed
  moreover
  have "InvariantClCharacterization (getCl ?state') (getC ?state') (getM ?state')"
    using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
    using `set (getC state) \<noteq> {opposite ?l}`
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    by (auto simp add:Let_def)
  moreover
  have "InvariantCllCharacterization (getCl ?state') (getCll ?state') (getC ?state') (getM ?state')"
    unfolding InvariantCllCharacterization_def
    using `isLastAssertedLiteral ?ll (removeAll ?l ?oppC) (elements (getM state))`
    using `set (getC state) \<noteq> {opposite ?l}`
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    by (auto simp add:Let_def)
  ultimately
  show ?thesis
    by simp
qed

lemma InvariantCllCharacterizationAfterApplyLearn:
assumes
  "InvariantUniq (getM state)"
  "InvariantClCharacterization (getCl state) (getC state) (getM state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "InvariantUniqC (getC state)"
  "getConflictFlag state"
shows
  "let state' = applyLearn state in 
     InvariantCllCharacterization (getCl state') (getCll state') (getC state') (getM state')"
proof (cases "getC state \<noteq> [opposite (getCl state)]")
  case False
  thus ?thesis
    using assms
    unfolding applyLearn_def
    unfolding InvariantCllCharacterization_def
    by (simp add: Let_def)
next
  case True

  let ?oppC = "oppositeLiteralList (getC state)"
  let ?l = "getCl state"
  let ?ll = "getLastAssertedLiteral (removeAll ?l ?oppC) (elements (getM state))"

  have "clauseFalse (getC state) (elements (getM state))"
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    unfolding InvariantCFalse_def
    by simp


  from True
  have "set (getC state) \<noteq> {opposite ?l}"
    using `InvariantUniqC (getC state)`
    using uniqOneElementCharacterization[of "getC state" "opposite ?l"]
    unfolding InvariantUniqC_def
    by (simp add: Let_def)

  have "isLastAssertedLiteral ?l ?oppC (elements (getM state))"
    using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
    unfolding InvariantClCharacterization_def
    by simp

  have "opposite ?l el (getC state)"
    using `isLastAssertedLiteral ?l ?oppC (elements (getM state))`
    unfolding isLastAssertedLiteral_def
    using literalElListIffOppositeLiteralElOppositeLiteralList[of "?l" "?oppC"]
    by simp

  have "removeAll ?l ?oppC \<noteq> []"
  proof-
    { 
      assume "\<not> ?thesis"
      hence "set ?oppC \<subseteq> {?l}"
        using set_removeAll[of "?l" "?oppC"]
        by auto
      have "set (getC state) \<subseteq> {opposite ?l}"
      proof
        fix x
        assume "x \<in> set (getC state)"
        hence "opposite x \<in> set ?oppC"
          using literalElListIffOppositeLiteralElOppositeLiteralList[of "x" "getC state"]
          by simp
        hence "opposite x \<in> {?l}"
          using `set ?oppC \<subseteq> {?l}`
          by auto
        thus "x \<in> {opposite ?l}"
          using oppositeSymmetry[of "x" "?l"]
          by force
      qed
      hence False
        using `set (getC state) \<noteq> {opposite ?l}`
        using `opposite ?l el getC state`
        by (auto simp add: Let_def)
    } thus ?thesis
      by auto
  qed

  have "clauseFalse (oppositeLiteralList (removeAll ?l ?oppC)) (elements (getM state))"
    using `clauseFalse (getC state) (elements (getM state))`
    using oppositeLiteralListRemove[of "?l" "?oppC"]
    by (simp add: clauseFalseIffAllLiteralsAreFalse)
  moreover 
  have "oppositeLiteralList (removeAll ?l ?oppC) \<noteq> []"
    using `removeAll ?l ?oppC \<noteq> []`
    using oppositeLiteralListNonempty
    by simp
  ultimately
  have "isLastAssertedLiteral ?ll (removeAll ?l ?oppC) (elements (getM state))"
    using getLastAssertedLiteralCharacterization[of "oppositeLiteralList (removeAll ?l ?oppC)" "elements (getM state)"]
    using `InvariantUniq (getM state)`
    unfolding InvariantUniq_def
    by auto
  thus ?thesis
    using `set (getC state) \<noteq> {opposite ?l}`
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    unfolding InvariantCllCharacterization_def
    by (auto simp add:Let_def)
qed


lemma InvariantConflictClauseCharacterizationAfterApplyLearn:
assumes
  "getConflictFlag state"
  "InvariantConflictClauseCharacterization (getConflictFlag state) (getConflictClause state) (getF state) (getM state)"
shows
  "let state' = applyLearn state in
       InvariantConflictClauseCharacterization (getConflictFlag state') (getConflictClause state') (getF state') (getM state')"
proof-
  have "getConflictClause state < length (getF state)"
    using assms
    unfolding InvariantConflictClauseCharacterization_def
    by (auto simp add: Let_def)
  hence "nth ((getF state) @ [getC state]) (getConflictClause state) = 
    nth (getF state) (getConflictClause state)"
    by (simp add: nth_append)
  thus ?thesis
    using `InvariantConflictClauseCharacterization (getConflictFlag state) (getConflictClause state) (getF state) (getM state)`
    unfolding InvariantConflictClauseCharacterization_def
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    by (auto simp add: Let_def clauseFalseAppendValuation)
qed

lemma InvariantGetReasonIsReasonAfterApplyLearn:
assumes
  "InvariantGetReasonIsReason (getReason state) (getF state) (getM state) (set (getQ state))"
shows
  "let state' = applyLearn state in
    InvariantGetReasonIsReason (getReason state') (getF state') (getM state') (set (getQ state'))
  "
proof (cases "getC state = [opposite (getCl state)]")
  case True
  thus ?thesis
    unfolding applyLearn_def
    using assms
    by (simp add: Let_def)
next
  case False
  have "InvariantGetReasonIsReason (getReason state) ((getF state) @ [getC state]) (getM state) (set (getQ state))"
    using assms
    using nth_append[of "getF state" "[getC state]"]
    unfolding InvariantGetReasonIsReason_def
    by auto
  thus ?thesis
    using False
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    by (simp add: Let_def)
qed

lemma InvariantQCharacterizationAfterApplyLearn:
assumes
  "getConflictFlag state"
  "InvariantQCharacterization (getConflictFlag state) (getQ state) (getF state) (getM state)"
shows
  "let state' = applyLearn state in
      InvariantQCharacterization (getConflictFlag state') (getQ state') (getF state') (getM state')"
using assms
unfolding InvariantQCharacterization_def
unfolding applyLearn_def
unfolding setWatch1_def
unfolding setWatch2_def
by (simp add: Let_def)

lemma InvariantUniqQAfterApplyLearn:
assumes
  "InvariantUniqQ (getQ state)"
shows
  "let state' = applyLearn state in
      InvariantUniqQ (getQ state')"
using assms
unfolding applyLearn_def
unfolding setWatch1_def
unfolding setWatch2_def
by (simp add: Let_def)

lemma InvariantConflictFlagCharacterizationAfterApplyLearn:
assumes
  "getConflictFlag state"
  "InvariantConflictFlagCharacterization (getConflictFlag state) (getF state) (getM state)"
shows
  "let state' = applyLearn state in
      InvariantConflictFlagCharacterization (getConflictFlag state') (getF state') (getM state')"
using assms
unfolding InvariantConflictFlagCharacterization_def
unfolding applyLearn_def
unfolding setWatch1_def
unfolding setWatch2_def
by (auto simp add: Let_def formulaFalseIffContainsFalseClause)

lemma InvariantNoDecisionsWhenConflictNorUnitAfterApplyLearn:
assumes 
  "InvariantUniq (getM state)"
  "InvariantConsistent (getM state)"
  "InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))"
  "InvariantNoDecisionsWhenUnit (getF state) (getM state) (currentLevel (getM state))"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)"
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantUniqC (getC state)"

  "getConflictFlag state"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"
shows
  "let state' = applyLearn state in
      InvariantNoDecisionsWhenConflict (getF state) (getM state') (currentLevel (getM state')) \<and> 
      InvariantNoDecisionsWhenUnit (getF state) (getM state') (currentLevel (getM state')) \<and> 
      InvariantNoDecisionsWhenConflict [getC state] (getM state') (getBackjumpLevel state') \<and> 
      InvariantNoDecisionsWhenUnit [getC state] (getM state') (getBackjumpLevel state')"
proof-
  let ?state' = "applyLearn state"
  let ?l = "getCl state"

  have  "clauseFalse (getC state) (elements (getM state))"
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    unfolding InvariantCFalse_def
    by simp

  have "getM ?state' = getM state" "getC ?state' = getC state" 
    "getCl ?state' = getCl state" "getConflictFlag ?state' = getConflictFlag state"
    unfolding applyLearn_def
    unfolding setWatch2_def
    unfolding setWatch1_def
    by (auto simp add: Let_def)

  hence "InvariantNoDecisionsWhenConflict (getF state) (getM ?state') (currentLevel (getM ?state')) \<and> 
         InvariantNoDecisionsWhenUnit (getF state) (getM ?state') (currentLevel (getM ?state'))"
    using `InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))`
    using `InvariantNoDecisionsWhenUnit (getF state) (getM state) (currentLevel (getM state))`
    by simp
  moreover
  have "InvariantCllCharacterization (getCl ?state') (getCll ?state') (getC ?state') (getM ?state')"
    using assms
    using InvariantCllCharacterizationAfterApplyLearn[of "state"]
    by (simp add: Let_def)
  hence "isMinimalBackjumpLevel (getBackjumpLevel ?state') (opposite ?l) (getC ?state') (getM ?state')"
    using assms
    using `getM ?state' = getM state` `getC ?state' = getC state` 
      `getCl ?state' = getCl state` `getConflictFlag ?state' = getConflictFlag state`
    using isMinimalBackjumpLevelGetBackjumpLevel[of "?state'"]
    unfolding isUIP_def
    unfolding SatSolverVerification.isUIP_def
    by (simp add: Let_def)
  hence "getBackjumpLevel ?state' < elementLevel ?l (getM ?state')"
    unfolding isMinimalBackjumpLevel_def
    unfolding isBackjumpLevel_def
    by simp
  hence "getBackjumpLevel ?state' < currentLevel (getM ?state')"
    using elementLevelLeqCurrentLevel[of "?l" "getM ?state'"]
    by simp

  have "InvariantNoDecisionsWhenConflict [getC state] (getM ?state') (getBackjumpLevel ?state') \<and> 
        InvariantNoDecisionsWhenUnit [getC state] (getM ?state') (getBackjumpLevel ?state')"
  proof-
    {
      fix clause::Clause
      assume "clause el [getC state]"
      hence "clause = getC state"
        by simp
      
      have "(\<forall> level'. level' < (getBackjumpLevel ?state') \<longrightarrow> 
                \<not> clauseFalse clause (elements (prefixToLevel level' (getM ?state')))) \<and> 
            (\<forall> level'. level' < (getBackjumpLevel ?state') \<longrightarrow> 
                \<not> (\<exists> l. isUnitClause clause l (elements (prefixToLevel level' (getM ?state')))))" (is "?false \<and> ?unit")
      proof(cases "getC state = [opposite ?l]")
        case True
        thus ?thesis
          using `getM ?state' = getM state` `getC ?state' = getC state` `getCl ?state' = getCl state` 
          unfolding getBackjumpLevel_def
          by (simp add: Let_def)
      next
        case False
        hence "getF ?state' = getF state @ [getC state]" 
          unfolding applyLearn_def
          unfolding setWatch2_def
          unfolding setWatch1_def
          by (auto simp add: Let_def)

        show ?thesis
        proof-
          have "?unit"
            using `clause = getC state`
            using `InvariantUniq (getM state)`
            using `InvariantConsistent (getM state)`
            using `getM ?state' = getM state` `getC ?state' = getC state`
            using `clauseFalse (getC state) (elements (getM state))`
            using `isMinimalBackjumpLevel (getBackjumpLevel ?state') (opposite ?l) (getC ?state') (getM ?state')`
            using isMinimalBackjumpLevelEnsuresIsNotUnitBeforePrefix[of "getM ?state'" "getC ?state'" "getBackjumpLevel ?state'" "opposite ?l"]
            unfolding InvariantUniq_def
            unfolding InvariantConsistent_def
            by simp
          moreover
          have "isUnitClause (getC state) (opposite ?l) (elements (prefixToLevel (getBackjumpLevel ?state') (getM state)))"
            using `InvariantUniq (getM state)`
            using `InvariantConsistent (getM state)`
            using `isMinimalBackjumpLevel (getBackjumpLevel ?state') (opposite ?l) (getC ?state') (getM ?state')`
            using `getM ?state' = getM state` `getC ?state' = getC state`
            using `clauseFalse (getC state) (elements (getM state))`
            using isBackjumpLevelEnsuresIsUnitInPrefix[of "getM ?state'" "getC ?state'" "getBackjumpLevel ?state'" "opposite ?l"]
            unfolding isMinimalBackjumpLevel_def
            unfolding InvariantUniq_def
            unfolding InvariantConsistent_def
            by simp
          hence "\<not> clauseFalse (getC state) (elements (prefixToLevel (getBackjumpLevel ?state') (getM state)))"
            unfolding isUnitClause_def
            by (auto simp add: clauseFalseIffAllLiteralsAreFalse)
          have "?false"
          proof
            fix level'
            show "level' < getBackjumpLevel ?state' \<longrightarrow> \<not> clauseFalse clause (elements (prefixToLevel level' (getM ?state')))"
            proof
              assume "level' < getBackjumpLevel ?state'"
              show "\<not> clauseFalse clause (elements (prefixToLevel level' (getM ?state')))"
              proof-
                have "isPrefix (prefixToLevel level' (getM state)) (prefixToLevel (getBackjumpLevel ?state') (getM state))"
                  using `level' < getBackjumpLevel ?state'`
                  using isPrefixPrefixToLevelLowerLevel[of "level'" "getBackjumpLevel ?state'" "getM state"]
                  by simp
                then obtain s
                  where "prefixToLevel level' (getM state) @ s = prefixToLevel (getBackjumpLevel ?state') (getM state)"
                  unfolding isPrefix_def
                  by auto
                hence "prefixToLevel (getBackjumpLevel ?state') (getM state) = prefixToLevel level' (getM state) @ s"
                  by (rule sym)
                thus ?thesis
                  using `getM ?state' = getM state`
                  using `clause = getC state`
                  using `\<not> clauseFalse (getC state) (elements (prefixToLevel (getBackjumpLevel ?state') (getM state)))`
                  unfolding isPrefix_def
                  by (auto simp add: clauseFalseIffAllLiteralsAreFalse)
              qed
            qed
          qed
          ultimately
          show ?thesis
            by simp
        qed
      qed
    } thus ?thesis
      unfolding InvariantNoDecisionsWhenConflict_def
      unfolding InvariantNoDecisionsWhenUnit_def
      by (auto simp add: formulaFalseIffContainsFalseClause)
  qed
  ultimately
  show ?thesis
    by (simp add: Let_def)
qed

lemma InvariantEquivalentZLAfterApplyLearn:
assumes
  "InvariantEquivalentZL (getF state) (getM state) F0" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "getConflictFlag state"
shows
  "let state' = applyLearn state in 
         InvariantEquivalentZL (getF state') (getM state') F0"
proof-
  let ?M0 = "val2form (elements (prefixToLevel 0 (getM state)))"
  have "equivalentFormulae F0 (getF state @ ?M0)"
    using `InvariantEquivalentZL (getF state) (getM state) F0`
    using equivalentFormulaeSymmetry[of "F0" "getF state @ ?M0"]
    unfolding InvariantEquivalentZL_def
    by simp
  moreover
  have "formulaEntailsClause (getF state @ ?M0) (getC state)"
    using assms
    unfolding InvariantEquivalentZL_def
    unfolding InvariantCEntailed_def
    unfolding equivalentFormulae_def
    unfolding formulaEntailsClause_def
    by auto
  ultimately
  have "equivalentFormulae F0 ((getF state @ ?M0) @ [getC state])"
    using extendEquivalentFormulaWithEntailedClause[of "F0" "getF state @ ?M0" "getC state"]
    by simp
  hence "equivalentFormulae ((getF state @ ?M0) @ [getC state]) F0"
    by (simp add: equivalentFormulaeSymmetry)
  have "equivalentFormulae ((getF state) @ [getC state] @ ?M0) F0"
  proof-
    {
      fix valuation::Valuation
      have "formulaTrue ((getF state @ ?M0) @ [getC state]) valuation = formulaTrue ((getF state) @ [getC state] @ ?M0) valuation"
        by (simp add: formulaTrueIffAllClausesAreTrue)
    }
    thus ?thesis
      using `equivalentFormulae ((getF state @ ?M0) @ [getC state]) F0`
      unfolding equivalentFormulae_def
      by auto
  qed
  thus ?thesis
    using assms
    unfolding InvariantEquivalentZL_def
    unfolding applyLearn_def
    unfolding setWatch1_def
    unfolding setWatch2_def
    by (auto simp add: Let_def)
qed


lemma InvariantVarsFAfterApplyLearn:
assumes
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "getConflictFlag state"
  "InvariantVarsF (getF state) F0 Vbl"
  "InvariantVarsM (getM state) F0 Vbl"
shows
  "let state' = applyLearn state in 
     InvariantVarsF (getF state') F0 Vbl
  "
proof-
  from assms
  have "clauseFalse (getC state) (elements (getM state))"
    unfolding InvariantCFalse_def
    by simp
  hence "vars (getC state) \<subseteq> vars (elements (getM state))"
    using valuationContainsItsFalseClausesVariables[of "getC state" "elements (getM state)"]
    by simp
  thus ?thesis
    using applyLearnPreservedVariables[of "state"]
    using assms
    using varsAppendFormulae[of "getF state" "[getC state]"]
    unfolding InvariantVarsF_def
    unfolding InvariantVarsM_def
    by (auto simp add: Let_def)
qed


(******************************************************************************)
(*           A P P L Y    B A C K J U M P                                     *)
(******************************************************************************)

lemma applyBackjumpEffect:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantUniqC (getC state)"
  
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"
shows
  "let l = (getCl state) in
   let bClause = (getC state) in
   let bLiteral = opposite l in
   let level = getBackjumpLevel state in
   let prefix = prefixToLevel level (getM state) in
   let state'' = applyBackjump state in 
         (formulaEntailsClause F0 bClause \<and> 
          isUnitClause bClause bLiteral (elements prefix) \<and> 
          (getM state'') = prefix @ [(bLiteral, False)]) \<and> 
          getF state'' = getF state"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "applyBackjump state"

  have "clauseFalse (getC state) (elements (getM state))"
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    unfolding InvariantCFalse_def
    by simp

  have "formulaEntailsClause F0 (getC state)"
    using `getConflictFlag state`
    using `InvariantCEntailed (getConflictFlag state) F0 (getC state)`
    unfolding InvariantCEntailed_def
    by simp

  have "isBackjumpLevel ?level (opposite ?l) (getC state) (getM state)"
    using assms
    using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
    unfolding isMinimalBackjumpLevel_def
    by (simp add: Let_def)
  then have "isUnitClause (getC state) (opposite ?l) (elements ?prefix)"
    using assms
    using `clauseFalse (getC state) (elements (getM state))`
    using isBackjumpLevelEnsuresIsUnitInPrefix[of "getM state" "getC state" "?level" "opposite ?l"]
    unfolding InvariantConsistent_def
    unfolding InvariantUniq_def
    by simp
  moreover
  have "getM ?state'' = ?prefix @ [(opposite ?l, False)]" "getF ?state'' = getF state"
    unfolding applyBackjump_def
    using assms
    using assertLiteralEffect
    unfolding setReason_def
    by (auto simp add: Let_def)
  ultimately
  show ?thesis
    using `formulaEntailsClause F0 (getC state)`
    by (simp add: Let_def)
qed

lemma applyBackjumpPreservedVariables:
assumes 
"InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)"
"InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)"
shows 
"let state' = applyBackjump state in 
   getSATFlag state' = getSATFlag state"
using assms
unfolding applyBackjump_def
unfolding setReason_def
by (auto simp add: Let_def assertLiteralEffect)


lemma InvariantWatchCharacterizationInBackjumpPrefix:
assumes
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)"

shows
  "let l = getCl state in
   let level = getBackjumpLevel state in
   let prefix = prefixToLevel level (getM state) in
   let state' = state\<lparr> getConflictFlag := False, getQ := [], getM := prefix \<rparr> in
     InvariantWatchCharacterization (getF state') (getWatch1 state') (getWatch2 state') (getM state')"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"

    {
      fix c w1 w2
      assume "c < length (getF state)" "Some w1 = getWatch1 state c" "Some w2 = getWatch2 state c"
      with `InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)`
      have "watchCharacterizationCondition w1 w2 (getM state) (nth (getF state) c)"
        "watchCharacterizationCondition w2 w1 (getM state) (nth (getF state) c)"
        unfolding InvariantWatchCharacterization_def
        by auto

      let ?clause = "nth (getF state) c"
      let "?a state w1 w2" = "\<exists> l. l el ?clause \<and> literalTrue l (elements (getM state)) \<and> 
                                   elementLevel l (getM state) \<le> elementLevel (opposite w1) (getM state)"
      let "?b state w1 w2" = "\<forall> l. l el ?clause \<and> l \<noteq> w1 \<and> l \<noteq> w2 \<longrightarrow> 
                             literalFalse l (elements (getM state)) \<and> 
                             elementLevel (opposite l) (getM state) \<le> elementLevel (opposite w1) (getM state)"

      have "watchCharacterizationCondition w1 w2 (getM ?state') ?clause \<and> 
            watchCharacterizationCondition w2 w1 (getM ?state') ?clause"
      proof-
        {
          assume "literalFalse w1 (elements (getM ?state'))"
          hence "literalFalse w1 (elements (getM state))"
            using isPrefixPrefixToLevel[of "?level" "getM state"]
            using isPrefixElements[of "prefixToLevel ?level (getM state)" "getM state"]
            using prefixIsSubset[of "elements (prefixToLevel ?level (getM state))" "elements (getM state)"]
            by auto

          from `literalFalse w1 (elements (getM ?state'))`
          have "elementLevel (opposite w1) (getM state) \<le> ?level"
            using prefixToLevelElementsElementLevel[of  "opposite w1" "?level" "getM state"]
            by simp

          from `literalFalse w1 (elements (getM ?state'))`
          have "elementLevel (opposite w1) (getM ?state') = elementLevel (opposite w1) (getM state)"
            using elementLevelPrefixElement
            by simp


          have "?a ?state' w1 w2 \<or> ?b ?state' w1 w2"
          proof (cases "?a state w1 w2")
            case True
            then obtain l
              where "l el ?clause" "literalTrue l (elements (getM state))" 
              "elementLevel l (getM state) \<le> elementLevel (opposite w1) (getM state)"
            by auto
            
            have "literalTrue l (elements (getM ?state'))"
              using `elementLevel (opposite w1) (getM state) \<le> ?level`
              using elementLevelLtLevelImpliesMemberPrefixToLevel[of "l" "getM state" "?level"]
              using `elementLevel l (getM state) \<le> elementLevel (opposite w1) (getM state)`
              using `literalTrue l (elements (getM state))`
              by simp
            moreover
            from `literalTrue l (elements (getM ?state'))`
            have "elementLevel l (getM ?state') = elementLevel l (getM state)"
              using elementLevelPrefixElement
              by simp
            ultimately 
            show ?thesis
              using `elementLevel (opposite w1) (getM ?state') = elementLevel (opposite w1) (getM state)`
              using `elementLevel l (getM state) \<le> elementLevel (opposite w1) (getM state)`
              using `l el ?clause`
              by auto
          next
            case False
            {
              fix l
              assume "l el ?clause" "l \<noteq> w1" "l \<noteq> w2"
              hence "literalFalse l (elements (getM state))" 
                "elementLevel (opposite l) (getM state) \<le> elementLevel (opposite w1) (getM state)"
                using `literalFalse w1 (elements (getM state))`
                using False
                using `watchCharacterizationCondition w1 w2 (getM state) ?clause`
                unfolding watchCharacterizationCondition_def
                by auto
              
              have "literalFalse l (elements (getM ?state')) \<and> 
                elementLevel (opposite l) (getM ?state') \<le> elementLevel (opposite w1) (getM ?state')"
              proof-
                have "literalFalse l (elements (getM ?state'))"
                  using `elementLevel (opposite w1) (getM state) \<le> ?level`
                  using elementLevelLtLevelImpliesMemberPrefixToLevel[of "opposite l" "getM state" "?level"]
                  using `elementLevel (opposite l) (getM state) \<le> elementLevel (opposite w1) (getM state)`
                  using `literalFalse l (elements (getM state))`
                  by simp
                moreover
                from `literalFalse l (elements (getM ?state'))`
                have "elementLevel (opposite l) (getM ?state') = elementLevel (opposite l) (getM state)"
                  using elementLevelPrefixElement
                  by simp
                ultimately 
                show ?thesis
                  using `elementLevel (opposite w1) (getM ?state') = elementLevel (opposite w1) (getM state)`
                  using `elementLevel (opposite l) (getM state) \<le> elementLevel (opposite w1) (getM state)`
                  using `l el ?clause`
                  by auto
              qed
            }
            thus ?thesis
              by auto
          qed
        }
        moreover
        {
          assume "literalFalse w2 (elements (getM ?state'))"
          hence "literalFalse w2 (elements (getM state))"
            using isPrefixPrefixToLevel[of "?level" "getM state"]
            using isPrefixElements[of "prefixToLevel ?level (getM state)" "getM state"]
            using prefixIsSubset[of "elements (prefixToLevel ?level (getM state))" "elements (getM state)"]
            by auto

          from `literalFalse w2 (elements (getM ?state'))`
          have "elementLevel (opposite w2) (getM state) \<le> ?level"
            using prefixToLevelElementsElementLevel[of "opposite w2" "?level" "getM state"]
            by simp

          from `literalFalse w2 (elements (getM ?state'))`
          have "elementLevel (opposite w2) (getM ?state') = elementLevel (opposite w2) (getM state)"
            using elementLevelPrefixElement
            by simp

          have "?a ?state' w2 w1 \<or> ?b ?state' w2 w1"
          proof (cases "?a state w2 w1")
            case True
            then obtain l
              where "l el ?clause" "literalTrue l (elements (getM state))" 
              "elementLevel l (getM state) \<le> elementLevel (opposite w2) (getM state)"
            by auto
            
            have "literalTrue l (elements (getM ?state'))"
              using `elementLevel (opposite w2) (getM state) \<le> ?level`
              using elementLevelLtLevelImpliesMemberPrefixToLevel[of "l" "getM state" "?level"]
              using `elementLevel l (getM state) \<le> elementLevel (opposite w2) (getM state)`
              using `literalTrue l (elements (getM state))`
              by simp
            moreover
            from `literalTrue l (elements (getM ?state'))`
            have "elementLevel l (getM ?state') = elementLevel l (getM state)"
              using elementLevelPrefixElement
              by simp
            ultimately 
            show ?thesis
              using `elementLevel (opposite w2) (getM ?state') = elementLevel (opposite w2) (getM state)`
              using `elementLevel l (getM state) \<le> elementLevel (opposite w2) (getM state)`
              using `l el ?clause`
              by auto
          next
            case False
            {
              fix l
              assume "l el ?clause" "l \<noteq> w1" "l \<noteq> w2"
              hence "literalFalse l (elements (getM state))" 
                "elementLevel (opposite l) (getM state) \<le> elementLevel (opposite w2) (getM state)"
                using `literalFalse w2 (elements (getM state))`
                using False
                using `watchCharacterizationCondition w2 w1 (getM state) ?clause`
                unfolding watchCharacterizationCondition_def
                by auto
              
              have "literalFalse l (elements (getM ?state')) \<and> 
                elementLevel (opposite l) (getM ?state') \<le> elementLevel (opposite w2) (getM ?state')"
              proof-
                have "literalFalse l (elements (getM ?state'))"
                  using `elementLevel (opposite w2) (getM state) \<le> ?level`
                  using elementLevelLtLevelImpliesMemberPrefixToLevel[of "opposite l" "getM state" "?level"]
                  using `elementLevel (opposite l) (getM state) \<le> elementLevel (opposite w2) (getM state)`
                  using `literalFalse l (elements (getM state))`
                  by simp
                moreover
                from `literalFalse l (elements (getM ?state'))`
                have "elementLevel (opposite l) (getM ?state') = elementLevel (opposite l) (getM state)"
                  using elementLevelPrefixElement
                  by simp
                ultimately 
                show ?thesis
                  using `elementLevel (opposite w2) (getM ?state') = elementLevel (opposite w2) (getM state)`
                  using `elementLevel (opposite l) (getM state) \<le> elementLevel (opposite w2) (getM state)`
                  using `l el ?clause`
                  by auto
              qed
            }
            thus ?thesis
              by auto
          qed
        }
        ultimately
        show ?thesis
          unfolding watchCharacterizationCondition_def
          by auto
      qed
    }
    thus ?thesis
      unfolding InvariantWatchCharacterization_def
      by auto
qed

lemma InvariantConsistentAfterApplyBackjump:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and 
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantUniqC (getC state)"
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "currentLevel (getM state) > 0"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
shows
  "let state' = applyBackjump state in 
         InvariantConsistent (getM state')"
proof-
  let ?l = "getCl state"
  let ?bClause = "getC state"
  let ?bLiteral = "opposite ?l"
  let ?level = "getBackjumpLevel state" 
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state'' = "applyBackjump state"

  have "formulaEntailsClause F0 ?bClause" and
    "isUnitClause ?bClause ?bLiteral (elements ?prefix)" and
    "getM ?state'' = ?prefix @ [(?bLiteral, False)]"
    using assms
    using applyBackjumpEffect[of "state"]
    by (auto simp add: Let_def)
  thus ?thesis
    using `InvariantConsistent (getM state)`
    using InvariantConsistentAfterBackjump[of "getM state" "?prefix" "?bClause" "?bLiteral" "getM ?state''"]
    using isPrefixPrefixToLevel
    by (auto simp add: Let_def)
qed
      

lemma InvariantUniqAfterApplyBackjump:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and 
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantUniqC (getC state)"
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "currentLevel (getM state) > 0"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
shows
  "let state' = applyBackjump state in
      InvariantUniq (getM state')"
proof-
  let ?l = "getCl state"
  let ?bClause = "getC state"
  let ?bLiteral = "opposite ?l"
  let ?level = "getBackjumpLevel state" 
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state'' = "applyBackjump state"

  have "clauseFalse (getC state) (elements (getM state))"
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    unfolding InvariantCFalse_def
    by simp
    
  have "isUnitClause ?bClause ?bLiteral (elements ?prefix)" and
    "getM ?state'' = ?prefix @ [(?bLiteral, False)]"
    using assms
    using applyBackjumpEffect[of "state"]
    by (auto simp add: Let_def)
  thus ?thesis
    using `InvariantUniq (getM state)`
    using InvariantUniqAfterBackjump[of "getM state" "?prefix" "?bClause" "?bLiteral" "getM ?state''"]
    using isPrefixPrefixToLevel
    by (auto simp add: Let_def)
qed

lemma WatchInvariantsAfterApplyBackjump:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and 
  "InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)" and 
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)" and 
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)"

  "getConflictFlag state"
  "InvariantUniqC (getC state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"
shows
  "let state' = (applyBackjump state) in
     InvariantWatchesEl (getF state') (getWatch1 state') (getWatch2 state') \<and> 
     InvariantWatchesDiffer (getF state') (getWatch1 state') (getWatch2 state') \<and> 
     InvariantWatchCharacterization (getF state') (getWatch1 state') (getWatch2 state') (getM state') \<and> 
     InvariantWatchListsContainOnlyClausesFromF (getWatchList state') (getF state') \<and> 
     InvariantWatchListsUniq (getWatchList state') \<and> 
     InvariantWatchListsCharacterization (getWatchList state') (getWatch1 state') (getWatch2 state')"
(is "let state' = (applyBackjump state) in ?inv state'")
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "setReason (opposite (getCl state)) (length (getF state) - 1) ?state'"
  let ?state0 = "assertLiteral (opposite (getCl state)) False ?state''"

  have "getF ?state' = getF state" "getWatchList ?state' = getWatchList state" 
    "getWatch1 ?state' = getWatch1 state" "getWatch2 ?state' = getWatch2 state"
    unfolding setReason_def
    by (auto simp add: Let_def)
  moreover
  have "InvariantWatchCharacterization (getF ?state') (getWatch1 ?state') (getWatch2 ?state') (getM ?state')"
    using assms
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    unfolding setReason_def
    by (simp add: Let_def)
  moreover 
  have "InvariantConsistent (?prefix @ [(opposite ?l, False)])"
    using assms
    using InvariantConsistentAfterApplyBackjump[of "state" "F0"]
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def split: split_if_asm)
  moreover
  have "InvariantUniq (?prefix @ [(opposite ?l, False)])"
    using assms
    using InvariantUniqAfterApplyBackjump[of "state" "F0"]
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def split: split_if_asm)
  ultimately
  show ?thesis
    using assms
    using WatchInvariantsAfterAssertLiteral[of "?state''" "opposite ?l" "False"]
    using WatchInvariantsAfterAssertLiteral[of "?state'" "opposite ?l" "False"]
    using InvariantWatchCharacterizationAfterAssertLiteral[of "?state''" "opposite ?l" "False"]
    using InvariantWatchCharacterizationAfterAssertLiteral[of "?state'" "opposite ?l" "False"]
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def)
qed

lemma InvariantUniqQAfterApplyBackjump:
assumes 
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)"
shows
  "let state' = applyBackjump state in
      InvariantUniqQ (getQ state')"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "setReason (opposite (getCl state)) (length (getF state) - 1) ?state'"

  show ?thesis
    using assms
    unfolding applyBackjump_def
    using InvariantUniqQAfterAssertLiteral[of "?state'" "opposite ?l" "False"]
    using InvariantUniqQAfterAssertLiteral[of "?state''" "opposite ?l" "False"]
    unfolding InvariantUniqQ_def
    unfolding setReason_def
    by (auto simp add: Let_def)
qed

  
lemma invariantQCharacterizationAfterApplyBackjump_1:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)" and
  "InvariantConflictFlagCharacterization (getConflictFlag state) (getF state) (getM state)" and
  "InvariantQCharacterization (getConflictFlag state) (getQ state) (getF state) (getM state)" and
  
  "InvariantUniqC (getC state)"
  "getC state = [opposite (getCl state)]"
  "InvariantNoDecisionsWhenUnit (getF state) (getM state) (currentLevel (getM state))"
  "InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))"

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" 
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "currentLevel (getM state) > 0"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
shows
  "let state'' = (applyBackjump state) in
     InvariantQCharacterization (getConflictFlag state'') (getQ state'') (getF state'') (getM state'')"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "setReason (opposite (getCl state)) (length (getF state) - 1) ?state'"

  let ?state'1 = "assertLiteral  (opposite ?l) False ?state'"
  let ?state''1 = "assertLiteral  (opposite ?l) False ?state''"

  have "?level < elementLevel ?l (getM state)"
    using assms
    using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
    unfolding isMinimalBackjumpLevel_def
    unfolding isBackjumpLevel_def
    by (simp add: Let_def)
  hence "?level < currentLevel (getM state)"
    using elementLevelLeqCurrentLevel[of "?l" "getM state"]
    by simp
  hence "InvariantQCharacterization (getConflictFlag ?state') (getQ ?state') (getF ?state') (getM ?state')"
        "InvariantConflictFlagCharacterization (getConflictFlag ?state') (getF ?state') (getM ?state')"
    unfolding InvariantQCharacterization_def
    unfolding InvariantConflictFlagCharacterization_def
    using `InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))`
    using `InvariantNoDecisionsWhenUnit (getF state) (getM state) (currentLevel (getM state))`
    unfolding InvariantNoDecisionsWhenConflict_def
    unfolding InvariantNoDecisionsWhenUnit_def
    unfolding applyBackjump_def
    by (auto simp add: Let_def set_conv_nth)
  moreover
  have "InvariantConsistent (?prefix @  [(opposite ?l, False)])"
    using assms
    using InvariantConsistentAfterApplyBackjump[of "state" "F0"]
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def split: split_if_asm)
  moreover
  have "InvariantWatchCharacterization (getF ?state') (getWatch1 ?state') (getWatch2 ?state') (getM ?state')"
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    using assms
    by (simp add: Let_def)
  moreover
  have "\<not> opposite ?l el (getQ ?state'1)" "\<not> opposite ?l el (getQ ?state''1)"
    using assertedLiteralIsNotUnit[of "?state'" "opposite ?l" "False"]
    using assertedLiteralIsNotUnit[of "?state''" "opposite ?l" "False"]
    using `InvariantQCharacterization (getConflictFlag ?state') (getQ ?state') (getF ?state') (getM ?state')`
    using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
    using `InvariantWatchCharacterization (getF ?state') (getWatch1 ?state') (getWatch2 ?state') (getM ?state')`
    unfolding applyBackjump_def
    unfolding setReason_def
    using assms
    by (auto simp add: Let_def split: split_if_asm)
  hence "removeAll (opposite ?l) (getQ ?state'1) = getQ ?state'1" 
        "removeAll (opposite ?l) (getQ ?state''1) = getQ ?state''1"
    using removeAll_id[of "opposite ?l" "getQ ?state'1"]
    using removeAll_id[of "opposite ?l" "getQ ?state''1"]
    unfolding setReason_def
    by auto
  ultimately
  show ?thesis
    using assms
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    using InvariantQCharacterizationAfterAssertLiteral[of "?state'" "opposite ?l" "False"]
    using InvariantQCharacterizationAfterAssertLiteral[of "?state''" "opposite ?l" "False"]
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def) 
qed


lemma invariantQCharacterizationAfterApplyBackjump_2:
fixes state::State
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)" and
  "InvariantConflictFlagCharacterization (getConflictFlag state) (getF state) (getM state)" and
  "InvariantQCharacterization (getConflictFlag state) (getQ state) (getF state) (getM state)" and
  
  "InvariantUniqC (getC state)"
  "getC state \<noteq> [opposite (getCl state)]"
  "InvariantNoDecisionsWhenUnit (butlast (getF state)) (getM state) (currentLevel (getM state))"
  "InvariantNoDecisionsWhenConflict (butlast (getF state)) (getM state) (currentLevel (getM state))"
  "getF state \<noteq> []"
  "last (getF state) = getC state"

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "currentLevel (getM state) > 0"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
shows
  "let state'' = (applyBackjump state) in
     InvariantQCharacterization (getConflictFlag state'') (getQ state'') (getF state'') (getM state'')"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"

  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "setReason (opposite (getCl state)) (length (getF state) - 1) ?state'"

  have "?level < elementLevel ?l (getM state)"
    using assms
    using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
    unfolding isMinimalBackjumpLevel_def
    unfolding isBackjumpLevel_def
    by (simp add: Let_def)
  hence "?level < currentLevel (getM state)"
    using elementLevelLeqCurrentLevel[of "?l" "getM state"]
    by simp

  have "isUnitClause (last (getF state)) (opposite ?l) (elements ?prefix)"
    using `last (getF state) = getC state`
    using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
    using `InvariantUniq (getM state)`
    using `InvariantConsistent (getM state)`
    using `getConflictFlag state`
    using `InvariantUniqC (getC state)`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    using isBackjumpLevelEnsuresIsUnitInPrefix[of "getM state" "getC state" "getBackjumpLevel state" "opposite ?l"]
    using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
    using `InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)`
    using `InvariantClCurrentLevel (getCl state) (getM state)`
    using `currentLevel (getM state) > 0`
    using `isUIP (opposite (getCl state)) (getC state) (getM state)`
    unfolding isMinimalBackjumpLevel_def
    unfolding InvariantUniq_def
    unfolding InvariantConsistent_def
    unfolding InvariantCFalse_def
    by (simp add: Let_def)
  hence "\<not> clauseFalse (last (getF state)) (elements ?prefix)"
    unfolding isUnitClause_def
    by (auto simp add: clauseFalseIffAllLiteralsAreFalse)

  have "InvariantConsistent (?prefix @  [(opposite ?l, False)])"
    using assms
    using InvariantConsistentAfterApplyBackjump[of "state" "F0"]
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def split: split_if_asm)

  have "InvariantUniq (?prefix @  [(opposite ?l, False)])"
    using assms
    using InvariantUniqAfterApplyBackjump[of "state" "F0"]
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def split: split_if_asm)

  let ?state'1 = "?state' \<lparr> getQ := getQ ?state' @ [opposite ?l]\<rparr>"
  let ?state'2 = "assertLiteral (opposite ?l) False ?state'1"

  let ?state''1 = "?state'' \<lparr> getQ := getQ ?state'' @ [opposite ?l]\<rparr>"
  let ?state''2 = "assertLiteral (opposite ?l) False ?state''1"

  have "InvariantQCharacterization (getConflictFlag ?state') ((getQ ?state') @ [opposite ?l]) (getF ?state') (getM ?state')"
  proof-
    have "\<forall> l c. c el (butlast (getF state)) \<longrightarrow> \<not> isUnitClause c l (elements (getM ?state'))"
      using `InvariantNoDecisionsWhenUnit (butlast (getF state)) (getM state) (currentLevel (getM state))`
      using `?level < currentLevel (getM state)`
      unfolding InvariantNoDecisionsWhenUnit_def
      by simp

    have "\<forall> l. ((\<exists> c. c el (getF state) \<and> isUnitClause c l (elements (getM ?state'))) = (l = opposite ?l))"
    proof
      fix l
      show "(\<exists> c. c el (getF state) \<and> isUnitClause c l (elements (getM ?state'))) = (l = opposite ?l)" (is "?lhs = ?rhs")
      proof
        assume "?lhs"
        then obtain c::Clause 
          where "c el (getF state)" and "isUnitClause c l (elements ?prefix)"
          by auto
        show "?rhs"
        proof (cases "c el (butlast (getF state))")
          case True
          thus ?thesis
            using `\<forall> l c. c el (butlast (getF state)) \<longrightarrow> \<not> isUnitClause c l (elements (getM ?state'))`
            using `isUnitClause c l (elements ?prefix)`
            by auto
        next
          case False

          from `getF state \<noteq> []`
          have "butlast (getF state) @ [last (getF state)] = getF state"
            using append_butlast_last_id[of "getF state"]
            by simp
          hence "getF state = butlast (getF state) @ [last (getF state)]"
            by (rule sym)
          with `c el getF state`
          have "c el butlast (getF state) \<or> c el [last (getF state)]"
            using set_append[of "butlast (getF state)" "[last (getF state)]"]
            by auto
          hence "c = last (getF state)"
            using `\<not> c el (butlast (getF state))`
            by simp
          thus ?thesis
            using `isUnitClause (last (getF state)) (opposite ?l) (elements ?prefix)`
            using `isUnitClause c l (elements ?prefix)`
            unfolding isUnitClause_def
            by auto
        qed
        next
          from `getF state \<noteq> []`
          have "last (getF state) el (getF state)"
            by auto
          assume "?rhs"
          thus "?lhs"
            using `isUnitClause (last (getF state)) (opposite ?l) (elements ?prefix)`
            using `last (getF state) el (getF state)`
            by auto
      qed
    qed
    thus ?thesis
      unfolding InvariantQCharacterization_def
      by simp
  qed
  hence "InvariantQCharacterization (getConflictFlag ?state'1) (getQ ?state'1) (getF ?state'1) (getM ?state'1)"
    by simp
  hence "InvariantQCharacterization (getConflictFlag ?state''1) (getQ ?state''1) (getF ?state''1) (getM ?state''1)"
    unfolding setReason_def
    by simp

  have "InvariantWatchCharacterization (getF ?state'1) (getWatch1 ?state'1) (getWatch2 ?state'1) (getM ?state'1)"
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    using assms
    by (simp add: Let_def)
  hence "InvariantWatchCharacterization (getF ?state''1) (getWatch1 ?state''1) (getWatch2 ?state''1) (getM ?state''1)"
    unfolding setReason_def
    by simp

  have "InvariantWatchCharacterization (getF ?state') (getWatch1 ?state') (getWatch2 ?state') (getM ?state')"
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    using assms
    by (simp add: Let_def)
  hence "InvariantWatchCharacterization (getF ?state'') (getWatch1 ?state'') (getWatch2 ?state'') (getM ?state'')"
    unfolding setReason_def
    by simp

  have "InvariantConflictFlagCharacterization (getConflictFlag ?state'1) (getF ?state'1) (getM ?state'1)"
  proof-
    {
      fix c::Clause
      assume "c el (getF state)"
      have "\<not> clauseFalse c (elements ?prefix)"
      proof (cases "c el (butlast (getF state))")
        case True
        thus ?thesis
          using `InvariantNoDecisionsWhenConflict (butlast (getF state)) (getM state) (currentLevel (getM state))`
          using `?level < currentLevel (getM state)`
          unfolding InvariantNoDecisionsWhenConflict_def
          by (simp add: formulaFalseIffContainsFalseClause)
      next
        case False
        from `getF state \<noteq> []`
        have "butlast (getF state) @ [last (getF state)] = getF state"
          using append_butlast_last_id[of "getF state"]
          by simp
        hence "getF state = butlast (getF state) @ [last (getF state)]"
          by (rule sym)
        with `c el getF state`
        have "c el butlast (getF state) \<or> c el [last (getF state)]"
          using set_append[of "butlast (getF state)" "[last (getF state)]"]
          by auto
        hence "c = last (getF state)"
          using `\<not> c el (butlast (getF state))`
          by simp
        thus ?thesis
          using `\<not> clauseFalse (last (getF state)) (elements ?prefix)`
          by simp
      qed
    } thus ?thesis
      unfolding InvariantConflictFlagCharacterization_def
      by (simp add: formulaFalseIffContainsFalseClause)
  qed
  hence "InvariantConflictFlagCharacterization (getConflictFlag ?state''1) (getF ?state''1) (getM ?state''1)"
    unfolding setReason_def
    by simp
  
  
  have "InvariantQCharacterization (getConflictFlag ?state'2) (removeAll (opposite ?l) (getQ ?state'2)) (getF ?state'2) (getM ?state'2)"
    using assms
    using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
    using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
    using `InvariantConflictFlagCharacterization (getConflictFlag ?state'1) (getF ?state'1) (getM ?state'1)`
    using `InvariantWatchCharacterization (getF ?state'1) (getWatch1 ?state'1) (getWatch2 ?state'1) (getM ?state'1)`
    using `InvariantQCharacterization (getConflictFlag ?state'1) (getQ ?state'1) (getF ?state'1) (getM ?state'1)`
    using InvariantQCharacterizationAfterAssertLiteral[of "?state'1" "opposite ?l" "False"]
    by (simp add: Let_def)

  have "InvariantQCharacterization (getConflictFlag ?state''2) (removeAll (opposite ?l) (getQ ?state''2)) (getF ?state''2) (getM ?state''2)"
    using assms
    using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
    using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
    using `InvariantConflictFlagCharacterization (getConflictFlag ?state''1) (getF ?state''1) (getM ?state''1)`
    using `InvariantWatchCharacterization (getF ?state''1) (getWatch1 ?state''1) (getWatch2 ?state''1) (getM ?state''1)`
    using `InvariantQCharacterization (getConflictFlag ?state''1) (getQ ?state''1) (getF ?state''1) (getM ?state''1)`
    using InvariantQCharacterizationAfterAssertLiteral[of "?state''1" "opposite ?l" "False"]
    unfolding setReason_def
    by (simp add: Let_def)

  let ?stateB = "applyBackjump state"
  show ?thesis
  proof (cases "getBackjumpLevel state > 0")
    case False
    let ?state01 = "state\<lparr>getConflictFlag := False, getM := ?prefix\<rparr>"
    have  "InvariantWatchesEl (getF ?state01) (getWatch1 ?state01) (getWatch2 ?state01)"
      using `InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)`
      unfolding InvariantWatchesEl_def
      by auto
    
    have "InvariantWatchListsContainOnlyClausesFromF (getWatchList ?state01) (getF ?state01)"
      using `InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)`
      unfolding InvariantWatchListsContainOnlyClausesFromF_def
      by auto

    have "assertLiteral (opposite ?l) False (state \<lparr>getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>) = 
          assertLiteral (opposite ?l) False (state \<lparr>getConflictFlag := False, getM := ?prefix, getQ := [] \<rparr>)"
      using arg_cong[of "state \<lparr>getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
                        "state \<lparr>getConflictFlag := False, getM := ?prefix, getQ := [] \<rparr>"
                        "\<lambda> x. assertLiteral (opposite ?l) False x"]
      by simp
    hence "getConflictFlag ?stateB = getConflictFlag ?state'2" 
      "getF ?stateB = getF ?state'2"  
      "getM ?stateB = getM ?state'2"
      unfolding applyBackjump_def
      using AssertLiteralStartQIreleveant[of "?state01" "opposite ?l" "False" "[]" "[opposite ?l]"]
      using `InvariantWatchesEl (getF ?state01) (getWatch1 ?state01) (getWatch2 ?state01)`
      using `InvariantWatchListsContainOnlyClausesFromF (getWatchList ?state01) (getF ?state01)`
      using `\<not> getBackjumpLevel state > 0`
      by (auto simp add: Let_def)

    have  "set (getQ ?stateB) = set (removeAll (opposite ?l) (getQ ?state'2))"
    proof-
      have "set (getQ ?stateB) = set(getQ ?state'2) - {opposite ?l}"
      proof-
        let ?ulSet = "{ ul. (\<exists> uc. uc el (getF ?state'1) \<and> 
                                   ?l el uc \<and> 
                                   isUnitClause uc ul ((elements (getM ?state'1)) @ [opposite ?l])) }"
        have "set (getQ ?state'2) = {opposite ?l} \<union> ?ulSet"
          using assertLiteralQEffect[of "?state'1" "opposite ?l" "False"]
          using assms
          using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
          using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
          using `InvariantWatchCharacterization (getF ?state'1) (getWatch1 ?state'1) (getWatch2 ?state'1) (getM ?state'1)`
          by (simp add:Let_def)
        moreover
        have "set (getQ ?stateB) = ?ulSet"
          using assertLiteralQEffect[of "?state'" "opposite ?l" "False"]
          using assms
          using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
          using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
          using `InvariantWatchCharacterization (getF ?state') (getWatch1 ?state') (getWatch2 ?state') (getM ?state')`
          using `\<not> getBackjumpLevel state > 0`
          unfolding applyBackjump_def
          by (simp add:Let_def)
        moreover
        have "\<not> (opposite ?l) \<in> ?ulSet"
          using assertedLiteralIsNotUnit[of "?state'" "opposite ?l" "False"]
          using assms
          using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
          using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
          using `InvariantWatchCharacterization (getF ?state') (getWatch1 ?state') (getWatch2 ?state') (getM ?state')`
          using `set (getQ ?stateB) = ?ulSet`
          using `\<not> getBackjumpLevel state > 0`
          unfolding applyBackjump_def
          by (simp add: Let_def)
        ultimately
        show ?thesis
          by simp
      qed
      thus ?thesis
        by simp
    qed

    show ?thesis
      using `InvariantQCharacterization (getConflictFlag ?state'2) (removeAll (opposite ?l) (getQ ?state'2)) (getF ?state'2) (getM ?state'2)`
      using `set (getQ ?stateB) = set (removeAll (opposite ?l) (getQ ?state'2))`
      using `getConflictFlag ?stateB = getConflictFlag ?state'2`
      using `getF ?stateB = getF ?state'2`
      using `getM ?stateB = getM ?state'2`
      unfolding InvariantQCharacterization_def
      by (simp add: Let_def)
  next
    case True
    let ?state02 = "setReason (opposite (getCl state)) (length (getF state) - 1) 
                    state\<lparr>getConflictFlag := False, getM := ?prefix\<rparr>"
    have  "InvariantWatchesEl (getF ?state02) (getWatch1 ?state02) (getWatch2 ?state02)"
      using `InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)`
      unfolding InvariantWatchesEl_def
      unfolding setReason_def
      by auto
    
    have "InvariantWatchListsContainOnlyClausesFromF (getWatchList ?state02) (getF ?state02)"
      using `InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)`
      unfolding InvariantWatchListsContainOnlyClausesFromF_def
      unfolding setReason_def
      by auto


    let ?stateTmp' = "assertLiteral (opposite (getCl state)) False
      (setReason (opposite (getCl state)) (length (getF state) - 1) 
           state \<lparr>getConflictFlag := False,
                  getM := prefixToLevel (getBackjumpLevel state) (getM state),
                  getQ := []\<rparr>
      )"
    let ?stateTmp'' = "assertLiteral (opposite (getCl state)) False
     (setReason (opposite (getCl state)) (length (getF state) - 1) 
          state  \<lparr>getConflictFlag := False,
                  getM := prefixToLevel (getBackjumpLevel state) (getM state),
                  getQ := [opposite (getCl state)]\<rparr>
     )"

    have "getM ?stateTmp' = getM ?stateTmp''"
         "getF ?stateTmp' = getF ?stateTmp''"
         "getSATFlag ?stateTmp' = getSATFlag ?stateTmp''"
         "getConflictFlag ?stateTmp' = getConflictFlag ?stateTmp''"
      using AssertLiteralStartQIreleveant[of "?state02" "opposite ?l" "False" "[]" "[opposite ?l]"]
      using `InvariantWatchesEl (getF ?state02) (getWatch1 ?state02) (getWatch2 ?state02)`
      using `InvariantWatchListsContainOnlyClausesFromF (getWatchList ?state02) (getF ?state02)`
      by (auto simp add: Let_def)
    moreover
    have "?stateB = ?stateTmp'"
      using `getBackjumpLevel state > 0`
      using arg_cong[of "state \<lparr>
                               getConflictFlag := False,
                               getQ := [],
                               getM := ?prefix,
                               getReason := getReason state(opposite ?l \<mapsto> length (getF state) - 1)
                               \<rparr>"
                        "state \<lparr>
                               getReason := getReason state(opposite ?l \<mapsto> length (getF state) - 1),
                               getConflictFlag := False, 
                               getM := prefixToLevel (getBackjumpLevel state) (getM state),
                               getQ := []
                               \<rparr>"
                        "\<lambda> x. assertLiteral (opposite ?l) False x"]
      unfolding applyBackjump_def
      unfolding setReason_def
      by (auto simp add: Let_def)
    moreover
    have "?stateTmp'' = ?state''2"
      unfolding setReason_def
      using arg_cong[of "state \<lparr>getReason := getReason state(opposite ?l \<mapsto> length (getF state) - 1), 
                               getConflictFlag := False,
                               getM := ?prefix, getQ := [opposite ?l]\<rparr>"
                        "state \<lparr>getConflictFlag := False, 
                               getM := prefixToLevel (getBackjumpLevel state) (getM state),
                               getReason := getReason state(opposite ?l \<mapsto> length (getF state) - 1),
                               getQ := [opposite ?l]\<rparr>"
                        "\<lambda> x. assertLiteral (opposite ?l) False x"]
      by simp
    ultimately 
    have "getConflictFlag ?stateB = getConflictFlag ?state''2" 
      "getF ?stateB = getF ?state''2"  
      "getM ?stateB = getM ?state''2"
      by auto

    have  "set (getQ ?stateB) = set (removeAll (opposite ?l) (getQ ?state''2))"
    proof-
      have "set (getQ ?stateB) = set(getQ ?state''2) - {opposite ?l}"
      proof-
        let ?ulSet = "{ ul. (\<exists> uc. uc el (getF ?state''1) \<and> 
                                   ?l el uc \<and> 
                                   isUnitClause uc ul ((elements (getM ?state''1)) @ [opposite ?l])) }"
        have "set (getQ ?state''2) = {opposite ?l} \<union> ?ulSet"
          using assertLiteralQEffect[of "?state''1" "opposite ?l" "False"]
          using assms
          using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
          using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
          using `InvariantWatchCharacterization (getF ?state''1) (getWatch1 ?state''1) (getWatch2 ?state''1) (getM ?state''1)`
          unfolding setReason_def
          by (simp add:Let_def)
        moreover
        have "set (getQ ?stateB) = ?ulSet"
          using assertLiteralQEffect[of "?state''" "opposite ?l" "False"]
          using assms
          using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
          using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
          using `InvariantWatchCharacterization (getF ?state'') (getWatch1 ?state'') (getWatch2 ?state'') (getM ?state'')`
          using `getBackjumpLevel state > 0`
          unfolding applyBackjump_def
          unfolding setReason_def
          by (simp add:Let_def)
        moreover
        have "\<not> (opposite ?l) \<in> ?ulSet"
          using assertedLiteralIsNotUnit[of "?state''" "opposite ?l" "False"]
          using assms
          using `InvariantConsistent (?prefix @  [(opposite ?l, False)])`
          using `InvariantUniq (?prefix @  [(opposite ?l, False)])`
          using `InvariantWatchCharacterization (getF ?state'') (getWatch1 ?state'') (getWatch2 ?state'') (getM ?state'')`
          using `set (getQ ?stateB) = ?ulSet`
          using `getBackjumpLevel state > 0`
          unfolding applyBackjump_def
          unfolding setReason_def
          by (simp add: Let_def)
        ultimately
        show ?thesis
          by simp
      qed
      thus ?thesis
        by simp
    qed

    show ?thesis
      using `InvariantQCharacterization (getConflictFlag ?state''2) (removeAll (opposite ?l) (getQ ?state''2)) (getF ?state''2) (getM ?state''2)`
      using `set (getQ ?stateB) = set (removeAll (opposite ?l) (getQ ?state''2))`
      using `getConflictFlag ?stateB = getConflictFlag ?state''2`
      using `getF ?stateB = getF ?state''2`
      using `getM ?stateB = getM ?state''2`
      unfolding InvariantQCharacterization_def
      by (simp add: Let_def)
  qed
qed

lemma InvariantConflictFlagCharacterizationAfterApplyBackjump_1:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)" and

  "InvariantUniqC (getC state)"
  "getC state = [opposite (getCl state)]"
  "InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))"

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "currentLevel (getM state) > 0"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
shows
  "let state' = (applyBackjump state) in
     InvariantConflictFlagCharacterization (getConflictFlag state') (getF state') (getM state')"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "setReason (opposite ?l) (length (getF state) - 1) ?state'"
  let ?stateB = "applyBackjump state"

  have "?level < elementLevel ?l (getM state)"
    using assms
    using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
    unfolding isMinimalBackjumpLevel_def
    unfolding isBackjumpLevel_def
    by (simp add: Let_def)
  hence "?level < currentLevel (getM state)"
    using elementLevelLeqCurrentLevel[of "?l" "getM state"]
    by simp
  hence "InvariantConflictFlagCharacterization (getConflictFlag ?state') (getF ?state') (getM ?state')"
    using `InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))`
    unfolding InvariantNoDecisionsWhenConflict_def
    unfolding InvariantConflictFlagCharacterization_def
    by simp
  moreover
  have "InvariantConsistent (?prefix @ [(opposite ?l, False)])"
    using assms
    using InvariantConsistentAfterApplyBackjump[of "state" "F0"]
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def split: split_if_asm)
  ultimately
  show ?thesis
    using InvariantConflictFlagCharacterizationAfterAssertLiteral[of "?state'"]
    using InvariantConflictFlagCharacterizationAfterAssertLiteral[of "?state''"]
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    using assms
    unfolding applyBackjump_def
    unfolding setReason_def
    using assertLiteralEffect
    by (auto simp add: Let_def)
qed


lemma InvariantConflictFlagCharacterizationAfterApplyBackjump_2:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)" and

  "InvariantUniqC (getC state)"
  "getC state \<noteq> [opposite (getCl state)]"
  "InvariantNoDecisionsWhenConflict (butlast (getF state)) (getM state) (currentLevel (getM state))"
  "getF state \<noteq> []" "last (getF state) = getC state"

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "currentLevel (getM state) > 0"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
shows
  "let state' = (applyBackjump state) in
     InvariantConflictFlagCharacterization (getConflictFlag state') (getF state') (getM state')"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "setReason (opposite ?l) (length (getF state) - 1) ?state'"
  let ?stateB = "applyBackjump state"

  have "?level < elementLevel ?l (getM state)"
    using assms
    using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
    unfolding isMinimalBackjumpLevel_def
    unfolding isBackjumpLevel_def
    by (simp add: Let_def)
  hence "?level < currentLevel (getM state)"
    using elementLevelLeqCurrentLevel[of "?l" "getM state"]
    by simp

  hence "InvariantConflictFlagCharacterization (getConflictFlag ?state') (butlast (getF ?state')) (getM ?state')"
    using `InvariantNoDecisionsWhenConflict (butlast (getF state)) (getM state) (currentLevel (getM state))`
    unfolding InvariantNoDecisionsWhenConflict_def
    unfolding InvariantConflictFlagCharacterization_def
    by simp
  moreover
  have "isBackjumpLevel (getBackjumpLevel state) (opposite (getCl state)) (getC state) (getM state)"
    using assms
    using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
    unfolding isMinimalBackjumpLevel_def
    by (simp add: Let_def)
  hence "isUnitClause (last (getF state)) (opposite ?l) (elements ?prefix)"
    using isBackjumpLevelEnsuresIsUnitInPrefix[of "getM state" "getC state" "getBackjumpLevel state" "opposite ?l"]
    using `InvariantUniq (getM state)`
    using `InvariantConsistent (getM state)`
    using `getConflictFlag state`
    using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
    using `last (getF state) = getC state`
    unfolding InvariantUniq_def
    unfolding InvariantConsistent_def
    unfolding InvariantCFalse_def
    by (simp add: Let_def)
  hence "\<not> clauseFalse (last (getF state)) (elements ?prefix)"
    unfolding isUnitClause_def
    by (auto simp add: clauseFalseIffAllLiteralsAreFalse)
  moreover
  from `getF state \<noteq> []`
  have "butlast (getF state) @ [last (getF state)] = getF state"
    using append_butlast_last_id[of "getF state"]
    by simp
  hence "getF state = butlast (getF state) @ [last (getF state)]"
    by (rule sym)
  ultimately
  have "InvariantConflictFlagCharacterization (getConflictFlag ?state') (getF ?state') (getM ?state')"
    using set_append[of "butlast (getF state)" "[last (getF state)]"]
    unfolding InvariantConflictFlagCharacterization_def
    by (auto simp add: formulaFalseIffContainsFalseClause)
  moreover
  have "InvariantConsistent (?prefix @ [(opposite ?l, False)])"
    using assms
    using InvariantConsistentAfterApplyBackjump[of "state" "F0"]
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def split: split_if_asm)
  ultimately
  show ?thesis
    using InvariantConflictFlagCharacterizationAfterAssertLiteral[of "?state'"]
    using InvariantConflictFlagCharacterizationAfterAssertLiteral[of "?state''"]
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    using assms
    using assertLiteralEffect
    unfolding applyBackjump_def
    unfolding setReason_def
    by (auto simp add: Let_def)
qed

lemma InvariantConflictClauseCharacterizationAfterApplyBackjump:
assumes
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)"
shows
  "let state' = applyBackjump state in
      InvariantConflictClauseCharacterization (getConflictFlag state') (getConflictClause state') (getF state') (getM state')"
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "if 0 < ?level then setReason (opposite ?l) (length (getF state) - 1) ?state' else ?state'"

  have "\<not> getConflictFlag ?state'"
    by simp
  hence "InvariantConflictClauseCharacterization (getConflictFlag ?state'') (getConflictClause ?state'') (getF ?state'') (getM ?state'')"
    unfolding InvariantConflictClauseCharacterization_def
    unfolding setReason_def
    by auto
  moreover
  have "getF ?state'' = getF state" 
    "getWatchList ?state'' = getWatchList state"
    "getWatch1 ?state'' = getWatch1 state"
    "getWatch2 ?state'' = getWatch2 state"
    unfolding setReason_def
    by auto
  ultimately
  show ?thesis
    using assms
    using InvariantConflictClauseCharacterizationAfterAssertLiteral[of "?state''"]
    unfolding applyBackjump_def
    by (simp only: Let_def)
qed

lemma InvariantGetReasonIsReasonAfterApplyBackjump:
assumes
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and
  "InvariantWatchListsUniq (getWatchList state)" and
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)" and
  "getConflictFlag state"
  "InvariantUniqC (getC state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)"
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)"
  "InvariantClCharacterization (getCl state) (getC state) (getM state)"
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)"
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "0 < currentLevel (getM state)"
  "InvariantGetReasonIsReason (getReason state) (getF state) (getM state) (set (getQ state))"
  "getBackjumpLevel state > 0 \<longrightarrow> getF state \<noteq> [] \<and> last (getF state) = getC state"
shows
  "let state' = applyBackjump state in
    InvariantGetReasonIsReason (getReason state') (getF state') (getM state') (set (getQ state'))
  "
proof-
  let ?l = "getCl state"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "if 0 < ?level then setReason (opposite ?l) (length (getF state) - 1) ?state' else ?state'"
  let ?stateB = "applyBackjump state"
  have "InvariantGetReasonIsReason (getReason ?state') (getF ?state') (getM ?state') (set (getQ ?state'))"
  proof-
    {
      fix l::Literal
      assume *: "l el (elements ?prefix) \<and> \<not> l el (decisions ?prefix) \<and> elementLevel l ?prefix > 0"
      hence "l el (elements (getM state)) \<and> \<not> l el (decisions (getM state)) \<and> elementLevel l (getM state) > 0"
        using `InvariantUniq (getM state)`
        unfolding InvariantUniq_def
        using isPrefixPrefixToLevel[of "?level" "(getM state)"]
        using isPrefixElements[of "?prefix" "getM state"]
        using prefixIsSubset[of "elements ?prefix" "elements (getM state)"]
        using markedElementsTrailMemPrefixAreMarkedElementsPrefix[of "getM state" "?prefix" "l"]
        using elementLevelPrefixElement[of "l" "getBackjumpLevel state" "getM state"]
        by auto
        
      with assms
      obtain reason
        where "reason < length (getF state)" "isReason (nth (getF state) reason) l (elements (getM state))"
        "getReason state l = Some reason"
        unfolding InvariantGetReasonIsReason_def
        by auto
      hence "\<exists> reason. getReason state l = Some reason \<and> 
                       reason < length (getF state) \<and> 
                       isReason (nth (getF state) reason) l (elements ?prefix)"
        using isReasonHoldsInPrefix[of "l" "elements ?prefix" "elements (getM state)" "nth (getF state) reason"]
        using isPrefixPrefixToLevel[of "?level" "(getM state)"]
        using isPrefixElements[of "?prefix" "getM state"]
        using *
        by auto
    }
    thus ?thesis
      unfolding InvariantGetReasonIsReason_def
      by auto
  qed

  let ?stateM = "?state'' \<lparr> getM := getM ?state'' @ [(opposite ?l, False)] \<rparr>"


  have **: "getM ?stateM = ?prefix @ [(opposite ?l, False)]" 
    "getF ?stateM = getF state" 
    "getQ ?stateM = []"
    "getWatchList ?stateM = getWatchList state"
    "getWatch1 ?stateM = getWatch1 state"
    "getWatch2 ?stateM = getWatch2 state"
    unfolding setReason_def
    by auto

  have "InvariantGetReasonIsReason (getReason ?stateM) (getF ?stateM) (getM ?stateM) (set (getQ ?stateM))"
  proof-
    {
      fix l::Literal
      assume *: "l el (elements (getM ?stateM)) \<and> \<not> l el (decisions  (getM ?stateM)) \<and> elementLevel l  (getM ?stateM) > 0"

      have "isPrefix ?prefix (getM ?stateM)"
        unfolding setReason_def
        unfolding isPrefix_def
        by auto

      have "\<exists> reason. getReason ?stateM l = Some reason \<and> 
                       reason < length (getF ?stateM) \<and> 
                       isReason (nth (getF ?stateM) reason) l (elements (getM ?stateM))"
      proof (cases "l = opposite ?l") 
        case False
        hence "l el (elements ?prefix)"
          using *
          using **
          by auto
        moreover
        hence "\<not> l el (decisions ?prefix)"
          using elementLevelAppend[of "l" "?prefix" "[(opposite ?l, False)]"]
          using `isPrefix ?prefix (getM ?stateM)`
          using markedElementsPrefixAreMarkedElementsTrail[of "?prefix" "getM ?stateM" "l"]
          using *
          using **
          by auto
        moreover
        have "elementLevel l ?prefix = elementLevel l (getM ?stateM)"
          using `l el (elements ?prefix)`
          using *
          using **
          using elementLevelAppend[of "l" "?prefix" "[(opposite ?l, False)]"]
          by auto
        hence "elementLevel l ?prefix > 0"
          using *
          by simp
        ultimately
        obtain reason
          where "reason < length (getF state)" 
          "isReason (nth (getF state) reason) l (elements ?prefix)"
          "getReason state l = Some reason"
          using `InvariantGetReasonIsReason (getReason ?state') (getF ?state') (getM ?state') (set (getQ ?state'))`
          unfolding InvariantGetReasonIsReason_def
          by auto
        moreover
        have "getReason ?stateM l = getReason ?state' l"
          using False
          unfolding setReason_def
          by auto
        ultimately
        show ?thesis
          using isReasonAppend[of "nth (getF state) reason" "l" "elements ?prefix" "[opposite ?l]"]
          using **
          by auto
      next
        case True
        show ?thesis
        proof (cases "?level = 0")
          case True
          hence "currentLevel (getM ?stateM) = 0"
            using currentLevelPrefixToLevel[of "0" "getM state"]
            using *
            unfolding currentLevel_def
            by (simp add: markedElementsAppend)
          hence "elementLevel l (getM ?stateM) = 0"
            using `?level = 0`
            using elementLevelLeqCurrentLevel[of "l" "getM ?stateM"]
            by simp
          with *
          have False
            by simp
          thus ?thesis
            by simp
        next
          case False
          let ?reason = "length (getF state) - 1"

          have "getReason ?stateM l = Some ?reason"
            using `?level \<noteq> 0`
            using `l = opposite ?l`
            unfolding setReason_def
            by auto
          moreover
          have "(nth (getF state) ?reason) = (getC state)"
            using `?level \<noteq> 0`
            using `getBackjumpLevel state > 0 \<longrightarrow> getF state \<noteq> [] \<and> last (getF state) = getC state`
            using last_conv_nth[of "getF state"]
            by simp

          hence "isUnitClause (nth (getF state) ?reason) l (elements ?prefix)"
            using assms
            using applyBackjumpEffect[of "state" "F0"]
            using `l = opposite ?l`
            by (simp add: Let_def)
          hence "isReason (nth (getF state) ?reason) l (elements (getM ?stateM))"
            using **
            using isUnitClauseIsReason[of "nth (getF state) ?reason" "l" "elements ?prefix" "[opposite ?l]"]
            using `l = opposite ?l`
            by simp
          moreover
          have "?reason < length (getF state)"
            using `?level \<noteq> 0`
            using `getBackjumpLevel state > 0 \<longrightarrow> getF state \<noteq> [] \<and> last (getF state) = getC state`
            by simp
          ultimately
          show ?thesis
            using `?level \<noteq> 0`
            using `l = opposite ?l`
            using **
            by auto
        qed
      qed
    }
    thus ?thesis
      unfolding InvariantGetReasonIsReason_def
      unfolding setReason_def
      by auto
  qed
  thus ?thesis
    using InvariantGetReasonIsReasonAfterNotifyWatches[of "?stateM" "getWatchList ?stateM ?l" "?l" "?prefix" "False" "{}" "[]"]
    unfolding applyBackjump_def
    unfolding Let_def
    unfolding assertLiteral_def
    unfolding Let_def
    unfolding notifyWatches_def
    using **
    using assms
    unfolding InvariantWatchListsCharacterization_def
    unfolding InvariantWatchListsUniq_def
    unfolding InvariantWatchListsContainOnlyClausesFromF_def
    by auto
qed


lemma InvariantsNoDecisionsWhenConflictNorUnitAfterApplyBackjump_1:
assumes 
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and

  "InvariantUniqC (getC state)"
  "getC state = [opposite (getCl state)]"

  "InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))"
  "InvariantNoDecisionsWhenUnit (getF state) (getM state) (currentLevel (getM state))"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "getConflictFlag state"
  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"
shows 
  "let state' = applyBackjump state in 
          InvariantNoDecisionsWhenConflict (getF state') (getM state') (currentLevel (getM state')) \<and> 
          InvariantNoDecisionsWhenUnit (getF state') (getM state') (currentLevel (getM state'))"
proof-
  let ?l = "getCl state"
  let ?bClause = "getC state"
  let ?bLiteral = "opposite ?l"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "applyBackjump state"
  have "getM ?state' = ?prefix @ [(?bLiteral, False)]" "getF ?state' = getF state"
    using assms
    using applyBackjumpEffect[of "state"]
    by (auto simp add: Let_def)
  show ?thesis
  proof-
    
    have "?level < elementLevel ?l (getM state)"
      using assms
      using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
      unfolding isMinimalBackjumpLevel_def
      unfolding isBackjumpLevel_def
      by (simp add: Let_def)
    hence "?level < currentLevel (getM state)"
      using elementLevelLeqCurrentLevel[of "?l" "getM state"]
      by simp

    have "currentLevel (getM ?state') = currentLevel ?prefix"
      using `getM ?state' = ?prefix @ [(?bLiteral, False)]`
      using markedElementsAppend[of "?prefix" "[(?bLiteral, False)]"]
      unfolding currentLevel_def
      by simp

    hence "currentLevel (getM ?state') \<le> ?level"
      using currentLevelPrefixToLevel[of "?level" "getM state"]
      by simp

    show ?thesis
    proof-
      {
        fix level
        assume "level < currentLevel (getM ?state')"
        hence "level < currentLevel ?prefix"
          using `currentLevel (getM ?state') = currentLevel ?prefix`
          by simp
        hence "prefixToLevel level (getM (applyBackjump state)) = prefixToLevel level ?prefix"
          using `getM ?state' = ?prefix @ [(?bLiteral, False)]`
          using prefixToLevelAppend[of "level" "?prefix" "[(?bLiteral, False)]"]
          by simp
        have "level < ?level"
          using `level < currentLevel ?prefix`
          using `currentLevel (getM ?state') \<le> ?level`
          using `currentLevel (getM ?state') = currentLevel ?prefix`
          by simp
        have "prefixToLevel level (getM ?state') = prefixToLevel level ?prefix"
          using `getM ?state' = ?prefix @ [(?bLiteral, False)]`
          using prefixToLevelAppend[of "level" "?prefix" "[(?bLiteral, False)]"]
          using `level < currentLevel ?prefix`
          by simp

        hence "\<not> formulaFalse (getF ?state') (elements (prefixToLevel level (getM ?state')))"  (is "?false")
          using `InvariantNoDecisionsWhenConflict (getF state) (getM state) (currentLevel (getM state))`
          unfolding InvariantNoDecisionsWhenConflict_def
          using `level < ?level`
          using `?level < currentLevel (getM state)`
          using prefixToLevelPrefixToLevelHigherLevel[of "level" "?level" "getM state", THEN sym]
          using `getF ?state' = getF state`
          using `prefixToLevel level (getM ?state') = prefixToLevel level ?prefix`
          using prefixToLevelPrefixToLevelHigherLevel[of "level" "?level" "getM state", THEN sym]
          by (auto simp add: formulaFalseIffContainsFalseClause)
        moreover
        have "\<not> (\<exists> clause literal. 
                     clause el (getF ?state') \<and> 
                     isUnitClause clause literal (elements (prefixToLevel level (getM ?state'))))" (is "?unit")
          using `InvariantNoDecisionsWhenUnit  (getF state) (getM state) (currentLevel (getM state))`
          unfolding InvariantNoDecisionsWhenUnit_def
          using `level < ?level`
          using `?level < currentLevel (getM state)`
          using `getF ?state' = getF state`
          using `prefixToLevel level (getM ?state') = prefixToLevel level ?prefix`
          using prefixToLevelPrefixToLevelHigherLevel[of "level" "?level" "getM state", THEN sym]
          by simp
        ultimately
        have "?false \<and> ?unit"
          by simp
      } 
      thus ?thesis
        unfolding InvariantNoDecisionsWhenConflict_def
        unfolding InvariantNoDecisionsWhenUnit_def
        by (auto simp add: Let_def)
    qed
  qed
qed


lemma InvariantsNoDecisionsWhenConflictNorUnitAfterApplyBackjump_2:
assumes 
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and

  "InvariantUniqC (getC state)"
  "getC state \<noteq>  [opposite (getCl state)]"
  "InvariantNoDecisionsWhenConflict (butlast (getF state)) (getM state) (currentLevel (getM state))"
  "InvariantNoDecisionsWhenUnit (butlast (getF state)) (getM state) (currentLevel (getM state))"
  "getF state \<noteq> []" "last (getF state) = getC state"
  "InvariantNoDecisionsWhenConflict [getC state] (getM state) (getBackjumpLevel state)"
  "InvariantNoDecisionsWhenUnit [getC state] (getM state) (getBackjumpLevel state)"

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"

  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"
shows 
  "let state' = applyBackjump state in 
          InvariantNoDecisionsWhenConflict (getF state') (getM state') (currentLevel (getM state')) \<and> 
          InvariantNoDecisionsWhenUnit (getF state') (getM state') (currentLevel (getM state'))"
proof-
  let ?l = "getCl state"
  let ?bClause = "getC state"
  let ?bLiteral = "opposite ?l"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "applyBackjump state"
  have "getM ?state' = ?prefix @ [(?bLiteral, False)]" "getF ?state' = getF state"
    using assms
    using applyBackjumpEffect[of "state"]
    by (auto simp add: Let_def)
  show ?thesis
  proof-
    have "?level < elementLevel ?l (getM state)"
      using assms
      using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
      unfolding isMinimalBackjumpLevel_def
      unfolding isBackjumpLevel_def
      by (simp add: Let_def)
    hence "?level < currentLevel (getM state)"
      using elementLevelLeqCurrentLevel[of "?l" "getM state"]
      by simp

    have "currentLevel (getM ?state') = currentLevel ?prefix"
      using `getM ?state' = ?prefix @ [(?bLiteral, False)]`
      using markedElementsAppend[of "?prefix" "[(?bLiteral, False)]"]
      unfolding currentLevel_def
      by simp

    hence "currentLevel (getM ?state') \<le> ?level"
      using currentLevelPrefixToLevel[of "?level" "getM state"]
      by simp

    show ?thesis
    proof-
      {
        fix level
        assume "level < currentLevel (getM ?state')"
        hence "level < currentLevel ?prefix"
          using `currentLevel (getM ?state') = currentLevel ?prefix`
          by simp
        hence "prefixToLevel level (getM (applyBackjump state)) = prefixToLevel level ?prefix"
          using `getM ?state' = ?prefix @ [(?bLiteral, False)]`
          using prefixToLevelAppend[of "level" "?prefix" "[(?bLiteral, False)]"]
          by simp
        have "level < ?level"
          using `level < currentLevel ?prefix`
          using `currentLevel (getM ?state') \<le> ?level`
          using `currentLevel (getM ?state') = currentLevel ?prefix`
          by simp
        have "prefixToLevel level (getM ?state') = prefixToLevel level ?prefix"
          using `getM ?state' = ?prefix @ [(?bLiteral, False)]`
          using prefixToLevelAppend[of "level" "?prefix" "[(?bLiteral, False)]"]
          using `level < currentLevel ?prefix`
          by simp

        have "\<not> formulaFalse (butlast (getF ?state')) (elements (prefixToLevel level (getM ?state')))" 
          using `getF ?state' = getF state`
          using `InvariantNoDecisionsWhenConflict (butlast (getF state)) (getM state) (currentLevel (getM state))`
          using `level < ?level`
          using `?level < currentLevel (getM state)`
          using `prefixToLevel level (getM ?state') = prefixToLevel level ?prefix`
          using prefixToLevelPrefixToLevelHigherLevel[of "level" "?level" "getM state", THEN sym]
          unfolding InvariantNoDecisionsWhenConflict_def
          by (auto simp add: formulaFalseIffContainsFalseClause)
        moreover
        have "\<not> clauseFalse (last (getF ?state')) (elements (prefixToLevel level (getM ?state')))"
          using `getF ?state' = getF state`
          using `InvariantNoDecisionsWhenConflict [getC state] (getM state) (getBackjumpLevel state)`
          using `last (getF state) = getC state`
          using `level < ?level`
          using `prefixToLevel level (getM ?state') = prefixToLevel level ?prefix`
          using prefixToLevelPrefixToLevelHigherLevel[of "level" "?level" "getM state", THEN sym]
          unfolding InvariantNoDecisionsWhenConflict_def
          by (simp add: formulaFalseIffContainsFalseClause)
        moreover
        from `getF state \<noteq> []`
        have "butlast (getF state) @ [last (getF state)] = getF state"
          using append_butlast_last_id[of "getF state"]
          by simp
        hence "getF state = butlast (getF state) @ [last (getF state)]"
          by (rule sym)
        ultimately
        have "\<not> formulaFalse (getF ?state') (elements (prefixToLevel level (getM ?state')))" (is "?false")
          using `getF ?state' = getF state`
          using set_append[of "butlast (getF state)" "[last (getF state)]"]
          by (auto simp add: formulaFalseIffContainsFalseClause)
        
        have "\<not> (\<exists> clause literal. 
          clause el (butlast (getF ?state')) \<and> 
          isUnitClause clause literal (elements (prefixToLevel level (getM ?state'))))"
          using `InvariantNoDecisionsWhenUnit (butlast (getF state)) (getM state) (currentLevel (getM state))`
          unfolding InvariantNoDecisionsWhenUnit_def
          using `level < ?level`
          using `?level < currentLevel (getM state)`
          using `getF ?state' = getF state`
          using `prefixToLevel level (getM ?state') = prefixToLevel level ?prefix`
          using prefixToLevelPrefixToLevelHigherLevel[of "level" "?level" "getM state", THEN sym]
          by simp
        moreover
        have "\<not> (\<exists> l. isUnitClause (last (getF ?state')) l (elements (prefixToLevel level (getM ?state'))))"
          using `getF ?state' = getF state`
          using `InvariantNoDecisionsWhenUnit [getC state] (getM state) (getBackjumpLevel state)`
          using `last (getF state) = getC state`
          using `level < ?level`
          using `prefixToLevel level (getM ?state') = prefixToLevel level ?prefix`
          using prefixToLevelPrefixToLevelHigherLevel[of "level" "?level" "getM state", THEN sym]
          unfolding InvariantNoDecisionsWhenUnit_def
          by simp
        moreover
        from `getF state \<noteq> []`
        have "butlast (getF state) @ [last (getF state)] = getF state"
          using append_butlast_last_id[of "getF state"]
          by simp
        hence "getF state = butlast (getF state) @ [last (getF state)]"
          by (rule sym)
        ultimately
        have "\<not> (\<exists> clause literal. 
                   clause el (getF ?state') \<and> 
                   isUnitClause clause literal (elements (prefixToLevel level (getM ?state'))))" (is ?unit)
          using `getF ?state' = getF state`
          using set_append[of "butlast (getF state)" "[last (getF state)]"]
          by auto

        have "?false \<and> ?unit"
          using `?false` `?unit`
          by simp
      } 
      thus ?thesis
        unfolding InvariantNoDecisionsWhenConflict_def
        unfolding InvariantNoDecisionsWhenUnit_def
        by (auto simp add: Let_def)
    qed
  qed
qed

lemma InvariantEquivalentZLAfterApplyBackjump:
assumes 
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and

  "getConflictFlag state"
  "InvariantUniqC (getC state)"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0 (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantEquivalentZL (getF state) (getM state) F0"

  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"
shows
  "let state' = applyBackjump state in
      InvariantEquivalentZL (getF state') (getM state') F0
  "
proof-
  
  let ?l = "getCl state"
  let ?bClause = "getC state"
  let ?bLiteral = "opposite ?l"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "applyBackjump state"
  
  have "formulaEntailsClause F0 ?bClause"
    "isUnitClause ?bClause ?bLiteral (elements ?prefix)"
    "getM ?state' = ?prefix @ [(?bLiteral, False)] "
    "getF ?state' = getF state"
    using assms
    using applyBackjumpEffect[of "state" "F0"]
    by (auto simp add: Let_def)
  note * = this
  show ?thesis
  proof (cases "?level = 0") 
    case False
    have "?level < elementLevel ?l (getM state)"
      using assms
      using isMinimalBackjumpLevelGetBackjumpLevel[of "state"]
      unfolding isMinimalBackjumpLevel_def
      unfolding isBackjumpLevel_def
      by (simp add: Let_def)
    hence "?level < currentLevel (getM state)"
      using elementLevelLeqCurrentLevel[of "?l" "getM state"]
      by simp
    hence "prefixToLevel 0 (getM ?state') = prefixToLevel 0 ?prefix"
      using *
      using prefixToLevelAppend[of "0" "?prefix" "[(?bLiteral, False)]"]
      using `?level \<noteq> 0`
      using currentLevelPrefixToLevelEq[of "?level" "getM state"]
      by simp

    hence "prefixToLevel 0 (getM ?state') = prefixToLevel 0 (getM state)"
      using `?level \<noteq> 0`
      using prefixToLevelPrefixToLevelHigherLevel[of "0" "?level" "getM state"]
      by simp
    thus ?thesis
      using *
      using `InvariantEquivalentZL (getF state) (getM state) F0`
      unfolding InvariantEquivalentZL_def
      by (simp add: Let_def)    
  next
    case True
    hence "prefixToLevel 0 (getM ?state') = ?prefix @ [(?bLiteral, False)]"
      using *
      using prefixToLevelAppend[of "0" "?prefix" "[(?bLiteral, False)]"]
      using currentLevelPrefixToLevel[of "0" "getM state"]
      by simp

    let ?FM = "getF state @ val2form (elements (prefixToLevel 0 (getM state)))"
    let ?FM' = "getF ?state' @ val2form (elements (prefixToLevel 0 (getM ?state')))"
  
    have "formulaEntailsValuation F0 (elements ?prefix)"
      using `?level = 0`
      using val2formIsEntailed[of "getF state" "elements (prefixToLevel 0 (getM state))" "[]"]
      using `InvariantEquivalentZL (getF state) (getM state) F0`
      unfolding formulaEntailsValuation_def
      unfolding InvariantEquivalentZL_def
      unfolding equivalentFormulae_def
      unfolding formulaEntailsLiteral_def
      by auto

    have "formulaEntailsLiteral (F0 @ val2form (elements ?prefix)) ?bLiteral"
      using *
      using unitLiteralIsEntailed [of "?bClause" "?bLiteral" "elements ?prefix" "F0"]
      by simp

    have "formulaEntailsLiteral F0 ?bLiteral"
    proof-
      {
        fix valuation::Valuation
        assume "model valuation F0"
        hence "formulaTrue (val2form (elements ?prefix)) valuation"
          using `formulaEntailsValuation F0 (elements ?prefix)`
          using val2formFormulaTrue[of "elements ?prefix" "valuation"]
          unfolding formulaEntailsValuation_def
          unfolding formulaEntailsLiteral_def
          by simp
        hence "formulaTrue (F0 @ (val2form (elements ?prefix))) valuation"
          using `model valuation F0`
          by (simp add: formulaTrueAppend)
        hence "literalTrue ?bLiteral valuation"
          using `model valuation F0`
          using `formulaEntailsLiteral (F0 @ val2form (elements ?prefix)) ?bLiteral`
          unfolding formulaEntailsLiteral_def
          by auto
      }
      thus ?thesis
        unfolding formulaEntailsLiteral_def
        by simp
    qed
  
    hence "formulaEntailsClause F0 [?bLiteral]"
      unfolding formulaEntailsLiteral_def
      unfolding formulaEntailsClause_def
      by (auto simp add: clauseTrueIffContainsTrueLiteral)

    hence "formulaEntailsClause ?FM [?bLiteral]"
      using `InvariantEquivalentZL (getF state) (getM state) F0`
      unfolding InvariantEquivalentZL_def
      unfolding equivalentFormulae_def
      unfolding formulaEntailsClause_def
      by auto
    
    have "?FM' = ?FM @ [[?bLiteral]]"
      using *
      using `?level = 0`
      using `prefixToLevel 0 (getM ?state') = ?prefix @ [(?bLiteral, False)]`
      by (auto simp add: val2formAppend)

    show ?thesis
      using `InvariantEquivalentZL (getF state) (getM state) F0`
      using `?FM' = ?FM @ [[?bLiteral]]`
      using `formulaEntailsClause ?FM [?bLiteral]`
      unfolding InvariantEquivalentZL_def
      using extendEquivalentFormulaWithEntailedClause[of "F0" "?FM" "[?bLiteral]"]
      by (simp add: equivalentFormulaeSymmetry)
  qed
qed

lemma InvariantsVarsAfterApplyBackjump:
assumes 
  "InvariantConsistent (getM state)"
  "InvariantUniq (getM state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)" and
  "InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)" and

  "InvariantWatchListsUniq (getWatchList state)"
  "InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)"
  "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (getM state)" and 

  "getConflictFlag state"
  "InvariantCFalse (getConflictFlag state) (getM state) (getC state)" and
  "InvariantUniqC (getC state)" and
  "InvariantCEntailed (getConflictFlag state) F0' (getC state)" and
  "InvariantClCharacterization (getCl state) (getC state) (getM state)" and
  "InvariantCllCharacterization (getCl state) (getCll state) (getC state) (getM state)" and
  "InvariantClCurrentLevel (getCl state) (getM state)"
  "InvariantEquivalentZL (getF state) (getM state) F0'"

  "isUIP (opposite (getCl state)) (getC state) (getM state)"
  "currentLevel (getM state) > 0"

  "vars F0' \<subseteq> vars F0"

  "InvariantVarsM (getM state) F0 Vbl"
  "InvariantVarsF (getF state) F0 Vbl"
  "InvariantVarsQ (getQ state) F0 Vbl"
shows
  "let state' = applyBackjump state in
      InvariantVarsM (getM state') F0 Vbl \<and> 
      InvariantVarsF (getF state') F0 Vbl \<and> 
      InvariantVarsQ (getQ state') F0 Vbl 
  "
proof-
  
  let ?l = "getCl state"
  let ?bClause = "getC state"
  let ?bLiteral = "opposite ?l"
  let ?level = "getBackjumpLevel state"
  let ?prefix = "prefixToLevel ?level (getM state)"
  let ?state' = "state\<lparr> getConflictFlag := False, getQ := [], getM := ?prefix \<rparr>"
  let ?state'' = "setReason (opposite (getCl state)) (length (getF state) - 1) ?state'"
  let ?stateB = "applyBackjump state"
  
  have "formulaEntailsClause F0' ?bClause"
    "isUnitClause ?bClause ?bLiteral (elements ?prefix)"
    "getM ?stateB = ?prefix @ [(?bLiteral, False)] "
    "getF ?stateB = getF state"
    using assms
    using applyBackjumpEffect[of "state" "F0'"]
    by (auto simp add: Let_def)
  note * = this

  have "var ?bLiteral \<in> vars F0 \<union> Vbl"
  proof-
    have "vars (getC state) \<subseteq> vars (elements (getM state))"
      using `getConflictFlag state`
      using `InvariantCFalse (getConflictFlag state) (getM state) (getC state)`
      using valuationContainsItsFalseClausesVariables[of "getC state" "elements (getM state)"]
      unfolding InvariantCFalse_def
      by simp
    moreover
    have "?bLiteral el (getC state)"
      using `InvariantClCharacterization (getCl state) (getC state) (getM state)`
      unfolding InvariantClCharacterization_def
      unfolding isLastAssertedLiteral_def
      using literalElListIffOppositeLiteralElOppositeLiteralList[of "?bLiteral" "getC state"]
      by simp
    ultimately
    show ?thesis
      using `InvariantVarsM (getM state) F0 Vbl`
      using `vars F0' \<subseteq> vars F0`
      unfolding InvariantVarsM_def
      using clauseContainsItsLiteralsVariable[of "?bLiteral" "getC state"]
      by auto
  qed

  hence "InvariantVarsM (getM ?stateB) F0 Vbl"
    using `InvariantVarsM (getM state) F0 Vbl`
    using InvariantVarsMAfterBackjump[of "getM state" "F0" "Vbl" "?prefix" "?bLiteral" "getM ?stateB"]
    using *
    by (simp add: isPrefixPrefixToLevel)
  moreover
  have "InvariantConsistent (prefixToLevel (getBackjumpLevel state) (getM state) @ [(opposite (getCl state), False)])"
    "InvariantUniq (prefixToLevel (getBackjumpLevel state) (getM state) @ [(opposite (getCl state), False)])"
    "InvariantWatchCharacterization (getF state) (getWatch1 state) (getWatch2 state) (prefixToLevel (getBackjumpLevel state) (getM state))"
    using assms
    using InvariantConsistentAfterApplyBackjump[of "state" "F0'"]
    using InvariantUniqAfterApplyBackjump[of "state" "F0'"]
    using *
    using InvariantWatchCharacterizationInBackjumpPrefix[of "state"]
    by (auto simp add: Let_def)
  hence "InvariantVarsQ (getQ ?stateB) F0 Vbl"
    using `InvariantVarsF (getF state) F0 Vbl`
    using `InvariantWatchListsContainOnlyClausesFromF (getWatchList state) (getF state)`
    using `InvariantWatchListsUniq (getWatchList state)`
    using `InvariantWatchListsCharacterization (getWatchList state) (getWatch1 state) (getWatch2 state)`
    using `InvariantWatchesEl (getF state) (getWatch1 state) (getWatch2 state)`
    using `InvariantWatchesDiffer (getF state) (getWatch1 state) (getWatch2 state)`
    using InvariantVarsQAfterAssertLiteral[of "if ?level > 0 then ?state'' else ?state'" "?bLiteral" "False" "F0" "Vbl"]
    unfolding applyBackjump_def
    unfolding InvariantVarsQ_def
    unfolding setReason_def
    by (auto simp add: Let_def)
  moreover
  have "InvariantVarsF (getF ?stateB) F0 Vbl"
    using assms
    using assertLiteralEffect[of "if ?level > 0 then ?state'' else ?state'" "?bLiteral" "False"]
    using `InvariantVarsF (getF state) F0 Vbl`
    unfolding applyBackjump_def
    unfolding setReason_def
    by (simp add: Let_def)
  ultimately
  show ?thesis
    by (simp add: Let_def)
qed

end
