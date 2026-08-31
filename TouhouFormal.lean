import TouhouFormal.Core.Evidence
import TouhouFormal.Core.Fault
import TouhouFormal.Core.Transition
import TouhouFormal.ECL
import TouhouFormal.Search
import TouhouFormal.TH06
import TouhouFormal.TH07
import TouhouFormal.TH08

/-!
Top-level module for the Touhou formal modeling workspace.

The library is intentionally split between a small generic transition-system
core and title-specific models. Title packages should model the original VM
behavior first, including known unsafe behavior, before adding search backends
or retail validation harnesses.
-/
