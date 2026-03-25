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

(defvar hanxic/org-agenda-normal-keys
  '(("TAB" . org-agenda-goto)
    ("RET" . org-agenda-switch-to)
    ("+" . org-agenda-priority-up)
    ("-" . org-agenda-priority-down)
    ("d" . org-agenda-day-view)
    ("w" . org-agenda-week-view)
    ))

(with-eval-after-load 'org-agenda
  (evil-set-initial-state 'org-agenda-mode 'normal)
  (dolist (binding hanxic/org-agenda-normal-keys)
    (evil-define-key 'normal org-agenda-mode-map
      (kbd (car binding)) (cdr binding))))

(use-package org-tree-slide
  :ensure t
  :after org
  :commands org-tree-slide-mode
  :init
  (setq org-tree-slide-skip-outline-level 0)
  )

;;;; ── Section Configuration ──────────────────────────────

(defvar hanxic/org-project-sections
  '(("Tasks" . (:subdir "tasks"
                        :file-prop "TASK_FILE"
                        :has-todo t
                        :sort-done-last t
                        :display ("CREATED" "TARGET" "TYPES")))
    ("Notes" . (:subdir "notes"
                        :file-prop "NOTE_FILE"
                        :has-todo nil
                        :sort-done-last nil
                        :display ("CREATED" "TYPES"))))
  "Project section definitions. Each entry is (NAME . PLIST).
  :subdir          - subdirectory for linked files
  :file-prop       - property name for the linked file
  :has-todo        - whether entries carry TODO keywords
  :sort-done-last  - whether to sort DONE/CANCELLED below active
  :display         - list of properties to show in projects.org")

(defun hanxic/org--section-get (section key)
  "Get KEY from SECTION config in `hanxic/org-project-sections'."
  (plist-get (cdr (assoc section hanxic/org-project-sections)) key))

