;;; ferl-test.el --- Tests for ferl.el
;;
;; This file is not part of GNU Emacs.
;;
;;
;; This file is part of EDTS.
;;
;; EDTS is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Lesser General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; EDTS is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public License
;; along with EDTS. If not, see <http://www.gnu.org/licenses/>.

(require 'edts-test)
(require 'ferl)

(edts-test-add-suite
 ;; Name
 ferl-suite)

(defconst ferl-test-doc-string-module
  "-module(foo).
-moduledoc \"\"\"
Module docs.

bar(X) in the docs is not a function.
\"\"\".

-export([foo/0, bar/1]).

foo() -> ok.

-doc \"\"\"
Docs for bar.
\"\"\".
bar(a) -> 1;
bar(b) -> 2.
"
  "Module with triple-quoted doc strings, which used to make
`ferl-local-functions' loop forever.")

(defmacro ferl-test-with-module (&rest body)
  `(with-temp-buffer
     (insert ferl-test-doc-string-module)
     (erlang-mode)
     ,@body))

(defun ferl-test-line-start (regexp)
  (save-excursion
    (goto-char (point-min))
    (re-search-forward regexp)
    (line-beginning-position)))

(edts-test-case ferl-suite ferl-local-functions-doc-strings ()
  "Test ferl-local-functions skips doc strings and merges clauses"
  (ferl-test-with-module
   (should (equal `(("bar/1" . ,(ferl-test-line-start "^bar(a)"))
                    ("foo/0" . ,(ferl-test-line-start "^foo()")))
                  (ferl-local-functions)))))

(edts-test-case ferl-suite ferl-local-function-names-doc-strings ()
  "Test ferl-local-function-names skips doc strings"
  (ferl-test-with-module
   (should (equal '("bar" "foo") (ferl-local-function-names)))))

(edts-test-case ferl-suite ferl-goto-next-function-clause ()
  "Test ferl-goto-next-function-clause"
  (ferl-test-with-module
   (goto-char (point-min))
   (should (equal (ferl-test-line-start "^foo()")
                  (ferl-goto-next-function-clause)))
   (should (equal (ferl-test-line-start "^bar(a)")
                  (ferl-goto-next-function-clause)))
   (should (equal (ferl-test-line-start "^bar(b)")
                  (ferl-goto-next-function-clause)))
   (let ((last (point)))
     (should-not (ferl-goto-next-function-clause))
     (should (equal last (point))))))

(provide 'ferl-test)
