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

;;; iTerm2 integration
;; Delegate terminal work to iTerm2 instead of living in vterm. These commands
;; drive iTerm2 over AppleScript (`osascript') — no extra packages. The reuse
;; command targets whatever session iTerm2 currently has focused (the "active
;; tab"); the new-tab command opens a fresh tab. Both `cd' to the project root
;; (falling back to the buffer's `default-directory' when not in a project).
(defun hanxic/iterm--as-quote (s)
  "Escape S for use inside an AppleScript double-quoted string."
  (replace-regexp-in-string "[\\\"]" "\\\\\\&" s))

(defun hanxic/iterm--project-dir ()
  "Directory to drop the iTerm2 shell into: project root, else `default-directory'."
  (expand-file-name
   (or (and (fboundp 'projectile-project-root) (projectile-project-root))
       default-directory)))

(defun hanxic/iterm-here (&optional new-tab)
  "Bring iTerm2 to the front with a shell in the current project directory.
Reuse the active session; with prefix arg NEW-TAB, open a new tab instead."
  (interactive "P")
  (let* ((cmd (hanxic/iterm--as-quote
               (concat "cd " (shell-quote-argument (hanxic/iterm--project-dir)))))
         (script
          (concat
           "tell application \"iTerm2\"\n"
           "  activate\n"
           "  if (count of windows) = 0 then\n"
           "    create window with default profile\n"
           (if new-tab
               "  else\n    tell current window to create tab with default profile\n"
             "")
           "  end if\n"
           "  tell current session of current window to write text \"" cmd "\"\n"
           "end tell\n")))
    (call-process "osascript" nil nil nil "-e" script)))

(defun hanxic/iterm-new-tab ()
  "Bring iTerm2 to the front in a NEW tab at the current project directory."
  (interactive)
  (hanxic/iterm-here t))

;;; Keybindings
(define-key hanxic/personal-map (kbd "t") #'hanxic/iterm-here)
(define-key hanxic/personal-map (kbd "T") #'hanxic/iterm-new-tab)
;; vterm kept as a fallback, off the muscle-memory keys.
(define-key hanxic/personal-map (kbd "v") #'vterm)
(define-key hanxic/personal-map (kbd "V") #'multi-vterm)

(provide 'terminal)
;;; terminal.el ends here
