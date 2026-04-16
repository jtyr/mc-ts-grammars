;; order must go from most specific to generic for 'elisp-tree-sitter` package
;; https://github.com/emacs-tree-sitter/elisp-tree-sitter

;; defined forms
(macro_definition name: (symbol) @function)
(function_definition name: (symbol) @function)
(variable_setter name: (symbol) @variable.argument)
(custom_definition name: (symbol) @variable.argument)
(variable_definition name: (symbol) @variable.argument)

arglist: (list (symbol) @variable.parameter)
arglist: (list (symbol (param_keyword) @type))
interactive: (interactive (special_form) @keyword)
interactive: (interactive (string) @string)
macro: (symbol) @keyword
special_form: (symbol) @keyword
mode: (symbol) @constant
marker: _ @operator
;; strings
docstring: (string open: _ @doc)
docstring: (string (escape_sequence) @doc)
docstring: (string (string_fragment) @doc)
docstring: (string (lisp_code) @type)
docstring: (string close: _ @doc)

(string open: _ @string)
(string (escape_sequence) @string)
(string (string_fragment) @string)
(string (lisp_code) @type)
(string close: _ @string)
;; comments
(comment (lisp_code) @type)
(autoload (function)* @function (keyword) @error)
;; symbols
(special_syntax (uninterned_symbol (symbol_name) @constant.builtin))
(symbol (boolean) @constant.builtin)
(symbol (keyword) @variable.builtin)
(symbol (param_keyword) @type)
(dotted_pair (dot) @constant.builtin)
(fn_quote (symbol) @function)
(quote (symbol) @constant)
;; misc
(number) @number
(char) @constant
(lisp_code) @type
(comment) @comment




