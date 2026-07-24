;;; org-setup.el --- Org configuration, rebuilt incrementally  -*- lexical-binding: t; -*-

;;; Commentary:
;; Rebuilt from scratch after the first attempt grew into an unused monster.
;; Rule: nothing is added until its absence has actually hurt.  Each step ships
;; ONE capability; we live with it before adding the next.
;;
;; The plan:
;;   1. Journal      — one append-only file for random thoughts.   [DONE]
;;   2. Todos        — a task list + a file-specific key cheat-sheet + reminders.
;;   3. Note-taking  — notes with good math rendering.               [math preview DONE]
;;
;; Step 1 keys (under C-c o):
;;   C-c o j   jump to the journal and start a new timestamped entry (insert)
;;   C-c o o   open the journal to read / browse
;; Math preview (Step 3, works in any org buffer):
;;   type $...$ or \[...\] — leave the fragment and it renders in place;
;;   move point back onto it and it becomes editable LaTeX again (org-fragtog).
;;   C-c C-x C-l   toggle the preview at point by hand if you want to.
;; Notes (Step 3): a flat pile of .org files in ~/research/scratch/.
;;   C-c o n   new note  (prompts a title -> YYYYMMDD-slug.org, drops you in)
;;   C-c o f   find/open an existing note by name
;;   manage    just dired the folder: d/x delete, R rename, m move.

;;; Code:

;;;; ── Prefix map ─────────────────────────────────────────
(defvar hanxic/personal-org-map (make-sparse-keymap)
  "Personal org command prefix, bound to C-c o.")
(global-set-key (kbd "C-c o") hanxic/personal-org-map)

;;;; ── Org itself (minimal) ───────────────────────────────
(use-package org
  :hook (org-mode . visual-line-mode)
  :custom
  ;; Render $...$, \(...\), \[...\] and begin/end blocks as inline images.
  ;; dvisvgm gives vector-sharp math (dvipng is the older bitmap route); the
  ;; binary is installed, so prefer it.
  (org-preview-latex-default-process 'dvisvgm)
  ;; Treat {} after _/^ as grouping so a_{ij} previews correctly.
  (org-use-sub-superscripts '{})
  :config
  ;; :foreground 'default makes the math ink follow the current theme instead
  ;; of a hard-coded black; bump :scale until the size feels right.
  (setq org-format-latex-options
        (plist-put org-format-latex-options :foreground 'default))
  (setq org-format-latex-options
        (plist-put org-format-latex-options :scale 1.5)))

;;;; ── Step 3 (partial): live math preview ────────────────
;; org-fragtog is the "select it and redo it again" half: it auto-renders a
;; fragment the moment your cursor leaves it, and turns the image back into
;; editable LaTeX the moment your cursor re-enters it.  No key to remember.
(use-package org-fragtog
  :ensure t
  :hook (org-mode . org-fragtog-mode))

;;;; ── Step 1: Journal ────────────────────────────────────
(defconst hanxic/org-directory (expand-file-name "~/.org/")
  "Root directory for personal org files.")

(defconst hanxic/journal-file (expand-file-name "journal.org" hanxic/org-directory)
  "Single append-only file for random thoughts.")

;;; Cleanup of accidental empty entries.
(declare-function org-back-to-heading "org" (&optional invisible-ok))
(declare-function org-end-of-subtree "org" (&optional invisible-ok to-heading))
(declare-function org-get-heading "org" (&optional no-tags no-todo no-priority no-comment))

(defun hanxic/journal--blank-string-p (s)
  "Non-nil if S is nil, empty, or only whitespace."
  (string-match-p "\\`[ \t\n\r]*\\'" (or s "")))

(defun hanxic/journal--body-blank-p ()
  "Non-nil if the subtree at point has nothing below its heading line.
For a day heading this also means it has no child thoughts left."
  (save-excursion
    (org-back-to-heading t)
    (let ((beg (line-end-position))
          (end (progn (org-end-of-subtree t t) (point))))
      (hanxic/journal--blank-string-p
       (buffer-substring-no-properties beg end)))))

(defun hanxic/journal--delete-subtree ()
  "Delete the whole subtree at point: heading, body and trailing blanks."
  (org-back-to-heading t)
  (delete-region (point) (progn (org-end-of-subtree t t) (point))))

(defun hanxic/journal-cleanup ()
  "Remove empty stubs from anywhere in the journal.
An entry is deleted when it holds no input:
  - a `** ' thought with a blank title AND no body, or
  - a `* ' day heading left with no thoughts and no body.
Scans the whole file, deleting bottom-up so positions stay valid.  Handy
after you open the journal by accident and type nothing; also runs
automatically on open via `hanxic/journal'."
  (interactive)
  (let ((buf (find-file-noselect hanxic/journal-file))
        (removed 0))
    (with-current-buffer buf
      (org-with-wide-buffer
       ;; Pass 1: empty ** thoughts (walk backward so deletions never shift
       ;; positions we still have to visit).  Match `** foo', `** ' and a
       ;; bare `**' (trailing space may be stripped on save).
       (goto-char (point-max))
       (while (re-search-backward "^\\*\\* \\|^\\*\\*$" nil t)
         (when (and (hanxic/journal--blank-string-p (org-get-heading t t t t))
                    (hanxic/journal--body-blank-p))
           (hanxic/journal--delete-subtree)
           (setq removed (1+ removed))))
       ;; Pass 2: day headings that pass 1 left hollow.
       (goto-char (point-max))
       (while (re-search-backward "^\\* " nil t)
         (when (hanxic/journal--body-blank-p)
           (hanxic/journal--delete-subtree)
           (setq removed (1+ removed)))))
      (when (> removed 0) (save-buffer)))
    (when (called-interactively-p 'interactive)
      (message "Journal cleanup: removed %d empty entr%s"
               removed (if (= removed 1) "y" "ies")))
    removed))

(defun hanxic/journal ()
  "Jump to the journal, at the end of today's entries.
If today's `* YYYY-MM-DD Day' heading does not exist yet, append it plus one
empty `** ' sub-entry and drop into insert state so you can start typing.
If it already exists, just open the file at the end and let you edit."
  (interactive)
  (unless (file-directory-p hanxic/org-directory)
    (make-directory hanxic/org-directory t))
  (find-file hanxic/journal-file)
  (when (= (point-min) (point-max))
    (insert "#+TITLE: Journal\n"))
  ;; Sweep away any empty stubs left from a previous accidental open before we
  ;; decide whether today's heading exists.
  (hanxic/journal-cleanup)
  (let ((day (format-time-string "%Y-%m-%d %A")))
    (if (save-excursion
          (goto-char (point-min))
          (re-search-forward (concat "^\\* " (regexp-quote day) "$") nil t))
        ;; Existing day: just land at the end, no scaffolding.
        (goto-char (point-max))
      ;; New day: scaffold the date heading + one empty sub-entry.
      (goto-char (point-max))
      (unless (bolp) (insert "\n"))
      (insert "\n* " day "\n** ")
      (when (fboundp 'org-fold-show-entry) (org-fold-show-entry))
      (when (fboundp 'evil-insert-state) (evil-insert-state)))))

(defun hanxic/journal-open ()
  "Open the journal for reading / browsing (no new entry)."
  (interactive)
  (find-file hanxic/journal-file))

(define-key hanxic/personal-org-map (kbd "j") #'hanxic/journal)
(define-key hanxic/personal-org-map (kbd "o") #'hanxic/journal-open)
(define-key hanxic/personal-org-map (kbd "x") #'hanxic/journal-cleanup)

;;;; ── Step 3 (partial): notes ────────────────────────────
;; A flat folder of .org files — no database, no backlinks.  Filenames follow
;; the YYYYMMDD-slug convention so they sort by date, never collide, and could
;; be handed to Denote later without renaming anything.  Finding is by name;
;; managing (delete/rename/move) is just dired on the folder.
(defconst hanxic/notes-directory (expand-file-name "~/research/scratch/")
  "Flat directory of ad-hoc .org notes (math and general).")

(defun hanxic/note--slugify (title)
  "Turn TITLE into a filename-safe slug: lowercase words joined by hyphens."
  (let ((s (replace-regexp-in-string
            "\\`-+\\|-+\\'" ""
            (replace-regexp-in-string "[^a-z0-9]+" "-" (downcase title)))))
    (if (string-empty-p s) "note" s)))