(defun hanxic/org--section-names ()
  "Return list of configured section names."
  (mapcar #'car hanxic/org-project-sections))

(defun hanxic/org--section-for-prop (prop)
  "Find which section uses PROP as its :file-prop."
  (car (seq-find (lambda (s) (string= (plist-get (cdr s) :file-prop) prop))
                 hanxic/org-project-sections)))

;;;; ── Priority (Re)Configuration ──────────────────────────────

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

;;;; ── Constants & Init ──────────────────────────────

(defconst hanxic/org-directory "~/.org/")
(defconst hanxic/org-projects-directory (concat hanxic/org-directory "projects/"))
(defconst hanxic/org-inbox-file (concat hanxic/org-directory "inbox.org"))
(defconst hanxic/org-projects-file (concat hanxic/org-directory "projects.org"))

;; Ensure directories exist
(dolist (dir (list hanxic/org-directory hanxic/org-projects-directory))
  (unless (file-exists-p dir) (make-directory dir t)))

;; Initialize inbox file
(unless (file-exists-p hanxic/org-inbox-file)
  (with-temp-file hanxic/org-inbox-file
    (insert "#+TITLE: Inbox\n\n* Thoughts\n\n* Next Steps\n\n* To Read\n")))

(unless (file-exists-p hanxic/org-projects-file)
  (with-temp-file hanxic/org-projects-file
    (insert "#+TITLE: Projects\n\n")))

;;;; ── Helpers ────────────────────────────────────────────
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
  "Read #+TASK_TYPES from PROJECT-SLUG's master file."
  (let* ((master (concat hanxic/org-projects-directory project-slug "/" project-slug ".org"))
         (raw (hanxic/org--read-keyword master "TASK_TYPES")))
    (when (and raw (not (string-empty-p raw)))
      (split-string raw))))

(defun hanxic/org--resolve-project-context ()
  "Determine project slug and section from current buffer and point.
  Works from both projects.org and a project master file.
  Returns (project-slug . section)."
  (let ((file (buffer-file-name)))
    (cond
     ((string= (expand-file-name file) (expand-file-name hanxic/org-projects-file))
      (let ((section (save-excursion
                       (outline-up-heading 1 t)
                       (org-get-heading t t t t)))
            (project-slug (save-excursion
                            (outline-up-heading 2 t)
                            (let ((h (org-get-heading t t t t)))
                              (if (string-match "\\[\\[.*\\]\\[\\(.*\\)\\]\\]" h)
                                  (match-string 1 h)
                                h)))))
        (cons project-slug section)))
     (t
      (let ((project-slug (file-name-sans-extension
                           (file-name-nondirectory file)))
            (section (save-excursion
                       (outline-up-heading 1 t)
                       (org-get-heading t t t t))))
        (cons project-slug section))))))

(defun hanxic/org--task-done-p (heading)
  "Return non-nil if HEADING starts with a done keyword."
  (string-match "^\\(DONE\\|CANCELLED\\)" heading))

;;;; ── 1. CAPTURE ─────────────────────────────────────────

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

;;;; ── 2 & 3. CLARIFY & ORGANIZE ──────────────────────────

(defun hanxic/org-create-project (name)
  "Create project NAME with folders for each configured section."
  (interactive "sProject name: ")
  (let* ((slug (hanxic/org--slugify name))
         (project-type (read-string "Project type (e.g. work, personal): "))
         (task-types (read-string "Task types (space-separated, e.g. step1 step2): "))
         (description (read-string "Project description: "))
         (project-dir (concat hanxic/org-projects-directory slug "/"))
         (master-file (concat project-dir slug ".org")))
    ;; Create subdirs for each section
    (dolist (sec hanxic/org-project-sections)
      (make-directory (concat project-dir (plist-get (cdr sec) :subdir) "/") t))
    (unless (file-exists-p master-file)
      (with-temp-file master-file
        (insert (format "#+TITLE: %s\n#+CATEGORY: %s\n#+TYPE: %s\n#+TASK_TYPES: %s\n\n* Description\n%s\n"
                        name slug project-type task-types description))
        ;; Create a * heading for each section
        (dolist (sec hanxic/org-project-sections)
          (insert (format "\n* %s\n" (car sec))))))
    (hanxic/org--update-projects-file)
    (message "Project '%s' created at %s" name project-dir)
    slug))

(defun hanxic/org-add-entry (section-name)
  "Add an entry to SECTION-NAME of a project. Prompts for project, title, types, linked file."
  (interactive
   (list (completing-read "Section: " (hanxic/org--section-names) nil t)))
  (let* ((has-todo (hanxic/org--section-get section-name :has-todo))
         (file-prop (hanxic/org--section-get section-name :file-prop))
         (subdir (hanxic/org--section-get section-name :subdir))
         ;; Project
         (project-slug (completing-read "Project: " (hanxic/org--project-slugs) nil t))
         (project-dir (concat hanxic/org-projects-directory project-slug "/"))
         (master-file (concat project-dir project-slug ".org"))
         ;; Entry details
         (title (read-string (format "%s title: " section-name)))
         (available-types (hanxic/org--read-project-task-types project-slug))
         (selected-types (when available-types
                           (completing-read-multiple
                            (format "Types (%s): " (string-join available-types " | "))
                            available-types)))
         (types-str (when selected-types (string-join selected-types " ")))
         ;; Priority (only for todo sections)
         (priority (when has-todo
                     (let ((label (completing-read "Priority: " (mapcar #'car hanxic/org-priority-alist) nil t)))
                       (cdr (assoc label hanxic/org-priority-alist)))))
         ;; Target date (only for todo sections)
           (schedule-date (when has-todo
                   (read-string "Start date (e.g. 2025-03-01, empty to skip): ")))
           (deadline-date (when has-todo
                            (read-string "Deadline (e.g. 2025-03-01, empty to skip): ")))
         ;; Linked file
         (create-file (y-or-n-p "Create linked file? "))
         (slug (hanxic/org--slugify title))
         (linked-file (concat project-dir subdir "/" slug ".org"))
         (created (format-time-string "[%Y-%m-%d]")))
    ;; Write linked file
    (when create-file
      (make-directory (concat project-dir subdir "/") t)
      (with-temp-file linked-file
        (insert (format "#+TITLE: %s\n#+PROJECT: %s\n#+CREATED: %s\n" title project-slug created))
        (when (and schedule-date (not (string-empty-p schedule-date)))
          (insert (format "SCHEDULED: <%s>\n" schedule-date)))
        (when (and deadline-date (not (string-empty-p deadline-date)))
          (insert (format "DEADLINE: <%s>\n" deadline-date)))
        (when types-str
          (insert (format "#+TYPES: %s\n" types-str)))
        (insert "\n")))
    ;; Add to master sheet
    (with-current-buffer (find-file-noselect master-file)
      (goto-char (point-min))
      (if (re-search-forward (format "^\\* %s" (regexp-quote section-name)) nil t)
          (org-end-of-subtree t)
        (goto-char (point-max)))
      ;; Heading
      (if (and has-todo priority)
          (insert (format "\n** TODO [#%s] %s\n" priority title))
        (insert (format "\n** %s\n" title)))
      ;; Properties
      (insert ":PROPERTIES:\n")
      (when create-file
        (insert (format ":%s: [[file:%s/%s.org]]\n" file-prop subdir slug)))
      (insert (format ":CREATED: %s\n" created))
      (when (and target (not (string-empty-p target)))
        (insert (format ":TARGET: %s\n" target)))
      (when types-str
        (insert (format ":TYPES: %s\n" types-str)))
      (insert ":END:\n")
      (save-buffer))
    (hanxic/org--update-projects-file)
    (when create-file
      (find-file linked-file)
      (goto-char (point-max)))))

(defun hanxic/org-process-inbox-item ()
  "Process inbox item at point: assign to a section of a project."
  (interactive)
  (org-back-to-heading t)
  (let* ((heading (org-get-heading t t t t))
         (body (save-excursion
                 (org-end-of-meta-data t)
                 (string-trim
                  (buffer-substring-no-properties (point) (org-end-of-subtree t t)))))
         ;; Pick section
         (section-name (completing-read "Section: " (hanxic/org--section-names) nil t))
         (has-todo (hanxic/org--section-get section-name :has-todo))
         (file-prop (hanxic/org--section-get section-name :file-prop))
         (subdir (hanxic/org--section-get section-name :subdir))
         ;; Priority
         (priority (when has-todo
                     (let ((label (completing-read "Priority: " (mapcar #'car hanxic/org-priority-alist) nil t)))
                       (cdr (assoc label hanxic/org-priority-alist)))))
         ;; Project
         (projects (hanxic/org--project-slugs))
         (choice (completing-read "Project: " (append projects '("+ New Project")) nil t))
         (project-slug (if (string= choice "+ New Project")
                           (hanxic/org-create-project (read-string "New project name: "))
                         choice))
         (project-dir (concat hanxic/org-projects-directory project-slug "/"))
         (master-file (concat project-dir project-slug ".org"))
         ;; Types
         (available-types (hanxic/org--read-project-task-types project-slug))
         (selected-types (when available-types
                           (completing-read-multiple
                            (format "Types (%s): " (string-join available-types " | "))
                            available-types)))
         (types-str (when selected-types (string-join selected-types " ")))
         ;; Target
         (target (when has-todo
                   (read-string "Target date (e.g. [2025-03-01], empty to skip): ")))
         ;; Linked file
         (create-file (y-or-n-p "Create linked file? "))
         (slug (hanxic/org--slugify heading))
         (linked-file (concat project-dir subdir "/" slug ".org"))
         (created (format-time-string "[%Y-%m-%d]")))
    (make-directory (concat project-dir subdir "/") t)
    ;; Write linked file
    (when create-file
      (with-temp-file linked-file
        (insert (format "#+TITLE: %s\n#+PROJECT: %s\n#+CREATED: %s\n" heading project-slug created))
        (when (and target (not (string-empty-p target)))
          (insert (format "#+TARGET: %s\n" target)))
        (when types-str
          (insert (format "#+TYPES: %s\n" types-str)))
        (insert (format "\n%s\n" body))))
    ;; Add to master sheet
    (with-current-buffer (find-file-noselect master-file)
      (goto-char (point-min))
      (if (re-search-forward (format "^\\* %s" (regexp-quote section-name)) nil t)
          (org-end-of-subtree t)
        (goto-char (point-max)))
      (if (and has-todo priority)
          (insert (format "\n** TODO [#%s] %s\n" priority heading))
        (insert (format "\n** %s\n" heading)))
      (insert ":PROPERTIES:\n")
      (when create-file
        (insert (format ":%s: [[file:%s/%s.org]]\n" file-prop subdir slug)))
      (insert (format ":CREATED: %s\n" created))
      (when (and target (not (string-empty-p target)))
        (insert (format ":TARGET: %s\n" target)))
      (when types-str
        (insert (format ":TYPES: %s\n" types-str)))
      (insert ":END:\n")
      (save-buffer))
    (hanxic/org--update-projects-file)
    ;; Remove from inbox
    (org-back-to-heading t)
    (org-cut-subtree)
    (save-buffer)
    (message "→ '%s' filed under %s/%s [#%s]" heading project-slug section-name (or priority "-"))))

;;;; ── Move Entry ─────────────────────────────────────────

(defun hanxic/org-move-entry ()
  "Move the entry at point to a different section.
  Adds/strips TODO based on target section config."
  (interactive)
  (let* ((ctx (hanxic/org--resolve-project-context))
         (project-slug (car ctx))
         (current-section (cdr ctx))
         (project-dir (concat hanxic/org-projects-directory project-slug "/"))
         (master-file (concat project-dir project-slug ".org"))
         (in-projects-org (string= (expand-file-name (buffer-file-name))
                                   (expand-file-name hanxic/org-projects-file)))
         ;; Pick target
         (targets (seq-remove (lambda (s) (or (string= s current-section)
                                              (string= s "Description")))
                              (hanxic/org--section-names)))
         (target-section (completing-read
                          (format "Move from %s to: " current-section)
                          targets nil t))
         (from-todo (hanxic/org--section-get current-section :has-todo))
         (to-todo (hanxic/org--section-get target-section :has-todo))
         (old-prop (hanxic/org--section-get current-section :file-prop))
         (new-prop (hanxic/org--section-get target-section :file-prop))
         (old-subdir (hanxic/org--section-get current-section :subdir))
         (new-subdir (hanxic/org--section-get target-section :subdir)))
    (with-current-buffer (find-file-noselect master-file)
      ;; Navigate to entry in master if called from projects.org
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
      (let* ((heading (org-get-heading t t t t))
             (link-val (when old-prop (org-entry-get nil old-prop))))
        ;; Adjust TODO
        (cond
         ((and from-todo (not to-todo))
          (org-todo "")
          (org-priority ?\s))
         ((and (not from-todo) to-todo)
          (org-todo "TODO")))
        ;; Cut
        (org-cut-subtree)
        ;; Move linked file
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
        ;; Paste in target section
        (goto-char (point-min))
        (if (re-search-forward (format "^\\* %s" (regexp-quote target-section)) nil t)
            (org-end-of-subtree t)
          (goto-char (point-max)))
        (org-paste-subtree 2)
        ;; Update property key
        (org-back-to-heading t)
        (when (and link-val old-prop new-prop)
          (org-delete-property old-prop)
          (let ((file-base (file-name-nondirectory
                            (replace-regexp-in-string
                             "\\[\\[file:\\(.*\\)\\]\\]" "\\1" link-val))))
            (org-set-property new-prop (format "[[file:%s/%s]]" new-subdir file-base))))
        (save-buffer)
        (hanxic/org--update-projects-file)
        (message "Moved '%s' from %s → %s" heading current-section target-section)))))

;;;; ── Create Linked File ─────────────────────────────────

(defun hanxic/org-create-linked-file ()
  "Create a linked file for the entry at point.
  Works from both projects.org and a project master file."
  (interactive)
  (org-back-to-heading t)
  (let* ((ctx (hanxic/org--resolve-project-context))
         (project-slug (car ctx))
         (section (cdr ctx))
         (file-prop (hanxic/org--section-get section :file-prop))
         (subdir (hanxic/org--section-get section :subdir))
         (heading (org-get-heading t t t t))
         (clean-heading (if (string-match "\\[\\[.*\\]\\[\\(.*\\)\\]\\]" heading)
                            (match-string 1 heading)
                          heading))
         (slug (hanxic/org--slugify clean-heading))
         (project-dir (concat hanxic/org-projects-directory project-slug "/"))
         (master-file (concat project-dir project-slug ".org"))
         (target-dir (concat project-dir subdir "/"))
         (target-file (concat target-dir slug ".org"))
         (created (org-entry-get nil "CREATED"))
         (target-date (org-entry-get nil "TARGET"))
         (types (org-entry-get nil "TYPES")))
    (when (org-entry-get nil file-prop)
      (user-error "Entry already has a linked file"))
    (make-directory target-dir t)
    (with-temp-file target-file
      (insert (format "#+TITLE: %s\n#+PROJECT: %s\n" clean-heading project-slug))
      (when created (insert (format "#+CREATED: %s\n" created)))
      (when target-date (insert (format "#+TARGET: %s\n" target-date)))
      (when types (insert (format "#+TYPES: %s\n" types)))
      (insert "\n"))
    (with-current-buffer (find-file-noselect master-file)
      (goto-char (point-min))
      (when (re-search-forward (format "^\\*\\* .*%s" (regexp-quote clean-heading)) nil t)
        (org-back-to-heading t)
        (org-set-property file-prop (format "[[file:%s/%s.org]]" subdir slug))
        (save-buffer)))
    (hanxic/org--update-projects-file)
    (find-file target-file)
    (goto-char (point-max))
    (message "Linked file created: %s" target-file)))

;;;; ── projects.org Builder ───────────────────────────────

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
  "Rebuild projects.org driven by `hanxic/org-project-sections'."
  (with-current-buffer (find-file-noselect hanxic/org-projects-file)
    (erase-buffer)
    (insert "#+TITLE: Projects\n\n")
    (dolist (slug (hanxic/org--project-slugs))
      (let* ((master (concat hanxic/org-projects-directory slug "/" slug ".org"))
             (proj-type (hanxic/org--read-keyword master "TYPE"))
             (task-types (hanxic/org--read-keyword master "TASK_TYPES"))
             (description (hanxic/org--extract-description master)))
        ;; Project heading
        (insert (format "* [[file:projects/%s/%s.org][%s]]" slug slug slug))
        (when (and proj-type (not (string-empty-p proj-type)))
          (insert (format " (%s)" proj-type)))
        (when (and task-types (not (string-empty-p task-types)))
          (insert (format " [%s]" task-types)))
        (insert "\n")
        ;; Description
        (insert "** Description\n")
        (when (and description (not (string-empty-p description)))
          (insert description "\n"))
        ;; Each configured section
        (dolist (sec hanxic/org-project-sections)
          (let* ((sec-name (car sec))
                 (sec-conf (cdr sec))
                 (file-prop (plist-get sec-conf :file-prop))
                 (subdir (plist-get sec-conf :subdir))
                 (sort-done (plist-get sec-conf :sort-done-last))
                 (display-props (plist-get sec-conf :display))
                 (entries (hanxic/org--extract-entries master sec-name))
                 (sorted (if sort-done
                             (append
                              (seq-remove (lambda (e) (hanxic/org--task-done-p (car e))) entries)
                              (seq-filter (lambda (e) (hanxic/org--task-done-p (car e))) entries))
                           entries)))
            (insert (format "** %s\n" sec-name))
            (dolist (entry sorted)
              (let* ((heading (car entry))
                     (props (cdr entry))
                     (link-val (cdr (assoc file-prop props)))
                     ;; Strip TODO/priority for display title
                     (display-title (replace-regexp-in-string
                                     "^\\(TODO\\|DONE\\|NEXT\\|IN-PROGRESS\\|WAITING\\|CANCELLED\\)\\(?: \\[#[A-C]\\]\\)? "
                                     "" heading))
                     (has-todo (plist-get sec-conf :has-todo))
                     (todo-prefix (if (and has-todo (string-match "^\\(\\(?:TODO\\|DONE\\|NEXT\\|IN-PROGRESS\\|WAITING\\|CANCELLED\\)\\(?: \\[#[A-C]\\]\\)?\\) " heading))
                                         (concat (match-string 1 heading) " ")
                                       ""))
                     )
                ;; Heading with link if available
                (if link-val
                    (let ((link (replace-regexp-in-string
                                 "\\[\\[file:\\(.*\\)\\]\\]" "\\1" link-val)))
                      (insert (format "*** %s[[file:projects/%s/%s][%s]]\n" todo-prefix slug link display-title)))
                  (insert (format "*** %s%s\n" todo-prefix display-title)))
                ;; Configured properties
                (let ((visible-props
                       (seq-filter #'identity
                                   (mapcar (lambda (prop-name)
                                             (let ((val (cdr (assoc prop-name props))))
                                               (when (and val (not (string-empty-p val))
                                                          (not (string= prop-name file-prop)))
                                                 (cons prop-name val))))
                                           display-props))))
                  (when visible-props
                    (insert ":PROPERTIES:\n")
                    (dolist (p visible-props)
                      (insert (format ":%s: %s\n" (car p) (cdr p))))
                    (insert ":END:\n")))))))
        (insert "\n")))
    (save-buffer)))

;;;; ── Toggle Visibility ──────────────────────────────────

(defvar-local hanxic/org--descriptions-visible t)
(defvar-local hanxic/org--details-visible t)

(defun hanxic/org-projects-toggle-descriptions ()
  "Toggle all ** Description sections."
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
  "Toggle all section headings (Tasks, Notes, etc.)."
  (interactive)
  (let ((pattern (format "^\\*\\* \\(%s\\)$"
                         (mapconcat #'regexp-quote (hanxic/org--section-names) "\\|"))))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward pattern nil t)
        (if hanxic/org--details-visible
            (outline-hide-subtree)
          (outline-show-subtree)))))
  (setq hanxic/org--details-visible (not hanxic/org--details-visible))
  (message "Details %s" (if hanxic/org--details-visible "shown" "hidden")))

;;;; ── Review & Engage ────────────────────────────────────

(defun hanxic/org--collect-project-files ()
  "Return list of all project master .org files."
  (let (files)
    (dolist (slug (hanxic/org--project-slugs) files)
      (let ((f (concat hanxic/org-projects-directory slug "/" slug ".org")))
        (when (file-exists-p f) (push f files))))))

(defun hanxic/org-refresh-agenda-files ()
  "Rebuild `org-agenda-files' from inbox + project master sheets."
  (interactive)
  (setq org-agenda-files
        (append (when (file-exists-p hanxic/org-inbox-file)
                  (list hanxic/org-inbox-file))
                (hanxic/org--collect-project-files))))

(defun hanxic/org-refresh-projects ()
  "Manually rebuild projects.org."
  (interactive)
  (hanxic/org--update-projects-file)
  (message "projects.org updated"))

(advice-add 'org-agenda :before (lambda (&rest _) (hanxic/org-refresh-agenda-files)))

(setq org-agenda-custom-commands
      `(("g" "GTD Review"
         ((agenda "" ((org-agenda-span 'week)
                      (org-deadline-warning-days 7)
                      (org-agenda-overriding-header "Schedule")))
          (todo "NEXT"
                ((org-agenda-overriding-header "Next Actions")
                 (org-agenda-sorting-strategy '(priority-down category-up))))
          (todo "IN-PROGRESS"
                ((org-agenda-overriding-header "In Progress")
                 (org-agenda-sorting-strategy '(priority-down category-up))))
          (todo "WAITING"
                ((org-agenda-overriding-header "Waiting On")
                 (org-agenda-sorting-strategy '(category-up))))
          (todo "TODO"
                ((org-agenda-overriding-header "Backlog")
                 (org-agenda-sorting-strategy '(priority-down category-up))))))
        ("i" "Inbox"
         ((alltodo ""
                   ((org-agenda-files ,(list hanxic/org-inbox-file))
                    (org-agenda-overriding-header "Unprocessed Inbox")))))))

(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "IN-PROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))

;;;; ── Dependencies ────────────────────────────────────
(require 'org-id)

;;;; ── Dependencies ───────────────────────────────────────

(defun hanxic/org-set-dependency ()
  "Add a BLOCKER dependency on the entry at point.
  Prompts to select a task from the same project."
  (interactive)
  (let* ((ctx (hanxic/org--resolve-project-context))
         (project-slug (car ctx))
         (master-file (concat hanxic/org-projects-directory project-slug "/" project-slug ".org"))
         ;; Collect all task headings from the project
         (tasks (mapcar #'car (hanxic/org--extract-entries master-file "Tasks")))
         (current (org-get-heading t t t t))
         ;; Remove current task from choices
         (choices (seq-remove (lambda (t_) (string= t_ current)) tasks))
         (blocker (completing-read "Blocked by: " choices nil t))
         (existing (org-entry-get nil "BLOCKER")))
    (org-set-property "BLOCKER"
                      (if (and existing (not (string-empty-p existing)))
                          (concat existing ", " blocker)
                        blocker))
    (save-buffer)
    (message "Added blocker: %s" blocker)))

(defun hanxic/org-remove-dependency ()
  "Remove a BLOCKER dependency from the entry at point."
  (interactive)
  (let* ((existing (org-entry-get nil "BLOCKER")))
    (if (or (null existing) (string-empty-p existing))
        (message "No blockers on this entry")
      (let* ((blockers (split-string existing ", "))
             (to-remove (completing-read "Remove blocker: " blockers nil t))
             (remaining (seq-remove (lambda (b) (string= b to-remove)) blockers))
             (new-val (string-join remaining ", ")))
        (if (string-empty-p new-val)
            (org-delete-property "BLOCKER")
          (org-set-property "BLOCKER" new-val))
        (save-buffer)
        (message "Removed blocker: %s" to-remove)))))

(defun hanxic/org--entry-blocked-p ()
  "Return non-nil if the entry at point has unfinished blockers."
  (let ((blockers (org-entry-get nil "BLOCKER")))
    (when (and blockers (not (string-empty-p blockers)))
      (let* ((blocker-list (split-string blockers ", "))
             (ctx (hanxic/org--resolve-project-context))
             (project-slug (car ctx))
             (master-file (concat hanxic/org-projects-directory project-slug "/" project-slug ".org"))
             (tasks (hanxic/org--extract-entries master-file "Tasks")))
        ;; Check if any blocker is not DONE/CANCELLED
        (seq-some (lambda (b)
                    (let ((entry (seq-find (lambda (t_)
                                             (string-match-p (regexp-quote b) (car t_)))
                                           tasks)))
                      (when entry
                        (not (string-match "^\\(DONE\\|CANCELLED\\)" (car entry))))))
                  blocker-list)))))

;;;; ── Scheduling helpers ─────────────────────────────────

(defun hanxic/org-agenda-set-types ()
  "Set TYPES on the agenda entry at point."
  (interactive)
  (org-agenda-check-no-diary)
  (let* ((marker (or (org-get-at-bol 'org-marker)
                     (org-agenda-error)))
         (buf (marker-buffer marker))
         (pos (marker-position marker)))
    (with-current-buffer buf
      (goto-char pos)
      (let* ((ctx (hanxic/org--resolve-project-context))
             (project-slug (car ctx))
             (available-types (hanxic/org--read-project-task-types project-slug))
             (selected (when available-types
                         (completing-read-multiple
                          (format "Types (%s): " (string-join available-types " | "))
                          available-types)))
             (types-str (when selected (string-join selected " "))))
        (when types-str
          (org-set-property "TYPES" types-str)
          (save-buffer))))
    (org-agenda-redo)))

(defun hanxic/org-agenda-set-dependency ()
  "Set BLOCKER on the agenda entry at point."
  (interactive)
  (org-agenda-check-no-diary)
  (let* ((marker (or (org-get-at-bol 'org-marker)
                     (org-agenda-error)))
         (buf (marker-buffer marker))
         (pos (marker-position marker)))
    (with-current-buffer buf
      (goto-char pos)
      (hanxic/org-set-dependency))
    (org-agenda-redo)))

(defun hanxic/org-agenda-remove-dependency ()
  "Remove BLOCKER on the agenda entry at point."
  (interactive)
  (org-agenda-check-no-diary)
  (let* ((marker (or (org-get-at-bol 'org-marker)
                     (org-agenda-error)))
         (buf (marker-buffer marker))
         (pos (marker-position marker)))
    (with-current-buffer buf
      (goto-char pos)
      (hanxic/org-remove-dependency))
    (org-agenda-redo)))

;;;; ── Agenda views ───────────────────────────────────────

(setq org-agenda-custom-commands
      `(("d" "Daily Schedule"
         ((agenda "" ((org-agenda-span 'day)
                      (org-agenda-start-on-weekday nil)
                      (org-deadline-warning-days 7)))))

        ("g" "GTD Review"
         ((agenda "" ((org-agenda-span 'day)
                      (org-deadline-warning-days 3)))
          (todo "NEXT"
                ((org-agenda-overriding-header "Next Actions")
                 (org-agenda-sorting-strategy '(priority-down category-up))))
          (todo "IN-PROGRESS"
                ((org-agenda-overriding-header "In Progress")
                 (org-agenda-sorting-strategy '(priority-down category-up))))
          (todo "WAITING"
                ((org-agenda-overriding-header "Waiting On")
                 (org-agenda-sorting-strategy '(category-up))))
          (todo "TODO"
                ((org-agenda-overriding-header "Backlog")
                 (org-agenda-sorting-strategy '(priority-down category-up))))))

        ("p" "By Project"
         ((alltodo ""
                   ((org-agenda-overriding-header "Tasks by Project")
                    (org-agenda-sorting-strategy '(category-up todo-state-up priority-down))
                    (org-agenda-prefix-format " %c | %(org-entry-get nil \"CREATED\") |")))))

        ("b" "Blocked Tasks"
         ((tags "BLOCKER<>\"\""
                ((org-agenda-overriding-header "Tasks with Dependencies")
                 (org-agenda-sorting-strategy '(category-up priority-down))))))

        ("i" "Inbox"
         ((alltodo ""
                   ((org-agenda-files ,(list hanxic/org-inbox-file))
                    (org-agenda-overriding-header "Unprocessed Inbox")))))))


(provide 'org-setup)
;;; org-setup.el ends here
