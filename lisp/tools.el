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
  (which-key-mode)
  ;; Label the prefix groups so the popup shows intent, not raw keymap names.
  (which-key-add-key-based-replacements
    "C-c p"   "personal"
    "C-c p h" "helm/project"
    "C-c p p" "preview"
    "C-c o"   "org"
    "C-c C-j" "flycheck-nav"
    "C-c ^"   "smerge"))

;;; Magit
(use-package magit
  :ensure t
  :bind (("C-x g"   . magit-status)
         ("C-x C-g" . magit-status)))

;;; Merge conflicts
;; Preferred flow: from magit-status, put point on a conflicted ("Unmerged")
;; file and press `e' to launch a 3-way ediff (magit-ediff-resolve). Inside
;; ediff: `n'/`p' move between conflicts, `a'/`b' take the A/B side, `q' saves.
;; Keep ediff in one frame, split side-by-side (no detached control frame).
(with-eval-after-load 'ediff
  (setq ediff-window-setup-function #'ediff-setup-windows-plain
        ediff-split-window-function #'split-window-horizontally))

;; smerge (C-c ^ ...) stays as the in-buffer fallback; auto-enable it whenever
;; a buffer actually has conflict markers so you never `M-x smerge-mode' by hand.
(defun hanxic/maybe-enable-smerge ()
  "Turn on `smerge-mode' if the buffer contains conflict markers."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^<<<<<<< " nil t)
      (smerge-mode 1))))
(add-hook 'find-file-hook    #'hanxic/maybe-enable-smerge)
(add-hook 'after-revert-hook #'hanxic/maybe-enable-smerge)

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
