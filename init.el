(server-start)

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
;; lsp
;;

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
      backup--by-copying t
      version-control t
      )

;;; Line number
(global-display-line-numbers-mode t)
(dolist (mode '(org-mode-hook
		term-mode-hook
		eshell-mode-hook
		shell-mode--hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))
(setq display-line-numbers-type 'visual)

;;; Fill column indicator
(setq-default display-fill-column-indicator-column 80)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)
(add-hook 'after-change-major-mode-hook
	  (lambda ()
	    (setq display--fill-column-indicator-column 80)))

;;; Miscellaneous
(global-hl-line-mode 1) ; highlight current line
(scroll-bar-mode -1)    ; Disable visible scrollbar
(tool-bar-mode -1)      ; Disable tool bar
(tooltip-mode -1)       ; Disable tooltips
(set-fringe-mode 3)     ; Give some breathing room
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
  :custom
  (helm-M-x-show-short-doc t))

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
;; (use-package all-the-icons
;;   :if (display-graphic-p))
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
(setq ispell-program-name "aspell")
(setq ispell-dictionary "english")
(add-hook 'text-mode-hook 'flyspell-mode)

;;; Checking
(use-package flycheck
  :ensure t
  :config
  (global-flycheck-mode)
  )

;;; Customization
(defun hanxic/elisp-highlight-section ()
  "Make comments starting with ';;;' appear larger."
  (font-lock-add-keywords
   nil
   '((";;;.*$"                ;; regex: lines starting with ;;;
      0
      '(:inherit font-lock-comment-face :height 1.2 :weight bold) t))))
(add-hook 'emacs-lisp-mode-hook 'hanxic/elisp-highlight-section)

;;; Company
(use-package company
  :ensure t
  :hook (afer-init . global-company-mode))

;;; Org mode

(use-package org
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

;;; LSP mode
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
  (lsp-eldoc-render-all t)
  (lsp-idle-delay 0.6)
  (lsp-inlay-hint-enable t)
  )

(setq gc-cons-threshold 1280000)
(setq read-process-output-max (* 1024 1024)) ;; 1mb
(setq lsp-log-io nil)

;; optionally
(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :commands lsp-ui-mode
  )
;; if you are helm user
(use-package helm-lsp :commands helm-lsp-workspace-symbol)

;;; Rocq
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




(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(helm-minibuffer-history-key "M-p")
 '(package-selected-packages '(evil command-log-mode use-package)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