;; macros from std directory lisp/emacs-lisp
;; ((symbol) @keyword
;;  (.match? @keyword "^(syntax-propertize-precompile-rules|syntax-propertize-rules|internal--thread-argument|thread-first|thread-last|if-let\*|when-let\*|and-let\*|if-let|when-let|named-let|with-memoization|package--with-work-buffer|package--with-response-buffer|package--unless-error|package--push|seq-doseq|seq|seq-let|seq-setq|radix-tree-leaf|with-timeout|rx|rx-let-eval|rx-let|rx-define|rx|pcase|pcase-exhaustive|pcase-lambda|pcase-let\*|pcase-let|pcase-dolist|pcase-setq|pcase--flip|guard|map|map-let|map--dispatch|map-put|reb-target-binding|add-function|remove-function|define-advice|let-alist|lm-with-file|gv-letplace|gv-define-expander|gv-define-expand|gv-define-setter|gv-define-simple-setter|setf|gv-pushnew!|gv-inc!|gv-dec!|gv-synthetic-place|gv-delay-error|gv-ref|gv-letref|macroexp--accumulate|macroexp-let2|macroexp-let2\*|degrees-to-radians|radians-to-degrees|cps--gensym|cps--define-unsupported|cps--with-value-wrapper|cps--with-dynamic-binding|iter-yield-from|iter-defun|iter-lambda|iter-make|iter-do|cps--advance-for|cps--initialize-for|ewoc--set-buffer-bind-dll-let\*|ewoc--set-buffer-bind-dll|ert-with-test-buffer|ert-simulate-keys|ert-with-buffer-renamed|ert-with-message-capture|ert-resource-directory|ert-resource-file|ert-with-temp-file|ert-with-temp-directory|defclass|oref|oref-default|with-slots|eieio|eieio-class-parent|oset|oset-default|faceup-defexplainer|let-when-compile|thunk-delay|thunk-let|thunk-let\*|ert-deftest|should|should-not|should-error|ert--skip-unless|ert-info|eldoc--documentation-strategy-defcustom|eieio--class-option-assoc|eieio-declare-slots|defgeneric|defmethod|crm--completion-command|define-derived-mode|define-minor-mode|define-globalized-minor-mode|easy-mmode-defmap|easy-mmode-defsyntax|easy-mmode-define-navigation|debugger-env-macro|easy-menu-define|cl-incf|cl-decf|cl-pushnew|cl-declaim|with-comp-cstr-accessors|comp-cstr-set-range-for-arithm|proclaim-inline|proclaim-notinline|defsubst|define-obsolete-function-alias|define-obsolete-variable-alias|define-obsolete-face-alias|dont-compile|eval-when-compile|eval-and-compile|with-suppressed-warnings|byte-compiler-options|benchmark-elapse|benchmark-run|benchmark-run-compiled|benchmark-progn|backtrace--with-output-variables|cl-generic-define-generalizer|cl--generic|cl-defgeneric|cl-generic-current-method-specializers|cl-generic-define-context-rewriter|cl-defmethod|cl--generic-prefill-dispatchers|backquote-list*-macro|backquote|avl-tree--root|avl-tree--switch-dir|avl-tree--dir-to-sign|avl-tree--sign-to-dir|byte-compile-log-lap|byte-optimize--pcase|myaccessor|cl-defsubst|inline-quote|inline-const-p|inline-const-val|inline-error|inline--leteval|inline--letlisteval|inline-letevals|inline-if|define-inline|cl--pop2|cl-defun|cl-iter-defun|cl-function|cl-destructuring-bind|cl-eval-when|cl-load-time-value|cl-case|cl-ecase|cl-typecase|cl-etypecase|cl-block|cl-return|cl-return-from|cl-loop|cl--push-clause-loop-body|cl-do|cl-do\*|cl-dolist|cl-dotimes|cl-tagbody|cl-prog|cl-prog\*|cl-do-symbols|cl-do-all-symbols|cl-psetq|cl-progv|cl-flet|cl-flet\*|cl-labels|cl-macrolet|cl-symbol-macrolet|cl-multiple-value-bind|cl-multiple-value-setq|cl-locally|cl-the|cl-declare|cl-psetf|cl-remf|cl-shiftf|cl-rotatef|cl-letf|cl-letf\*|cl-callf|cl-callf2|cl-defsubst|cl--find-class|cl-defstruct|cl-struct|cl-check-type|cl-assert|cl-define-compiler-macro|cl-deftype|cl-type|comp-loop-insn-in-block|comp-with-sp|comp-op-case|comp-apply-in-env|cl-defgeneric|byte-defop|byte-extrude-byte-code-vectors|byte-compile-push-bytecodes|byte-compile-push-bytecode-const2|byte-compile-log|byte-compile-close-variables|displaying-byte-compile-warnings|byte-compile-get-constant|byte-defop-compiler|byte-defop-compiler-1|byte-compile-goto-if|byte-compile-maybe-guarded|bindat--pcase|bindat-type|u8|sint|require|repeat|edebug-save-restriction|edebug-storing-offsets|edebug-tracing|edebug-changing-windows|edebug-outside-excursion|cl--parsing-keywords|cl--check-key|cl--check-test-nokey|cl--check-test|cl--check-match|define-generic-mode|foom|ad-do-advised-functions|defadvice|ad-with-originals)$"))

;; highlight locally bound variables
;; (list
;;  (symbol) @keyword
;;  (.match? @keyword "^(cl-|when-|if-|rx-|map-|org-|seq-)?(f)?let(f)?(\\*)?$")
;;  .
;;  (list . (symbol)* @variable
;;        (list . (symbol)? @variable)*
;;        (symbol)* @variable))

