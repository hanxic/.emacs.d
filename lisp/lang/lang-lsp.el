;;; lang-lsp.el --- LSP mode configuration  -*- lexical-binding: t; -*-

;;; Performance tuning
(setq gc-cons-threshold (* 100 1024 1024))
(setq read-process-output-max (* 1024 1024))
(setq lsp-log-io nil)

;;; LSP mode
(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook ((haskell-mode tuareg-mode) . lsp)
  (lsp-mode . lsp-enable-which-key-integration)
  :commands lsp
  :custom
  (lsp-completion-auto-delay 1)
  (lsp-eldoc-render-all t)
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
          "[/\\\\]\\.vscode$")))

(defun hanxic/cleanup-lsp ()
  "Remove all workspace folders from LSP."
  (interactive)
  (let ((folders (lsp-session-folders (lsp-session))))
    (while folders
      (lsp-workspace-folders-remove (car folders))
      (setq folders (cdr folders)))))

;;; LSP UI
(use-package lsp-ui
  :ensure t
  :hook (lsp-mode . lsp-ui-mode)
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover t
        lsp-ui-sideline-show-code-actions t))

;;; Helm integration
(use-package helm-lsp :commands helm-lsp-workspace-symbol)

(provide 'lang-lsp)
;;; lang-lsp.el ends here
