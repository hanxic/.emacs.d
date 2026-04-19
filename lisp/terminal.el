;;; terminal.el --- VTerm and multi-vterm configuration  -*- lexical-binding: t; -*-

;;; VTerm
(use-package vterm
  :ensure t
  :commands vterm)

;;; Multi-VTerm
(use-package multi-vterm
  :after vterm
  :config
  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local evil-insert-state-cursor 'box)
              (evil-insert-state)
              (setq-local global-hl-line-mode nil)
              (hl-line-mode -1)))
  (define-key vterm-mode-map [return] #'vterm-send-return)
  (setq vterm-keymap-exceptions nil)
  (evil-define-key 'insert vterm-mode-map (kbd "C-e")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-f")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-a")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-v")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-b")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-w")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-u")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-d")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-n")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-m")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-p")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-j")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-k")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-r")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-t")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-g")   #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-SPC") #'vterm--self-insert)
  (evil-define-key 'normal vterm-mode-map (kbd "C-d")   #'vterm--self-insert)
  (evil-define-key 'normal vterm-mode-map (kbd ",n")    #'multi-vterm)
  (evil-define-key 'normal vterm-mode-map (kbd ",>")    #'multi-vterm-next)
  (evil-define-key 'normal vterm-mode-map (kbd ",<")    #'multi-vterm-prev)
  (evil-define-key 'normal vterm-mode-map (kbd "i")     #'evil-insert-resume)
  (evil-define-key 'normal vterm-mode-map (kbd "o")     #'evil-insert-resume)
  (evil-define-key 'normal vterm-mode-map (kbd "<return>") #'evil-insert-resume))

;;; Keybindings
(define-key hanxic/personal-map (kbd "t") #'vterm)
(define-key hanxic/personal-map (kbd "T") #'multi-vterm)

(provide 'terminal)
;;; terminal.el ends here
