;;; lang-latex.el --- AUCTeX, LaTeX workflow, snippets, CSV  -*- lexical-binding: t; -*-

(require 'project)

;;; AUCTeX
(use-package auctex
  :ensure t
  :defer t
  :mode ("\\.tex\\'" . latex-mode))

(use-package tex
  :ensure auctex
  :after auctex
  :config
  (setq TeX-source-correlate-mode t
        TeX-source-correlate-start-server t
        TeX-command-extra-options "-synctex=1"
        TeX-view-program-selection '((output-pdf "Skim"))
        TeX-view-program-list '(("Skim" "/Applications/Skim.app/Contents/SharedSupport/displayline -b -g %n %o %b"))
        TeX-show-compilation t
        TeX-scroll-buffer t))

(with-eval-after-load 'tex
  (defun my/TeX-run-make-at-project-root (name command file)
    "Run make from the project root (project.el), falling back to current dir."
    (let* ((proj (project-current nil))
           (root (when proj (project-root proj)))
           (default-directory (or root default-directory)))
      (TeX-run-compile name command file)))

  (add-to-list 'TeX-command-list
               '("LatexMk" "latexmk -pdf -synctex=1 %s"
                 TeX-run-compile nil t))

  (setq TeX-command-list
        (assq-delete-all "Make" TeX-command-list))
  (push '("Make" "make" my/TeX-run-make-at-project-root nil t) TeX-command-list)
  (setq TeX-command-default "Make")

  (defun my/TeX-force-make-default ()
    (setq-local TeX-command-default "Make"))

  (add-hook 'LaTeX-mode-hook #'my/TeX-force-make-default)

  (defun my/TeX-command-default-always-make (&rest _)
    "Always return \"Make\" as the next TeX command."
    "Make")
  (advice-add 'TeX-command-default :override #'my/TeX-command-default-always-make)

  (defun my/TeX-process-check-kill (orig name)
    "Silently kill any running TeX process for NAME instead of prompting."
    (let (process)
      (while (and (setq process (TeX-process name))
                  (eq (process-status process) 'run))
        (delete-process process))))
  (advice-add 'TeX-process-check :around #'my/TeX-process-check-kill))

(setq compilation-scroll-output t)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq LaTeX-item-indent 0)
(setq TeX-open-quote "\"")
(setq TeX-close-quote "\"")
(setq LaTeX-includegraphics-read-file 'LaTeX-includegraphics-read-file-relative)

(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'TeX-mode-hook 'turn-on-auto-fill)

;;; Keep the chktex flycheck checker ON, but silence the warnings that are
;;; pure noise in math-heavy LaTeX (they used to flood past
;;; `flycheck-checker-error-threshold' and disable the checker entirely):
;;;   1  - "Command terminated with space"                 (\alpha x, \sum f, ...)
;;;   36 - "You should put a space in front of parenthesis" (f(x))
;;;   3  - "Enclose the previous parenthesis with {}"        (math sub/superscripts)
;;; Kept: 2 and 24 (non-breaking-space checks before \cite/\ref) are real.
(with-eval-after-load 'flycheck
  (setq flycheck-chktex-extra-flags '("-n1" "-n36" "-n3")))

;; Make `LaTeX-indent-line' tolerant of unmatched environments so that
;; `indent-region' over a buffer (e.g. an \input'd subfile with no local
;; \begin{document}) completes instead of aborting at the first \end whose
;; \begin lives in the parent file.
(with-eval-after-load 'latex
  (defun hanxic/LaTeX-indent-line-tolerant (orig-fn &rest args)
    (condition-case _err
        (apply orig-fn args)
      (error nil)))
  (advice-add 'LaTeX-indent-line :around #'hanxic/LaTeX-indent-line-tolerant))

;;; Pairing is handled by yasnippet.  The plain pairs `(' `[' `{' live in
;;; ~/.emacs.d/snippets/fundamental-mode/ so they fire in every mode (yas
;;; treats `fundamental-mode' as the universal ancestor).  The LaTeX-only
;;; variants — `\{' `\[' and the `((' `[[' `{{' `\left ... \right' forms —
;;; stay in ~/.emacs.d/snippets/latex-mode/.  See the `yas-key-syntaxes' tweak
;;; below — it makes these fire after arbitrary preceding text. Subscript/superscript
;;; pairs `_{}'/`^{}' come from the same `{' snippet (type `_{<TAB>' or
;;; `^{<TAB>'), so AUCTeX's electric sub/superscript is disabled. `$' stays
;;; electric since yasnippet can't isolate a single `$'.
(setq LaTeX-electric-left-right-brace nil
      TeX-electric-math '("$" . "$")
      TeX-electric-sub-and-superscript nil
      TeX-electric-escape nil)

;;; Smart delete for empty `^{}' / `_{}': backspace, forward-delete, evil `x'
;;; and `X' inside such a construct remove the whole thing in one go.

(defun hanxic/latex-smart-delete-region (direction)
  "If the char being deleted in DIRECTION (`back' or `forward') sits inside
an empty/whitespace `^{}'/`_{}', delete the whole construct and return t.
Otherwise return nil."
  (let* ((target (if (eq direction 'back) (1- (point)) (point))))
    (and (>= target (point-min))
         (< target (point-max))
         (let ((bounds (save-excursion
                         (beginning-of-line)
                         (catch 'found
                           (while (re-search-forward "[_^]{[ \t]*}"
                                                     (line-end-position) t)
                             (when (and (<= (match-beginning 0) target)
                                        (< target (match-end 0)))
                               (throw 'found (cons (match-beginning 0)
                                                   (match-end 0)))))))))
           (when bounds
             (delete-region (car bounds) (cdr bounds))
             t)))))

(defun hanxic/latex-smart-backspace ()
  "Backspace, promoting to whole-`^{}'/`_{}' delete when applicable."
  (interactive)
  (unless (hanxic/latex-smart-delete-region 'back)
    (delete-char -1)))

(defun hanxic/latex-smart-delete-forward ()
  "Forward delete, promoting to whole-`^{}'/`_{}' delete when applicable."
  (interactive)
  (unless (hanxic/latex-smart-delete-region 'forward)
    (delete-char 1)))

(defun hanxic/latex-evil-x ()
  "Evil `x', promoting to whole-`^{}'/`_{}' delete when applicable."
  (interactive)
  (unless (hanxic/latex-smart-delete-region 'forward)
    (call-interactively #'evil-delete-char)))

(defun hanxic/latex-evil-X ()
  "Evil `X', promoting to whole-`^{}'/`_{}' delete when applicable."
  (interactive)
  (unless (hanxic/latex-smart-delete-region 'back)
    (call-interactively #'evil-delete-backward-char)))

(with-eval-after-load 'latex
  (define-key LaTeX-mode-map (kbd "<backspace>") #'hanxic/latex-smart-backspace)
  (define-key LaTeX-mode-map (kbd "DEL")         #'hanxic/latex-smart-backspace))

(with-eval-after-load 'evil
  (with-eval-after-load 'latex
    (evil-define-key 'insert LaTeX-mode-map
      (kbd "<backspace>") #'hanxic/latex-smart-backspace
      (kbd "DEL")         #'hanxic/latex-smart-backspace)
    (evil-define-key 'normal LaTeX-mode-map
      "x" #'hanxic/latex-evil-x
      "X" #'hanxic/latex-evil-X)))

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda () (flyspell-mode 1))))
(dolist (hook '(change-log-mode-hook log-edit-mode-hook))
  (add-hook hook (lambda () (flyspell-mode -1))))

;;; Company-AUCTeX
(use-package company-auctex
  :after auctex
  :hook (LaTeX-mode . company-auctex-init))

;;; YASnippet
(use-package yasnippet
  :ensure t
  :defer 1
  :init
  (setq yas-verbosity 1
        yas-wrap-around-region t
        ;; Allow snippet expansion inside an active snippet field, so e.g.
        ;; `_{<TAB>' still fires when the cursor is inside an outer `(...)'.
        yas-triggers-in-field t)
  :config
  ;; Default `yas-key-syntaxes' only isolates word chars or non-whitespace
  ;; runs, so a key like `(' or `((' won't trigger after a letter (the
  ;; non-whitespace strategy yields `foo((', which matches nothing). Try
  ;; the last 2 chars and then the last 1 char first so single/double-
  ;; punctuation triggers fire regardless of preceding text.
  (defun hanxic/yas-key-fixed-2 (_original)
    (goto-char (max (point-min) (- (point) 2))))
  (defun hanxic/yas-key-fixed-1 (_original)
    (goto-char (max (point-min) (- (point) 1))))
  (setq yas-key-syntaxes
        (append (list #'hanxic/yas-key-fixed-2 #'hanxic/yas-key-fixed-1)
                yas-key-syntaxes))
  ;; Enable yasnippet in every buffer (not just prog/LaTeX) so the global
  ;; `(' `[' `{' pairs in snippets/fundamental-mode/ work in all files.
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)

;;; CSV
(use-package csv-mode
  :ensure t
  :mode ("\\.csv\\'" . csv-mode))

;;; Compilation helpers
(defun hanxic/latex-make ()
  "Run `make` from project root if a Makefile exists."
  (when-let ((root (locate-dominating-file default-directory "Makefile")))
    (let ((default-directory root))
      (compile "make"))))

(defun hanxic/close-compilation-window-on-success (buffer status)
  "Close compilation window if compilation finished successfully."
  (when (and (string-match-p "finished" status)
             (buffer-live-p buffer))
    (when-let ((win (get-buffer-window buffer)))
      (delete-window win))))

(add-hook 'compilation-finish-functions
          #'hanxic/close-compilation-window-on-success)

;;; latex-save-mode
(defvar latex-save-mode--default-enabled nil
  "Whether `latex-save-mode` should start enabled in LaTeX buffers.")

;;;###autoload
(define-minor-mode latex-save-mode
  "Toggle Latex Save Mode.
When enabled, run latex-make on saving LaTeX files."
  :lighter "LaTeX-Save"
  :global nil
  (if latex-save-mode
      (progn
        (message "latex-save-mode enabled")
        (add-hook 'after-save-hook #'hanxic/latex-make))
    (progn
      (message "latex-save-mode disabled")
      (remove-hook 'after-save-hook #'hanxic/latex-make))))

(defun latex-save-mode--auto-enable ()
  "Enable `latex-save-mode` in LaTeX buffers if default is on."
  (when (derived-mode-p 'latex-mode 'LaTeX-mode)
    (unless (bound-and-true-p latex-save-mode)
      (when latex-save-mode--default-enabled
        (latex-save-mode 1)))))

(add-hook 'latex-mode-hook  #'latex-save-mode--auto-enable)
(add-hook 'LaTeX-mode-hook  #'latex-save-mode--auto-enable)

(defun latex-save-mode--remember-choice ()
  (setq latex-save-mode--default-enabled latex-save-mode))
(add-hook 'latex-save-mode-hook #'latex-save-mode--remember-choice)

;;; Research notes
(defun hanxic/new-research-note (date)
  "Create a new research note for DATE in the project's notes/ directory."
  (interactive
   (list (read-string "Date (YYYY-MM-DD): "
                      (format-time-string "%Y-%m-%d"))))
  (let* ((root (or (when-let ((proj (project-current nil)))
                     (project-root proj))
                   default-directory))
         (dir  (expand-file-name "notes" root))
         (file (expand-file-name (concat date ".tex") dir)))
    (when (file-exists-p file)
      (find-file file)
      (user-error "Note %s already exists" date))
    (find-file file)
    (insert "\\section{" date "}\n"
            "\n"
            "\\subsection{What did I do last week?}\n"
            "\\begin{itemize}\n"
            "  \\item \n"
            "\\end{itemize}\n"
            "\n"
            "\\subsection{Questions}\n"
            "\\begin{itemize}\n"
            "  \\item \n"
            "\\end{itemize}\n"
            "\n"
            "\\subsection{Next Step}\n"
            "\\begin{itemize}\n"
            "  \\item \n"
            "\\end{itemize}\n"
            "\n\n"
            "%%% Local" " Variables:\n"
            "%%% eval: (setq TeX-master\n"
            "%%%             (file-name-directory\n"
            "%%%              (directory-file-name default-directory)))\n"
            "%%% End:\n")
    (save-buffer)
    (hack-local-variables)
    (goto-char (point-min))
    (search-forward "\\item " nil t)))

(define-key hanxic/personal-map (kbd "n") #'hanxic/new-research-note)

(provide 'lang-latex)
;;; lang-latex.el ends here
