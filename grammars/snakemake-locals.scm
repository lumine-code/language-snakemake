; Adapted from nvim-treesitter at
; 19071296d3d643b48615ee574a20e8a03ac40872 (Apache-2.0).

(rule_definition
  name: (identifier) @local.definition) @local.scope

(rule_inheritance alias: (as_pattern_target) @local.definition) @local.scope

(checkpoint_definition
  name: (identifier) @local.definition) @local.scope

(module_definition
  name: (identifier) @local.definition) @local.scope

; use rule A from X
(rule_import (rule_import_list (identifier) @local.definition) . module_name: (identifier) .) @local.scope

; use rule A from X as A_fromX
; use rule A from X as *_fromX
; use rule * from X as *_fromX
(rule_import alias: (as_pattern_target) @local.definition . ) @local.scope

; use rule A from X with:
(rule_import (rule_import_list (identifier) @local.definition) .  module_name: (identifier) . "with") @local.scope

; use rule A from X as Y with:
(rule_import alias: (as_pattern_target) @local.definition "with") @local.scope
