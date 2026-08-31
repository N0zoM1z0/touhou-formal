import Lake
open Lake DSL

package «touhou-formal» where
  version := v!"0.1.0"

lean_lib TouhouFormal where

@[default_target]
lean_exe check where
  root := `Main

lean_exe smt where
  root := `SmtMain

lean_exe symex where
  root := `SymexMain
