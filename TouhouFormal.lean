/-!
Top-level module for the Touhou formal modeling workspace.

The library is intentionally split between a small generic transition-system
core and title-specific models. Title packages should model the original VM
behavior first, including known unsafe behavior, before adding search backends
or retail validation harnesses.
-/
