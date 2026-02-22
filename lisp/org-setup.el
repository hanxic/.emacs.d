;;; org-setup.el --- Org configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;; Org mode
(defvar hanxic/personal-org-map
  (make-sparse-keymap)
  "Personal preview commands.")

(global-set-key (kbd "C-c o") hanxic/personal-org-map)

(use-package org
  :init
  (setq-default fill-column 80)
  :hook (org-mode . visual-line-mode)
  :bind (("C-c o c" . org-capture)
         ("C-c o a" . org-agenda))
  :custom
  (org-highlight-latex-and-related '(latex))
  (org-use-sub-superscripts '{})
  (org-export-with-LaTeX-fragments t)
  (org-latex-create formula-image-program 'dvipng)
  (org-hide-emphasis-markers t)
  :config
  (setq org-format-latex-options
      '(:foreground "Black"
        :background "White"
        :scale 1.2           ; increase this to make math bigger
        :html-foreground "Black"
        :html-background "White"
        :html-scale 1.5
        :matchers ("begin" "$1" "$" "\\(" "\\[")))
  (use-package org-fragtog
    :ensure t
    :hook (org-mode . org-fragtog-mode))
  )
(use-package org-tree-slide
  :ensure t
  :after org
  :commands org-tree-slide-mode
  :init
  (setq org-tree-slide-skip-outline-level 0)
  )

;;;; Org-mode capture
(defconst hanxic/org-directory "~/.org/")
(defconst hanxic/org-projects-directory (concat hanxic/org-directory "projects/"))
(defconst hanxic/org-inbox-file (concat hanxic/org-directory "inbox.org"))

;; Ensure directories exist
(dolist (dir (list hanxic/org-directory hanxic/org-projects-directory))
(unless (file-exists-p dir) (make-directory dir t)))

;; Initialize inbox file
(unless (file-exists-p hanxic/org-inbox-file)
  (with-temp-file hanxic/org-inbox-file
    (insert "#+TITLE: Inbox\n\n* Thoughts\n\n* Next Steps\n\n* To Read\n")))

;; Step 1: Org-capture
(setq org-capture-templates
    `(("i" "Inbox")
        ("it" "Thought" entry
        (file+headline ,hanxic/org-inbox-file "Thoughts")
        "* %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n"
        :empty-lines 1)
        ("in" "Next Step" entry
        (file+headline ,hanxic/org-inbox-file "Next Steps")
        "* %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n"
        :empty-lines 1)
        ("ir" "To Read" entry
        (file+headline ,hanxic/org-inbox-file "To Read")
        "* %?\n:PROPERTIES:\n:CAPTURED: %U\n:URL: \n:END:\n"
        :empty-lines 1)))

;; Step 2: Clarify and organize in project
(defconst hanxic/org-projects-file (concat hanxic/org-directory "projects.org"))

;; Initialize projects.org
(unless (file-exists-p hanxic/org-projects-file)
(with-temp-file hanxic/org-projects-file
    (insert "#+TITLE: Projects\n\n")))

(provide 'org-setup)
;;; org-setup.el ends here
