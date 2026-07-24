;;; lang-ocaml.el --- OCaml development environment  -*- lexical-binding: t; -*-

;;; OPAM / merlin / caml setup — deferred until the first OCaml file loads.
;; This block runs several synchronous `opam' subprocesses and loads merlin
;; and caml; doing that at startup is wasted work when no OCaml file is open.
;; `tuareg' loads from elpa, and `with-eval-after-load' runs before the first
;; `tuareg-mode-hook', so the merlin/company hooks it installs still apply to
;; the first OCaml buffer.
(with-eval-after-load 'tuareg
  (let ((prefix (string-trim (shell-command-to-string "opam config var prefix 2> /dev/null"))))
    (setq opam-dir (if (> (length prefix) 0) prefix nil)))
  (let ((share (string-trim (shell-command-to-string "opam config var share 2> /dev/null"))))
    (setq opam-share (if (> (length share) 0) share nil)))
  (add-to-list 'load-path (concat opam-share "/emacs/site-lisp"))
  ;; ## added by OPAM user-setup for emacs / base ## you can edit, but keep this line
  (require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
  ;; ## end of OPAM user-setup addition for emacs / base ## keep this line
  ;; Caml (elpa) — needed by tuareg-menhir-mode and .mlg/.mll files.
  (require 'caml))

(autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
(autoload 'camldebug  "camldebug" "Run the Caml debugger" t)

;; Hide OCaml-generated files from completion
(mapc #'(lambda (ext) (add-to-list 'completion-ignored-extensions ext))
      '(".aux" ".vo" ".cmo" ".cmx" ".cma" ".cmxa" ".cmi" ".cmxs" ".cmt" ".annot" ".byte" ".native"))

;;; OCamlformat
(use-package ocamlformat
  :ensure t
  :defer t
  :hook
  (tuareg-mode
   . (lambda ()
       (define-key tuareg-mode-map (kbd "C-M-<tab>") #'ocamlformat))))

;;; OCaml comment/header helpers
(defun chomp (str)
  "Chomp leading and trailing whitespace from STR."
  (replace-regexp-in-string (rx (or (: bos (* (any " \t\n")))
                                    (: (* (any " \t\n")) eos)))
                            "" str))

(defun pad-to-column (col pad)
  "Add PAD character from current point to column COL."
  (interactive)
  (let ((len (- col (current-column))))
    (dotimes (_ len)
      (insert pad))))

(defun dashes ()
  "Add dashes from current point to column 77."
  (interactive)
  (pad-to-column 77 "-"))

(defun ocaml-close-comment ()
  "Pad spaces then insert '*)'  ending on column 80."
  (interactive)
  (pad-to-column 77 " ")
  (insert " *)"))

(defun ocaml-insert-header-string (str)
  "Insert an OCaml comment header for STR."
  (interactive)
  (insert "(* ")
  (insert (chomp str))
  (insert " ")
  (dashes)
  (insert " *)"))

(defun ocaml-comment-header ()
  "Make the current line into a beautiful OCaml comment header."
  (interactive)
  (let (p1 p2 theLine newLine)
    (setq p1 (line-beginning-position)
          p2 (line-end-position)
          theLine (buffer-substring-no-properties p1 p2))
    (setq newLine
          (with-temp-buffer
            (insert theLine)
            (goto-char (point-min))
            (if (re-search-forward "^ *(\\* *\\([^-]*\\)-* *\\*) *" (point-max) t)
                (let ((comment (match-string 1)))
                  (erase-buffer)
                  (ocaml-insert-header-string comment))
              (progn
                (erase-buffer)
                (ocaml-insert-header-string theLine)))
            (buffer-string)))
    (delete-region p1 p2)
    (insert newLine)
    (forward-line)
    (beginning-of-line)))

(defun ocaml-comment-footer ()
  "Add a trailing '*)'  (if needed) padded to column 80."
  (interactive)
  (let (p1 p2 theLine newLine)
    (setq p1 (line-beginning-position)
          p2 (line-end-position)
          theLine (buffer-substring-no-properties p1 p2))
    (setq newLine
          (with-temp-buffer
            (insert theLine)
            (goto-char (point-min))
            (if (re-search-forward "\\*)" (point-max) t)
                (progn
                  (forward-char -2)
                  (pad-to-column 78 " "))
              (progn
                (end-of-line)
                (ocaml-close-comment)))
            (buffer-string)))
    (delete-region p1 p2)
    (insert newLine)
    (forward-line)
    (beginning-of-line)))

;;; Tuareg
(use-package tuareg
  :mode (("\\.ocamlinit\\'" . tuareg-mode)))

(add-to-list 'auto-mode-alist '("\\.mlg$" . tuareg-mode) t)
(add-to-list 'auto-mode-alist '("\\.ml[yl]+$" . tuareg-menhir-mode))

;;; Dune
(use-package dune
  :ensure t
  :mode ("dune\\'" . dune-mode))

;;; Merlin
(use-package merlin
  :ensure t
  :defer t
  :hook ((tuareg-mode . merlin-mode)
         (merlin-mode . company-mode))
  :init
  (setq merlin-error-after-save nil))

;;; Flycheck-OCaml
;; Gate on BOTH flycheck and tuareg so this (which pulls in merlin) only loads
;; for real OCaml buffers, not at startup when flycheck loads for prog-mode.
(use-package flycheck-ocaml
  :ensure t
  :after (flycheck tuareg)
  :hook
  (tuareg-mode . (lambda ()
                   (setq-local merlin-error-after-save nil)
                   (flycheck-ocaml-setup))))

(provide 'lang-ocaml)
;;; lang-ocaml.el ends here
