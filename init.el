;;; Package -- summary  -*- lexical-binding: t; -*-
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

(defvar hanxic/personal-map
  (make-sparse-keymap)
  "Personal prefix keymap.")

(global-set-key (kbd "C-c p") hanxic/personal-map)


(defun my/apply-font (&optional frame)
  (with-selected-frame (or frame (selected-frame))
    (set-face-attribute 'default nil :font "Iosevka-12")))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/apply-font)
  (my/apply-font))

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
(setq use-package-compute-statistics t)
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
;; (use-package command-log-mode
;;   :bind (("C-c p c" . clm/toggle-command-log-buffer))
;;   :config
;;   (global-unset-key (kbd "C-c o"))
;;   )

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

(defvar hanxic/personal-helm-map
  (make-sparse-keymap)
  "Personal preview commands.")

(define-key hanxic/personal-map (kbd "h") hanxic/personal-helm-map)

(use-package helm-projectile
  :ensure t
  :commands (helm-projectile helm-projectile-switch-project helm-projectile-ag helm-projectile-rg helm-projectile-grep)
  :bind (("C-c p h h" . helm-projectile)
         ("C-c p h p" . helm-projectile-switch-project)
         ("C-c p h r" . helm-projectile-rg)
         ("C-c p h a" . helm-projectile-ag)
         ("C-c p h g" . helm-projectile-grep)
         ("C-c p h o" . helm-projectile-find-other-file))
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
  (ef-themes-select 'ef-summer)
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
  :init
  :config
  (setq evil-collection-mode-list
        (remove 'flycheck evil-collection-mode-list))
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
  :hook ((prog-mode . flycheck-mode)
         (LaTeX-mode . flycheck-mode)))
  ;; :config
  ;; (global-flycheck-mode)
  ;; :bind (:map flycheck-mode-map
  ;;             ("C-c C-j n" . flycheck-next-error)
  ;;             ("C-c C-j p" . flycheck-previous-error)))
(with-eval-after-load 'flycheck
  (define-key flycheck-mode-map (kbd "C-c C-j n") #'flycheck-next-error)
  (define-key flycheck-mode-map (kbd "C-c C-j p") #'flycheck-previous-error))

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
(add-to-list 'load-path (concat user-emacs-directory "lisp"))
(require 'org-setup)


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
  :after auctex
  :config
  (setq
   TeX-source-correlate-mode t
   TeX-source-correlate-start-server t
   TeX-command-extra-options "-synctex=1"
   TeX-view-program-selection '((output-pdf "Skim"))
   TeX-view-program-list '(("Skim" "/Applications/Skim.app/Contents/SharedSupport/displayline -b -g %n %o %b"))
   TeX-show-compilation t
   TeX-scroll-buffer t
   )
  ) 

(require 'project)

(with-eval-after-load 'tex
  ;; --- 1) Define a runner that executes MAKE from the project root ---
  (defun my/TeX-run-make-at-project-root (name command file)
    "Run make from the project root (project.el), falling back to current dir."
    (let* ((proj (project-current nil))
           (root (when proj (project-root proj)))
           ;; (default-directory (or root default-directory))
           )
      ;; (setq TeX-master ".")
      (message "proj = %s" proj)
      (message "root = %s" root)
      (message "default-directory = %s" default-directory)
      (TeX-run-compile name command file)))

  ;; --- 2) (Optional but recommended) Register LatexMk as well ---
  ;; Comment this out if you don't use latexmk.
  (add-to-list 'TeX-command-list
               '("LatexMk" "latexmk -pdf -synctex=1 %s"
                 TeX-run-compile nil t))

  ;; --- 3) Register Make as a TeX command (so AUCTeX knows about it) ---
  ;; This makes "Make" show up in the C-c C-c menu, and lets it be the default.
  (setq TeX-command-list
        (assq-delete-all "Make" TeX-command-list))
  (push '("Make" "make" my/TeX-run-make-at-project-root nil t) TeX-command-list)

  (setq Tex-command-default "Make")
  ;; --- 4) Conditional default command per buffer ---
  (defun my/TeX-set-default-command ()
    "If project root has Makefile, default to Make; else default to LaTeX (or LatexMk)."
    (let* ((proj (project-current nil))
           (root (when proj (project-root proj)))
           (has-makefile (and root (file-exists-p (expand-file-name "Makefile" root)))))
      (setq-local TeX-command-default
                  (if has-makefile
                      "Make"
                    ;; choose ONE:
                    ;; "LaTeX"
                    "LatexMk"))))

  (add-hook 'LaTeX-mode-hook #'my/TeX-set-default-command))

(setq compilation-scroll-output t)

(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
;; (setq-default TeX-master nil)
(add-hook 'plain-TeX-mode-hook
          (lambda () (set (make-local-variable 'TeX-electric-math)
                          (cons "$" "$"))))


(use-package company-auctex
  :after auctex
  :hook (LaTeX-mode . company-auctex-init)
  )

(use-package yasnippet                  ; Snippets
  :ensure t
  :commands yas-minor-mode
  :hook ((prog-mode . yas-minor-mode))
  :init
  (setq
   yas-verbosity 1                      ; No need to be so verbose
   yas-wrap-around-region t))

  ;; (with-eval-after-load 'yasnippet
  ;;   (setq yas-snippet-dirs '(yasnippet-snippets-dir)))

  ;; (yas-reload-all)
  ;; (yas-global-mode))

(use-package yasnippet-snippets         ; Collection of snippets
  :ensure t
  :after yasnippet)

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
;; (setq opam-dir (substring (shell-command-to-string "opam config var prefix 2> /dev/null") 0 -1))
;; (setq opam-share (substring (shell-command-to-string "opam config var share 2> /dev/null") 0 -1))
(let ((prefix (string-trim (shell-command-to-string "opam config var prefix 2> /dev/null"))))
  (setq opam-dir (if (> (length prefix) 0) prefix nil)))
(let ((share (string-trim (shell-command-to-string "opam config var share 2> /dev/null"))))
  (setq opam-share (if (> (length share) 0) share nil)))

(add-to-list 'load-path (concat opam-share "/emacs/site-lisp"))


(autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
(autoload 'camldebug "camldebug" "Run the Caml debugger" t)

;; make OCaml-generated files invisible to filename completion
(mapc #'(lambda (ext) (add-to-list 'completion-ignored-extensions ext))
  '(".aux" ".vo" ".cmo" ".cmx" ".cma" ".cmxa" ".cmi" ".cmxs" ".cmt" ".annot" ".byte" ".native"))

;;; OCaml format
(use-package ocamlformat
  :ensure t
  :defer t
  :hook
  (tuareg-mode
   . (lambda ()
       (define-key tuareg-mode-map (kbd "C-M-<tab>") #'ocamlformat))))

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
  :ensure t
  :mode ("dune\\'" . dune-mode))

;; Merlin provides advanced IDE features
(use-package merlin
  ;; :after company
  :ensure t
  :defer t
  :hook ((tuareg-mode . merlin-mode)
         (merlin.mode . company-mode))
  :init
  (setq merlin-error-after-save nil)
  :config
  (custom-set-faces
 '(merlin-type-face ((t (:background "#46484f"))))
 ))
(add-to-list 'auto-mode-alist '("\\.mlg$"      . tuareg-mode) t)

;; This uses Merlin internally
(use-package flycheck-ocaml
  :ensure t
  :after flycheck
  :hook
  (tuareg-mode . (lambda ()
                   (setq-local merlin-error-after-save nil)
                   (flycheck-ocaml-setup))))

(let ((opam-share (ignore-errors (car (process-lines "opam" "var" "share")))))
  (when (and opam-share (file-directory-p opam-share))
    (add-to-list 'load-path (expand-file-name "emacs/site-lisp" opam-share))))
(require 'caml)
;; automatically activate caml-mode when eidting .ml, .mli, .mly, .mll
(add-to-list 'auto-mode-alist '("\\.ml[yl]+$" . tuareg-menhir-mode))


;;;; Lean
;; lean4-mode require Dash
;; (use-package dash
;;   :ensure t)
;; (use-package lean4-mode
;;   :load-path "~/projects/lean-self/lean4-mode/"
;;   :config
;;   (require 'lean4-ghost)
;;   (add-to-list 'auto-mode-alist '("\\.lean\\'" . lean4-mode)))

;; (use-package nael-autoloads
;;   :load-path "~/projects/lean-self/nael"
;;   )

(add-to-list 'load-path "~/projects/lean-self/nael/nael")
(add-to-list 'load-path "~/projects/lean-self/nael/nael-lsp")
(require 'info)
(info-initialize)
(add-to-list 'Info-directory-list "~/projects/lean-self/nael/nael")
(require 'nael-autoloads)
(add-hook 'nael-mode-hook #'abbrev-mode)
(add-hook 'nael-mode-hook #'eglot-ensure)

;; (use-package nael-lsp-autoloads
;;   :load-path "~/projects/lean-self/nael"
;;   )


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

(defun hanxic/latex-make ()
  "Run `make` on the file if there is a make on the project root"
  (when-let ((root (locate-dominating-file default-directory "Makefile")))
    (let ((default-directory root))
      (compile "make"))))

;; (defun hanxic/latex-make (&rest _args)
;;   "Run `make` on saving a LaTeX file, or normal `latexmk`, in overleaf style."
;;   (interactive)
;;   (when (and buffer-file-name
;;              (derived-mode-p 'latex-mode 'LaTeX-mode))
;;     (let ((default-directory (file-name-directory buffer-file-name))
;;           (make-cmd
;;            (format
;;             "make -k && open %s"
;;             (hanxic/suffix-conversion buffer-file-name ".pdf")))
;;           (latexmk-cmd
;;            (format
;;             "latexmk -xelatex -pdf && open %s"
;;             (hanxic/suffix-conversion buffer-file-name ".pdf"))))
;;       (message "Running make for %s..." buffer-file-name)

;;       ;; Step 1: run make
;;       (hanxic/compile-with-callbacks
;;        ;; "make -k"
;;        make-cmd
;;        ;; make success
;;        (lambda ()
;;          (hanxic/funcall-after-delay-focus
;;           1
;;           (lambda ()
;;             (hanxic/invoke-funcall-window "*compilation*" #'delete-window))))
;;        ;; make failure
;;        (lambda ()
;;          ;; Step 2: run latexmk
;;          (message "Make failed, running latexmk...")
;;          (hanxic/compile-with-callbacks
;;           ;; "latexmk -pdf"
;;           latexmk-cmd
;;           ;; latexmk success
;;           (lambda ()
;;             (hanxic/funcall-after-delay-focus
;;              1
;;              (lambda ()
;;                (hanxic/invoke-funcall-window "*compilation*" #'delete-window))))
;;           ;; latexmk failure
;;           (lambda ()
;;             (hanxic/funcall-after-delay-focus
;;              1
;;              (lambda ()
;;                (hanxic/invoke-funcall-window "*compilation*" #'select-window))))))))))
(defun hanxic/close-compilation-window-on-success (buffer status)
  "Close compilation window if compilation finished successfully."
  (when (and (string-match-p "finished" status)
             (buffer-live-p buffer))
    (when-let ((win (get-buffer-window buffer)))
      (delete-window win))))

(add-hook 'compilation-finish-functions
          #'hanxic/close-compilation-window-on-success)

(defvar latex-save-mode--default-enabled nil
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

;; (defun hanxic/TeX-set-compile-command ()
;;   "Use make if a Makefile exists, otherwise use LaTeX"

;;;; CSV Mode
(use-package csv-mode
  :ensure t
  :mode ("\\.csv\\'" . csv-mode))

;;; Terminal
;;;; VTerm
(use-package vterm
  :ensure t
  :commands vterm
  )

(use-package multi-vterm
  :after vterm
	:config
	(add-hook 'vterm-mode-hook
			(lambda ()
			(setq-local evil-insert-state-cursor 'box)
			(evil-insert-state)
      (setq-local global-hl-line-mode nil)
      (hl-line-mode -1)))
	(define-key vterm-mode-map [return]                      #'vterm-send-return)

	(setq vterm-keymap-exceptions nil)
	(evil-define-key 'insert vterm-mode-map (kbd "C-e")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-f")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-a")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-v")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-b")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-w")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-u")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-d")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-n")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-m")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-p")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-j")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-k")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-r")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-t")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-g")      #'vterm--self-insert)
	;; (evil-define-key 'insert vterm-mode-map (kbd "C-c")      #'vterm--self-insert)
	(evil-define-key 'insert vterm-mode-map (kbd "C-SPC")    #'vterm--self-insert)
	(evil-define-key 'normal vterm-mode-map (kbd "C-d")      #'vterm--self-insert)
	(evil-define-key 'normal vterm-mode-map (kbd ",n")       #'multi-vterm)
	(evil-define-key 'normal vterm-mode-map (kbd ",>")       #'multi-vterm-next)
	(evil-define-key 'normal vterm-mode-map (kbd ",>")       #'multi-vterm-prev)
	(evil-define-key 'normal vterm-mode-map (kbd "i")        #'evil-insert-resume)
	(evil-define-key 'normal vterm-mode-map (kbd "o")        #'evil-insert-resume)
	(evil-define-key 'normal vterm-mode-map (kbd "<return>") #'evil-insert-resume))

;;; Customization
;;;; Dired
(with-eval-after-load 'dired
  (define-key dired-mode-map "?" #'dired-summary)
  (define-key dired-mode-map (kbd "C-c +") #'dired-create-empty-file)
  )

  ;; (defun hanxic/hide-buffers-from-helm (orig-fn &rest args)
  ;;   "Filter out dired and magit buffers from helm-mini."
  ;;   (let ((helm-boring-buffer-regexp-list
  ;;          (append helm-boring-buffer-regexp-list
  ;;                  (mapcar (lambda (b)
  ;;                            (concat "\\`" (regexp-quote (buffer-name b)) "\\'"))
  ;;                          (seq-filter (lambda (b)
  ;;                                        (with-current-buffer b
  ;;                                          (or (derived-mode-p 'dired-mode)
  ;;                                              (derived-mode-p 'magit-mode))))
  ;;                                      (buffer-list))))))
  ;;     (apply orig-fn args)))

;; (advice-add 'helm-mini :around #'hanxic/hide-buffers-from-helm)
(defvar hanxic/helm-hidden-modes '(dired-mode magit-mode)
    "Major modes to hide from `helm-mini'.")

  (defun hanxic/hide-buffers-from-helm (orig-fn &rest args)
    "Filter out buffers whose major mode derives from `hanxic/helm-hidden-modes'."
    (let ((helm-boring-buffer-regexp-list
           (append helm-boring-buffer-regexp-list
                   (mapcar (lambda (b)
                             (concat "\\`" (regexp-quote (buffer-name b)) "\\'"))
                           (seq-filter (lambda (b)
                                         (with-current-buffer b
                                           (apply #'derived-mode-p hanxic/helm-hidden-modes)))
                                       (buffer-list))))))
      (apply orig-fn args)))

  (advice-add 'helm-mini :around #'hanxic/hide-buffers-from-helm)

;;;; Preview hotkeys
(defvar hanxic/personal-preview-map
  (make-sparse-keymap)
  "Personal preview commands.")

(define-key hanxic/personal-map (kbd "p") hanxic/personal-preview-map)

;; (defun hanxic/preview-init ()
;;   "Preview init.el in View mode."
;;   (interactive)
;;   (view-file user-init-file))
;; (define-key hanxic/personal-preview-map (kbd "i") #'hanxic/preview-init)

;; (defun hanxic/preview-bin ()
;;   "Preview ~/.bin directory."
;;   (interactive)
;;   (dired "~/.bin"))
;; (define-key hanxic/personal-preview-map (kbd "b") #'hanxic/preview-bin)

(defun hanxic/preview-path (path)
  "Preview PATH.
If PATH is a directory, open with dired.
If PATH is a file, open with view-file."
  (interactive)
  (cond
   ((file-directory-p path)
    (dired path))
   ((file-regular-p path)
    (view-file path))
   (t
    (user-error "Invalid preview target: %s" target))))

(defun hanxic/define-preview-command (name path)
  "Define a named preview command NAME for PATH."
  (let ((fn-symbol (intern (format "hanxic/preview-%s" name))))
    (fset fn-symbol
          `(lambda ()
             ,(format "Preview %s." path)
             (interactive)
             (hanxic/preview-path ,path)))
    fn-symbol))

(defvar hanxic/preview-spec
  '(("i" init user-init-file "init.el")
    ("b" bin "~/.bin" "bin")
    ("r" research "~/research" "research")
    ("p" project "~/projects" "projects")
    ("z" zshrc "~/.zshrc" "zshrc")))

(defun hanxic/install-preview-bindings ()
  (dolist (spec hanxic/preview-spec)
    (pcase-let ((`(,key ,name ,path ,label) spec))
      (let ((cmd (hanxic/define-preview-command name path)))
        ;; key binding
        (define-key hanxic/personal-preview-map (kbd key) cmd)

        ;; which-key
        (with-eval-after-load 'which-key
          (which-key-add-key-based-replacements
            (concat "C-c p p " key) label))))))

(hanxic/install-preview-bindings)

(defun hanxic/open-in-finder ()
  "Open the current directory in macOS Finder.
In dired, open the dired directory. In a file buffer, open the
file's parent directory. Otherwise, open `default-directory'."
  (interactive)
  (let ((dir (cond
              ((derived-mode-p 'dired-mode)
               (dired-current-directory))
              (buffer-file-name
               (file-name-directory buffer-file-name))
              (t default-directory))))
    (start-process "finder" nil "open" (expand-file-name dir))))

(define-key hanxic/personal-map (kbd "f") #'hanxic/open-in-finder)

(defun hanxic/iterm-dir ()
  "Return the directory to open in iTerm.
In dired, the dired directory. In a file buffer, the file's
parent directory. Otherwise, `default-directory'."
  (expand-file-name
   (cond
    ((derived-mode-p 'dired-mode)
     (dired-current-directory))
    (buffer-file-name
     (file-name-directory buffer-file-name))
    (t default-directory))))

(defun hanxic/open-in-iterm-window ()
  "Open the current directory in a new iTerm window."
  (interactive)
  (let ((dir (hanxic/iterm-dir)))
    (do-applescript
     (format "tell application \"iTerm\"
  create window with default profile
  tell current session of current window
    write text \"cd %s\"
  end tell
end tell" (shell-quote-argument dir)))))

(defun hanxic/open-in-iterm-tab ()
  "Open the current directory in a new iTerm tab.
If an iTerm window exists, open a new tab there. Otherwise, open
a new window."
  (interactive)
  (let ((dir (hanxic/iterm-dir)))
    (do-applescript
     (format "tell application \"iTerm\"
  if it is not running then
    activate
    if (count windows) is 0 then
      create window with default profile
    end if
  else if (count windows) is 0 then
    create window with default profile
  else
    tell current window
      create tab with default profile
    end tell
  end if
  tell current window
    tell current session
      write text \"cd %s\"
    end tell
  end tell
end tell" (shell-quote-argument dir)))))

(define-key hanxic/personal-map (kbd "i") #'hanxic/open-in-iterm-tab)
(define-key hanxic/personal-map (kbd "I") #'hanxic/open-in-iterm-window)

(define-key hanxic/personal-map (kbd "t") #'vterm)
(define-key hanxic/personal-map (kbd "T") #'multi-vterm)

;;;; Themes
(use-package autothemer
  :ensure t)


;; (with-eval-after-load 'which-key
;;   (which-key-add-key-based-replacements
;;     "C-c p" "personal"
;;     "C-c p p" "preview"
;;     "C-c p p i" "init.el"
;;     "C-c p p b" "bin"))


;; (defun hanxic/evil-visual-indent-right-1 ()
;;   "Indent selected region by 1 space to the right, keeping cursor at same column."
;;   (interactive)
;;   (when (use-region-p)
;;     ;; record line and column of point and mark
;;     (let* ((point-line (line-number-at-pos (point)))
;;            (point-col  (current-column))
;;            (mark-line  (line-number-at-pos (mark)))
;;            (mark-col   (save-excursion (goto-char (mark)) (current-column))))
;;       ;; indent region
;;       (indent-rigidly (region-beginning) (region-end) 1)
;;       ;; restore point
;;       (goto-char (point-min))
;;       (forward-line (1- point-line))
;;       (move-to-column (+ point-col 1))
;;       ;; restore mark
;;       (set-mark (point-min))
;;       (forward-line (1- mark-line))
;;       (move-to-column (+ mark-col 1))
;;       (evil-visual-restore))))

;; (defun hanxic/evil-visual-indent-left-1 ()
;;   "Indent selected region by 1 space to the left, keeping cursor at same column."
;;   (interactive)
;;   (when (use-region-p)
;;     ;; record line and column of point and mark
;;     (let* ((point-line (line-number-at-pos (point)))
;;            (point-col  (current-column))
;;            (mark-line  (line-number-at-pos (mark)))
;;            (mark-col   (save-excursion (goto-char (mark)) (current-column))))
;;       ;; indent region
;;       (indent-rigidly (region-beginning) (region-end) -1)
;;       ;; restore point
;;       (goto-char (point-min))
;;       (forward-line (1- point-line))
;;       (move-to-column (max 0 (- point-col 1)))
;;       ;; restore mark
;;       (set-mark (point-min))
;;       (forward-line (1- mark-line))
;;       (move-to-column (max 0 (- mark-col 1)))
;;       (evil-visual-restore))))

(defun hanxic/evil-calculate-region ()
  "Calculate the region selected in Evil visual mode.
Returns:
- For 'char or 'line: a cons (BEG . END) of buffer positions.
- Currently don't support block
  "
  (interactive)
  (if (use-region-p)
      (pcase evil-visual-selection
        ('char
         ;; character-wise: just return point and mark in order
         (let ((beg (region-beginning))
               (end (region-end)))
           ;; (message "character: %d to %d" beg end)
           (cons beg end)))
        ('line
         ;; Line-wise: extend to full lines
        (let* ((beg (region-beginning))
               (end (- (region-end) 1))
               (beg-line (save-excursion (goto-char beg) (line-beginning-position)))
               (end-line (save-excursion (goto-char end) (pos-eol))))
          ;; (message "line: %d to %d" beg end)
          ;; (message "beg-line: %d, end-line: %d" beg-line end-line)
          (cons beg-line end-line))))))

(defun hanxic/evil-indent-right-1 ()
  "Indent selected lines (or current line) by one step, keep cursor in the same place."
  (interactive)
  (let ((cursor-marker (point-marker))
        (col (current-column))
        (line (line-number-at-pos)))
    (if (use-region-p)
        (pcase evil-visual-selection
          ('char
           (let* ((beg (region-beginning))
                  (end (region-end))
                  (beg-line (save-excursion (goto-char beg) (line-beginning-position)))
                  (end-line (save-excursion (goto-char end) (pos-eol))))
             (indent-rigidly beg-line end-line 1)
             (evil-visual-select (1+ beg) end 'char)
             (goto-char (point-min))
             (forward-line (1- line))
             (move-to-column col)))
          ('line
           (let* ((beg (region-beginning))
                 (end (region-end))
                 (beg-line (line-number-at-pos beg))
                 (end-line (1- (line-number-at-pos end)))
                 (beg-pos (save-excursion (goto-line beg-line) (line-beginning-position)))
                 (end-pos (save-excursion (goto-line end-line) (line-end-position)))
                 (visual-end-pos (save-excursion (goto-line (1- end-line)) (line-end-position))))
             (indent-rigidly beg-pos end-pos 1)
             (message "End is: %d" (- end 1))
             (message "Beg-line is: %d, end-line is: %d" beg-line end-line)
             (message "Beg-pos is: %d, end-pos is: %d" beg-pos end-pos)
             (message "visual-end-pos is: %d" visual-end-pos)
             (evil-visual-select beg-pos beg-pos 'line)
             ;; (goto-char (point-min))
             ;; (forward-line (1- line))
             (goto-char beg-pos)
             (forward-line (- end-line beg-line))
             (message "line is: %d, column is: %d" line col)
             (move-to-column col))))
      (progn
        (indent-rigidly (line-beginning-position) (line-end-position) 1)
        (goto-char cursor-marker)))))
(defun hanxic/evil-indent-left-1 ()
  "Indent selected lines (or current line) by one step, keep cursor in the same place."
  (interactive)
  (let ((cursor-marker (point-marker))
        (col (current-column))
        (line (line-number-at-pos)))
    (if (use-region-p)
        (pcase evil-visual-selection
          ('char
           (let* ((beg (region-beginning))
                  (end (region-end))
                  (beg-line (save-excursion (goto-char beg) (line-beginning-position)))
                  (end-line (save-excursion (goto-char end) (pos-eol))))
             (indent-rigidly beg-line end-line -1)
             (evil-visual-select (1- beg) end 'char)
             ;; (goto-char (point-min))
             ;; (forward-line (1- line))
             ;; (move-to-column (1- col))
             (goto-char (- end (- beg-line end-line))
             )))
          ('line
           (let* ((beg (region-beginning))
                 (end (region-end))
                 (beg-line (line-number-at-pos beg))
                 (end-line (1- (line-number-at-pos end)))
                 (beg-pos (save-excursion (goto-line beg-line) (line-beginning-position)))
                 (end-pos (save-excursion (goto-line end-line) (line-end-position)))
                 (visual-end-pos (save-excursion (goto-line (1- end-line)) (line-end-position))))
             (indent-rigidly beg-pos end-pos -1)
             (message "End is: %d" (- end 1))
             (message "Beg-line is: %d, end-line is: %d" beg-line end-line)
             (message "Beg-pos is: %d, end-pos is: %d" beg-pos end-pos)
             (message "visual-end-pos is: %d" visual-end-pos)
             (evil-visual-select beg-pos beg-pos 'line)
             ;; (goto-char (point-min))
             ;; (forward-line (1- line))
             (goto-char beg-pos)
             (forward-line (- end-line beg-line))
             (message "line is: %d, column is: %d" line col)
             (move-to-column col))))
      (progn
        (indent-rigidly (line-beginning-position) (line-end-position) -1)
        (goto-char cursor-marker)))))

(defvar hanxic-indent-keymap (make-sparse-keymap)
  "Keymap for Hanxic indentation commands after C-<tab>.")
;; Bind sub-keys
(define-key hanxic-indent-keymap (kbd "<right>") #'hanxic/evil-indent-right-1)
(define-key hanxic-indent-keymap (kbd "<left>")  #'hanxic/evil-indent-left-1);
(global-set-key (kbd "C-<tab>") hanxic-indent-keymap)
;; Step 2: bind prefix key in normal and visual modes
(define-key evil-normal-state-map (kbd "C-<tab>") hanxic-indent-keymap)
(define-key evil-visual-state-map (kbd "C-<tab>") hanxic-indent-keymap)


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("b1808f57c03036c9eac03a194ec683dd14d5a1b3a99e58a3ed755296debe7eb9"
     "e1d764c14d06a3ee795fc8825488b915ac4f543fcaa15cd3e74e3c484a6f9454"
     "10d44b43eb420d1dc019700cdec828ed9d0e8aeab130083f413040881d9453ca" default))
 '(helm-minibuffer-history-key "M-p")
 '(package-selected-packages
   '(autothemer company-auctex company-coq copilot csv-mode dune ef-themes
                evil-collection evil-nerd-commenter flycheck-haskell
                flycheck-ocaml helm-lsp helm-projectile helm-rg helpful
                hlint-refactor lsp-haskell lsp-ui magit multi-vterm ocamlformat
                org-fragtog proof-general telephone-line tuareg undo-fu web-mode
                yasnippet-snippets))
 '(safe-local-variable-values
   '((eval setq TeX-master-directory
           (file-name-directory (directory-file-name default-directory)))
     (eval setq TeX-master
           (file-name-directory (directory-file-name default-directory)))
     (eval setq default-directory
           (file-name-directory (directory-file-name default-directory)))
     (jinx-dir-local-words . "ElDoc Nael Mekeor Melire reindent")))
 '(warning-suppress-log-types '((lsp-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(merlin-type-face ((t (:background "#46484f")))))

(provide 'init)
;;; init.el ends here
