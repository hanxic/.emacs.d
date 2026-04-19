;;; core-settings.el --- Basic UI, editing, and Emacs behaviour  -*- lexical-binding: t; -*-

;;; Mode line
(setq inhibit-startup-message t
      column-number-mode t
      line-number-mode t)

;;; File Backup
(setq backup-directory-alist `(("." . ,(expand-file-name "backup" user-emacs-directory)))
      delete-old-versions t
      kept-old-versions 1
      kept-new-versions 2
      backup-by-copying t
      version-control t)

;;; Line numbers
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

;;; Miscellaneous UI
(global-hl-line-mode 1)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode 7)
(menu-bar-mode -1)
(save-place-mode 1)
(setq save-place-file "~/.emacs.d/saveplace")
(put 'upcase-region 'disabled nil)

;;; VC
(setq vc-handled-backends '(Git))

;;; Uniquify
(require 'uniquify)

;;; Indentation defaults
(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)

;;; Spelling
(use-package ispell
  :config
  (setq ispell-program-name "aspell")
  (setq ispell-dictionary "english"))
(add-hook 'text-mode-hook 'flyspell-mode)

;;; Elisp section highlighting
(defun hanxic/elisp-highlight-section ()
  "Make comments starting with ';;;' appear larger."
  (font-lock-add-keywords
   nil
   '((";;;\\([^;].*\\)"
      1 '(:weight bold :height 1.3 :foreground "Orange") t)
     (";;;;\\([^;].*\\)"
      1 '(:weight bold :height 1.1 :foreground "LightSkyBlue") t))))
(add-hook 'emacs-lisp-mode-hook 'hanxic/elisp-highlight-section)

(provide 'core-settings)
;;; core-settings.el ends here
