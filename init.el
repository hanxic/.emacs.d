;;; init.el --- Emacs configuration entry point  -*- lexical-binding: t; -*-

;;; Commentary:
;; This file bootstraps the package system and loads all modules from lisp/.

;;; Code:

;;; Personal prefix keymap (must be defined before modules)
(defvar hanxic/personal-map
  (make-sparse-keymap)
  "Personal prefix keymap.")
(global-set-key (kbd "C-c p") hanxic/personal-map)

;;; Font — daemon-aware
(defun my/apply-font (&optional frame)
  (with-selected-frame (or frame (selected-frame))
    (set-face-attribute 'default nil :font "Iosevka-12")))
(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/apply-font)
  (my/apply-font))

;;; Server
(require 'server)
(unless (server-running-p)
  (server-start))

;;; Package bootstrap
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(setq use-package-compute-statistics t)
(require 'use-package)
(setq use-package-always-ensure t)

;;; Load modules
(add-to-list 'load-path (concat user-emacs-directory "lisp"))
(add-to-list 'load-path (concat user-emacs-directory "lisp/lang"))

(require 'core-settings)
(require 'ui-theme)
(require 'completion-ui)
(require 'evil-setup)
(require 'tools)
(require 'terminal)
(require 'org-setup)
(require 'todo-manager)
(define-key hanxic/personal-org-map (kbd "t") #'hanxic/todo)
(require 'lang)
(require 'ui-extras)

;;; Custom — managed by Emacs, do not edit manually
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
 '(package-selected-packages nil)
 '(safe-local-variable-values
   '((eval setq-local default-directory
           (expand-file-name "~/research/papers/opcol/"))
     (eval setq-local default-directory
           (or (locate-dominating-file default-directory "Makefile")
               default-directory))
     (eval setq TeX-master-directory
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
 '(helm-rg-file-match-face ((t (:extend t :foreground "BlueViolet" :underline t))))
 '(merlin-type-face ((t (:background "#46484f")))))

(provide 'init)
;;; init.el ends here