;; std directory lisp/
;; ((symbol) @keyword
;;  (.match? @keyword
;;           "^(save-mark-and-excursion|define-alternatives|custom-put-if-not|with-help-window|strokes-define-stroke|strokes-define-stroke|hfy-save-buffer-state|define-widget-keywords|image-dired--with-db-file|image-dired--with-marked|image-dired--with-thumbnail-buffer|image-dired--on-file-in-dired-buffer|image-dired--do-mark-command|speedbar-with-writable|widget-specify-insert|dired-mark-if|dired-map-over-marks|define-thing-chars|define-skeleton|transient--with-emergency-exit|transient-define-prefix|transient-define-suffix|transient-define-infix|server-with-environment|rtree-make-node|rtree-set-left|rtree-set-right|rtree-set-range|rtree-low|rtree-high|rtree-set-low|rtree-set-high|rtree-left|rtree-right|rtree-range|repos-debug-macro|declare-function|noreturn|1value|def-edebug-spec|setq-local|defvar-local|push|pop|when|unless|dolist|dotimes|declare|ignore-errors|ignore-error|letrec|dlet|with-wrapper-hook|subr--with-wrapper-hook-no-warnings|delay-mode-hooks|atomic-change-group|with-undo-amalgamate|track-mouse|with-current-buffer|with-selected-window|with-selected-frame|save-window-excursion|with-output-to-temp-buffer|with-temp-file|with-temp-message|with-temp-buffer|with-silent-modifications|with-output-to-string|with-local-quit|while-no-input|condition-case-unless-debug|with-demoted-errors|combine-after-change-calls|combine-change-calls|with-case-table|with-file-modes|with-existing-directory|save-match-data|with-eval-after-load|with-syntax-table|dotimes-with-progress-reporter|dolist-with-progress-reporter|with-mutex|defvar-keymap|with-delayed-message|recentf-dialog|with-cpu-profiling|with-memory-profiling|pcomplete-here|pcomplete-here\*|replace--push-stack|proced-with-processes-buffer|save-selected-window|with-temp-buffer-window|with-current-buffer-window|with-displayed-buffer-window|with-window-non-dedicated|comment-with-narrowing|json--with-output-to-string|json--with-indentation|json-readtable-dispatch|with-auto-compression-mode|jsonrpc-lambda|menu-bar-make-mm-toggle|menu-bar-make-toggle|menu-bar-make-toggle-command|imenu-progress-message|with-buffer-prepared-for-jit-lock|info-xref-with-file|info-xref-with-output|lazy-completion-table|with-minibuffer-selected-window|ibuffer-aif|ibuffer-awhen|ibuffer-save-marks|define-ibuffer-column|define-ibuffer-sorter|define-ibuffer-op|define-ibuffer-filter|defimage|make-help-screen|Info-no-error|with-isearch-suspended|isearch-define-mode-toggle|with-connection-local-variables|defezimage|save-buffer-state|with-environment-variables|electric-pair--with-uncached-syntax|electric-pair--save-literal-point-excursion|dframe-with-attached-buffer|face-attribute-specified-or|dabbrev-filter-elements|custom-put-if-not|defcustom|defface|defgroup|deftheme|completion-string|completion-num-uses|completion-last-use-time|completion-source|set-completion-string|set-completion-num-uses|set-completion-last-use-time|cmpl-prefix-entry-symbol|set-cmpl-prefix-entry-head|set-cmpl-prefix-entry-tail|with-buffer-modified-unmodified|bookmark-maybe-historicize-string|bound-and-true-p|auth-source--aput|pcmpl-gnu-with-file-buffer|align--set-marker|hex-char-to-num|num-to-hex-char|md4-make-step|dom-attr|minibuffer-with-setup-hook)$"))

;; (["let" "let*"] @keyword
;;  . (list . (symbol)* @variable
;;          (list . (symbol)? @variable)*
;;          (symbol)* @variable))

;; (["cond"] @keyword
;;  (list (symbol)? @embedded)*)

;; ((symbol) @keyword
;;  (.match? @keyword "^\\(pcase-\\)")
;;  . (list . (symbol)* @variable
;;          (list . (symbol)? @variable)*
;;          (symbol)* @variable)
;;  (list (symbol)? @default))

;; ;; highlight missed properties
;; ((symbol) @variable.builtin
;;  (.match? @variable.builtin "^:"))

;; ;; (quote (list (symbol) @embedded))


;; ;; (quote "#'" (_)* (list (symbol) @function))

;; (quoting_lit (symbol) @constant)


;; lambda definitions
