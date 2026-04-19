;;; lang-lean.el --- Lean 4 via Nael  -*- lexical-binding: t; -*-

;;; Tree-sitter grammar for Lean
(require 'treesit)
(add-to-list 'treesit-language-source-alist
             '(lean "https://github.com/Julian/tree-sitter-lean.git"))

;;; Nael (Lean 4 mode)
(add-to-list 'load-path "~/projects/lean-self/nael/nael")
(add-to-list 'load-path "~/projects/lean-self/nael/nael-lsp")
(require 'info)
(info-initialize)
(add-to-list 'Info-directory-list "~/projects/lean-self/nael/nael")
(require 'nael-autoloads)
(add-hook 'nael-mode-hook #'abbrev-mode)
(add-hook 'nael-mode-hook #'eglot-ensure)

(provide 'lang-lean)
;;; lang-lean.el ends here
