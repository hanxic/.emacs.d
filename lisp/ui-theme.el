;;; ui-theme.el --- Theme, modeline, and visual extras  -*- lexical-binding: t; -*-

;;; Theme
(use-package ef-themes
  :config
  (setq ef-themes-to-toggle '(ef-summer ef-winter))
  (ef-themes-select 'ef-summer))

;;; Modeline
(use-package telephone-line
  :config
  (setq telephone-line-lhs
        '((evil   . (telephone-line-evil-tag-segment))
          (accent . (telephone-line-vc-segment
                     telephone-line-erc-modified-channels-segment
                     telephone-line-process-segment))
          (nil .    (telephone-line-projectile-segment
                     telephone-line-buffer-segment))))
  (setq telephone-line-rhs
        '((nil    . (telephone-line-misc-info-segment))
          (accent . (telephone-line-major-mode-segment))
          (evil   . (telephone-line-airline-position-segment))))
  (telephone-line-mode 1))

;;; Autothemer (for custom themes)
(use-package autothemer
  :ensure t)

(provide 'ui-theme)
;;; ui-theme.el ends here
