;;; ui-extras.el --- Dired, preview, Finder/iTerm, Copilot  -*- lexical-binding: t; -*-

;;; Dired
(with-eval-after-load 'dired
  (define-key dired-mode-map "?" #'dired-summary)
  (define-key dired-mode-map (kbd "C-c +") #'dired-create-empty-file))

;;; Preview commands
(defvar hanxic/personal-preview-map
  (make-sparse-keymap)
  "Personal preview commands.")
(define-key hanxic/personal-map (kbd "p") hanxic/personal-preview-map)

(defun hanxic/preview-path (path)
  "Preview PATH in dired (directories) or view-file (files)."
  (interactive)
  (cond
   ((file-directory-p path) (dired path))
   ((file-regular-p path)   (view-file path))
   (t (user-error "Invalid preview target: %s" path))))

(defun hanxic/define-preview-command (name path)
  "Define a named preview command NAME for PATH."
  (let ((fn-symbol (intern (format "hanxic/preview-%s" name))))
    (fset fn-symbol
          `(lambda ()
             ,(format "Preview %s." path)
             (interactive)
             (hanxic/preview-path ,path)))
    fn-symbol))

(defvar hanxic/preview-spec
  '(("i" init user-init-file "init.el")
    ("b" bin  "~/.bin"       "bin")
    ("r" research "~/research"  "research")
    ("p" project  "~/projects"  "projects")
    ("z" zshrc    "~/.zshrc"    "zshrc")))

(defun hanxic/install-preview-bindings ()
  (dolist (spec hanxic/preview-spec)
    (pcase-let ((`(,key ,name ,path ,label) spec))
      (let ((cmd (hanxic/define-preview-command name path)))
        (define-key hanxic/personal-preview-map (kbd key) cmd)
        (with-eval-after-load 'which-key
          (which-key-add-key-based-replacements
            (concat "C-c p p " key) label))))))

(hanxic/install-preview-bindings)

;;; macOS Finder integration
(defun hanxic/open-in-finder ()
  "Open the current directory in macOS Finder."
  (interactive)
  (let ((dir (cond
              ((derived-mode-p 'dired-mode) (dired-current-directory))
              (buffer-file-name (file-name-directory buffer-file-name))
              (t default-directory))))
    (start-process "finder" nil "open" (expand-file-name dir))))

(define-key hanxic/personal-map (kbd "f") #'hanxic/open-in-finder)

;;; iTerm integration
(defun hanxic/iterm-dir ()
  "Return the directory to open in iTerm."
  (expand-file-name
   (cond
    ((derived-mode-p 'dired-mode) default-directory)
    (buffer-file-name (file-name-directory buffer-file-name))
    (t default-directory))))

(defun hanxic/open-in-iterm-window ()
  "Open the current directory in a new iTerm window."
  (interactive)
  (let ((dir (hanxic/iterm-dir)))
    (do-applescript
     (format "tell application \"iTerm\"
  create window with default profile
  tell current session of current window
    write text \"cd %s\"
  end tell
end tell" (shell-quote-argument dir)))))

(defun hanxic/open-in-iterm-tab ()
  "Open the current directory in a new iTerm tab."
  (interactive)
  (let ((dir (hanxic/iterm-dir)))
    (do-applescript
     (format "tell application \"iTerm\"
  if it is not running then
    activate
    if (count windows) is 0 then
      create window with default profile
    end if
  else if (count windows) is 0 then
    create window with default profile
  else
    tell current window
      create tab with default profile
    end tell
  end if
  tell current window
    tell current session
      write text \"cd %s\"
    end tell
  end tell
end tell" (shell-quote-argument dir)))))

(define-key hanxic/personal-map (kbd "i") #'hanxic/open-in-iterm-tab)
(define-key hanxic/personal-map (kbd "I") #'hanxic/open-in-iterm-window)

;;; Copilot
(add-to-list 'exec-path "/opt/homebrew/bin")
(setenv "PATH" (concat "/opt/homebrew/bin:" (getenv "PATH")))

(use-package copilot
  :vc (:url "https://github.com/copilot-emacs/copilot.el"
            :rev :newest
            :branch "main")
  :defer t
  :config
  (define-key copilot-completion-map (kbd "C-<tab>") 'copilot-accept-completion)
  (define-key copilot-completion-map (kbd "C-TAB")   'copilot-accept-completion))

(provide 'ui-extras)
;;; ui-extras.el ends here
