; Shared with the bundled Python grammar and retargeted to Snakemake scopes.

; TODO
; ====
;
; * numbers: hex, octal, binary, and log versions of each
; * long integers
; * complex numbers
; * how to scope import identifiers?


; CAVEATS
; =======
;
; * No support for highlighting replacement fields in `String.format` calls
;   because `tree-sitter-python` doesn't parse them at all. Would need a
;   special-purpose tree-sitter parser in an injection.
;
; * The TM grammar highlighted any strings that looked like SQL; this could
;   be supported via an injection.

; SUPPORT
; =======

((identifier) @support.type.exception.snakemake
  (#match? @support.type.exception.snakemake "^(BaseException|Exception|TypeError|StopAsyncIteration|StopIteration|ImportError|ModuleNotFoundError|OSError|ConnectionError|BrokenPipeError|ConnectionAbortedError|ConnectionRefusedError|ConnectionResetError|BlockingIOError|ChildProcessError|FileExistsError|FileNotFoundError|IsADirectoryError|NotADirectoryError|InterruptedError|PermissionError|ProcessLookupError|TimeoutError|EOFError|RuntimeError|RecursionError|NotImplementedError|NameError|UnboundLocalError|AttributeError|SyntaxError|IndentationError|TabError|LookupError|IndexError|KeyError|ValueError|UnicodeError|UnicodeEncodeError|UnicodeDecodeError|UnicodeTranslateError|AssertionError|ArithmeticError|FloatingPointError|OverflowError|ZeroDivisionError|SystemError|ReferenceError|BufferError|MemoryError|Warning|UserWarning|DeprecationWarning|PendingDeprecationWarning|SyntaxWarning|RuntimeWarning|FutureWarning|ImportWarning|UnicodeWarning|BytesWarning|ResourceWarning|GeneratorExit|SystemExit|KeyboardInterrupt)$")
  (#set! capture.final true))

; These methods have magic interpretation by python and are generally called
; indirectly through syntactic constructs.
(call
  function: [
    (identifier) @support.function.magic.snakemake
    (attribute
      attribute: (identifier) @support.function.magic.snakemake)
  ]
  (#match? @support.function.magic.snakemake "^__(abs|add|and|bool|bytes|call|cmp|coerce|complex|contains|del|delattr|delete|delitem|delslice|dir|div|divmod|enter|eq|exit|float|floordiv|format|ge|get|getattr|getattribute|getitem|getslice|gt|hash|hex|iadd|iand|idiv|ifloordiv|ilshift|imatmul|imod|imul|index|init|instancecheck|int|invert|ior|ipow|irshift|isub|iter|itruediv|ixor|le|len|length_hint|long|lshift|lt|matmul|missing|mod|mul|ne|neg|next|new|nonzero|oct|or|pos|pow|radd|rand|rdiv|rdivmod|repr|reversed|rfloordiv|rlshift|rmatmul|rmod|rmul|ror|round|rpow|rrshift|rshift|rsub|rtruediv|rxor|set|setattr|setitem|setslice|str|sub|subclasscheck|truediv|unicode|xor)__$")
  (#set! capture.final true))

; Magic variables which a class/module may have.
((identifier) @support.variable.magic.snakemake
  (#match? @support.variable.magic.snakemake "^__(all|annotations|bases|class|closure|code|debug|dict|doc|file|func|globals|kwdefaults|members|metaclass|methods|module|name|qualname|self|slots|weakref)__$"))

(call
  function: (identifier) @support.type.constructor.snakemake
  (#match? @support.type.constructor.snakemake "^[A-Z][A-Za-z_]+")
  (#set! capture.final true))

(call
  function: (attribute
    attribute: (identifier) @support.type.constructor.snakemake)
    (#match? @support.type.constructor.snakemake "^[A-Z][A-Za-z_]+")
    (#set! capture.final true))

(call
  function: (identifier) @support.function.builtin.snakemake
  (#match? @support.function.builtin.snakemake "^(__import__|abs|all|any|ascii|bin|bool|bytearray|bytes|callable|chr|classmethod|compile|complex|delattr|dict|dir|divmod|enumerate|eval|exec|filter|float|format|frozenset|getattr|globals|hasattr|hash|help|hex|id|input|int|isinstance|issubclass|iter|len|list|locals|map|max|memoryview|min|next|object|oct|open|ord|pow|print|property|range|repr|reversed|round|set|setattr|slice|sorted|staticmethod|str|sum|super|tuple|type|vars|zip|file|long|raw_input|reduce|reload|unichr|unicode|xrange|apply|buffer|coerce|intern|execfile)$")
  (#set! capture.final true))

; `NotImplemented` is a constant, but is not recognized as such by the parser.
((identifier) @constant.language.not-implemented.snakemake
  (#eq? @constant.language.not-implemented.snakemake "NotImplemented")
  (#set! capture.final true))

; `Ellipsis` is also a constant, and though there don't seem to be any use
; cases for using it directly instead of `...`, we should at least mark it as a
; constant because that's how it'll be interpreted by Python.
((identifier) @constant.language.ellipsis.snakemake
  (#eq? @constant.language.ellipsis.snakemake "Ellipsis")
  (#set! capture.final true))


; CONSTANTS
; =======

((identifier) @constant.other.snakemake
  (#match? @constant.other.snakemake "^[A-Z][A-Z_]*$")
  (#set? final true))

; ((identifier) @support.class.snakemake
;   (#match? @support.class.snakemake "^[A-Z]"))

; CLASSES
; =======

; The "class" and "Foo" in `class Foo():`
(class_definition
  "class" @storage.type.class.snakemake
  name: (identifier) @entity.name.type.class.snakemake)

; The "Bar" in `class Foo(Bar):`
(class_definition
  superclasses: (argument_list
    (identifier) @entity.other.inherited-class.snakemake))

; TYPES
; =====

(generic_type (identifier) @support.storage.type.generic.snakemake)
(type (identifier) @support.storage.type.snakemake)

; FUNCTIONS
; =========

(function_definition "def" @storage.type.function.snakemake)

; Lambdas
; -------

(lambda ":" @punctuation.definition.function.lambda.colon.snakemake)


; Function calls
; --------------

; An entire decorator without arguments, like `@foo`.
(decorator "@" (identifier) .) @support.other.function.decorator.snakemake

; A namespaced decorator, like the `@foo` in `@foo.bar`, with or without a
; function invocation.
((decorator [(attribute) (call)]) @support.other.function.decorator.snakemake
  (#set! adjust.endAfterFirstMatchOf "\\."))

; The "@" and "foo" together in a decorator with arguments, like `@foo(True)`.
((decorator "@" (call function: (identifier))) @support.other.function.decorator.snakemake
  (#set! adjust.endAt firstNamedChild.firstNamedChild.endPosition))

; Claim the "foo" in `@foo(True)` so it doesn't get scoped like an ordinary
; function call.
(decorator
  (call
    function: (identifier) @_IGNORE_
    (#set! capture.final true)))

(call
  function: (attribute
    attribute: (identifier) @support.other.function.snakemake)
    (#set! capture.final true))

(call
  function: (identifier) @support.other.function.snakemake)


; Function definitions
; --------------------

(function_definition
  name: (identifier) @entity.name.function.magic.snakemake
  (#match? @entity.name.function.magic.snakemake "^__(?:abs|add|and|bool|bytes|call|cmp|coerce|complex|contains|del|delattr|delete|delitem|delslice|dir|div|divmod|enter|eq|exit|float|floordiv|format|ge|get|getattr|getattribute|getitem|getslice|gt|hash|hex|iadd|iand|idiv|ifloordiv|ilshift|imatmul|imod|imul|index|init|instancecheck|int|invert|ior|ipow|irshift|isub|iter|itruediv|ixor|le|len|length_hint|long|lshift|lt|matmul|missing|mod|mul|ne|neg|next|new|nonzero|oct|or|pos|pow|radd|rand|rdiv|rdivmod|repr|reversed|rfloordiv|rlshift|rmatmul|rmod|rmul|ror|round|rpow|rrshift|rshift|rsub|rtruediv|rxor|set|setattr|setitem|setslice|str|sub|subclasscheck|truediv|unicode|xor)__$"))

(attribute
  attribute: (identifier) @support.other.property.snakemake)

(attribute
  attribute: (identifier) @constant.other.property.snakemake
    (#match? @constant.other.property.snakemake "^[A-Z][A-Z_]*$"))

(function_definition
  name: (identifier) @entity.name.function.snakemake)


; Type annotations
; ----------------

(function_definition
  (type) @support.storage.type.snakemake)

(typed_parameter
  (type) @support.storage.type.snakemake)

(typed_default_parameter
  (type) @support.storage.type.snakemake)


; COMMENTS
; ========

((comment) @comment.line.number-sign.snakemake
  (#set! adjust.endBeforeFirstMatchOf "\\r?$"))
((comment) @punctuation.definition.comment.snakemake
  (#set! adjust.endAfterFirstMatchOf "^#"))

; DICTIONARIES
; ============

((pair
  key: (identifier) @entity.other.attribute-name.snakemake)
  (#is? test.typeAt "parent.parent dictionary"))

; STRINGS
; =======

; Each kind of string (single-, double-, triple-quoted) can have certain
; prefixes. Luckily, there are limits to how these prefixes can be combined;
; format strings, for instance, are new in Python 3 and are implicitly Unicode,
; so there's no such thing as an `fu` string.
;
; All format strings can be optionally raw, so we need to treat `f` and `fr`
; similarly here. No need to account for the rawness of a string in the scope
; name unless someone requests that feature.

((string) @string.quoted.triple.block.format.snakemake
  (#match? @string.quoted.triple.block.format.snakemake "^[fFtTrR]+\"\"\"")
  (#set! capture.final))

((string) @string.quoted.triple.block.snakemake
  (#match? @string.quoted.triple.block.snakemake "^[bBrRuU]*\"\"\""))

((string) @string.quoted.double.single-line.format.snakemake
  (#match? @string.quoted.double.single-line.format.snakemake "^[fFtTrR]+\"")
  (#set! capture.final))

((string) @string.quoted.double.single-line.snakemake
  (#match? @string.quoted.double.single-line.snakemake "^[bBrRuU]*\"(?!\")"))

((string) @string.quoted.single.single-line.format.snakemake
  (#match? @string.quoted.single.single-line.format.snakemake "^[fFtTrR]+?\'")
  (#set! capture.final))

((string) @string.quoted.single.single-line.snakemake
  (#match? @string.quoted.single.single-line.snakemake "^[bBrRuU]*\'"))

((escape_sequence) @constant.character.escape.snakemake
  (#is? test.childOfType string_content))

(interpolation
  "{" @punctuation.section.embedded.begin.snakemake
  "}" @punctuation.section.embedded.end.snakemake) @meta.embedded.line.interpolation.snakemake

(string_start) @punctuation.definition.string.begin.snakemake

(string_end) @punctuation.definition.string.end.snakemake

((string_start) @storage.type.string.snakemake
  (#match? @storage.type.string.snakemake "^[bBfFtTrRuU]+")
  (#set! adjust.endAfterFirstMatchOf "^[bBfFtTrRuU]+"))


; CONSTANTS
; =========

[(none) (true) (false)] @constant.builtin._TYPE_.snakemake


; NUMBERS
; =======

(integer) @constant.numeric.integer.snakemake
(float) @constant.numeric.float.snakemake


; KEYWORDS
; ========

[
  "if"
  "elif"
  "else"
] @keyword.control.conditional._TYPE_.snakemake

[
  "async"
  "await"
  "pass"
  "return"
  "with"
] @keyword.control.statement._TYPE_.snakemake

[
  "break"
  "continue"
  "for"
  "while"
  "yield"
] @keyword.control.repeat._TYPE_.snakemake

"import" @keyword.control.import.snakemake
"from" @keyword.control.import.from.snakemake

[
  "except"
  "finally"
  "try"
] @keyword.control.exception._TYPE_.snakemake

(except_clause "*" @keyword.control.exception.group-clause.snakemake)

[
  "global"
  "nonlocal"
] @keyword.control.scope._TYPE_.snakemake

[
  "as"
  "assert"
  "case"
  "del"
  "lambda"
  "match"
] @keyword.control._TYPE_.snakemake

[
  "raise"
] @keyword.control._TYPE_.snakemake


; VARIABLES
; =========

((identifier) @variable.parameter.function.snakemake
  (#is? test.childOfType parameters))

(default_parameter
  name: (identifier) @variable.parameter.function.snakemake
  (#is? test.typeAt "parent.parent parameters"))

(list_splat_pattern
  (identifier) @variable.parameter.function.snakemake
  (#is? test.typeAt "parent.parent parameters"))

(dictionary_splat_pattern
  (identifier) @variable.parameter.function.snakemake
  (#is? test.typeAt "parent.parent parameters"))


; The "foo" in `except TypeError as foo:`.
(as_pattern_target
  (identifier) @variable.other.exception.snakemake)

; `self` and `cls` are just conventions, but they are _strong_ conventions.
((identifier) @variable.language.self.snakemake
  (#eq? @variable.language.self.snakemake "self")
  (#set! capture.final true))

((identifier) @variable.language.cls.snakemake
  (#eq? @variable.language.cls.snakemake "cls")
  (#set! capture.final true))

(keyword_argument
  name: (identifier) @variable.parameter.function.snakemake)

(typed_parameter
  (identifier) @variable.parameter.function.snakemake)

(typed_default_parameter
  (identifier) @variable.parameter.function.snakemake)

(lambda_parameters
  (identifier) @variable.parameter.function.lambda.snakemake)

(lambda_parameters
  (default_parameter
    (identifier) @variable.parameter.function.lambda.snakemake))

(lambda_parameters
  (list_splat_pattern
    (identifier) @variable.parameter.function.lambda.snakemake))

(lambda_parameters
  (dictionary_splat_pattern
    (identifier) @variable.parameter.function.lambda.snakemake))

(assignment
  left: (identifier) @variable.other.assignment.snakemake)

; The "a" and "b" in `a, b = 2, 3`.
(assignment
  left: (pattern_list
    (identifier) @variable.other.assignment.snakemake))

; OPERATORS
; =========

(list_splat_pattern "*" @keyword.operator.splat.snakemake
  (#set! capture.final true))

(dictionary_splat_pattern "**" @keyword.operator.splat.snakemake
  (#set! capture.final true))

"=" @keyword.operator.assignment.snakemake

[
  "-="
  "*="
  "**="
  "/="
  "//="
  "%="
  "+="
  ":="
] @keyword.operator.assignment.compound.snakemake

["&" "|" "^" "~" "<<"] @keyword.operator.bitwise.snakemake

"->" @keyword.operator.function-annotation.snakemake

[
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
] @keyword.operator.comparison.snakemake

"<>" @keyword.operator.comparison.snakemake @invalid.deprecated.snakemake

[
  "+"
  "-"
  "/"
  "*"
  "**"
  "//"
  "%"
] @keyword.operator.arithmetic.snakemake

[
  "and"
  "in"
  "is"
  "not"
  "or"
] @keyword.operator.logical._TYPE_.snakemake

; The 'not' and 'in' are each scoped separately, each one being an anonymous
; node incorrectly named "not in".
"not in" @keyword.operator.logical.not-in.snakemake
"is not" @keyword.operator.logical.is-not.snakemake

(call
  function: (identifier) @keyword.other._TEXT_.snakemake
  (#match? @keyword.other._TEXT_.snakemake "^(exec|print)$")
  (#set! capture.final true))

(print_statement "print" @keyword.other.print.snakemake)

(attribute "." @keyword.operator.accessor.snakemake)


; PUNCTUATION
; ===========

("[" @punctuation.definition.subscript.begin.bracket.square.snakemake
  (#is? test.childOfType subscript))
("]" @punctuation.definition.subscript.end.bracket.square.snakemake
  (#is? test.childOfType subscript))

("[" @punctuation.definition.list.begin.bracket.square.snakemake
  (#is? test.childOfType "list list_comprehension")
  (#is? test.first true))
("]" @punctuation.definition.list.end.bracket.square.snakemake
  (#is? test.childOfType "list list_comprehension")
  (#is? test.last true))

("[" @punctuation.definition.list.begin.bracket.square.snakemake
  (#is? test.childOfType type_parameter)
  (#is? test.first true))
("]" @punctuation.definition.list.end.bracket.square.snakemake
  (#is? test.childOfType type_parameter)
  (#is? test.last true))

(slice ":" @punctuation.separator.slice.colon.snakemake)

(function_definition
  ":" @punctuation.definition.function.colon.snakemake
  (#set! capture.final true))

((pair ":" @punctuation.separator.key-value.snakemake)
  (#is? test.typeAt "parent.parent dictionary"))

(typed_parameter ":" @punctuation.separator.type-annotation.snakemake)
(typed_default_parameter ":" @punctuation.separator.type-annotation.snakemake)

("(" @punctuation.definition.parameters.begin.bracket.round.snakemake
  (#is? test.childOfType parameters)
  (#is? test.first true)
  (#set! capture.final true))
(")" @punctuation.definition.parameters.end.bracket.round.snakemake
  (#is? test.childOfType parameters)
  (#is? test.last true)
  (#set! capture.final true))

(("," @punctuation.separator.parameters.comma.snakemake)
  (#is? test.childOfType "parameters lambda_parameters")
  (#set! capture.final true))

("," @punctuation.separator.destructuring.comma.snakemake
  (#is? test.childOfType pattern_list))

("(" @punctuation.definition.arguments.begin.bracket.round.snakemake
  (#is? test.childOfType argument_list)
  (#is? test.first true)
  (#set! capture.final true))
(")" @punctuation.definition.arguments.end.bracket.round.snakemake
  (#is? test.childOfType argument_list)
  (#is? test.last true)
  (#set! capture.final true))

("," @punctuation.separator.arguments.comma.snakemake
  (#is? test.childOfType argument_list)
  (#set! capture.final true))

("(" @punctuation.definition.tuple.begin.bracket.round.snakemake
  (#is? test.childOfType tuple)
  (#is? test.first true)
  (#set! capture.final true))
(")" @punctuation.definition.tuple.end.bracket.round.snakemake
  (#is? test.childOfType tuple)
  (#is? test.last true)
  (#set! capture.final true))

("," @punctuation.separator.tuple.comma.snakemake
  (#is? test.childOfType tuple)
  (#set! capture.final true))

("{" @punctuation.definition.dictionary.begin.bracket.curly.snakemake
  (#is? test.childOfType dictionary)
  (#is? test.first true)
  (#set! capture.final true))
("}" @punctuation.definition.dictionary.end.bracket.curly.snakemake
  (#is? test.childOfType dictionary)
  (#is? test.last true)
  (#set! capture.final true))

("," @punctuation.separator.dictionary.comma.snakemake
  (#is? test.childOfType dictionary)
  (#set! capture.final true))

; MISC
; ====

(parameters) @meta.function.parameters.snakemake

(
  (argument_list) @meta.function-call.arguments.snakemake
  (#set! adjust.offsetStart 1)
  (#set! adjust.offsetEnd -1)
)

(lambda) @meta.function.inline.snakemake

(
  (lambda_parameters) @meta.function.inline.parameters.snakemake
)
