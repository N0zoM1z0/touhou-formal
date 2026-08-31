namespace TouhouFormal.Search.SMT

private def joinLines : List String -> String
  | [] => ""
  | line :: rest => line ++ "\n" ++ joinLines rest

def th06SubTableOobQuery : String :=
  joinLines
    [ "(set-logic QF_LIA)"
    , "; Seed query for TH06 timeline arg0 flowing into EclManager::CallEclSub."
    , "; Source relation: safe iff 0 <= subId && subId < subCount."
    , "(declare-const subCount Int)"
    , "(declare-const arg0 Int)"
    , "(assert (= subCount 1))"
    , "(assert (= arg0 256))"
    , "(assert (<= (- 32768) arg0))"
    , "(assert (<= arg0 32767))"
    , "(define-fun th06_call_safe () Bool (and (<= 0 arg0) (< arg0 subCount)))"
    , "(assert (not th06_call_safe))"
    , "(check-sat)"
    , "(get-model)" ]

def th06FindAnySubTableOobQuery : String :=
  joinLines
    [ "(set-logic QF_LIA)"
    , "; Find any i16 timeline arg0 that makes TH06 CallEclSub read outside subTable."
    , "(declare-const subCount Int)"
    , "(declare-const arg0 Int)"
    , "(assert (<= 1 subCount))"
    , "(assert (<= subCount 1024))"
    , "(assert (<= (- 32768) arg0))"
    , "(assert (<= arg0 32767))"
    , "(define-fun th06_call_safe () Bool (and (<= 0 arg0) (< arg0 subCount)))"
    , "(assert (not th06_call_safe))"
    , "(check-sat)"
    , "(get-model)" ]

end TouhouFormal.Search.SMT
