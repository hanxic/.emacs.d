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
           (root (when proj (project-root proj))))
      (TeX-run-compile name command file)))

  (add-to-list 'TeX-command-list
               '("LatexMk" "latexmk -pdf -synctex=1 %s"
                 TeX-run-compile nil t))

  (setq TeX-command-list
        (assq-delete-all "Make" TeX-command-list))
  (push '("Make" "make" my/TeX-run-make-at-project-root nil t) TeX-command-list)
  (setq Tex-command-default "Make")

  (defun my/TeX-set-default-command ()
    "If project root has Makefile, default to Make; else default to LatexMk."
    (let* ((proj (project-current nil))
           (root (when proj (project-root proj)))
           (has-makefile (and root (file-exists-p (expand-file-name "Makefile" root)))))
      (setq-local TeX-command-default
                  (if has-makefile "Make" "LatexMk"))))

  (add-hook 'LaTeX-mode-hook #'my/TeX-set-default-command))

(setq compilation-scroll-output t)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq LaTeX-item-indent 0)
(setq TeX-open-quote "\"")
(setq TeX-close-quote "\"")
(setq LaTeX-includegraphics-read-file 'LaTeX-includegraphics-read-file-relative)

(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'TeX-mode-hook 'turn-on-auto-fill)

;; ;;; Auto-fill only inside math environments
;; (defun hanxic/latex-math-auto-fill ()
;;   "Auto-fill only when point is inside a LaTeX math environment."
;;   (when (and (> (current-column) fill-column)
;;              (fboundp 'texmathp)
;;              (texmathp))
;;     (do-auto-fill)))

;; ;;; Smart RET: semantic line break after `. ` or `, ` in prose
;; (defun hanxic/latex-newline ()
;;   "Smart RET for LaTeX.
;; After `.[spaces]` or `,[spaces]` outside math, insert a semantic line break.
;; Inside math environments or elsewhere, insert a regular newline."
;;   (interactive)
;;   (if (and (looking-back "[.,] +" (line-beginning-position))
;;            (not (and (fboundp 'texmathp) (texmathp))))
;;       (progn
;;         (delete-horizontal-space)
;;         (newline))
;;     (newline)))

;; ;;; Auto-format: reformat prose to one sentence per line before saving
;; (defun hanxic/latex-format-sentences ()
;;   "Reformat prose paragraphs in current buffer to one sentence per line.
;; Leaves blank lines, comments (%), and LaTeX commands (\\) untouched."
;;   (save-excursion
;;     (goto-char (point-min))
;;     (while (not (eobp))
;;       (cond
;;        ((looking-at "^[ \t]*$")     (forward-line 1)) ; blank line
;;        ((looking-at "^[ \t]*[%\\]") (forward-line 1)) ; comment or command
;;        (t
;;         (let ((start (point)))
;;           (while (and (not (eobp))
;;                       (not (looking-at "^[ \t]*$"))
;;                       (not (looking-at "^[ \t]*[%\\]")))
;;             (forward-line 1))
;;           (let* ((end  (point))
;;                  (text (buffer-substring-no-properties start end))
;;                  (text (replace-regexp-in-string "[ \t]*\n[ \t]*" " " text))
;;                  (text (replace-regexp-in-string "[ \t]+" " " text))
;;                  (text (string-trim text))
;;                  (text (replace-regexp-in-string
;;                         "\\([.!?]\\) +\\([A-Z]\\)" "\\1\n\\2" text)))
;;             (delete-region start end)
;;             (insert text "\n"))))))))

;; (add-hook 'LaTeX-mode-hook
;;           (lambda ()
;;             (auto-fill-mode 1)
;;             (setq-local auto-fill-function #'hanxic/latex-math-auto-fill)
;;             (local-set-key (kbd "RET") #'hanxic/latex-newline)
;;             (add-hook 'before-save-hook #'hanxic/latex-format-sentences nil t)))

(add-hook 'TeX-mode-hook
          (lambda () (set (make-local-variable 'TeX-electric-math)
                          (cons "\\(" "\\)"))))
(add-hook 'plain-TeX-mode-hook
          (lambda () (set (make-local-variable 'TeX-electric-math)
                          (cons "$" "$"))))

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
  :commands yas-minor-mode
  :hook ((prog-mode  . yas-minor-mode)
         (LaTeX-mode . yas-minor-mode))
  :init
  (setq yas-verbosity 1
        yas-wrap-around-region t))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)

;;; CSV
(use-package csv-mode
  :ensure t
  :mode ("\\.csv\\'" . csv-mode))

;;; Compilation helpers
(defun hanxic/compile-with-callbacks (command on-success on-failure)
  "Run COMMAND with `compile`.
If compilation succeeds, call ON-SUCCESS.
If it exits abnormally, call ON-FAILURE."
  (let ((done nil))
    (cl-labels
        ((handler (buf msg)
           (unless done
             (setq done t)
             (remove-hook 'compilation-finish-functions #'handler)
             (cond
              ((string-match "finished" msg) (funcall on-success))
              ((string-match "killed"   msg) (message "Compilation was killed; ignoring."))
              (t (funcall on-failure))))))
      (add-hook 'compilation-finish-functions #'handler)
      (compile command))))

(defun hanxic/funcall-after-delay-focus (seconds on-focus)
  "Wait SECONDS, then activate Emacs and call ON-FOCUS."
  (run-at-time seconds nil
               (lambda ()
                 (when (fboundp 'ns-do-applescript)
                   (ns-do-applescript "tell application \"Emacs\" to activate")
                   (funcall on-focus)))))

(defun hanxic/invoke-funcall-window (windowname on-focus)
  "Get the window for WINDOWNAME, then call ON-FOCUS on it."
  (let ((window (get-buffer-window windowname)))
    (when (window-live-p window)
      (funcall on-focus window))))

(defun hanxic/suffix-conversion (filename suffix)
  "Return FILENAME with extension replaced by SUFFIX."
  (concat (file-name-sans-extension filename) suffix))

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
