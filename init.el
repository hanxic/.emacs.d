(server-start)
;; Initialize package sources
(require 'package)

(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
			 ("org" . "http://orgmode.org/elpa/")
                         ("melpa" .  "https://melpa.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)


;; ******** Basics ********
(setq inhibit-startup-message t
      column-number-mode t
      line-number-mode t
      size-indication-mode t
      )

(global-display-line-numbers-mode t)

(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

;; Set the fill column indicator column to 80
(setq-default display-fill-column-indicator-column 80)

;; Ensure that other modes or configurations don't overrule it
(add-hook 'after-change-major-mode-hook
          (lambda ()
            (setq display-fill-column-indicator-column 80)))


(dolist (mode '(org-mode-hook
		term-mode-hook
		eshell-mode-hook
		shell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(global-hl-line-mode 1)
(scroll-bar-mode -1)    ; Disable visible scrollbar
(tool-bar-mode -1)      ; Disable the tool bar
(tooltip-mode -1)       ; Disable tooltips
(set-fringe-mode 10)    ; Give some breathing room

(menu-bar-mode -1)      ; Disable the menu bar

(use-package command-log-mode)

;; ******** Tree-sitter ********
;; (use-package tree-sitter
;;   :config
;;   (global-tree-sitter-mode))

;; (use-package tree-sitter-langs
;;   :after (tree-sitter))

;; (use-package tree-sitter-indent
;;   :after (tree-sitter))
;; (setq treesit-language-source-alist
;;    '((bash "https://github.com/tree-sitter/tree-sitter-bash")
;;      (cmake "https://github.com/uyha/tree-sitter-cmake")
;;      (css "https://github.com/tree-sitter/tree-sitter-css")
;;      (elisp "https://github.com/Wilfred/tree-sitter-elisp")
;;      (go "https://github.com/tree-sitter/tree-sitter-go")
;;      (html "https://github.com/tree-sitter/tree-sitter-html")
;;      (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
;;      (json "https://github.com/tree-sitter/tree-sitter-json")
;;      (make "https://github.com/alemuller/tree-sitter-make")
;;      (markdown "https://github.com/ikatyang/tree-sitter-markdown")
;;      (python "https://github.com/tree-sitter/tree-sitter-python")
;;      (toml "https://github.com/tree-sitter/tree-sitter-toml")
;;      (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
;;      (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
;;      (yaml "https://github.com/ikatyang/tree-sitter-yaml")
;;      (haskell "https://github.com/tree-sitter/tree-sitter-haskell")
;;      (ocaml "https://github.com/tree-sitter/tree-sitter-ocaml")
;;      ))

;; (mapc #'treesit-install-language-grammar (mapcar #'car treesit-language-source-alist))
;; ******** ripgrep + helm + projectile ********

(use-package projectile
  :ensure t
  :commands (projectile-mode)
  :config

  (projectile-mode)

  ;; May not work on Windows
  (setq projectile-enable-caching t
        projectile-indexing-method 'alien)

  (add-to-list 'projectile-other-file-alist '("v" "ml" "mli"))
  (add-to-list 'projectile-other-file-alist '("mli" "ml" "mll" "mly" "v")))

(use-package helm
  :ensure t
  :diminish helm-mode
  :bind (("M-x" . helm-M-x)
         ("C-x b" . helm-mini)
         ("C-x C-b" . helm-mini)
         ("C-x C-f" . helm-find-files)
         ("C-c h o" . helm-occur)
         ("M-p" . helm-show-kill-ring)
	 ("C-M-j" . helm-buffers-list))
  :defer 1
  :config

  ;(require 'helm-config)
  (helm-mode 1)
  (helm-autoresize-mode 1)
  :custom
  (helm-M-x-show-short-doc t))

(use-package helm-projectile
  :ensure t
  :commands (helm-projectile helm-projectile-switch-project helm-projectile-ag helm-projectile-rg helm-projectile-grep)
  :bind (("C-c p h" . helm-projectile)
         ("C-c p p" . helm-projectile-switch-project)
         ("C-c p r" . helm-projectile-rg)
         ("C-c p a" . helm-projectile-ag)
         ("C-c p g" . helm-projectile-grep)
         ("C-c p o" . helm-projectile-find-other-file))
  :config

  (helm-projectile-on))

(use-package helm-ag
  :ensure t
  :commands (helm-ag)
  :config

  (setq helm-ag-insert-at-point 'symbol))

(use-package helm-rg
  :ensure t
  :commands (helm-rg)
  :config(custom-set-faces
   '(helm-rg-file-match-face ((t (:extend t :foreground "BlueViolet" :underline t))))))
;; ## added by OPAM user-setup for emacs / base ## 56ab50dc8996d2bb95e7856a6eddb17b ## you can edit, but keep this line
(require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
;; ## end of OPAM user-setup addition for emacs / base ## keep this line

(use-package helm-tree-sitter
  )
;; ******** Doom-modeline ********
(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (all-the-icons must be installed!).
  (doom-themes-neotree-config)
  ;; or for treemacs users
  (setq doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
					;  (doom-themes-org-config))
  )




(use-package nerd-icons
  ;; :custom
  ;; The Nerd Font you want to use in GUI
  ;; "Symbols Nerd Font Mono" is the default and is recommended
  ;; but you can use any other Nerd Font if you want
  ;; (nerd-icons-font-family "Symbols Nerd Font Mono")
  )

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom    
  ((doom-modeline-height 25)
  (doom-modeline-bar-width 1)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-minor-modes nil)
  (doom-modeline-enable-word-count nil)
  (doom-modeline-buffer-encoding t)
  (doom-modeline-indent-info nil)
  (doom-modeline-checker-simple-format t)
  (doom-modeline-vcs-max-length 12)
  (doom-modeline-env-version t)
  (doom-modeline-irc-stylize 'identity)
  (doom-modeline-github-timer nil)
  (doom-modeline-gnus-timer nil)))

;; ******** Rainbow Delimiters ********
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

;; ******** Helpful ********
(use-package helpful
  :bind
  ([remap describe-key] . helpful-key)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-function] . helpful-callable)
  ([remap describe-command] . helpful-command)
  ("C-c C-d" . helpful-at-point)
  ("C-h F" . helpful-function))

;; ******** General ********
;;(use-package general)

;; ******** Evil Mode ********
(defun hanxic/evil-hook ()
  (dolist (mode '(custom-mode
                  eshell-mode
                  git-rebase-mode
                  erc-mode
                  circe-server-mode
                  circe-chat-mode
                  circe-query-mode
                  sauron-mode
                  term-mode))
    (add-to-list 'evil-emacs-state-modes mode)))

(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  :hook (after-init . evil-mode)
  :config
;  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal)
  ;; (setq evil-undo-system 'undo-fu)
  )

;; (use-package undo-fu
;;   :config
;;   (global-set-key (kbd "s-z") 'undo-fu-only-undo)
;;   (global-set-key (kbd "s-Z") 'undo-fu-only-redo))

(evil-mode 1)
(defun disable-evil-mode-in-doc-view ()
  ;; "Disable evil mode when entering doc-view-mode."
  (when (eq major-mode 'doc-view-mode)
    (evil-mode -1)))

(add-hook 'change-major-mode-hook 'disable-evil-mode-in-doc-view)
;; {{ specify major mode uses Evil (vim) NORMAL state or EMACS original state.
;; You may delete this setup to use Evil NORMAL state always.
(dolist (p '(fundamental-mode
	     custom-mode
             eshell-mode
             git-rebase-mode
             erc-mode
             circe-server-mode
             circe-chat-mode
             circe-query-mode
             sauron-mode
             term-mode))
	     	     
  (evil-set-initial-state p 'normal))
;; }}

;; (defun set-line-number-type-based-on-evil-state ()
;;   (setq display--line-numbers-type
;; 	(if (an))))

(defun my-evil-local-mode-hook ()
  (if evil-local-mode
     (setq display-line-numbers-type 'visual) 
    (setq display-line-numbers-type t)))

;; Add the hook to evil-local-mode
(add-hook 'evil-local-mode-hook 'my-evil-local-mode-hook)

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(setq doom-modeline-modal-icon nil)

(setq evil-normal-state-tag   (propertize "[Normal]" 'face '((:background "green" :foreground "black")))
      evil-emacs-state-tag    (propertize "[Emacs]" 'face '((:background "orange" :foreground "black")))
      evil-insert-state-tag   (propertize "[Insert]" 'face '((:background "red") :foreground "white"))
      evil-motion-state-tag   (propertize "[Motion]" 'face '((:background "blue") :foreground "white"))
      evil-visual-state-tag   (propertize "[Visual]" 'face '((:background "grey80" :foreground "black")))
      evil-operator-state-tag (propertize "[Operator]" 'face '((:background "purple"))))

(use-package evil-nerd-commenter
  :after evil
  :bind ("M-/" . evilnc-comment-or-uncomment-lines))

;; ******** Magit ********
(use-package magit
  :ensure t
  :init
  (message "Loading Magit!")
  :config
  (message "Loaded Magit!")
  :bind (("C-x g" . magit-status)
         ("C-x C-g" . magit-status)))

;; ******** Org Mode ********
(defun hanxic/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

(use-package org
  :hook (org-mode . hanxic/org-mode-setup)
  :config
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
	org-pretty-entities t)
  (setq org-agenda-start-with-log-mode t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  (setq org-todo-keywords
    '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
      (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))
  ;; Configure custom agenda views
  (setq org-agenda-custom-commands
   '(("d" "Dashboard"
     ((agenda "" ((org-deadline-warning-days 7)))
      (todo "NEXT"
        ((org-agenda-overriding-header "Next Tasks")))
      (tags-todo "agenda/ACTIVE" ((org-agenda-overriding-header "Active Projects")))))

    ("n" "Next Tasks"
     ((todo "NEXT"
        ((org-agenda-overriding-header "Next Tasks")))))

    ("W" "Work Tasks" tags-todo "+work-email")

    ;; Low-effort next actions
    ("e" tags-todo "+TODO=\"NEXT\"+Effort<15&+Effort>0"
     ((org-agenda-overriding-header "Low Effort Tasks")
      (org-agenda-max-todos 20)
      (org-agenda-files org-agenda-files)))

    ("w" "Workflow Status"
     ((todo "WAIT"
            ((org-agenda-overriding-header "Waiting on External")
             (org-agenda-files org-agenda-files)))
      (todo "REVIEW"
            ((org-agenda-overriding-header "In Review")
             (org-agenda-files org-agenda-files)))
      (todo "PLAN"
            ((org-agenda-overriding-header "In Planning")
             (org-agenda-todo-list-sublevels nil)
             (org-agenda-files org-agenda-files)))
      (todo "BACKLOG"
            ((org-agenda-overriding-header "Project Backlog")
             (org-agenda-todo-list-sublevels nil)
             (org-agenda-files org-agenda-files)))
      (todo "READY"
            ((org-agenda-overriding-header "Ready for Work")
             (org-agenda-files org-agenda-files)))
      (todo "ACTIVE"
            ((org-agenda-overriding-header "Active Projects")
             (org-agenda-files org-agenda-files)))
      (todo "COMPLETED"
            ((org-agenda-overriding-header "Completed Projects")
             (org-agenda-files org-agenda-files)))
      (todo "CANC"
            ((org-agenda-overriding-header "Cancelled Projects")
             (org-agenda-files org-agenda-files)))))))
  (setq org-refile-targets
	'(("Archive.org" :maxlevel . 1)
	  ("todolist.org" :maxlevel . 1)))
  ;; Save Org buffers after refiling!
  (advice-add 'org-refile :after 'org-save-all-org-buffers)
  (setq org-agenda-files
	'("~/things/todolist.org")))

(use-package org-bullets
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

(with-eval-after-load 'org-faces (dolist (face '((org-level-1 . 1.2)
                (org-level-2 . 1.1)
                (org-level-3 . 1.05)
                (org-level-4 . 1.0)
                (org-level-5 . 1.1)
                (org-level-6 . 1.1)
                (org-level-7 . 1.1)
                (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "Times New Roman" :weight 'regular :height (cdr face))))

(defun hanxic/org-mode-visual-fill ()
  (setq visual-fill-column-width 150 
	visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . hanxic/org-mode-visual-fill))

(setq org-capture-templates
      '(("t" "Tasks / Projects")
	("tt" "Task" entry (file+olp "~/things/todolist.org" "Inbox")
         "* TODO %?\n  %U\n  %a\n  %i" :empty-lines 1)
	))
(define-key global-map (kbd "C-c j")
  (lambda () (interactive) (org-capture nil "j")))

(with-eval-after-load 'org-faces (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch))
(with-eval-after-load 'org-faces (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch)))
(with-eval-after-load 'org-faces (set-face-attribute 'org-table nil :inherit '(shadow fixed-pitch)))
;; (with-eval-after-load 'org-faces (set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch)))
(with-eval-after-load 'org-faces (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch)))
(with-eval-after-load 'org-faces (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch)))
(with-eval-after-load 'org-faces (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch)))
(with-eval-after-load 'org-faces (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

;; (defmacro def-pairs (pairs)
;;   "Define functions for pairing. PAIRS is an alist of (NAME . STRING)
;; conses, where NAME is the function name that will be created and
;; STRING is a single-character string that marks the opening character.

;;   (def-pairs ((paren . \"(\")
;;               (bracket . \"[\"))

;; defines the functions WRAP-WITH-PAREN and WRAP-WITH-BRACKET,
;; respectively."
;;   `(progn
;;      ,@(loop for (key . val) in pairs
;;              collect
;;              `(defun ,(read (concat
;;                              "wrap-with-"
;;                              (prin1-to-string key)
;;                              "s"))
;;                   (&optional arg)
;;                 (interactive "p")
;;                 (sp-wrap-with-pair ,val)))))

;; (def-pairs ((paren . "(")
;;             (bracket . "[")
;;             (brace . "{")
;;             (single-quote . "'")
;;             (double-quote . "\"")
;;             (back-quote . "`")))

(defmacro def-pairs (pairs)
  `(progn
     ,@(cl-loop for (key . val) in pairs
		collect
		`(defun ,(read (concat
				"wrap-with-"
				(prin1-to-string key)
				"s"))
		     (&optional arg)
		   (interactive "p")
		   (sp-wrap-with-pair ,val)))))

(def-pairs ((paren . "(")
	    (bracket . "[")
	    (brace . "{")
	    (single-quote . "'")
	    (double-quote . "\"")
	    (back-quote . "``")))

(defun multiply-many (x &rest operands)
  (dolist (operand operands)
    (when operand
      (setq x (* x operand))))
  x)
;; Multiply any non-nil operands
(defun multiply-many (x &rest operands)
  (dolist (operand operands)
    (when operand
      (setq x (* x operand))))
  x)
(multiply-many 5)
(multiply-many 5 2)

(use-package smartparens-mode
  :ensure smartparens  ;; install the package
  :hook (prog-mode text-mode markdown-mode org-mode) ;; add `smartparens-mode` to these hooks
  :config
  ;; load default config
  (require 'smartparens-config)
  :bind
  (("C-(" . 'wrap-with-parens ) 
   ("C-{" . 'wrap-with-braces)
   ("M-)" . sp-unwrap-sexp)
   ("M-(" . sp-backward-unwrap-sexp)
   ("M-S-<right>" . sp-forward-slurp-sexp)
   ("M-S-<left>" . sp-forward-barf-sexp)
   ("C-S-<left>" . sp-backward-slurp-sexp)
   ("C-S-<right>" . sp-backward-barf-sexp)

  ))

(setq sp-pairs
      '((t
  (:open "\\\\(" :close "\\\\)" :actions
	 (insert wrap autoskip navigate))
  (:open "\\{" :close "\\}" :actions
	 (insert wrap autoskip navigate))
  (:open "\\(" :close "\\)" :actions
	 (insert wrap autoskip navigate))
  (:open "\\\"" :close "\\\"" :actions
	 (insert wrap autoskip navigate))
  (:open "\"" :close "\"" :actions
	 (insert wrap autoskip navigate escape)
	 :unless
	 (sp-in-string-quotes-p)
	 :post-handlers
	 (sp-escape-wrapped-region sp-escape-quotes-after-insert))
  ;; (:open "'" :close "'" :actions
  ;; 	 (insert wrap autoskip navigate escape)
  ;; 	 :unless
  ;; 	 (sp-in-string-quotes-p sp-point-after-word-p)
  ;; 	 :post-handlers
  ;; 	 (sp-escape-wrapped-region sp-escape-quotes-after-insert))
  (:open "(" :close ")" :actions
	 (insert wrap autoskip navigate))
  (:open "[" :close "]" :actions
	 (insert wrap autoskip navigate))
  (:open "{" :close "}" :actions
	 (insert wrap autoskip navigate))
  (:open "`" :close "`" :actions
	 (insert wrap autoskip navigate))))
)

(use-package undo-tree
  :ensure t
  :config
  (undo-tree-mode 1)
  (global-undo-tree-mode 1)
  :bind
  (("s-z" . undo-tree-undo)
   ("s-Z" . undo-tree-redo)))


;; ******** LaTeX ********

(dolist (hook '(text-mode-hook ))
  (add-hook hook (lambda () (flyspell-mode 1))))
(dolist (hook '(change-log-mode-hook log-edit-mode-hook))
  (add-hook hook (lambda () (flyspell-mode -1))))


(use-package tex 
  :ensure auctex
  :defer auctex
  :config
  ) 

(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)
(add-hook 'plain-TeX-mode-hook
          (lambda () (set (make-local-variable 'TeX-electric-math)
                          (cons "$" "$"))))


(use-package company-auctex
  )

(use-package yasnippet                  ; Snippets
  :ensure t
  :config
  (setq
   yas-verbosity 1                      ; No need to be so verbose
   yas-wrap-around-region t)

  (with-eval-after-load 'yasnippet
    (setq yas-snippet-dirs '(yasnippet-snippets-dir)))

  (yas-reload-all)
  (yas-global-mode))

(use-package yasnippet-snippets         ; Collection of snippets
  :ensure t)

(use-package latex-preview-pane)
(latex-preview-pane-enable)
;; ******** Company ********
;; (use-package company
;;   :config
;;   (setq company-idle-delay 0.3)
;;   (global-company-mode t))

(global-set-key (kbd "C-S-k") 'windmove-up)
(global-set-key (kbd "C-S-j") 'windmove-down)
(global-set-key (kbd "C-S-h") 'windmove-left)
(global-set-key (kbd "C-S-l") 'windmove-right)
;; (define-key evil-normal-state-map (kbd "C-o") 'evil-jump-forward)
;; (define-key evil-normal-state-map (kbd "C-S-o") 'evil-jump-backward)
(global-undo-tree-mode 1)
(save-place-mode 1)

;; ######## Programming Environment ######## 

;; ******** Markdown ********
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown"))


;;;
;;; miscellaneous
;;;
;; better naming of repeated buffers
(require 'uniquify)
(put 'upcase-region 'disabled nil)

;;;
;;; flyspell configuration
;;;
(autoload 'flyspell-mode "flyspell" "On-the-fly spelling checker." t)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)

;; ******** LLVM ********





;; ******** FlyCheck ********
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

;;;
;;; ocaml configuration
;;;
;; add opam emacs directory to the load-path
(setq opam-dir (substring (shell-command-to-string "opam config var prefix 2> /dev/null") 0 -1))
(setq opam-share (substring (shell-command-to-string "opam config var share 2> /dev/null") 0 -1))

(add-to-list 'load-path (concat opam-share "/emacs/site-lisp"))


(autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
(autoload 'camldebug "camldebug" "Run the Caml debugger" t)

;; make OCaml-generated files invisible to filename completion
(mapc #'(lambda (ext) (add-to-list 'completion-ignored-extensions ext))
  '(".aux" ".vo" ".cmo" ".cmx" ".cma" ".cmxa" ".cmi" ".cmxs" ".cmt" ".annot" ".byte" ".native"))

;; OCaml format
(require 'ocamlformat)
(add-hook 'tuareg-mode-hook (lambda ()
  (define-key tuareg-mode-map (kbd "C-M-<tab>") #'ocamlformat)))

(defun chomp (str)
      "Chomp leading and tailing whitespace from STR."
      (replace-regexp-in-string (rx (or (: bos (* (any " \t\n")))
                                        (: (* (any " \t\n")) eos)))
                                ""
                                str))

(defun pad-to-column (col pad)
  "Adds the character 'pad' from the current point to column 'col'."
  (interactive)
  (let (len)
    (setq len (- col (current-column)))
    (dotimes (i len)
      (insert pad))))
  
  
(defun dashes ()
  "Adds dashes from the current point to column 77"

  (interactive)
  (pad-to-column 77 "-"))

(defun ocaml-close-comment ()
  "Pads spaces and then inserts '*)' ending on column 80."

  (interactive)
  (pad-to-column 77 " ")
  (insert " *)"))
                                                                            

(defun ocaml-insert-header-string (str)
  "Inserts an ocaml comment header"
  (interactive)
  (insert "(* ")
  (insert (chomp str))
  (insert " ")
  (dashes)
  (insert " *)"))


;; nice comment formating for Ocaml
(defun ocaml-comment-header ()
  "Makes the current line into an beautiful OCaml comment header."

  (interactive)
  (let (p1 p2 theLine newLine)
    (setq p1 (line-beginning-position))
    (setq p2 (line-end-position))
    (setq theLine (buffer-substring-no-properties p1 p2))
    (setq newLine 
	  (with-temp-buffer
	    (insert theLine)
	    (goto-char (point-min))
	    (if (re-search-forward "^ *(\\* *\\([^-]*\\)-* *\\*) *" (point-max) t)
		(let (comment)
		  (setq comment (match-string 1))
		  (erase-buffer)
		  (ocaml-insert-header-string comment))
	      (progn
		(erase-buffer)
		(ocaml-insert-header-string theLine)))
	    (buffer-string)
	    ))
    (delete-region p1 p2)
    (insert newLine)
    (forward-line)
    (beginning-of-line)
    )
)



(defun ocaml-comment-footer ()
  "Adds a trailing '*)' (if needed) padded to column 80."

  (interactive)
  (let (p1 p2 theLine newLine)
    (setq p1 (line-beginning-position))
    (setq p2 (line-end-position))
    (setq theLine (buffer-substring-no-properties p1 p2))
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
	    (buffer-string)
	    ))
    (delete-region p1 p2)
    (insert newLine)
    (forward-line)
    (beginning-of-line)
    )
)

;; Major mode for OCaml programming
(use-package tuareg
  ;; :ensure t
  :mode (("\\.ocamlinit\\'" . tuareg-mode)))


;; Major mode for editing Dune project files
(use-package dune
  :ensure t)

;; Merlin provides advanced IDE features
(use-package merlin
  ;; :after company
  :ensure t
  :config
  (add-hook 'tuareg-mode-hook #'merlin-mode)
  (add-hook 'merlin-mode-hook #'company-mode)
  ;; we're using flycheck instead
  (setq merlin-error-after-save nil)
  (custom-set-faces
 '(merlin-type-face ((t (:background "#46484f"))))
 ))

;; (custom-set-faces
;;  '(merlin-type-face ((t (:background "#46484f"))))
;;  :when (eq 'dark (frame-parameter nil 'background-mode)))

(use-package merlin-eldoc
  :ensure t
  :hook ((tuareg-mode) . merlin-eldoc-setup))

;; This uses Merlin internally
(use-package flycheck-ocaml
  :ensure t
  :config
  (add-hook 'tuareg-mode-hook
            (lambda ()
              ;; disable Merlin's own error checking
              (setq-local merlin-error-after-save nil)
              ;; enable Flycheck checker
             (flycheck-ocaml-setup))))


;; coq
;; (load "~/.emacs.d/lisp/PG/generic/proof-site")
;; (add-hook 'proof-ready-for-assistant-hook (lambda () (show-paren-mode 0)))
 ;; Open .v files with Proof-General's coq-mode
(require 'proof-site "~/.emacs.d/lisp/PG/generic/proof-site")
(add-hook 'coq-mode-hook #'company-coq-mode)
     (add-to-list 'load-path
   "/Users/garychen/.opam/4.14.0/share/emacs/site-lisp")
;; (add-hook 'coq-mode-hook #'undo-tree-mode)

;; ******** Haskell ********
(use-package haskell-mode)
(use-package hlint-refactor
  :after (haskell-mode)
  :hook (hlint-refactor-mode . haskell-mode-hook))
(use-package flycheck-haskell
  :after (flycheck haskell-mode)
  ) 
(use-package lsp-haskell
  :after (lsp-mode))


;; ******** LSP ********
(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         ((haskell-mode tuareg-mode) . lsp)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp )

;; optionally
(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :commands lsp-ui-mode
  )
;; if you are helm user
(use-package helm-lsp :commands helm-lsp-workspace-symbol)
;; if you are ivy user


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(coq-compiler "coqc")
 '(coq-one-command-per-line nil)
 '(coq-prog-name "coqtop")
 '(coq-script-indent nil)
 '(coq-unicode-tokens-enable nil)
 '(helm-minibuffer-history-key "M-p")
 '(package-selected-packages
   '(ocaml-lsp lsp-haskell helm-lsp lsp-ui lsp-mode flycheck-haskell hlint-refactor tree-sitter-indent tree-sitter-langs helm-tree-sitter tree-sitter markdown-mode latex-preview-pane yasnippet-snippets company-auctex auctex undo-tree smartparens visual-fill-column org-bullets evil-nerd-commenter evil-magit evil-collection helpful which-key rainbow-delimiters doom-themes command-log-mode use-package tuareg treemacs-tab-bar treemacs-projectile treemacs-persp treemacs-magit treemacs-icons-dired treemacs-evil restart-emacs proof-general powerline ocp-indent ocamlformat merlin-eldoc helm-rg helm-projectile helm-ag haskell-mode flycheck-ocaml dune dracula-theme company-coq beacon auto-complete))
 '(proof-disappearing-proofs nil)
 '(proof-general-debug nil)
 '(proof-layout-windows-on-visit-file t)
 '(proof-script-fly-past-comments t)
 '(proof-splash-enable nil)
 '(proof-three-window-mode-policy 'hybrid)
 '(proof-toolbar-enable nil)
 '(save-place-mode t)
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(uniquify-buffer-name-style 'forward nil (uniquify))
 '(visual-line-mode nil t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(merlin-type-face ((t (:background "#46484f")))))
