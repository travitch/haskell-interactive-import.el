;;; haskell-interactive-import.el --- A package for inserting Haskell imports interactively    -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Tristan Ravitch

;; Author: Tristan Ravitch <tristan@ravit.ch>
;; Keywords: haskell, hydra
;; Version: 0.0.1

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;;  Commentary:

;; This package implements a minor mode for Haskell mode that adds a hydra for
;; interactively inserting imports and returning to the original point before
;; the import was started.  The interactive hydra interface allows the user to
;; select the import group to which the import should be added.
;;
;; Imports in the target group are sorted automatically.
;;
;; Example configuration:
;;
;; (use-package haskell-interactive-import
;;   :ensure nil
;;   :load-path "~/.emacs.d/local"
;;   :init (add-hook 'haskell-mode-hook 'haskell-interactive-import-mode))

;;; Code:

(require 'hydra)
(require 'haskell-mode)
(require 'eacl)

;; The formulation of this hydra tries to be a bit careful: we want to make sure
;; that canceling out of the hydra should correctly trigger the save-excursion
;; and atomic-change-group macros.
;;
;; This hydra uses :foreign-keys warn to make sure that hitting keys not in the
;; hydra don't cleanly exit the hydra (which would break those guard macros).
;; This means that hitting a key not in one of the hydra heads doesn't break out
;; of the hydra.
(defhydra hydra-haskell-interactive-import (:hint nil
                                            :foreign-keys warn)
  "Add Import"
  ("i" haskell-navigate-imports-go "Next import group")
  ("RET" exit-recursive-edit "Import here")
  ("C-g" abort-recursive-edit "Cancel")
  ("q" abort-recursive-edit "Cancel"))

;;;###autoload
(defun haskell-interactive-import-begin ()
  "Interactively select an import group and add an import to it."
  (interactive)
  (atomic-change-group
    (save-excursion
      (haskell-navigate-imports-go)
      (call-interactively #'hydra-haskell-interactive-import/body)
      (recursive-edit)
      (insert "\n")
      (forward-line -1)
      (insert "import ")
      (eacl-complete-line)
      (haskell-sort-imports))))

(defvar haskell-interactive-import-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map haskell-mode-map)
    (define-key map (kbd "C-c i") #'haskell-interactive-import-begin)
    map)
  "Keymap for Haskell mode hydras.")

;;;###autoload
(define-minor-mode haskell-interactive-import-mode
  "Add a hydra for interactively adding imports to Haskell mode."
  :keymap haskell-interactive-import-map
  :require 'haskell-mode)

(provide 'haskell-interactive-import)
;;; haskell-interactive-import.el ends here
