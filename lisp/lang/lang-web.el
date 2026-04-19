;;; lang-web.el --- HTML, CSS, JavaScript via web-mode  -*- lexical-binding: t; -*-

(use-package web-mode
  :ensure t
  :mode (("\\.html?\\'"    . web-mode)
         ("\\.phtml\\'"    . web-mode)
         ("\\.php\\'"      . web-mode)
         ("\\.tpl\\'"      . web-mode)
         ("\\.[agj]sp\\'"  . web-mode)
         ("\\.as[cp]x\\'"  . web-mode)
         ("\\.erb\\'"      . web-mode)
         ("\\.mustache\\'" . web-mode)
         ("\\.djhtml\\'"   . web-mode)))

(setq web-mode-markup-indent-offset 2
      web-mode-css-indent-offset    2
      web-mode-code-indent-offset   2)

(provide 'lang-web)
;;; lang-web.el ends here
