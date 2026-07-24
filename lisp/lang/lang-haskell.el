;;; lang-haskell.el --- Haskell development environment  -*- lexical-binding: t; -*-

(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :ensure t
  :defer t
  :hook (haskell-mode . interactive-haskell-mode))

(use-package hlint-refactor
  :after haskell-mode
  :hook (hlint-refactor-mode . haskell-mode-hook))

(use-package flycheck-haskell
  :after (flycheck haskell-mode))

(use-package lsp-haskell
  :after (lsp-mode haskell-mode)
  :config
  (setq lsp-haskell-server-path "~/.ghcup/bin/haskell-language-server-wrapper"))

(provide 'lang-haskell)
;;; lang-haskell.el ends here