(defun hanxic/note-new (title)
  "Create a new note titled TITLE in `hanxic/notes-directory'.
The file is named YYYYMMDD-slug.org and seeded with a #+TITLE header; you
land in insert state with math preview live.  If the name already exists you
are asked before opening it instead."
  (interactive "sNote title: ")
  (unless (file-directory-p hanxic/notes-directory)
    (make-directory hanxic/notes-directory t))
  (let* ((base (concat (format-time-string "%Y%m%d") "-"
                       (hanxic/note--slugify title) ".org"))
         (file (expand-file-name base hanxic/notes-directory)))
    (when (and (file-exists-p file)
               (not (y-or-n-p (format "%s already exists; open it? " base))))
      (user-error "Aborted"))
    (find-file file)
    (when (= (point-min) (point-max))
      (insert "#+TITLE: " title "\n\n")
      (when (fboundp 'evil-insert-state) (evil-insert-state)))))

(defun hanxic/note-find ()
  "Open an existing note from `hanxic/notes-directory' by name.
Uses `completing-read' (helm), so you can fuzzy-filter by any word in the
filename; the date prefix and slug make that behave like title search."
  (interactive)
  (unless (file-directory-p hanxic/notes-directory)
    (user-error "No notes directory yet: %s" hanxic/notes-directory))
  (let ((files (directory-files hanxic/notes-directory nil "\\.org\\'")))
    (unless files (user-error "No .org notes in %s" hanxic/notes-directory))
    (find-file (expand-file-name
                (completing-read "Note: " files nil t)
                hanxic/notes-directory))))

(define-key hanxic/personal-org-map (kbd "n") #'hanxic/note-new)
(define-key hanxic/personal-org-map (kbd "f") #'hanxic/note-find)

(provide 'org-setup)
;;; org-setup.el ends here
