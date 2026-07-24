;;; completion-ui.el --- Helm, Projectile, and Company  -*- lexical-binding: t; -*-

;;; Helm
(use-package helm
  :ensure t
  :diminish helm-mode
  :bind (("M-x"     . helm-M-x)
         ("C-x b"   . helm-mini)
         ("C-x C-b" . helm-mini)
         ("C-x C-f" . helm-find-files)
         ("C-c h o" . helm-occur)
         ("M-p"     . helm-show-kill-ring)
         ("C-M-j"   . helm-buffers-list))
  :defer 1
  :config
  (helm-mode 1)
  (helm-autoresize-mode 1)
  (require 'helm-command)
  :custom
  (helm-M-x-show-short-doc t)
  (helm-M-x-requires-pattern 0))

;;; Helm sub-keymap
(defvar hanxic/personal-helm-map
  (make-sparse-keymap)
  "Personal helm commands.")
(define-key hanxic/personal-map (kbd "h") hanxic/personal-helm-map)

;;; Projectile
(use-package projectile
  :ensure t
  :defer 1
  :config
  (projectile-mode)
  (setq projectile-enable-caching t
        projectile-indexing-method 'alien))

;;; Helm-Projectile
(use-package helm-projectile
  :ensure t
  :commands (helm-projectile helm-projectile-switch-project
             helm-projectile-ag helm-projectile-rg
             helm-projectile-grep)
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
  :commands (helm-rg))

(define-key hanxic/personal-helm-map (kbd "s") #'helm-rg)

;;; Helm-descbinds — searchable keybinding manual.
;; Remaps `describe-bindings' (C-h b) to a helm buffer you can fuzzy-filter by
;; key or command name. This is the "search through the manual" entry point.
(use-package helm-descbinds
  :ensure t
  :after helm
  :config
  (helm-descbinds-mode))

;;; Posframe — display Helm in a centered floating frame
(use-package posframe
  :ensure t
  :after helm
  :config
  (defun hanxic/helm-posframe-display (buffer &optional _resume)
    "Display Helm BUFFER in a centered posframe."
    (posframe-show buffer
                   :poshandler #'posframe-poshandler-frame-center
                   :width  (max 80 (round (* (frame-width) 0.65)))
                   :height 20
                   :border-width 2))
  (setq helm-display-function #'hanxic/helm-posframe-display)
  (add-hook 'helm-cleanup-hook
            (lambda () (posframe-hide helm-buffer))))

;;; Company
(use-package company
  :ensure t
  :hook (after-init . global-company-mode)
  :config
  (setq company-idle-delay 1))

;;; Hide dired/magit buffers from helm-mini
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

;; helm-posframe interaction: `helm--delete-frame-function' is on
;; `delete-frame-functions' and calls `top-level' to abort helm. When the
;; posframe child frame is deleted outside an active helm session, this
;; signals "No recursive edit is in progress". Swallow that user-error.
(with-eval-after-load 'helm
  (defun hanxic/helm-delete-frame-guarded (orig-fn &rest args)
    (condition-case _err
        (apply orig-fn args)
      (user-error nil)))
  (when (fboundp 'helm--delete-frame-function)
    (advice-add 'helm--delete-frame-function :around
                #'hanxic/helm-delete-frame-guarded)))

(provide 'completion-ui)
;;; completion-ui.el ends here
