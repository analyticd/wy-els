;;; ob-mathematica.el --- org-babel functions for Mathematica evaluation

;; Copyright (C) 2014 Yi Wang

;; Authors: Yi Wang
;; Keywords: literate programming, reproducible research
;; Homepage: https://github.com/tririver/wy-els/blob/master/ob-mathematica.el
;; Distributed under the GNU GPL v2 or later

;; Org-Babel support for evaluating Mathematica source code.

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
;; Optionally require mma.el for font lock, etc
(require 'mma nil 'noerror)
(add-to-list 'org-src-lang-modes '("mathematica" . "mma"))

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("mathematica" . "mma"))

(defvar org-babel-default-header-args:mathematica '())

;;; M-x customize-group RET ob-mathematica to edit
(defcustom org-babel-mathematica-command
  "MathematicaScript -script"
  "Mathematica executable to use. Depending on operating system, possible values
   could be:
    /Applications/Mathematica.app/Contents/MacOS/MathematicaScript -script
    /Applications/Mathematica.app/Contents/MacOS/MathKernel -script
    /path/to/mash.pl
    etc.
  Note that mash.pl for Mathematica version 6 and above is available from
  http://ai.eecs.umich.edu/people/dreeves/mash/mash.pl. For other versions, see
  also http://stackoverflow.com/a/151656/3034580. The advantage of mash.pl
  is that it can return the fully evaluated result of a Mathematica expression
  whereas the -script options above have a constraint that they ensure the
  evaluated Mathematica expression stays in InputForm (so that it can be read in
  by another Mathematica script in a command line chain). Who cares? Because
  if you are in org-mode you likely want to return the TeX/LaTeX output of a
  Mathematica expression via the TeXForm command for immediate
  typesetting with preview-latex, e.g.,
  src_mathematica{Integrate[x^2,x] // TeXForm} \\frac{x^3}{3}
  or
  #+NAME: example-table
  | 1 | 4 |
  | 2 | 4 |
  | 3 | 6 |
  | 4 | 8 |
  | 7 | 0 |

  #+BEGIN_SRC mathematica :var x=example-table :results raw
  (1+Transpose@x) // TeXForm
  #+END_SRC

  #+RESULTS:
  \\left(
  \\begin{array}{ccccc}
   2 & 3 & 4 & 5 & 8 \\\\
   5 & 5 & 7 & 9 & 1 \\\\
  \\end{array}
  \\right)
"
  :type 'string
  :group 'ob-mathematica)

(defun org-babel-expand-body:mathematica (body params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let ((vars (mapcar #'cdr (org-babel-get-header params :var))))
    (concat
     (mapconcat ;; define any variables
      (lambda (pair)
	(format "%s=%s;"
		(car pair)
		(org-babel-mathematica-var-to-mathematica (cdr pair))))
      vars "\n") "\nPrint[\n" body "\n]\n")))

(defun org-babel-execute:mathematica (body params)
  "Execute a block of Mathematica code with org-babel.  This function is
called by `org-babel-execute-src-block'"
  (let* ((result-params (cdr (assoc :result-params params)))
	 (full-body (org-babel-expand-body:mathematica body params))
	 (tmp-script-file (org-babel-temp-file "mathematica-")))
    ;; actually execute the source-code block
    (with-temp-file tmp-script-file (insert full-body))
    ;; (with-temp-file "/tmp/dbg" (insert full-body))
    ((lambda (raw)
       (if (or (member "code" result-params)
	       (member "pp" result-params)
	       (and (member "output" result-params)
		    (not (member "table" result-params))))
	   raw
	 (org-babel-script-escape (org-babel-trim raw))))
    (org-babel-eval (concat org-babel-mathematica-command " " tmp-script-file) ""))))

(defun org-babel-prep-session:mathematica (session params)
  "This function does nothing so far"
  (error "Currently no support for sessions"))

(defun org-babel-prep-session:mathematica (session body params)
  "This function does nothing so far"
  (error "Currently no support for sessions"))

(defun org-babel-mathematica-var-to-mathematica (var)
  "Convert an elisp value to a Mathematica variable.
Convert an elisp value, VAR, into a string of Mathematica source code
specifying a variable of the same value."
  (if (listp var)
      (concat "{" (mapconcat #'org-babel-mathematica-var-to-mathematica var ", ") "}")
    (format "%S" var)))

(provide 'ob-mathematica)
