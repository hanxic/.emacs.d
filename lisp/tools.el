;;; tools.el --- Helpful, Which-key, Magit, Flycheck, Undo-fu  -*- lexical-binding: t; -*-

;;; Helpful
(use-package helpful
  :bind
  ([remap describe-key]      . helpful-key)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-function] . helpful-callable)
  ([remap describe-command]  . helpful-command)
  ("C-c C-d" . helpful-at-point)
  ("C-h F"   . helpful-function))

;;; Which-key
(use-package which-key
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3)
  (which-key-mode))

;;; Magit
(use-package magit
  :ensure t
  :bind (("C-x g"   . magit-status)
         ("C-x C-g" . magit-status)))

;;; Flycheck
(use-package flycheck
  :ensure t
  :hook ((prog-mode  . flycheck-mode)
         (LaTeX-mode . flycheck-mode)))

(with-eval-after-load 'flycheck
  (define-key flycheck-mode-map (kbd "C-c C-j n") #'flycheck-next-error)
  (define-key flycheck-mode-map (kbd "C-c C-j p") #'flycheck-previous-error))

;;; Undo-fu
(use-package undo-fu
  :ensure t
  :config
  (global-unset-key (kbd "s-z"))
  (global-set-key (kbd "s-z") 'undo-fu-only-undo)
  (global-set-key (kbd "s-Z") 'undo-fu-only-redo))

(provide 'tools)
;;; tools.el ends here
