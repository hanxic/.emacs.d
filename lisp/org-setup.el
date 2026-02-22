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

(setq org-priority-highest ?A
      org-priority-lowest ?C
      org-priority-default ?B
      org-priority-faces '((?A . (:foreground "red" :weight bold))
                           (?B . (:foreground "yellow"))
                           (?C . (:foreground "gray"))))
(setq org-priority-get-priority-function nil)

;; Map display names to org priority letters
(defconst hanxic/org-priority-alist
  '(("URGENT" . "A")
    ("NORMAL" . "B")
    ("LATER" . "C")))



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

;;;; Org Toggle Button
  ;;; ── Toggle commands ────────────────────────────────────

(defvar-local hanxic/org--descriptions-visible t
  "Whether descriptions are currently visible in projects.org.")

(defvar-local hanxic/org--details-visible t
  "Whether tasks/notes are currently visible in projects.org.")

(defun hanxic/org-projects-toggle-descriptions ()
  "Toggle visibility of all ** Description sections in projects.org."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^\\*\\* Description$" nil t)
      (if hanxic/org--descriptions-visible
          (outline-hide-subtree)
        (outline-show-subtree))))
  (setq hanxic/org--descriptions-visible (not hanxic/org--descriptions-visible))
  (message "Descriptions %s" (if hanxic/org--descriptions-visible "shown" "hidden")))

(defun hanxic/org-projects-toggle-details ()
  "Toggle visibility of all ** Tasks and ** Notes sections in projects.org."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^\\*\\* \\(Tasks\\|Notes\\)$" nil t)
      (if hanxic/org--details-visible
          (outline-hide-subtree)
        (outline-show-subtree))))
  (setq hanxic/org--details-visible (not hanxic/org--details-visible))
  (message "Tasks/Notes %s" (if hanxic/org--details-visible "shown" "hidden")))

;;;; Org Update
(defun hanxic/org-refresh-projects ()
    "Manually rebuild projects.org."
    (interactive)
    (hanxic/org--update-projects-file)
    (message "projects.org updated"))

;; Step 2: Clarify and organize in project
(defconst hanxic/org-projects-file (concat hanxic/org-directory "projects.org"))

;; Initialize projects.org
(unless (file-exists-p hanxic/org-projects-file)
  (with-temp-file hanxic/org-projects-file
    (insert "#+TITLE: Projects\n\n")))

(defvar hanxic/org-projects-display-properties '("CREATED" "TARGET" "TYPES")
  "List of property names to show under tasks/notes in projects.org.
Properties not found on an entry are silently ignored.")

(defun hanxic/org--slugify (name)
  "Turn NAME into a filesystem-safe slug."
  (downcase (replace-regexp-in-string
             "-+" "-"
             (replace-regexp-in-string "[^a-zA-Z0-9]" "-" (string-trim name)))))

(defun hanxic/org--project-slugs ()
  "Return list of project slugs that have a master .org file."
  (when (file-directory-p hanxic/org-projects-directory)
    (seq-filter
     (lambda (f)
       (and (file-directory-p (concat hanxic/org-projects-directory f))
            (not (string-prefix-p "." f))
            (file-exists-p (concat hanxic/org-projects-directory f "/" f ".org"))))
     (directory-files hanxic/org-projects-directory))))

(defun hanxic/org--read-keyword (file keyword)
  "Read the value of #+KEYWORD from FILE, or nil if not found."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward (format "^#\\+%s:[ \t]*\\(.*\\)$" (regexp-quote keyword)) nil t)
      (string-trim (match-string 1)))))

(defun hanxic/org--read-project-task-types (project-slug)
  "Read #+TASK_TYPES from PROJECT-SLUG's master file. Returns list of strings."
  (let* ((master (concat hanxic/org-projects-directory project-slug "/" project-slug ".org"))
         (raw (hanxic/org--read-keyword master "TASK_TYPES")))
    (when (and raw (not (string-empty-p raw)))
      (split-string raw))))

