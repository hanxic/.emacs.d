;; -*- lexical-binding: t; -*-

;;; Package -- summary
;; Packeages that I want to install
;; use-package
;; display line number (functionality)
;; projectile
;; helm - 1. helm 2. helm-projectile 4. helm-rg
;; theme?
;; nerd-icons? all-the-icons?
;; doom-modeline? for fixing the mode line
;; rainbow-delimiters - maybe make this optional???
;; white-key
;; helpful - for help buffer
;;
;; -------- Editing --------
;; evil-mode
;; magit
;; org-mode - wait till tomorrow
;; org-bullets - probably not? just design some yourself
;; parenthesis stuff - a. smartparen 2. paredit 3. electric-pair
;; undo-tree - I don't think I need this anymore

;; -------- Languages --------
;; latex - tbd
;; ocaml
;; lsp-mode/
;;

;;; Commentary:

;;; Code:

(require 'server)
(unless (server-running-p)
  (server-start))


(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)
;; Refresh if needed
(unless package-archive-contents
  (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;; Mode line
(setq inhibit-startup-message t
      column-number-mode t
      line-number-mode t
      )

;;; File Backup
(setq backup-directory-alist `(("." . ,(expand-file-name "backup" user-emacs-directory)))
      delete-old-versions t
      kept-old-versions 1
      kept-new-versions 2
      backup-by-copying t
      version-control t
      )

;;; Line number
(global-display-line-numbers-mode t)
(dolist (mode '(org-mode-hook
		term-mode-hook
		eshell-mode-hook
		shell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))
(setq display-line-numbers-type 'visual)

;;; Fill column indicator
(setq-default display-fill-column-indicator-column 80)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)
(add-hook 'after-change-major-mode-hook
	  (lambda ()
	    (setq display-fill-column-indicator-column 80)))

;;; Miscellaneous
(global-hl-line-mode 1) ; highlight current line
(scroll-bar-mode -1)    ; Disable visible scrollbar
(tool-bar-mode -1)      ; Disable tool bar
(tooltip-mode -1)       ; Disable tooltips
(set-fringe-mode 7)     ; Give some breathing room
(menu-bar-mode -1)      ; Disable the menu bar
(save-place-mode 1)
(setq save-place-file "~/.emacs.d/saveplace")
(put'upcase-region 'disabled nil)

;; Command log mode for showing the event history
(use-package command-log-mode
  :defer 10)

;;; Self-defined functions
(defun hanxic/indent-for-tab-command ()
  "Run indent-for-tab-command but key point at the same column."
  (interactive)
  (let ((col (current-column)))
    (indent-for-tab-command)
    (move-to-column col))
  )

;;; Helm
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
  (require 'helm-command)
  :custom
  (helm-M-x-show-short-doc t)
  (helm-M-x-requires-pattern 0))

;;; Projectile

(use-package projectile
  :ensure t
  :config
  (projectile-mode)
  (setq projectile-enable-caching t
	projectile-indexing-method 'alien)
  )

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

;;; Helm-rg
(use-package helm-rg
  :ensure t
  :commands (helm-rg)
  :config(custom-set-faces
	  '(helm-rg-file-match-face ((t (:extend t :foreground "BlueViolet" :underline t))))))

;;; Emacs Theme
(use-package ef-themes
  :config
  (setq ef-themes-to-toggle '(ef-summer ef-winter))
  ;; (setq ef-themes-mixed-fonts nil
  ;; 	ef-themes-variable-pitch-ui t)
  ;; (mapc #'disable-theme custom-enabled-themes)
  (ef-themes-select 'ef-winter)
  )

;;; Icons
(use-package nerd-icons
  ;; :custom
  ;; The Nerd Font you want to use in GUI
  ;; "Symbols Nerd Font Mono" is the default and is recommended
  ;; but you can use any other Nerd Font if you want
  ;; (nerd-icons-font-family "Symbols Nerd Font Mono")
  )

;;; VC mode
(setq vc-handled-backends '(Git))

;;; Modeline
(use-package telephone-line
  :config
  (setq telephone-line-lhs
      '((evil   . (telephone-line-evil-tag-segment))
        (accent . (telephone-line-vc-segment
                   telephone-line-erc-modified-channels-segment
                   telephone-line-process-segment))
        (nil .    (telephone-line-projectile-segment
                   telephone-line-buffer-segment))))
  (setq telephone-line-rhs
      '((nil    . (telephone-line-misc-info-segment))
        (accent . (telephone-line-major-mode-segment))
        (evil   . (telephone-line-airline-position-segment))))
  (telephone-line-mode 1))

;;; Helpful
(use-package helpful
  :bind
  ([remap describe-key] . helpful-key)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-function] . helpful-callable)
  ([remap describe-command] . helpful-command)
  ("C-c C-d" . helpful-at-point)
  ("C-h F" . helpful-function)
  )

;;; Which-key
(use-package which-key
  :diminish which-key-mode
  :config
  (setq which-eky-idle-delay 0.3)
  (which-key-mode))


;;; Magit
(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)
         ("C-x C-g" . magit-status)))

;;; Evil Mode
;;;; Evil
(use-package evil
  :init
  (setq evil-want-integration t
	evil-want-keybinding nil
	evil-want-C-d-scroll t
	evil-want-C-u-scroll t
	evil-want-C-i-jump t)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)
  (evil-global-set-key 'normal (kbd "TAB") #'hanxic/indent-for-tab-command)
  (evil-global-set-key 'visual (kbd "TAB") #'hanxic/indent-for-tab-command)
  (evil-set-initial-state 'message-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal)
  )
(defun hanxic/evil-visual-indent-right-1 ()
  "Indent selected region by 1 space to the right."
  (interactive)
  (when (use-region-p)
    (indent-rigidly (region-beginning) (region-end) 1)
    (evil-visual-restore)))

(defun hanxic/evil-visual-indent-left-1 ()
  "Indent selected region by 1 space to the left."
  (interactive)
  (when (use-region-p)
    (indent-rigidly (region-beginning) (region-end) -1)
    (evil-visual-restore)))
(define-key evil-visual-state-map (kbd "S-<right>") 'hanxic/evil-visual-indent-right-1)
(define-key evil-visual-state-map (kbd "S-<left>") 'hanxic/evil-visual-indent-left-1)

;; Disable evil mode when entering doc-view-mode
(defun hanxic/disable-evil-mode-in-doc-view ()
  (when (eq major-mode 'doc-view-mode)
    (evil-mode -1)))
;; Add the hook to evil-local-mode
(add-hook 'change-major-mode-hook 'hanxic/disable-evil-mode-in-doc-view)

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

(define-key isearch-mode-map (kbd "<down>") 'isearch-ring-advance)
(define-key isearch-mode-map (kbd "<up>") 'isearch-ring-retreat)

;; Evil-collection
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Evil Mode Line
(setq evil-normal-state-tag   (propertize "[Normal]" 'face '((:background "green" :foreground "black")))
      evil-emacs-state-tag    (propertize "[Emacs]" 'face '((:background "orange" :foreground "black")))
      evil-insert-state-tag   (propertize "[Insert]" 'face '((:background "red") :foreground "white"))
      evil-motion-state-tag   (propertize "[Motion]" 'face '((:background "blue") :foreground "white"))
      evil-visual-state-tag   (propertize "[Visual]" 'face '((:background "grey80" :foreground "black")))
      evil-operator-state-tag (propertize "[Operator]" 'face '((:background "purple"))))

;; evil commenter
(use-package evil-nerd-commenter
  :after evil
  :bind ("M-;" . evilnc-comment-or-uncomment-lines))

;;; Uniquify
(require 'uniquify)

;;; Spelling
(use-package ispell
  :config
  (setq ispell-program-name "aspell")
  (setq ispell-dictionary "english")
  
  )
(add-hook 'text-mode-hook 'flyspell-mode)

;; ;;; Checking
(use-package flycheck
  :ensure t
  :config
  (global-flycheck-mode)
  :bind (:map flycheck-mode-map
              ("C-c C-j n" . flycheck-next-error)
              ("C-c C-j p" . flycheck-previous-error)))

;;; Undo-fu
(use-package undo-fu
  :ensure t
  :config
  (global-unset-key (kbd "s-z"))
  (global-set-key (kbd "s-z")   'undo-fu-only-undo)
  (global-set-key (kbd "s-Z") 'undo-fu-only-redo))

;;; Customization
(defun hanxic/elisp-highlight-section ()
  "Make comments starting with ';;;' appear larger."
(font-lock-add-keywords
   nil
   '((";;;\\([^;].*\\)"   ;; ;;;
      1 '(:weight bold :height 1.3 :foreground "Orange") t)
     (";;;;\\([^;].*\\)"  ;; ;;;;
      1 '(:weight bold :height 1.1 :foreground "LightSkyBlue") t))))
(add-hook 'emacs-lisp-mode-hook 'hanxic/elisp-highlight-section)

(set-face-attribute 'default nil :font "Iosevka-12")

;;; Company
(use-package company
  :ensure t
  :hook (afer-init . global-company-mode)
  :config
  (setq company-idle-delay 1))

;;; Org mode
;; (add-hook 'org-mode-hook #'turn-on-auto-fill)
;; (setq-default fill-column 80)
(use-package org
  :init
  (setq-default fill-column 80)
  :hook (org-mode . turn-on-auto-fill)
  :custom
  (org-highlight-latex-and-related '(latex))
  (org-use-sub-superscripts '{})
  (org-export-with-LaTeX-fragments t)
  (org-latex-create formula-image-program 'dvipng)
  :config
  (setq org-format-latex-options
      '(:foreground "Black"
        :background "White"
        :scale 1.2           ; increase this to make math bigger
        :html-foreground "Black"
        :html-background "White"
        :html-scale 1.5
        :matchers ("begin" "$1" "$" "\\(" "\\[")))
  (use-package org-fragtog
    :ensure t
    :hook (org-mode . org-fragtog-mode))
  )


;;; Latex
(use-package auctex
  :ensure t
  :defer t
  :mode ("\\.tex\\'" . latex-mode))
(dolist (hook '(text-mode-hook ))
  (add-hook hook (lambda () (flyspell-mode 1))))
(dolist (hook '(change-log-mode-hook log-edit-mode-hook))
  (add-hook hook (lambda () (flyspell-mode -1))))


(use-package tex 
  :ensure auctex
  :defer auctex
  ) 

(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)
(add-hook 'plain-TeX-mode-hook
          (lambda () (set (make-local-variable 'TeX-electric-math)
                          (cons "$" "$"))))


(use-package company-auctex
  :defer auctex
  )
(company-auctex-init)

(add-hook 'TeX-mode-hook
	  'company-mode)

(use-package yasnippet                  ; Snippets
  :ensure t
  :defer tex
  :config
  (setq
   yas-verbosity 1                      ; No need to be so verbose
   yas-wrap-around-region t)

  (with-eval-after-load 'yasnippet
    (setq yas-snippet-dirs '(yasnippet-snippets-dir)))

  (yas-reload-all)
  (yas-global-mode))

(use-package yasnippet-snippets         ; Collection of snippets
  :ensure t
  :defer yasnippet)

(setq LaTeX-item-indent 0)
(add-hook 'TeX-mode-hook 'turn-on-auto-fill)
(setq TeX-open-quote "\"")
(setq TeX-close-quote "\"")
(add-hook 'TeX-mode-hook
          (lambda () (set (make-local-variable 'TeX-electric-math)
                          (cons "$" "$"))))
(add-hook 'TeX-mode-hook
          (lambda () (set (make-local-variable 'TeX-electric-math)
                          (cons "\\(" "\\)"))))
(setq LaTeX-includegraphics-read-file 'LaTeX-includegraphics-read-file-relative)

;; ;;; LSP mode
(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         ((haskell-mode tuareg-mode) . lsp)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp
  :custom
  (lsp-completion-auto-delay 1)
  (lsp-eldoc-render-all t)
  ;; (lsp-idle-delay 3)
  (lsp-inlay-hint-enable t)
  :config
  (setq lsp-file-watch-ignored-directories
        '("[/\\\\]\\.git$"
          "[/\\\\]\\.github$"
          "[/\\\\]node_modules$"
          "[/\\\\]_target$"
          "[/\\\\]build$"
          "[/\\\\]\\.direnv$"
          "[/\\\\]\\.devcontainer$"
          "[/\\\\]\\.docker$"
          "[/\\\\]\\.lake$"
          "[/\\\\]\\.vscode$"
        ))
  )
(defun hanxic/cleanup-lsp ()
  "Remove all the workspace folders from LSP"
  (interactive)
  (let ((folders (lsp-session-folders (lsp-session))))
    (while folders
      (lsp-workspace-folders-remove (car folders))
      (setq folders (cdr folders)))))

(setq gc-cons-threshold 1280000)
(setq read-process-output-max (* 1024 1024)) ;; 1mb
(setq lsp-log-io nil)

;; optionally
(use-package lsp-ui
  :ensure t
  :hook (lsp-mode . lsp-ui-mode)
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover t
        lsp-ui-sideline-show-code-actions t)
  )
;; if you are helm user
(use-package helm-lsp :commands helm-lsp-workspace-symbol)

;;; Language-specific Configuration
;;;; Treesit
(require 'treesit)
(add-to-list 'treesit-language-source-alist
             '(lean "https://github.com/Julian/tree-sitter-lean.git"))
;;;; Rocq
(use-package proof-general
  :init
  (setq proof-splash-enable nil
	      proof-toolbar-enable nil
	      proof-disappearing-proofs nil
	      proof-general-debug nil)
  :mode ("\\.v\\'" . coq-mode))

(setq
 coq-compiler "coqc"
 coq-one-command-per-line nil
 coq-prog-name "coqtop"
 coq-script-indent nil
 coq-unicode-tokens-enable nil)
;; company
(use-package company-coq
  :hook (coq-mode . company-coq-mode))

;;;; Haskell
(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :ensure t
  :defer t
  :hook
  (haskell-mode . interactive-haskell-mode))
(use-package hlint-refactor
  :after (haskell-mode)
  :hook (hlint-refactor-mode . haskell-mode-hook))
(use-package flycheck-haskell
  :after (flycheck haskell-mode)) 
(use-package lsp-haskell
  :after (lsp-mode haskell-mode)
  :config
  (setq lsp-haskell-server-path "~/.ghcup/bin/haskell-language-server-wrapper"))

;;;; HTML, CSS, JavaScript
(use-package web-mode
  :ensure t
  :mode
  (("\\.html?\\'" . web-mode)
   ("\\.phtml\\'" . web-mode)
   ("\\.php\\'" . web-mode)
   ("\\.tpl\\'" . web-mode)
   ("\\.[agj]sp\\'" . web-mode)
   ("\\.as[cp]x\\'" . web-mode)
   ("\\.erb\\'" . web-mode)
   ("\\.mustache\\'" . web-mode)
   ("\\.djhtml\\'" . web-mode)))

;;;; OCaml
;; ## added by OPAM user-setup for emacs / base ## 56ab50dc8996d2bb95e7856a6eddb17b ## you can edit, but keep this line
(require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
;; ## end of OPAM user-setup addition for emacs / base ## keep this line
;;;
;;;; ocaml configuration
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
(use-package ocamlformat
  :ensure t
  )
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
(add-to-list 'auto-mode-alist '("\\.mlg$"      . tuareg-mode) t)
;; (custom-set-faces
;;  '(merlin-type-face ((t (:background "#46484f"))))
;;  :when (eq 'dark (frame-parameter nil 'background-mode)))

;; (use-package merlin-eldoc
;;   :ensure t
;;   :hook ((tuareg-mode) . merlin-eldoc-setup))

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

(let ((opam-share (ignore-errors (car (process-lines "opam" "var" "share")))))
  (when (and opam-share (file-directory-p opam-share))
    (add-to-list 'load-path (expand-file-name "emacs/site-lisp" opam-share))))
(require 'caml)
;; automatically activate caml-mode when eidting .ml, .mli, .mly, .mll
(add-to-list 'auto-mode-alist '("\\.ml[yl]+$" . tuareg-menhir-mode))


;;;; Lean
;; lean4-mode require Dash
(use-package dash
  :ensure t)
;; (use-package lean4-mode
;;   :ensure t
;;   :commands lean4-mode
;;   :vc (:url "https://github.com/leanprover-community/lean4-mode.git"
;;        :rev :last-release
;;        ;; Or, if you prefer the bleeding edge version of Lean4-Mode:
;;        ;; :rev :newest
;;        )
;;   :mode ("\\.lean\\'" . lean4-mode)
;;   :config
;;   (setq lean4-lsp-file-watch-ignored
;;         '(".git" "_target" ".lake" "build"))
;;   :bind
;;   (:map lean4-mode-map
;;         ("C-c C-d" . lsp-describe-thing-at-point)))

;; (add-to-list 'load-path "~/projects/lean-self/lean4-mode/")
(use-package lean4-mode
  :load-path "~/projects/lean-self/lean4-mode/"
  :config
  (require 'lean4-ghost)
  (add-to-list 'auto-mode-alist '("\\.lean\\'" . lean4-mode)))
;; (add-to-list 'auto-mode-alist '("\\.lean\\'" . lean4-mode))
;; (require 'lean4-ghost)

;; (add-to-list 'major-mode-remap-alist
;;              '(lean4-mode . lean4-ts-mode))

;; (add-hook 'lean4-mode-hook
;;           (lambda ()
;;             (require 'lean4-ghost)
;;             (lean4-ghost-mode 1)))

;;; More Miscellaneous
(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)
(setq web-mode-markup-indent-offset 2)
(setq web-mode-css-indent-offset 2)
(setq web-mode-code-indent-offset 2)

;;; Copilot
(add-to-list 'exec-path "/opt/homebrew/bin")
(setenv "PATH" (concat "/opt/homebrew/bin:" (getenv "PATH")))

(use-package copilot
  :vc (:url "https://github.com/copilot-emacs/copilot.el"
            :rev :newest
            :branch "main")
  :defer t
  :config
  (define-key copilot-completion-map (kbd "C-<tab>") 'copilot-accept-completion)
  (define-key copilot-completion-map (kbd "C-TAB") 'copilot-accept-completion))

;;; More Customization
;;;; Overleaf functionality
(setq compilation-scroll-output t)

(defun hanxic/compile-with-callbacks (command on-success on-failure)
  "Run COMMAND with `compile`.
   If compilation succeeds, call ON-SUCCESS (a no-arg function).
   If compilation exits abnormally, call ON-FAILURE (a no-arg function).
   If compilation was killed, do nothing."
  (let ((done nil)) ;; guard so callbacks fire only once
    (cl-labels
        ((handler (buf msg)
           (unless done
             (setq done t)
             (remove-hook 'compilation-finish-functions #'handler)
             (cond
              ((string-match "finished" msg)
               (funcall on-success))
              ((string-match "killed" msg)
               (message "Compilation was killed; ignoring."))
              (t
               (funcall on-failure))))))
      ;; add-hook must be inside cl-labels
      (add-hook 'compilation-finish-functions #'handler)
      (compile command))))

(defun hanxic/funcall-after-delay-focus (seconds on-focus)
  "Wait SECONDS, then switch to *compilation* and kill it."
  (run-at-time seconds nil
               (lambda ()
                 (when (fboundp 'ns-do-applescript)
                   (ns-do-applescript "tell application \"Emacs\" to activate")
                   (message "AppleScript called to bring Emacs to front.")
                   (funcall on-focus)))))

(defun hanxic/invoke-funcall-window (windowname on-focus)
  "get the window from `WINDOWNAME`, then call on-focus"
  (let ((window (get-buffer-window windowname)))
    (when (window-live-p window)
      (funcall on-focus window))))


;; (hanxic/invoke-funcall-window "*scratch*" #'delete-window)

(defun hanxic/suffix-conversion (filename suffix)
  "Return the PDF filename corresponding to the LaTeX FILENAME."
  (concat (file-name-sans-extension filename) suffix))

(defun hanxic/latex-make (&rest _args)
  "Run `make` on saving a LaTeX file, or normal `latexmk`, in overleaf style."
  (interactive)
  (when (and buffer-file-name
             (derived-mode-p 'latex-mode 'LaTeX-mode))
    (let ((default-directory (file-name-directory buffer-file-name))
          (make-cmd
           (format
            "make -k && open %s"
            (hanxic/suffix-conversion buffer-file-name ".pdf")))
          (latexmk-cmd
           (format
            "latexmk -pdf && open %s"
            (hanxic/suffix-conversion buffer-file-name ".pdf"))))
      (message "Running make for %s..." buffer-file-name)

      ;; Step 1: run make
      (hanxic/compile-with-callbacks
       ;; "make -k"
       make-cmd
       ;; make success
       (lambda ()
         (hanxic/funcall-after-delay-focus
          1
          (lambda ()
            (hanxic/invoke-funcall-window "*compilation*" #'delete-window))))
       ;; make failure
       (lambda ()
         ;; Step 2: run latexmk
         (message "Make failed, running latexmk...")
         (hanxic/compile-with-callbacks
          ;; "latexmk -pdf"
          latexmk-cmd
          ;; latexmk success
          (lambda ()
            (hanxic/funcall-after-delay-focus
             1
             (lambda ()
               (hanxic/invoke-funcall-window "*compilation*" #'delete-window))))
          ;; latexmk failure
          (lambda ()
            (hanxic/funcall-after-delay-focus
             1
             (lambda ()
               (hanxic/invoke-funcall-window "*compilation*" #'select-window))))))))))

(defvar latex-save-mode--default-enabled t
  "Whether `latex-save-mode` shouldstart enabled the first time in a LaTeX buffer.
   This variable tracks the user's choice after the first toggle.")

;;;###autoload
(define-minor-mode latex-save-mode
  "Toggle Latex Save Mode.
   When enabled, run latex-make on saving LaTeX files.
   Only valid in LaTeX buffers."
  :lighter "LaTeX-Save"
  :global nil
  (if latex-save-mode
      ;; ON Branch
      (progn
        (message "latex-save-mode enabled")
        (add-hook 'after-save-hook #'hanxic/latex-make))
    ;; OFF branch
    (progn
      (message "latex-save-mode disabled")
      (remove-hook 'after-save-hook #'hanxic/latex-make))))

(defun latex-save-mode--auto-enable ()
  "Enable or respect `latex-save-mode` in LaTeX buffers."
  (when (derived-mode-p 'latex-mode 'LaTeX-mode)
    ;; If the mode hasn't been explicitly toggled, enable it by default
    (unless (bound-and-true-p latex-save-mode)
      (when latex-save-mode--default-enabled
        (latex-save-mode 1)))))

;; Hook into LaTeX buffers
(add-hook 'latex-mode-hook #'latex-save-mode--auto-enable)
(add-hook 'LaTeX-mode-hook #'latex-save-mode--auto-enable)

;; Track user choice (so toggling persists during the session)
(defun latex-save-mode--remember-choice ()
  (setq latex-save-mode--default-enabled latex-save-mode))

(add-hook 'latex-save-mode-hook #'latex-save-mode--remember-choice)





(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(helm-minibuffer-history-key "M-p")
 '(package-selected-packages nil)
 '(warning-suppress-log-types '((lsp-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(merlin-type-face ((t (:background "#46484f")))))

(provide 'init)
;;; init.el ends here
