; Adapted from nvim-treesitter at
; 19071296d3d643b48615ee574a20e8a03ac40872 (Apache-2.0).
; Scopes end in ".snakemake".

; Compound directives
[
  "rule"
  "checkpoint"
  "module"
] @keyword.control.snakemake

; Top level directives (eg. configfile, include)
(module
  (directive
    name: _ @keyword.control.snakemake))

; Subordinate directives (eg. input, output)
body: (_
  (directive
    name: _ @entity.name.label.snakemake))

; rule/module/checkpoint names
(rule_definition
  name: (identifier) @entity.name.function.rule.snakemake)

(module_definition
  name: (identifier) @entity.name.type.module.snakemake)

(checkpoint_definition
  name: (identifier) @entity.name.function.checkpoint.snakemake)

; Rule imports
(rule_import
  [
    "use"
    "rule"
    "from"
    "exclude"
    "as"
    "with"
  ] @keyword.control.import.snakemake)

; Rule inheritance
(rule_inheritance
  "use" @keyword.control.snakemake
  "rule" @keyword.control.snakemake
  "with" @keyword.control.snakemake)

; Wildcard names
(wildcard
  (identifier) @variable.other.snakemake)

(wildcard
  (flag) @variable.parameter.language.snakemake)

; builtin variables
((identifier) @variable.language.snakemake
  (#any-of? @variable.language.snakemake "checkpoints" "config" "gather" "rules" "scatter" "workflow"))

; References to directive labels in wildcard interpolations
; the #any-of? queries are moved above the #has-ancestor? queries to
; short-circuit the potentially expensive tree traversal, if possible
; see:
; https://github.com/nvim-treesitter/nvim-treesitter/pull/4302#issuecomment-1685789790
; directive labels in wildcard context
((wildcard
  (identifier) @entity.name.label.snakemake)
  (#any-of? @entity.name.label.snakemake "input" "jobid" "log" "output" "params" "resources" "rule" "threads" "wildcards"))

((wildcard
  (attribute
    object: (identifier) @entity.name.label.snakemake))
  (#any-of? @entity.name.label.snakemake "input" "jobid" "log" "output" "params" "resources" "rule" "threads" "wildcards"))

((wildcard
  (subscript
    value: (identifier) @entity.name.label.snakemake))
  (#any-of? @entity.name.label.snakemake "input" "jobid" "log" "output" "params" "resources" "rule" "threads" "wildcards"))

; directive labels in block context (eg. within 'run:')
((identifier) @entity.name.label.snakemake
  (#any-of? @entity.name.label.snakemake "input" "jobid" "log" "output" "params" "resources" "rule" "threads" "wildcards")
  (#is? test.descendantOfType "directive")
  (#is? test.descendantOfType "block"))
