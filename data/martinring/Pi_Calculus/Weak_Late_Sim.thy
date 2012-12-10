(* 
   Title: The pi-calculus   
   Author/Maintainer: Jesper Bengtson (jebe.dk), 2012
*)
theory Weak_Late_Sim
  imports Weak_Late_Semantics Strong_Late_Sim
begin

definition weakSimAct :: "pi \<Rightarrow> residual \<Rightarrow> ('a::fs_name) \<Rightarrow> (pi \<times> pi) set \<Rightarrow> bool" where
  "weakSimAct P Rs C Rel \<equiv> (\<forall>Q' a x. Rs = a<\<nu>x> \<prec> Q' \<longrightarrow> x \<sharp> C \<longrightarrow> (\<exists>P' . P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel)) \<and>
                         (\<forall>Q' a x. Rs = a<x> \<prec> Q' \<longrightarrow> x \<sharp> C \<longrightarrow> (\<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel)) \<and>
                         (\<forall>Q' \<alpha>. Rs = \<alpha> \<prec> Q' \<longrightarrow> (\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P' \<and> (P', Q') \<in> Rel))"

definition weakSimAux :: "pi \<Rightarrow> (pi \<times> pi) set \<Rightarrow> pi \<Rightarrow> bool" where
  "weakSimAux P Rel Q \<equiv> (\<forall>Q' a x. (Q \<longmapsto> a<\<nu>x> \<prec> Q' \<and> x \<sharp> P) \<longrightarrow> (\<exists>P' . P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel)) \<and>
                         (\<forall>Q' a x. (Q \<longmapsto> a<x> \<prec> Q' \<and> x \<sharp> P) \<longrightarrow> (\<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel)) \<and>
                         (\<forall>Q' \<alpha>. Q \<longmapsto> \<alpha> \<prec> Q' \<longrightarrow> (\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P' \<and> (P', Q') \<in> Rel))"

definition weakSimulation :: "pi \<Rightarrow> (pi \<times> pi) set \<Rightarrow> pi \<Rightarrow> bool" ("_ \<leadsto>\<^isup>^<_> _" [80, 80, 80] 80) where
  "P \<leadsto>\<^isup>^<Rel> Q \<equiv> (\<forall>Rs. Q \<longmapsto> Rs \<longrightarrow> weakSimAct P Rs P Rel)"

lemmas simDef = weakSimAct_def weakSimulation_def

lemma "weakSimAux P Rel Q = weakSimulation P Rel Q"
by(auto simp add: weakSimAux_def simDef)

lemma monotonic: 
  fixes A  :: "(pi \<times> pi) set"
  and   B  :: "(pi \<times> pi) set"
  and   P  :: pi
  and   P' :: pi

  assumes "P \<leadsto>\<^isup>^<A> P'"
  and     "A \<subseteq> B"

  shows "P \<leadsto>\<^isup>^<B> P'"
using assms
apply(auto simp add: simDef)
apply blast
apply(erule_tac x="a<x> \<prec> Q'" in allE)
apply(clarsimp)
apply(rotate_tac 4)
apply(erule_tac x=Q' in allE)
apply(erule_tac x=a in allE)
apply(erule_tac x=x in allE)
by blast+

lemma simCasesCont[consumes 1, case_names Bound Input Free]:
  fixes P   :: pi
  and   Q   :: pi
  and   Rel :: "(pi \<times> pi) set"
  and   C   :: "'a::fs_name"

  assumes Eqvt:  "eqvt Rel"
  and     Bound: "\<And>Q' a x. \<lbrakk>x \<sharp> C; Q \<longmapsto>a<\<nu>x> \<prec> Q'\<rbrakk> \<Longrightarrow> \<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel"
  and     Input: "\<And>Q' a x. \<lbrakk>x \<sharp> C; Q \<longmapsto>a<x> \<prec> Q'\<rbrakk> \<Longrightarrow> \<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel"
  and     Free:  "\<And>Q' \<alpha>. Q \<longmapsto> \<alpha> \<prec> Q' \<Longrightarrow> (\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ \<alpha> \<prec> P' \<and> (P', Q') \<in> Rel)"

  shows "P \<leadsto>\<^isup>^<Rel> Q"
using Free 
proof(auto simp add: simDef)
  fix Q' a x
  assume xFreshP: "(x::name) \<sharp> P"
  assume Trans: "Q \<longmapsto> a<\<nu>x> \<prec> Q'"
  have "\<exists>c::name. c \<sharp> (P, Q', x, C)" by(blast intro: name_exists_fresh)
  then obtain c::name where cFreshP: "c \<sharp> P" and cFreshQ': "c \<sharp> Q'" and cFreshC: "c \<sharp> C"
                        and cineqx: "c \<noteq> x"
    by(force simp add: fresh_prod)

  from Trans cFreshQ' have "Q \<longmapsto> a<\<nu>c> \<prec> ([(x, c)] \<bullet> Q')" by(simp add: alphaBoundResidual)
  with cFreshC have "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ a<\<nu>c> \<prec> P' \<and> (P', [(x, c)] \<bullet> Q') \<in> Rel"
    by(rule Bound)
  then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>c> \<prec> P'" and P'RelQ': "(P', [(x, c)] \<bullet> Q') \<in> Rel"
    by blast

  from PTrans xFreshP cineqx have xFreshP': "x \<sharp> P'" by(force dest: freshTransition)
  with PTrans have "P \<Longrightarrow>\<^isub>l\<^isup>^ a<\<nu>x> \<prec> ([(x, c)] \<bullet> P')" by(simp add: alphaBoundResidual name_swap)
  moreover have "([(x, c)] \<bullet> P', Q') \<in> Rel" (is "?goal")
  proof -
    from Eqvt P'RelQ' have "([(x, c)] \<bullet> P', [(x, c)] \<bullet> [(x, c)] \<bullet> Q') \<in> Rel"
      by(rule eqvtRelI)
    with cineqx show ?goal by(simp add: name_calc)
  qed
  ultimately show "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel" by blast
next
  fix Q' a x u
  assume QTrans: "Q \<longmapsto>a<x> \<prec> (Q'::pi)"and xFreshP: "x \<sharp> P"

  have "\<exists>c::name. c \<sharp> (P, Q', C, x)" by(blast intro: name_exists_fresh)
  then obtain c::name where cFreshP: "c \<sharp> P" and cFreshQ': "c \<sharp> Q'" and cFreshC: "c \<sharp> C"
                        and cineqx: "c \<noteq> x"
    by(force simp add: fresh_prod)

  from QTrans cFreshQ' have "Q \<longmapsto>a<c> \<prec> ([(x, c)] \<bullet> Q')" by(simp add: alphaBoundResidual)
  with cFreshC have "\<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<c> \<prec> P' \<and> (P', ([(x, c)] \<bullet> Q')[c::=u]) \<in> Rel"
    by(rule Input)

  then obtain P'' where L1: "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<c> \<prec> P' \<and> (P', ([(x, c)] \<bullet> Q')[c::=u]) \<in> Rel" by blast
    
  have "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in ([(c, x)] \<bullet> P'')\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel"
  proof(auto)
    fix u
    from L1 obtain P' where PTrans: "P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<c> \<prec> P'" and P'RelQ': "(P', ([(x, c)] \<bullet> Q')[c::=u]) \<in> Rel"
      by blast
      
    from PTrans xFreshP have "P \<Longrightarrow>\<^isub>lu in ([(c, x)] \<bullet> P'')\<rightarrow>a<x> \<prec> P'" by(rule alphaInput) 
    moreover from P'RelQ' cFreshQ' have "(P', Q'[x::=u]) \<in> Rel" by(simp add: renaming[THEN sym] name_swap)

    ultimately show "\<exists>P'. P \<Longrightarrow>\<^isub>lu in ([(c, x)] \<bullet> P'')\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel" by blast
  qed

  thus "\<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel" by blast
qed

lemma simCases[case_names Bound Input Free]:
  fixes P   :: pi
  and   Q   :: pi
  and   Rel :: "(pi \<times> pi) set"
  and   C   :: "'a::fs_name"

  assumes Bound: "\<And>Q' a x. \<lbrakk>Q \<longmapsto>a<\<nu>x> \<prec> Q'; x \<sharp> P\<rbrakk> \<Longrightarrow> \<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel"
  and     Input: "\<And>Q' a x. \<lbrakk>Q \<longmapsto>a<x> \<prec> Q'; x \<sharp> P\<rbrakk> \<Longrightarrow> \<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel"
  and     Free:  "\<And>Q' \<alpha>. Q \<longmapsto> \<alpha> \<prec> Q' \<Longrightarrow> (\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ \<alpha> \<prec> P' \<and> (P', Q') \<in> Rel)"

  shows "P \<leadsto>\<^isup>^<Rel> Q"
using assms
by(auto simp add: simDef)

lemma simActBoundCases[consumes 1, case_names Input BoundOutput]:
  fixes P   :: pi
  and   a   :: subject
  and   x   :: name
  and   Q'  :: pi
  and   C   :: "'a::fs_name"
  and   Rel :: "(pi \<times> pi) set"

  assumes EqvtRel: "eqvt Rel"
  and     DerInput: "\<And>b. a = InputS b \<Longrightarrow> (\<exists>P''. \<forall>u. \<exists>P'. (P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>b<x> \<prec> P') \<and> (P', Q'[x::=u]) \<in> Rel)"
  and     DerBoundOutput: "\<And>b. a = BoundOutputS b \<Longrightarrow> (\<exists>P'. (P \<Longrightarrow>\<^isub>l\<^isup>^b<\<nu>x> \<prec> P') \<and> (P', Q') \<in> Rel)"

  shows "weakSimAct P (a\<guillemotleft>x\<guillemotright> \<prec> Q') P Rel"
proof(simp add: weakSimAct_def fresh_prod, auto)
  fix Q'' b y
  assume Eq: "a\<guillemotleft>x\<guillemotright> \<prec> Q' = b<\<nu>y> \<prec> Q''"
  assume yFreshP: "y \<sharp> P"

  from Eq have "a = BoundOutputS b" by(simp add: residual.inject)

  from yFreshP DerBoundOutput[OF this] Eq show "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^b<\<nu>y> \<prec> P' \<and> (P', Q'') \<in> Rel"
  proof(cases "x=y", auto simp add: residual.inject name_abs_eq)
    fix P'
    assume PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^b<\<nu>x> \<prec> P'"
    assume P'RelQ': "(P', ([(x, y)] \<bullet> Q'')) \<in> Rel"
    assume xineqy: "x \<noteq> y"

    with PTrans yFreshP have yFreshP': "y \<sharp> P'"
      by(force intro: freshTransition)

    hence "b<\<nu>x> \<prec> P' = b<\<nu>y> \<prec> [(x, y)] \<bullet> P'" by(rule alphaBoundResidual)
    moreover have "([(x, y)] \<bullet> P', Q'') \<in> Rel"
    proof -
      from EqvtRel P'RelQ' have "([(x, y)] \<bullet> P', [(x, y)] \<bullet> ([(x, y)] \<bullet> Q''))\<in> Rel"
	by(rule eqvtRelI)
      thus ?thesis by(simp add: name_calc)
    qed

    ultimately show "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^b<\<nu>y> \<prec> P' \<and> (P', Q'') \<in> Rel" using PTrans by auto
  qed
next
  fix Q'' b y u
  assume Eq: "a\<guillemotleft>x\<guillemotright> \<prec> Q' = b<y> \<prec> Q''"
  assume yFreshP: "y \<sharp> P"
  
  from Eq have "a = InputS b" by(simp add: residual.inject)
  from DerInput[OF this] obtain P'' where L1: "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>b<x> \<prec> P' \<and>
                                                        (P', Q'[x::=u]) \<in> Rel"
    by blast
  have "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in ([(x, y)] \<bullet> P'')\<rightarrow>b<y> \<prec> P' \<and> (P', Q''[y::=u]) \<in> Rel"
  proof(rule allI)
    fix u
    from L1 Eq show "\<exists>P'. P \<Longrightarrow>\<^isub>lu in ([(x, y)] \<bullet> P'')\<rightarrow>b<y> \<prec> P' \<and> (P', Q''[y::=u]) \<in> Rel"
    proof(cases "x=y", auto simp add: residual.inject name_abs_eq)
      assume Der: "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>b<x> \<prec> P' \<and> (P', ([(x, y)] \<bullet> Q'')[x::=u]) \<in> Rel"
      assume xFreshQ'': "x \<sharp> Q''"
      
      from Der obtain P' where PTrans: "P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>b<x> \<prec> P'"
                          and P'RelQ': "(P', ([(x, y)] \<bullet> Q'')[x::=u]) \<in> Rel"
	by force
      
      from PTrans yFreshP have "P \<Longrightarrow>\<^isub>lu in ([(x, y)] \<bullet> P'')\<rightarrow>b<y> \<prec> P'" by(rule alphaInput)
      moreover from xFreshQ'' P'RelQ' have "(P', Q''[y::=u]) \<in> Rel"
	by(simp add: renaming)
      ultimately show ?thesis by force
    qed
  qed
  thus  "\<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>b<y> \<prec> P' \<and> (P', Q''[y::=u]) \<in> Rel"
    by blast
qed

lemma simActFreeCases[consumes 0, case_names Der]:
  fixes P   :: pi
  and   \<alpha>   :: freeRes
  and   Q'  :: pi
  and   Rel :: "(pi \<times> pi) set"

  assumes "\<exists>P'. (P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P') \<and> (P', Q') \<in> Rel"

  shows "weakSimAct P (\<alpha> \<prec> Q') P Rel"
using assms
by(simp add: residual.inject weakSimAct_def fresh_prod)

lemma simE:
  fixes P   :: pi
  and   Rel :: "(pi \<times> pi) set"
  and   Q   :: pi
  and   a   :: name
  and   x   :: name
  and   u   :: name
  and   Q'  :: pi

  assumes "P \<leadsto>\<^isup>^<Rel> Q"

  shows "Q \<longmapsto>a<\<nu>x> \<prec> Q' \<Longrightarrow> x \<sharp> P \<Longrightarrow> \<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel"
  and   "Q \<longmapsto>a<x> \<prec> Q' \<Longrightarrow> x \<sharp> P \<Longrightarrow> \<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel"
  and   "Q \<longmapsto>\<alpha> \<prec> Q' \<Longrightarrow> (\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P' \<and> (P', Q') \<in> Rel)"
using assms by(simp add: simDef)+

lemma weakSimTauChain:
  fixes P   :: pi
  and   Rel :: "(pi \<times> pi) set"
  and   Q   :: pi
  and   Q'  :: pi

  assumes QChain: "Q \<Longrightarrow>\<^isub>\<tau> Q'"
  and     PRelQ: "(P, Q) \<in> Rel"
  and     Sim: "\<And>P Q. (P, Q) \<in> Rel \<Longrightarrow> P \<leadsto>\<^isup>^<Rel> Q"

  shows "\<exists>P'. P \<Longrightarrow>\<^isub>\<tau> P' \<and> (P', Q') \<in> Rel"
proof -
  from QChain show ?thesis
  proof(induct rule: tauChainInduct)
    case id
    have "P \<Longrightarrow>\<^isub>\<tau> P" by simp
    with PRelQ show ?case by blast
  next
    case(ih Q' Q'')
    have IH: "\<exists>P'. P \<Longrightarrow>\<^isub>\<tau> P' \<and> (P', Q') \<in> Rel" by fact
    then obtain P' where PChain: "P \<Longrightarrow>\<^isub>\<tau> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast
    from P'RelQ' have "P' \<leadsto>\<^isup>^<Rel> Q'" by(rule Sim)
    moreover have Q'Trans: "Q' \<longmapsto>\<tau> \<prec> Q''" by fact
    ultimately have "\<exists>P''. P' \<Longrightarrow>\<^isub>l\<^isup>^\<tau> \<prec> P'' \<and> (P'', Q'') \<in> Rel" by(rule simE)
    then obtain P'' where P'Trans: "P' \<Longrightarrow>\<^isub>l\<^isup>^\<tau> \<prec> P''" and P''RelQ'': "(P'', Q'') \<in> Rel" by blast
    from P'Trans have "P' \<Longrightarrow>\<^isub>\<tau> P''" by(rule tauTransitionChain)
    with PChain have "P \<Longrightarrow>\<^isub>\<tau> P''" by auto
    with P''RelQ'' show ?case by blast
  qed
qed

lemma simE2:
  fixes P   :: pi
  and   Rel :: "(pi \<times> pi) set"
  and   Q   :: pi
  and   a   :: name
  and   x   :: name
  and   Q'  :: pi

  assumes PSimQ: "P \<leadsto>\<^isup>^<Rel> Q"
  and     Sim: "\<And>P Q. (P, Q) \<in> Rel \<Longrightarrow> P \<leadsto>\<^isup>^<Rel> Q"
  and     Eqvt: "eqvt Rel"
  and     PRelQ: "(P, Q) \<in> Rel"

  shows "Q \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> Q' \<Longrightarrow> x \<sharp> P \<Longrightarrow> \<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel"
  and   "Q \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> Q' \<Longrightarrow> \<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P' \<and> (P', Q') \<in> Rel"
proof -
  assume QTrans: "Q \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> Q'"
  assume xFreshP: "x \<sharp> P"
  have Goal: "\<And>P Q a x Q'. \<lbrakk>P \<leadsto>\<^isup>^<Rel> Q; Q \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> Q'; x \<sharp> P; x \<sharp> Q; (P, Q) \<in> Rel\<rbrakk> \<Longrightarrow>
                            \<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel"
  proof -
    fix P Q a x Q'
    assume PSimQ: "P \<leadsto>\<^isup>^<Rel> Q"
    assume QTrans: "Q \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> Q'"
    assume xFreshP: "x \<sharp> P"
    assume xFreshQ: "x \<sharp> Q"
    assume PRelQ: "(P, Q) \<in> Rel"

    from QTrans xFreshQ obtain Q'' Q''' where QChain: "Q \<Longrightarrow>\<^isub>\<tau> Q''"
                                          and Q''Trans: "Q'' \<longmapsto>a<\<nu>x> \<prec> Q'''"
                                          and Q'''Chain: "Q''' \<Longrightarrow>\<^isub>\<tau> Q'"
      by(force dest: Weak_Late_Step_Semantics.transitionE simp add: weakTransition_def)

    from QChain PRelQ Sim have "\<exists>P''. P \<Longrightarrow>\<^isub>\<tau> P'' \<and> (P'', Q'') \<in> Rel"
      by(rule weakSimTauChain)
    then obtain P'' where PChain: "P \<Longrightarrow>\<^isub>\<tau> P''" and P''RelQ'': "(P'', Q'') \<in> Rel" by blast
    from PChain xFreshP have xFreshP'': "x \<sharp> P''" by(rule freshChain)

    from P''RelQ'' have "P'' \<leadsto>\<^isup>^<Rel> Q''" by(rule Sim)
    hence "\<exists>P'''. P'' \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P''' \<and> (P''', Q''') \<in> Rel" using Q''Trans xFreshP''
      by(rule simE)
    then obtain P''' where P''Trans: "P'' \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P'''" and P'''RelQ''': "(P''', Q''') \<in> Rel"
      by blast

    from P'''RelQ''' have "P''' \<leadsto>\<^isup>^<Rel> Q'''" by(rule Sim)
    have "\<exists>P'. P''' \<Longrightarrow>\<^isub>\<tau> P' \<and> (P', Q') \<in> Rel" using Q'''Chain P'''RelQ''' Sim
      by(rule weakSimTauChain)
    then obtain P' where P'''Chain: "P''' \<Longrightarrow>\<^isub>\<tau> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast

    from PChain P''Trans P'''Chain xFreshP'' have "P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P'"
      by(blast dest: chainTransitionAppend)
    with P'RelQ' show "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel" by blast
  qed

  have "\<exists>c::name. c \<sharp> (Q, Q', P, x)" by(blast intro: name_exists_fresh)
  then obtain c::name where cFreshQ: "c \<sharp> Q" and cFreshQ': "c \<sharp> Q'" and cFreshP: "c \<sharp> P"
                        and xineqc: "x \<noteq> c"
    by(force simp add: fresh_prod)

  from QTrans cFreshQ' have "Q \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>c> \<prec> ([(x, c)] \<bullet> Q')" by(simp add: alphaBoundResidual)
  with PSimQ have "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>c> \<prec> P' \<and> (P', [(x, c)] \<bullet> Q') \<in> Rel" using cFreshP cFreshQ `(P, Q) \<in> Rel`
    by(rule Goal)
  then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>c> \<prec> P'" and P'RelQ': "(P', [(x, c)] \<bullet> Q') \<in> Rel"
    by force
  have "P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> ([(x, c)] \<bullet> P')"
  proof -
    from PTrans xFreshP xineqc have "x \<sharp> P'" by(rule freshTransition)
    with PTrans show ?thesis by(simp add: alphaBoundResidual name_swap)
  qed
  moreover have "([(x, c)] \<bullet> P', Q') \<in> Rel"
  proof -
    from Eqvt P'RelQ' have "([(x, c)] \<bullet> P', [(x, c)] \<bullet> [(x, c)] \<bullet> Q') \<in> Rel"
      by(rule eqvtRelI)
    thus ?thesis by simp
  qed

  ultimately show "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel" by blast
next
  assume QTrans: "Q \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> Q'"
  thus "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P' \<and> (P', Q') \<in> Rel"
  proof(induct rule: transitionCases)
    case Step
    have "Q \<Longrightarrow>\<^isub>l\<alpha> \<prec> Q'" by fact
    then obtain Q'' Q''' where QChain: "Q \<Longrightarrow>\<^isub>\<tau> Q''" 
                           and Q''Trans: "Q'' \<longmapsto>\<alpha> \<prec> Q'''"
                           and Q'''Chain: "Q''' \<Longrightarrow>\<^isub>\<tau> Q'"	
      by(blast dest: Weak_Late_Step_Semantics.transitionE)
    
    from QChain PRelQ Sim have "\<exists>P''. P \<Longrightarrow>\<^isub>\<tau> P'' \<and> (P'', Q'') \<in> Rel"
      by(rule weakSimTauChain)
    then obtain P'' where PChain: "P \<Longrightarrow>\<^isub>\<tau> P''" and P''RelQ'': "(P'', Q'') \<in> Rel" by blast
    from P''RelQ'' have "P'' \<leadsto>\<^isup>^<Rel> Q''" by(rule Sim)
    hence "\<exists>P'''. P'' \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P''' \<and> (P''', Q''') \<in> Rel" using Q''Trans
      by(rule simE)
    then obtain P''' where P''Trans: "P'' \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P'''" and P'''RelQ''': "(P''', Q''') \<in> Rel"
      by blast
    
    from P'''RelQ''' have "P''' \<leadsto>\<^isup>^<Rel> Q'''" by(rule Sim)
    have "\<exists>P'. P''' \<Longrightarrow>\<^isub>\<tau> P' \<and> (P', Q') \<in> Rel" using Q'''Chain P'''RelQ''' Sim
      by(rule weakSimTauChain)
    then obtain P' where P'''Chain: "P''' \<Longrightarrow>\<^isub>\<tau> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast
    
    from PChain P''Trans P'''Chain have "P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P'"
      by(blast dest: chainTransitionAppend)
    with P'RelQ' show ?case by blast
  next
    case Stay
    have "\<alpha> \<prec> Q' = \<tau> \<prec> Q" by fact
    hence "Q = Q'" and "\<alpha> = \<tau>" by(simp add: residual.inject)+
    moreover have "P \<Longrightarrow>\<^isub>l\<^isup>^\<tau> \<prec> P" by(simp add: weakTransition_def)
    ultimately show ?case using PRelQ by blast
  qed
qed
(*
lemma tauChainStep:
  fixes P  :: pi
  and   P' :: pi
  
  assumes PChain: "P \<Longrightarrow>\<^isub>\<tau> P'"
  and     PineqP': "P \<noteq> P'"

  shows "\<exists>P''. P \<longmapsto>\<tau> \<prec> P'' \<and> P'' \<Longrightarrow>\<^isub>\<tau> P'"
proof -
  from PChain have "(P, P') \<in> Id \<union> (tauActs O tauActs\<^sup>* )"
    by(insert rtrancl_unfold, blast)
  with PineqP' have "(P, P') \<in> tauActs O tauActs\<^sup>*" by simp
  hence "(P, P') \<in> tauActs\<^sup>* O tauActs" by(simp add: r_comp_rtrancl_eq)
  thus ?thesis
    by(auto simp add: tauActs_def tauChain_def)
qed
*)
lemma eqvtI:
  fixes P    :: pi
  and   Q    :: pi
  and   Rel  :: "(pi \<times> pi) set"
  and   perm :: "name prm"

  assumes Sim: "P \<leadsto>\<^isup>^<Rel> Q"
  and     RelRel': "Rel \<subseteq> Rel'"
  and     EqvtRel': "eqvt Rel'"

  shows "(perm \<bullet> P) \<leadsto>\<^isup>^<Rel'> (perm \<bullet> Q)"
proof -
  from EqvtRel' show ?thesis
  proof(induct rule: simCasesCont[of _ "(perm \<bullet> P)"])
    case(Bound Q' a x)
    have Trans: "(perm \<bullet> Q) \<longmapsto> a<\<nu>x> \<prec> Q'" and xFreshP: "x \<sharp> perm \<bullet> P" by fact+

    from Trans have "(rev perm \<bullet> (perm \<bullet> Q)) \<longmapsto> rev perm \<bullet> (a<\<nu>x> \<prec> Q')"
      by(rule eqvts)
    hence "Q \<longmapsto> (rev perm \<bullet> a)<\<nu>(rev perm \<bullet> x)> \<prec> (rev perm \<bullet> Q')" 
      by(simp add: name_rev_per)
    moreover from xFreshP have "(rev perm \<bullet> x) \<sharp> P" by(simp add: name_fresh_left)
    ultimately have "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ (rev perm \<bullet> a)<\<nu>(rev perm \<bullet> x)> \<prec> P' \<and> (P', rev perm \<bullet> Q') \<in> Rel" using Sim
      by(force intro: simE)
    then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^ (rev perm \<bullet> a)<\<nu>(rev perm \<bullet> x)> \<prec> P'" and P'RelQ': "(P', rev perm \<bullet> Q') \<in> Rel" by blast

    from PTrans have "(perm \<bullet> P) \<Longrightarrow>\<^isub>l\<^isup>^ perm \<bullet> ((rev perm \<bullet> a)<\<nu>(rev perm \<bullet> x)> \<prec> P')"
      by(rule Weak_Late_Semantics.eqvtI)
    hence L1: "(perm \<bullet> P) \<Longrightarrow>\<^isub>l\<^isup>^ a<\<nu>x> \<prec> (perm \<bullet> P')" by(simp add: name_per_rev)
    from P'RelQ' RelRel' have "(P', rev perm \<bullet> Q') \<in> Rel'" by blast
    with EqvtRel' have "(perm \<bullet> P', perm \<bullet> (rev perm \<bullet> Q')) \<in> Rel'"
      by(rule eqvtRelI)
    hence "(perm \<bullet> P', Q') \<in> Rel'" by(simp add: name_per_rev)
    with L1 show ?case by blast
  next
    case(Input Q' a x)
    have Trans: "(perm \<bullet> Q) \<longmapsto>a<x> \<prec> Q'" and xFreshP: "x \<sharp> perm \<bullet> P" by fact+

    from Trans have "(rev perm \<bullet> (perm \<bullet> Q)) \<longmapsto> rev perm \<bullet> (a<x> \<prec> Q')"
      by(rule eqvts)
    hence "Q \<longmapsto> (rev perm \<bullet> a)<(rev perm \<bullet> x)> \<prec> (rev perm \<bullet> Q')" 
      by(simp add: name_rev_per)
    moreover from xFreshP have xFreshP: "(rev perm \<bullet> x) \<sharp> P" by(simp add: name_fresh_left)
    ultimately have "\<exists>P''. \<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>(rev perm \<bullet> a)<(rev perm \<bullet> x)> \<prec> P' \<and> (P', (rev perm \<bullet> Q')[(rev perm \<bullet> x)::=u]) \<in> Rel" using Sim
      by(force intro: simE)
    then obtain P'' where L1:  "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>(rev perm \<bullet> a)<(rev perm \<bullet> x)> \<prec> P' \<and> (P', (rev perm \<bullet> Q')[(rev perm \<bullet> x)::=u]) \<in> Rel"
      by blast
    have "\<forall>u. \<exists>P'. (perm \<bullet> P) \<Longrightarrow>\<^isub>lu in (perm \<bullet> P'')\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel'"
    proof(rule allI)
      fix u
      from L1 obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l(rev perm \<bullet> u) in P''\<rightarrow>(rev perm \<bullet> a)<(rev perm \<bullet> x)> \<prec> P'"
                          and P'RelQ': "(P', (rev perm \<bullet> Q')[(rev perm \<bullet> x)::=(rev perm \<bullet> u)]) \<in> Rel" by blast      
      from PTrans have "(perm \<bullet> P) \<Longrightarrow>\<^isub>l(perm \<bullet> (rev perm \<bullet> u)) in (perm \<bullet> P'')\<rightarrow>(perm \<bullet> rev perm \<bullet> a)<(perm \<bullet> rev perm \<bullet> x)> \<prec> (perm \<bullet> P')"
	by(rule_tac Weak_Late_Step_Semantics.eqvtI, auto)
      hence L2: "(perm \<bullet> P) \<Longrightarrow>\<^isub>lu in (perm \<bullet> P'')\<rightarrow>a<x> \<prec> (perm \<bullet> P')" by(simp add: name_per_rev)
      from P'RelQ' RelRel' have "(P', (rev perm \<bullet> Q')[(rev perm \<bullet> x)::=(rev perm \<bullet> u)]) \<in> Rel'" by blast
      with EqvtRel' have "(perm \<bullet> P', perm \<bullet> ((rev perm \<bullet> Q')[(rev perm \<bullet> x)::=(rev perm \<bullet> u)])) \<in> Rel'"
	by(rule eqvtRelI)
      hence "(perm \<bullet> P', Q'[x::=u]) \<in> Rel'" by(simp add: name_per_rev eqvt_subs[THEN sym] name_calc)
      with L2 show "\<exists>P'. (perm \<bullet> P) \<Longrightarrow>\<^isub>lu in (perm \<bullet> P'')\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel'" by blast
    qed

    thus ?case by blast
  next
    case(Free Q' \<alpha>)
    have Trans: "(perm \<bullet> Q) \<longmapsto> \<alpha> \<prec> Q'" by fact

    from Trans have "(rev perm \<bullet> (perm \<bullet> Q)) \<longmapsto> rev perm \<bullet> (\<alpha> \<prec> Q')"
      by(rule eqvts)
    hence "Q \<longmapsto> (rev perm \<bullet> \<alpha>) \<prec> (rev perm \<bullet> Q')" 
      by(simp add: name_rev_per)
    with Sim have "(\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ (rev perm \<bullet> \<alpha>) \<prec> P' \<and> (P', (rev perm \<bullet> Q')) \<in> Rel)"
      by(rule simE)
    then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^ (rev perm \<bullet> \<alpha>) \<prec> P'" and PRel: "(P', (rev perm \<bullet> Q')) \<in> Rel" by blast
    from PTrans have "(perm \<bullet> P) \<Longrightarrow>\<^isub>l\<^isup>^ perm \<bullet> ((rev perm \<bullet> \<alpha>)\<prec> P')"
      by(rule Weak_Late_Semantics.eqvtI)
    hence L1: "(perm \<bullet> P) \<Longrightarrow>\<^isub>l\<^isup>^ \<alpha> \<prec> (perm \<bullet> P')" by(simp add: name_per_rev)
    from PRel EqvtRel' RelRel'  have "((perm \<bullet> P'), (perm \<bullet> (rev perm \<bullet> Q'))) \<in> Rel'"
      by(force intro: eqvtRelI)
    hence "((perm \<bullet> P'), Q') \<in> Rel'" by(simp add: name_per_rev)
    with L1 show ?case by blast
  qed 
qed

(*****************Reflexivity and transitivity*********************)

lemma reflexive:
  fixes P   :: pi
  and   Rel :: "(pi \<times> pi) set"

  assumes "Id \<subseteq> Rel"

  shows "P \<leadsto>\<^isup>^<Rel> P"
using assms
by(auto intro: Weak_Late_Step_Semantics.singleActionChain
  simp add: simDef weakTransition_def)

lemma transitive:
  fixes P     :: pi
  and   Q     :: pi
  and   R     :: pi
  and   Rel   :: "(pi \<times> pi) set"
  and   Rel'  :: "(pi \<times> pi) set"
  and   Rel'' :: "(pi \<times> pi) set"

  assumes QSimR: "Q \<leadsto>\<^isup>^<Rel'> R"
  and     Eqvt:  "eqvt Rel"
  and     Eqvt': "eqvt Rel''"
  and     Trans: "Rel O Rel' \<subseteq> Rel''"
  and     Sim:   "\<And>P Q. (P, Q) \<in> Rel \<Longrightarrow> P \<leadsto>\<^isup>^<Rel> Q"
  and     PRelQ: "(P, Q) \<in> Rel"

  shows "P \<leadsto>\<^isup>^<Rel''> R"
proof -
  from PRelQ have PSimQ: "P \<leadsto>\<^isup>^<Rel> Q" by(rule Sim)
  from Eqvt' show ?thesis
  proof(induct rule: simCasesCont[of _ "(P, Q)"])
    case(Bound R' a x)
    have RTrans: "R \<longmapsto> a<\<nu>x> \<prec> R'" by fact
    have "x \<sharp> (P, Q)" by fact
    hence xFreshP: "x \<sharp> P" and xFreshQ: "x \<sharp> Q" by(simp add: fresh_prod)+

    from QSimR RTrans xFreshQ have "\<exists>Q'. Q \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> Q' \<and> (Q', R') \<in> Rel'"
      by(rule simE)
    then obtain Q' where QTrans: "Q \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> Q'" and Q'RelR': "(Q', R') \<in> Rel'" by blast
    from PSimQ Sim Eqvt PRelQ QTrans xFreshP have "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel"
      by(rule simE2)
    then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast
    moreover from P'RelQ' Q'RelR' Trans have "(P', R') \<in> Rel''" by blast
    ultimately show ?case by blast
  next
    case(Input R' a x)
    have RTrans: "R \<longmapsto> a<x> \<prec> R'" by fact
    have "x \<sharp> (P, Q)" by fact
    hence xFreshP: "x \<sharp> P" and xFreshQ: "x \<sharp> Q" by(simp add: fresh_prod)+

    from QSimR RTrans xFreshQ  obtain Q'' where "\<forall>u. \<exists>Q'. Q \<Longrightarrow>\<^isub>lu in Q''\<rightarrow>a<x> \<prec> Q' \<and> (Q', R'[x::=u]) \<in> Rel'" 
      by(blast dest: simE)
    hence "\<exists>Q'''. Q \<Longrightarrow>\<^isub>\<tau> Q''' \<and> Q'''\<longmapsto>a<x> \<prec> Q'' \<and> (\<forall>u. \<exists>Q'. Q''[x::=u]\<Longrightarrow>\<^isub>\<tau> Q' \<and> (Q', R'[x::=u]) \<in> Rel')"
      by(simp add: inputTransition_def, blast)
    then obtain Q''' where QChain: "Q \<Longrightarrow>\<^isub>\<tau> Q'''"
                       and Q'''Trans: "Q''' \<longmapsto>a<x> \<prec> Q''"
                       and L1: "\<forall>u. \<exists>Q'. Q''[x::=u]\<Longrightarrow>\<^isub>\<tau> Q' \<and> (Q', R'[x::=u]) \<in> Rel'"
      by blast
    from QChain PRelQ Sim have "\<exists>P'''. P \<Longrightarrow>\<^isub>\<tau> P''' \<and> (P''', Q''') \<in> Rel"
      by(rule weakSimTauChain)
    then obtain P''' where PChain: "P \<Longrightarrow>\<^isub>\<tau> P'''" and P'''RelQ''': "(P''', Q''') \<in> Rel" by blast
    from PChain xFreshP have xFreshP''': "x \<sharp> P'''" by(rule freshChain)
    from P'''RelQ''' have "P''' \<leadsto>\<^isup>^<Rel> Q'''" by(rule Sim)
    hence "\<exists>P''''. \<forall>u. \<exists>P''. P''' \<Longrightarrow>\<^isub>lu in P''''\<rightarrow>a<x> \<prec> P'' \<and> (P'', Q''[x::=u]) \<in> Rel" using Q'''Trans xFreshP'''
      by(rule simE)
    then obtain P'''' where L2: "\<forall>u. \<exists>P''. P''' \<Longrightarrow>\<^isub>lu in P''''\<rightarrow>a<x> \<prec> P'' \<and> (P'', Q''[x::=u]) \<in> Rel" 
      by blast
    have "\<forall>u. \<exists>P' Q'. P \<Longrightarrow>\<^isub>lu in P''''\<rightarrow>a<x> \<prec> P' \<and> (P', R'[x::=u]) \<in> Rel''"
    proof(rule allI)
      fix u
      from L1 obtain Q' where Q''Chain: "Q''[x::=u] \<Longrightarrow>\<^isub>\<tau> Q'" and Q'RelR': "(Q', R'[x::=u]) \<in> Rel'"
	by blast
      from L2 obtain P'' where P'''Trans: "P''' \<Longrightarrow>\<^isub>lu in P''''\<rightarrow>a<x> \<prec> P''"
                           and P''RelQ'': "(P'', Q''[x::=u]) \<in> Rel"
	by blast
      from P''RelQ'' have "P'' \<leadsto>\<^isup>^<Rel> Q''[x::=u]" by(rule Sim)
      have "\<exists>P'. P'' \<Longrightarrow>\<^isub>\<tau> P' \<and> (P', Q') \<in> Rel" using Q''Chain P''RelQ'' Sim
	by(rule weakSimTauChain)
      then obtain P' where P''Chain: "P'' \<Longrightarrow>\<^isub>\<tau> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast
      from PChain P'''Trans P''Chain  have "P \<Longrightarrow>\<^isub>lu in P''''\<rightarrow>a<x> \<prec> P'"
	by(blast dest: Weak_Late_Step_Semantics.chainTransitionAppend)
      moreover from P'RelQ' Q'RelR' have "(P', R'[x::=u]) \<in> Rel''" by(insert Trans, auto)
      ultimately show "\<exists>P' Q'. P \<Longrightarrow>\<^isub>lu in P''''\<rightarrow>a<x> \<prec> P' \<and> (P', R'[x::=u]) \<in> Rel''" by blast
    qed
    thus ?case by force
  next
    case(Free R' \<alpha>)
    have RTrans: "R \<longmapsto> \<alpha> \<prec> R'" by fact
    with QSimR have "\<exists>Q'. Q \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> Q' \<and> (Q', R') \<in> Rel'" by(rule simE)
    then obtain Q' where QTrans: "Q \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> Q'" and Q'RelR': "(Q', R') \<in> Rel'" by blast
    from PSimQ Sim Eqvt PRelQ QTrans have "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P' \<and> (P', Q') \<in> Rel" by(rule simE2)
    then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast
    from P'RelQ' Q'RelR' Trans have "(P', R') \<in> Rel''" by blast
    with PTrans show "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P' \<and> (P', R') \<in> Rel''" by blast
  qed
qed

lemma strongSimWeakSim:
  fixes P   :: pi
  and   Q   :: pi
  and   Rel :: "(pi \<times> pi) set"

  assumes PSimQ: "P \<leadsto>[Rel] Q"

  shows "P \<leadsto>\<^isup>^<Rel> Q"
proof(induct rule: simCases)
  case(Bound Q' a x)
  have "Q \<longmapsto>a<\<nu>x> \<prec> Q'" and "x \<sharp> P" by fact+
  with PSimQ obtain P' where PTrans: "P \<longmapsto>a<\<nu>x> \<prec> P'" and P'RelQ': "(P', Q') \<in> Rel"
    by(force dest: Strong_Late_Sim.simE simp add: derivative_def)

  from PTrans have "P \<Longrightarrow>\<^isub>l\<^isup>^a<\<nu>x> \<prec> P'"
    by(force intro: Weak_Late_Step_Semantics.singleActionChain simp add: weakTransition_def)
  with P'RelQ' show ?case by blast
next
  case(Input Q' a x)
  assume "Q \<longmapsto>a<x> \<prec> Q'" and "x \<sharp> P"
  with PSimQ obtain P' where PTrans: "P \<longmapsto>a<x> \<prec> P'" and PDer: "derivative P' Q' (InputS a) x Rel"
    by(blast dest: Strong_Late_Sim.simE)

  have "\<forall>u. \<exists>P''. P \<Longrightarrow>\<^isub>lu in P'\<rightarrow>a<x> \<prec> P'' \<and> (P'', Q'[x::=u]) \<in> Rel"
  proof(rule allI)
    fix u
    from PTrans have "P \<Longrightarrow>\<^isub>lu in P'\<rightarrow>a<x> \<prec> P'[x::=u]" by(blast intro: Weak_Late_Step_Semantics.singleActionChain)
    moreover from PDer have "(P'[x::=u], Q'[x::=u]) \<in> Rel" by(force simp add: derivative_def)
    ultimately show "\<exists>P''. P \<Longrightarrow>\<^isub>lu in P'\<rightarrow>a<x> \<prec> P'' \<and> (P'', Q'[x::=u]) \<in> Rel" by auto
  qed
  thus ?case by blast
next
  case(Free Q' \<alpha>)
  have "Q \<longmapsto>\<alpha> \<prec> Q'" by fact
  with PSimQ obtain P' where PTrans: "P \<longmapsto>\<alpha> \<prec> P'" and P'RelQ': "(P', Q') \<in> Rel"
    by(blast dest: Strong_Late_Sim.simE)
  from PTrans have "P \<Longrightarrow>\<^isub>l\<^isup>^\<alpha> \<prec> P'" by(rule Weak_Late_Semantics.singleActionChain)
  with P'RelQ' show ?case by blast
qed

lemma strongAppend:
  fixes P     :: pi
  and   Q     :: pi
  and   R     :: pi
  and   Rel   :: "(pi \<times> pi) set"
  and   Rel'  :: "(pi \<times> pi) set"
  and   Rel'' :: "(pi \<times> pi) set"

  assumes PSimQ: "P \<leadsto>\<^isup>^<Rel> Q"
  and     QSimR: "Q \<leadsto>[Rel'] R"
  and     Eqvt'': "eqvt Rel''"
  and     Trans: "Rel O Rel' \<subseteq> Rel''"

  shows "P \<leadsto>\<^isup>^<Rel''> R"
proof -
  from Eqvt'' show ?thesis
  proof(induct rule: simCasesCont[of _ "(P, Q)"])
    case(Bound R' a x)
    have "x \<sharp> (P, Q)" by fact
    hence xFreshP: "x \<sharp> P" and xFreshQ: "x \<sharp> Q" by(simp add: fresh_prod)+
    have RTrans: "R \<longmapsto>a<\<nu>x> \<prec> R'" by fact
    from xFreshQ QSimR RTrans obtain Q' where QTrans: "Q \<longmapsto>a<\<nu>x> \<prec> Q'"
                                          and Q'Rel'R': "(Q', R') \<in> Rel'"
      by(force dest: Strong_Late_Sim.simE simp add: derivative_def)

    with PSimQ QTrans xFreshP have "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ a<\<nu>x> \<prec> P' \<and> (P', Q') \<in> Rel"
      by(blast intro: simE)
    then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^ a<\<nu>x> \<prec> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast
    moreover from P'RelQ' Q'Rel'R' Trans have "(P', R') \<in> Rel''" by blast
    ultimately show ?case by blast
  next
    case(Input R' a x)
    have RTrans: "R \<longmapsto> a<x> \<prec> R'" by fact
    have "x \<sharp> (P, Q)" by fact
    hence xFreshP: "x \<sharp> P" and xFreshQ: "x \<sharp> Q" by(simp add: fresh_prod)+

    from QSimR RTrans xFreshQ  obtain Q' where QTrans: "Q \<longmapsto>a<x> \<prec> Q'" and Q'Der: "derivative Q' R' (InputS a) x Rel'"
      by(blast dest: Strong_Late_Sim.simE)
    from QTrans PSimQ xFreshP obtain P'' where L2: "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', Q'[x::=u]) \<in> Rel" 
      by(blast dest: simE)
    have "\<forall>u. \<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', R'[x::=u]) \<in> Rel''"
    proof(rule allI)
      fix u
      from L2 obtain P' where PTrans: "P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P'"
                          and P'RelQ': "(P', Q'[x::=u]) \<in> Rel"
	by blast
      moreover from Q'Der have "(Q'[x::=u], R'[x::=u]) \<in> Rel'" by(simp add: derivative_def)
      ultimately show "\<exists>P'. P \<Longrightarrow>\<^isub>lu in P''\<rightarrow>a<x> \<prec> P' \<and> (P', R'[x::=u]) \<in> Rel''" using Trans by blast
    qed
    thus ?case by force
  next
    case(Free R' \<alpha>)
    have RTrans: "R \<longmapsto> \<alpha> \<prec> R'" by fact
    with QSimR obtain Q' where QTrans: "Q \<longmapsto>\<alpha> \<prec> Q'" and Q'RelR': "(Q', R') \<in> Rel'"
      by(blast dest: Strong_Late_Sim.simE)
    from PSimQ QTrans have "\<exists>P'. P \<Longrightarrow>\<^isub>l\<^isup>^ \<alpha> \<prec> P' \<and> (P', Q') \<in> Rel"
      by(blast intro: simE)
    then obtain P' where PTrans: "P \<Longrightarrow>\<^isub>l\<^isup>^ \<alpha> \<prec> P'" and P'RelQ': "(P', Q') \<in> Rel" by blast
    from P'RelQ' Q'RelR' Trans have "(P', R') \<in> Rel''" by blast
    with PTrans show ?case by blast
  qed
qed

end