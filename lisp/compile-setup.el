;;; compile-setup.el --- Context-aware compile/run/test  -*- lexical-binding: t; -*-

;;; Commentary:
;; One set of keys that does the right thing per context.  The main entry,
;; `hanxic/compile', dispatches through a buffer-local override so different
;; modes can share the same key: LaTeX buffers build the document, everything
;; else runs the project's compile command (projectile remembers it per
;; project), or plain `compile' when outside a project.
;;
;;   C-c p c   compile   (C-u to change / re-prompt the command)
;;   C-c p r   run
;;   C-c p k   test
;;
;; A mode enables the overlap by setting `hanxic/compile-command-function' in
;; its hook (see lang-latex.el for the LaTeX case).

;;; Code:

(defvar compilation-read-command)
(declare-function projectile-project-p "projectile")
(declare-function projectile-compile-project "projectile" (arg))
(declare-function projectile-run-project "projectile" (arg))
(declare-function projectile-test-project "projectile" (arg))

(defvar-local hanxic/compile-command-function nil
  "Buffer-local override for `hanxic/compile'.
When non-nil, it is called with the prefix arg instead of the default
projectile/`compile' dispatch.  Modes set this in their hook so the same
compile key does the mode-appropriate thing.")

(defun hanxic/compile (&optional arg)
  "Compile the current context.
If the buffer set `hanxic/compile-command-function', call that.  Otherwise
run the project's compile command (projectile, remembered per project), or
plain `compile' outside a project.  With prefix ARG, re-prompt for / change
the command."
  (interactive "P")
  (cond
   (hanxic/compile-command-function
    (funcall hanxic/compile-command-function arg))
   ((and (fboundp 'projectile-project-p) (projectile-project-p))
    (projectile-compile-project arg))
   (t
    (let ((compilation-read-command (if arg t compilation-read-command)))
      (call-interactively #'compile)))))

(defun hanxic/project-run (&optional arg)
  "Run the project's run command (projectile, remembered per project).
With prefix ARG, re-prompt for / change the command."
  (interactive "P")
  (if (and (fboundp 'projectile-project-p) (projectile-project-p))
      (projectile-run-project arg)
    (user-error "Not in a project")))

(defun hanxic/project-test (&optional arg)
  "Run the project's test command (projectile, remembered per project).
With prefix ARG, re-prompt for / change the command."
  (interactive "P")
  (if (and (fboundp 'projectile-project-p) (projectile-project-p))
      (projectile-test-project arg)
    (user-error "Not in a project")))

;;; Keybindings
(define-key hanxic/personal-map (kbd "c") #'hanxic/compile)
(define-key hanxic/personal-map (kbd "r") #'hanxic/project-run)
(define-key hanxic/personal-map (kbd "k") #'hanxic/project-test)

(provide 'compile-setup)
;;; compile-setup.el ends here