(defun hanxic/org-create-project (name)
  "Create project NAME with tasks/ and notes/ folders and a master sheet."
  (interactive "sProject name: ")
  (let* ((slug (hanxic/org--slugify name))
         (project-type (read-string "Project type (e.g. work, personal): "))
         (task-types (read-string "Task types (space-separated, e.g. step1 step2): "))
         (description (read-string "Project description: "))
         (project-dir (concat hanxic/org-projects-directory slug "/"))
         (master-file (concat project-dir slug ".org")))
    (dolist (d (list (concat project-dir "tasks/") (concat project-dir "notes/")))
      (make-directory d t))
    (unless (file-exists-p master-file)
      (with-temp-file master-file
        (insert (format "#+TITLE: %s\n#+CATEGORY: %s\n#+TYPE: %s\n#+TASK_TYPES: %s\n\n* Description\n%s\n\n* Tasks\n\n* Notes\n"
                        name slug project-type task-types description))))
    (hanxic/org--update-projects-file)
    (message "Project '%s' created at %s" name project-dir)
    slug))

  (defun hanxic/org-process-inbox-item ()
    "Process inbox item at point: assign priority, project, types, create task file."
    (interactive)
    (org-back-to-heading t)
    (let* ((heading (org-get-heading t t t t))
           (body (save-excursion
                   (org-end-of-meta-data t)
                   (string-trim
                    (buffer-substring-no-properties (point) (org-end-of-subtree t t)))))
           ;; Priority
           (priority-label (completing-read "Priority: " (mapcar #'car hanxic/org-priority-alist) nil t))
           (priority (cdr (assoc priority-label hanxic/org-priority-alist)))
           ;; Project
           (projects (hanxic/org--project-slugs))
           (choice (completing-read "Project: " (append projects '("+ New Project")) nil t))
           (project-slug (if (string= choice "+ New Project")
                             (hanxic/org-create-project (read-string "New project name: "))
                           choice))
           (project-dir (concat hanxic/org-projects-directory project-slug "/"))
           (master-file (concat project-dir project-slug ".org"))
           (tasks-dir (concat project-dir "tasks/"))
           ;; Task types
           (available-types (hanxic/org--read-project-task-types project-slug))
           (selected-types (when available-types
                             (completing-read-multiple
                              (format "Types (%s): " (string-join available-types " | "))
                              available-types)))
           (types-str (when selected-types (string-join selected-types " ")))
           ;; Target date
           (target (read-string "Target date (e.g. [2025-03-01], empty to skip): "))
           ;; Create linked file?
           (create-file (y-or-n-p "Create linked task file? "))
           ;; Task file
           (task-slug (hanxic/org--slugify heading))
           (task-file (concat tasks-dir task-slug ".org"))
           (created (format-time-string "[%Y-%m-%d]")))
      ;; Ensure project exists
      (unless (file-directory-p tasks-dir)
        (hanxic/org-create-project project-slug))
      ;; Write task detail file if requested
      (when create-file
        (with-temp-file task-file
          (insert (format "#+TITLE: %s\n#+PROJECT: %s\n#+CREATED: %s\n" heading project-slug created))
          (when (and target (not (string-empty-p target)))
            (insert (format "#+TARGET: %s\n" target)))
          (when types-str
            (insert (format "#+TYPES: %s\n" types-str)))
          (insert (format "\n%s\n" body))))
      ;; Link in master sheet under * Tasks
      (with-current-buffer (find-file-noselect master-file)
        (goto-char (point-min))
        (if (re-search-forward "^\\* Tasks" nil t)
            (org-end-of-subtree t)
          (goto-char (point-max)))
        (insert (format "\n** TODO [#%s] %s\n:PROPERTIES:\n" priority heading))
        (when create-file
          (insert (format ":TASK_FILE: [[file:tasks/%s.org]]\n" task-slug)))
        (insert (format ":CREATED: %s\n" created))
        (when (and target (not (string-empty-p target)))
          (insert (format ":TARGET: %s\n" target)))
        (when types-str
          (insert (format ":TYPES: %s\n" types-str)))
        (insert ":END:\n")
        (save-buffer))
      ;; Update projects.org
      (hanxic/org--update-projects-file)
      ;; Remove from inbox
      (org-back-to-heading t)
      (org-cut-subtree)
      (save-buffer)
      (message "→ '%s' filed under '%s' [#%s]" heading project-slug priority)))

  (defun hanxic/org-add-project-note ()
    "Create a new note in a project, optionally with a linked file."
    (interactive)
    (let* ((project-slug (completing-read "Project: " (hanxic/org--project-slugs) nil t))
           (project-dir (concat hanxic/org-projects-directory project-slug "/"))
           (master-file (concat project-dir project-slug ".org"))
           (notes-dir (concat project-dir "notes/"))
           (title (read-string "Note title: "))
           (available-types (hanxic/org--read-project-task-types project-slug))
           (selected-types (when available-types
                             (completing-read-multiple
                              (format "Types (%s): " (string-join available-types " | "))
                              available-types)))
           (types-str (when selected-types (string-join selected-types " ")))
           (create-file (y-or-n-p "Create linked note file? "))
           (note-slug (hanxic/org--slugify title))
           (note-file (concat notes-dir note-slug ".org"))
           (created (format-time-string "[%Y-%m-%d]")))
      ;; Write note file if requested
      (when create-file
        (with-temp-file note-file
          (insert (format "#+TITLE: %s\n#+PROJECT: %s\n#+CREATED: %s\n" title project-slug created))
          (when types-str
            (insert (format "#+TYPES: %s\n" types-str)))
          (insert "\n")))
      ;; Link in master sheet under * Notes
      (with-current-buffer (find-file-noselect master-file)
        (goto-char (point-min))
        (if (re-search-forward "^\\* Notes" nil t)
            (org-end-of-subtree t)
          (goto-char (point-max)))
        (insert (format "\n** %s\n:PROPERTIES:\n" title))
        (when create-file
          (insert (format ":NOTE_FILE: [[file:notes/%s.org]]\n" note-slug)))
        (insert (format ":CREATED: %s\n" created))
        (when types-str
          (insert (format ":TYPES: %s\n" types-str)))
        (insert ":END:\n")
        (save-buffer))
      (hanxic/org--update-projects-file)
      (when create-file
        (find-file note-file)
        (goto-char (point-max)))))

(defun hanxic/org--resolve-project-context ()
    "Determine project slug and section from current buffer and point.
  Works from both projects.org and a project master file.
  Returns (project-slug . section) where section is \"Tasks\" or \"Notes\"."
    (let ((file (buffer-file-name)))
      (cond
       ;; In projects.org — project is the * heading, section is the ** heading
       ((string= (expand-file-name file) (expand-file-name hanxic/org-projects-file))
        (let ((section (save-excursion
                         (outline-up-heading 1 t)
                         (org-get-heading t t t t)))
              (project-slug (save-excursion
                              (outline-up-heading 2 t)
                              ;; strip link markup to get slug
                              (let ((h (org-get-heading t t t t)))
                                (if (string-match "\\[\\[.*\\]\\[\\(.*\\)\\]\\]" h)
                                    (match-string 1 h)
                                  h)))))
          (cons project-slug section)))
       ;; In a project master file — project is filename, section is the * heading
       (t
        (let ((project-slug (file-name-sans-extension
                             (file-name-nondirectory file)))
              (section (save-excursion
                         (outline-up-heading 1 t)
                         (org-get-heading t t t t))))
          (cons project-slug section))))))

  (defun hanxic/org-create-linked-file ()
    "Create a linked file for the task/note entry at point.
  Works from both projects.org and a project master file."
    (interactive)
    (org-back-to-heading t)
    (let* ((ctx (hanxic/org--resolve-project-context))
           (project-slug (car ctx))
           (section (cdr ctx))
           (heading (org-get-heading t t t t))
           ;; Strip link/todo markup for clean title
           (clean-heading (if (string-match "\\[\\[.*\\]\\[\\(.*\\)\\]\\]" heading)
                              (match-string 1 heading)
                            heading))
           (slug (hanxic/org--slugify clean-heading))
           (is-task (string= section "Tasks"))
           (subdir (if is-task "tasks" "notes"))
           (prop-key (if is-task "TASK_FILE" "NOTE_FILE"))
           (project-dir (concat hanxic/org-projects-directory project-slug "/"))
           (master-file (concat project-dir project-slug ".org"))
           (target-dir (concat project-dir subdir "/"))
           (target-file (concat target-dir slug ".org"))
           ;; Read properties — try current entry first, fall back to master
           (created (org-entry-get nil "CREATED"))
           (target-date (org-entry-get nil "TARGET"))
           (types (org-entry-get nil "TYPES")))
      ;; Check if already linked
      (when (org-entry-get nil prop-key)
        (user-error "Entry already has a linked file"))
      (make-directory target-dir t)
      ;; Write linked file
      (with-temp-file target-file
        (insert (format "#+TITLE: %s\n#+PROJECT: %s\n" clean-heading project-slug))
        (when created (insert (format "#+CREATED: %s\n" created)))
        (when target-date (insert (format "#+TARGET: %s\n" target-date)))
        (when types (insert (format "#+TYPES: %s\n" types)))
        (insert "\n"))
      ;; Add link to master sheet entry (always update the master, not projects.org)
      (with-current-buffer (find-file-noselect master-file)
        (goto-char (point-min))
        (when (re-search-forward (format "^\\*\\* .*%s" (regexp-quote clean-heading)) nil t)
          (org-back-to-heading t)
          (org-set-property prop-key (format "[[file:%s/%s.org]]" subdir slug))
          (save-buffer)))
      (hanxic/org--update-projects-file)
      (find-file target-file)
      (goto-char (point-max))
      (message "Linked file created: %s" target-file)))

  (defun hanxic/org-toggle-task-note ()
    "Move the entry at point between Tasks and Notes.
  Works from both projects.org and a project master file.
  Also moves the linked file if one exists."
    (interactive)
    (let* ((ctx (hanxic/org--resolve-project-context))
           (project-slug (car ctx))
           (current-section (cdr ctx))
           (is-task (string= current-section "Tasks"))
           (target-section (if is-task "Notes" "Tasks"))
           (old-prop (if is-task "TASK_FILE" "NOTE_FILE"))
           (new-prop (if is-task "NOTE_FILE" "TASK_FILE"))
           (old-subdir (if is-task "tasks" "notes"))
           (new-subdir (if is-task "notes" "tasks"))
           (project-dir (concat hanxic/org-projects-directory project-slug "/"))
           (master-file (concat project-dir project-slug ".org"))
           (in-projects-org (string= (expand-file-name (buffer-file-name))
                                     (expand-file-name hanxic/org-projects-file))))
      ;; Always operate on the master file
      (with-current-buffer (find-file-noselect master-file)
        ;; If called from projects.org, find the matching entry in master
        (when in-projects-org
          (let ((heading (save-excursion
                           (with-current-buffer (find-file-noselect hanxic/org-projects-file)
                             (org-back-to-heading t)
                             (let ((h (org-get-heading t t t t)))
                               (if (string-match "\\[\\[.*\\]\\[\\(.*\\)\\]\\]" h)
                                   (match-string 1 h)
                                 h))))))
            (goto-char (point-min))
            (unless (re-search-forward (format "^\\*\\* .*%s" (regexp-quote heading)) nil t)
              (user-error "Cannot find '%s' in master file" heading))
            (org-back-to-heading t)))
        ;; Now at the entry in master file
        (let* ((heading (org-get-heading t t t t))
               (link-val (org-entry-get nil old-prop)))
          ;; Cut the subtree
          (org-cut-subtree)
          ;; Move linked file if it exists
          (when link-val
            (let* ((old-file-name (replace-regexp-in-string
                                   "\\[\\[file:\\(.*\\)\\]\\]" "\\1" link-val))
                   (old-path (concat project-dir old-file-name))
                   (file-base (file-name-nondirectory old-file-name))
                   (new-dir (concat project-dir new-subdir "/"))
                   (new-path (concat new-dir file-base)))
              (make-directory new-dir t)
              (when (file-exists-p old-path)
                (rename-file old-path new-path t))))
          ;; Find target section and paste
          (goto-char (point-min))
          (if (re-search-forward (format "^\\* %s" (regexp-quote target-section)) nil t)
              (org-end-of-subtree t)
            (goto-char (point-max)))
          (org-paste-subtree 2)
          ;; Update property key
          (org-back-to-heading t)
          (when link-val
            (org-delete-property old-prop)
            (let ((file-base (file-name-nondirectory
                              (replace-regexp-in-string
                               "\\[\\[file:\\(.*\\)\\]\\]" "\\1" link-val))))
              (org-set-property new-prop (format "[[file:%s/%s]]" new-subdir file-base))))
          (save-buffer)
          (hanxic/org--update-projects-file)
          (message "Moved '%s' from %s → %s" heading current-section target-section)))))

  ;;;; ── projects.org builder ───────────────────────────────

(defun hanxic/org--extract-entries (file section)
  "Extract sub-entries under * SECTION in FILE.
  Returns list of (heading . properties-alist)."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let (entries)
      (when (re-search-forward (format "^\\* %s" (regexp-quote section)) nil t)
        (let ((section-end (save-excursion
                             (if (re-search-forward "^\\* " nil t)
                                 (match-beginning 0)
                               (point-max)))))
          (while (re-search-forward "^\\*\\* \\(.*\\)$" section-end t)
            (let ((heading (match-string 1))
                  (props nil))
              (save-excursion
                (let ((entry-end (save-excursion
                                   (if (re-search-forward "^\\*\\* " section-end t)
                                       (match-beginning 0)
                                     section-end))))
                  (when (re-search-forward ":PROPERTIES:" entry-end t)
                    (let ((prop-end (save-excursion
                                      (re-search-forward ":END:" entry-end t)
                                      (point))))
                      (while (re-search-forward "^[ \t]*:\\([^:]+\\):[ \t]+\\(.*\\)$" prop-end t)
                        (push (cons (match-string 1) (string-trim (match-string 2))) props))))))
              (push (cons heading (nreverse props)) entries)))))
      (nreverse entries))))

(defun hanxic/org--extract-description (file)
  "Extract full text under * Description in FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward "^\\* Description\n" nil t)
      (let ((beg (point)))
        (if (re-search-forward "^\\* " nil t)
            (string-trim (buffer-substring-no-properties beg (match-beginning 0)))
          (string-trim (buffer-substring-no-properties beg (point-max))))))))

(defun hanxic/org--update-projects-file ()
  "Rebuild projects.org with descriptions, tasks, and notes for all projects."
  (with-current-buffer (find-file-noselect hanxic/org-projects-file)
    (erase-buffer)
    (insert "#+TITLE: Projects\n\n")
    (dolist (slug (hanxic/org--project-slugs))
      (let* ((master (concat hanxic/org-projects-directory slug "/" slug ".org"))
             (proj-type (hanxic/org--read-keyword master "TYPE"))
             (description (hanxic/org--extract-description master))
             (tasks (hanxic/org--extract-entries master "Tasks"))
             (notes (hanxic/org--extract-entries master "Notes")))
        ;; Project heading
        (let ((task-types (hanxic/org--read-keyword master "TASK_TYPES")))
          (insert (format "* [[file:projects/%s/%s.org][%s]]" slug slug slug))
          (when (and proj-type (not (string-empty-p proj-type)))
            (insert (format " (%s)" proj-type)))
          (when (and task-types (not (string-empty-p task-types)))
            (insert (format " [%s]" task-types)))
          (insert "\n"))
        ;; Description
        (insert "** Description\n")
        (when (and description (not (string-empty-p description)))
          (insert description "\n"))
        ;; Tasks
        (insert "** Tasks\n")
        (dolist (task tasks)
          (let ((heading (car task))
                (props (cdr task))
                (task-file (cdr (assoc "TASK_FILE" (cdr task)))))
            ;; Make heading a link if TASK_FILE exists
            (if task-file
                (let ((link (replace-regexp-in-string
                             "\\[\\[file:\\(.*\\)\\]\\]" "\\1" task-file)))
                  (insert (format "*** [[file:projects/%s/%s][%s]]\n"
                                  slug link
                                  (replace-regexp-in-string "^\\(TODO\\|DONE\\|NEXT\\|IN-PROGRESS\\|WAITING\\|CANCELLED\\)\\(?: \\[#[A-C]\\]\\)? " ""
                                                            heading))))
              (insert (format "*** %s\n" heading)))
            ;; Display configured properties
            (let ((display-props
                   (seq-filter #'identity
                               (mapcar (lambda (prop-name)
                                         (let ((val (cdr (assoc prop-name props))))
                                           (when (and val (not (string-empty-p val))
                                                      (not (string= prop-name "TASK_FILE")))
                                             (cons prop-name val))))
                                       hanxic/org-projects-display-properties))))
              (when display-props
                (insert ":PROPERTIES:\n")
                (dolist (p display-props)
                  (insert (format ":%s: %s\n" (car p) (cdr p))))
                (insert ":END:\n")))))
        ;; Notes
        (insert "** Notes\n")
        (dolist (note notes)
          (let ((heading (car note))
                (props (cdr note))
                (note-file (cdr (assoc "NOTE_FILE" (cdr note)))))
            (if note-file
                (let ((link (replace-regexp-in-string
                             "\\[\\[file:\\(.*\\)\\]\\]" "\\1" note-file)))
                  (insert (format "*** [[file:projects/%s/%s][%s]]\n" slug link heading)))
              (insert (format "*** %s\n" heading)))
            (let ((display-props
                   (seq-filter #'identity
                               (mapcar (lambda (prop-name)
                                         (let ((val (cdr (assoc prop-name props))))
                                           (when (and val (not (string-empty-p val))
                                                      (not (string= prop-name "NOTE_FILE")))
                                             (cons prop-name val))))
                                       hanxic/org-projects-display-properties))))
              (when display-props
                (insert ":PROPERTIES:\n")
                (dolist (p display-props)
                  (insert (format ":%s: %s\n" (car p) (cdr p))))
                (insert ":END:\n")))))
        (insert "\n")))
    (save-buffer)))

(provide 'org-setup)
;;; org-setup.el ends here
