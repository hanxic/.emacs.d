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

;;; Desktop: persist buffers, window splits, and frames across restarts
(setq desktop-dirname             "~/.emacs.d/desktop/"
      desktop-base-file-name      "emacs.desktop"
      desktop-base-lock-name      "lock"
      desktop-path                (list "~/.emacs.d/desktop/")
      desktop-save                t
      desktop-restore-frames      t
      desktop-restore-in-current-display t
      desktop-load-locked-desktop t
      desktop-auto-save-timeout   0)
(unless (file-directory-p "~/.emacs.d/desktop/")
  (make-directory "~/.emacs.d/desktop/" t))
(defvar my/desktop-restored nil
  "Non-nil once the saved desktop has been read in this session.")

(defun my/restore-desktop-once ()
  "Restore the saved desktop, but only on the first call.
Silences AUCTeX style-hook chatter on the terminal; messages
still land in *Messages*.  Enables `desktop-save-mode' afterward
so the session is persisted on exit."
  (interactive)
  (unless my/desktop-restored
    (setq my/desktop-restored t)
    (let ((inhibit-message t))
      (desktop-read))
    (desktop-save-mode 1)))

(if (daemonp)
    ;; Do NOT enable `desktop-save-mode' here: `(require 'desktop)' installs
    ;; an anonymous lambda on `after-init-hook' that calls `desktop-read'
    ;; whenever the mode is on.  Enabling it now would auto-restore during
    ;; daemon startup (and dump every AUCTeX `Loading ...' to the terminal).
    ;; `my/restore-desktop-once' turns the mode on after reading manually.
    nil
  (desktop-save-mode 1))

;; Exclude tty/terminal frames (including the daemon's invisible initial
;; frame) from the saved frameset — otherwise `frameset-restore' errors
;; with "Wrong type argument: number-or-marker-p, nil" on geometry params
;; that don't exist for tty frames.
(defun my/desktop-mark-tty-frame (frame)
  (when (memq (framep frame) '(t pc))
    (set-frame-parameter frame 'desktop-dont-save t)))
(mapc #'my/desktop-mark-tty-frame (frame-list))
(add-hook 'after-make-frame-functions #'my/desktop-mark-tty-frame)

;;; Auto-revert: reload buffers when underlying file changes on disk,
;;; but only when the buffer has no unsaved modifications.
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)

;;; VC
(setq vc-handled-backends '(Git))

;;; Dired: macOS BSD `ls' lacks --dired/-N. Prefer GNU `gls' if installed,
;;; otherwise fall back to BSD ls and disable --dired.
(let ((gls (or (executable-find "gls")
               (and (file-executable-p "/opt/homebrew/bin/gls") "/opt/homebrew/bin/gls")
               (and (file-executable-p "/usr/local/bin/gls")    "/usr/local/bin/gls"))))
  (if gls
      (setq insert-directory-program gls)
    (setq dired-use-ls-dired nil)))

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
