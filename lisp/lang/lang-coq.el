;;; lang-coq.el --- Coq / Rocq via Proof General  -*- lexical-binding: t; -*-

(use-package proof-general
  :init
  (setq proof-splash-enable nil
        proof-toolbar-enable nil
        proof-disappearing-proofs nil
        proof-general-debug nil)
  :mode ("\\.v\\'" . coq-mode))

(setq coq-compiler "coqc"
      coq-one-command-per-line nil
      coq-prog-name "coqtop"
      coq-script-indent nil
      coq-unicode-tokens-enable nil)

(use-package company-coq
  :hook (coq-mode . company-coq-mode))

(provide 'lang-coq)
;;; lang-coq.el ends here
