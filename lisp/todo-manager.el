;;; todo-manager.el --- Dired-like todo manager backed by org -*- lexical-binding: t; -*-
;;; Commentary:
;; A tabulated-list interface for todos stored flat in a single org file.
;; Open with M-x hanxic/todo or C-c o t.
;;
;; Keybindings (shown in header line):
;;   a       Add a new todo
;;   d       Delete todo at point
;;   t       Cycle state forward (TODO → NEXT → IN-PROGRESS → ...)
;;   T       Choose state from a list
;;   p       Set priority
;;   s       Set schedule / due date
;;   RET     Open notes pane for the todo at point
;;   /       Filter by tag
;;   \       Clear tag filter
;;   g       Refresh
;;   o       Open todos.org directly
;;   q       Quit
;;; Code:

(require 'org)
(require 'tabulated-list)

;;;; ── Config ─────────────────────────────────────────────

(defvar hanxic/todo-file
  (expand-file-name "~/.org/todos.org")
  "Path to the todos org file.  All todos live here as top-level headings.")

(defvar hanxic/todo-notify-lookahead 15
  "Fire a macOS notification when a todo is due within this many minutes.")

(defconst hanxic/todo-states
  '("TODO" "NEXT" "IN-PROGRESS" "WAITING" "DONE" "CANCELLED")
  "Ordered list of todo states.")

;;;; ── Faces ──────────────────────────────────────────────

(defface hanxic/todo-state-todo
  '((t :foreground "#d09070")) "Face for TODO state.")
(defface hanxic/todo-state-next
  '((t :foreground "#40c8e0" :weight bold)) "Face for NEXT state.")
(defface hanxic/todo-state-inprogress
  '((t :foreground "#d8b840" :weight bold)) "Face for IN-PROGRESS state.")
(defface hanxic/todo-state-waiting
  '((t :foreground "#c08840")) "Face for WAITING state.")
(defface hanxic/todo-state-done
  '((t :foreground "#60a860")) "Face for DONE state.")
(defface hanxic/todo-state-cancelled
  '((t :foreground "#686868")) "Face for CANCELLED state.")
(defface hanxic/todo-priority-a
  '((t :foreground "#e05858" :weight bold)) "Face for [A] Urgent priority.")
(defface hanxic/todo-priority-b
  '((t :foreground "#d0a840")) "Face for [B] Normal priority.")
(defface hanxic/todo-priority-c
  '((t :foreground "#909090")) "Face for [C] Later priority.")
(defface hanxic/todo-due-overdue
  '((t :foreground "#e05858" :weight bold)) "Face for overdue items.")
(defface hanxic/todo-due-today
  '((t :foreground "#e89040")) "Face for items due today.")
(defface hanxic/todo-due-soon
  '((t :foreground "#c8b840")) "Face for items due within 3 days.")
(defface hanxic/todo-tags
  '((t :foreground "#5898d8")) "Face for tag display.")
(defface hanxic/todo-done-title
  '((t :foreground "#686868")) "Face for DONE/CANCELLED titles.")

;;;; ── Icons & Face Maps ───────────────────────────────────

(defconst hanxic/todo--state-icons
  '(("TODO"        . "○")
    ("NEXT"        . "→")
    ("IN-PROGRESS" . "⟳")
    ("WAITING"     . "⏸")
    ("DONE"        . "✓")
    ("CANCELLED"   . "✗")))

(defconst hanxic/todo--state-faces
  '(("TODO"        . hanxic/todo-state-todo)
    ("NEXT"        . hanxic/todo-state-next)
    ("IN-PROGRESS" . hanxic/todo-state-inprogress)
    ("WAITING"     . hanxic/todo-state-waiting)
    ("DONE"        . hanxic/todo-state-done)
    ("CANCELLED"   . hanxic/todo-state-cancelled)))

;;;; ── Data Layer ─────────────────────────────────────────

(defun hanxic/todo--ensure-file ()
  "Create `hanxic/todo-file' if it does not exist."
  (unless (file-exists-p hanxic/todo-file)
    (make-directory (file-name-directory hanxic/todo-file) t)
    (with-temp-file hanxic/todo-file
      (insert "#+TITLE: Todos\n"
              "#+TODO: TODO NEXT IN-PROGRESS WAITING | DONE CANCELLED\n\n"))))

(defun hanxic/todo--parse ()
  "Return a list of todo plists from `hanxic/todo-file'.
Each plist has: :pos :title :state :prio :tags :due"
  (hanxic/todo--ensure-file)
  (let (todos)
    (with-current-buffer (find-file-noselect hanxic/todo-file)
      (org-with-wide-buffer
       (goto-char (point-min))
       (while (outline-next-heading)
         (when (= (org-outline-level) 1)
           (let* ((pos   (point))
                  (state (or (org-get-todo-state) ""))
                  (title (org-get-heading t t t t))
                  (prio  (org-entry-get nil "PRIORITY"))
                  (tags  (string-join (org-get-tags nil t) " "))
                  (dead  (org-entry-get nil "DEADLINE"))
                  (sched (org-entry-get nil "SCHEDULED"))
                  (due   (or dead sched "")))
             (push (list :pos   pos
                         :title title
                         :state state
                         :prio  (if (and prio (not (string= prio " "))) prio "")
                         :tags  tags
                         :due   due)
                   todos))))))
    (nreverse todos)))

(defun hanxic/todo--all-tags ()
  "Return sorted unique list of all tags currently used in todos.org."
  (let (tags)
    (dolist (todo (ignore-errors (hanxic/todo--parse)))
      (let ((t-tags (plist-get todo :tags)))
        (when (and t-tags (not (string-empty-p t-tags)))
          (dolist (tag (split-string t-tags))
            (push tag tags)))))
    (seq-uniq (sort tags #'string<))))

(defun hanxic/todo--read-tags ()
  "Read tags using helm multi-select if available, else completing-read-multiple.
Returns a list of tag strings (may be empty)."
  (let* ((candidates (hanxic/todo--all-tags))
         (result
          (if (fboundp 'helm-comp-read)
              (helm-comp-read
               "Tags (M-SPC to mark multiple, RET to confirm): "
               (or candidates '(""))
               :marked-candidates t
               :must-match nil
               :fuzzy t
               :buffer "*helm-todo-tags*")
            (completing-read-multiple
             "Tags (comma-separated, TAB for hints): "
             candidates))))
    (cond
     ((null result)          '())
     ((listp result)         (seq-filter (lambda (s) (not (string-empty-p (string-trim s)))) result))
     ((string-empty-p result) '())
     (t                      (list result)))))

(defun hanxic/todo--next-hour-string ()
  "Return a time string for the next whole hour, e.g. \"15:00\"."
  (let* ((now  (decode-time))
         (hour (mod (1+ (nth 2 now)) 24)))
    (format "%02d:00" hour)))

(defun hanxic/todo--read-date-time ()
  "Interactively read an optional date (org calendar) and optional time.
Returns a due string like \"2026-04-20 10:00\", \"2026-04-20\", or nil."
  (let* ((date (condition-case nil
                   (org-read-date nil nil nil "Due date (C-g to skip): "
                                  (current-time))
                 (quit nil))))
    (when date
      (let* ((default-time (hanxic/todo--next-hour-string))
             (input (read-string
                     (format "Time HH:MM (RET for %s, empty to skip): "
                             default-time)
                     nil nil default-time))
             (time (unless (string-empty-p (string-trim input)) (string-trim input))))
        (if time (concat date " " time) date)))))

(defun hanxic/todo--add (title tags due-string)
  "Append a new TODO heading to `hanxic/todo-file'."
  (hanxic/todo--ensure-file)
  (with-current-buffer (find-file-noselect hanxic/todo-file)
    (goto-char (point-max))
    (unless (bolp) (insert "\n"))
    (let ((tag-part (when (and tags (not (string-empty-p (string-trim tags))))
                      (concat "  :"
                              (string-join (split-string (string-trim tags)) ":")
                              ":"))))
      (insert (format "* TODO %s%s\n" title (or tag-part ""))))
    (when (and due-string (not (string-empty-p (string-trim due-string))))
      (org-back-to-heading t)
      (org-schedule nil due-string))
    (save-buffer)))

(defun hanxic/todo--at-pos (pos fn)
  "In `hanxic/todo-file', move to POS, call FN with no args, then save."
  (with-current-buffer (find-file-noselect hanxic/todo-file)
    (goto-char pos)
    (org-back-to-heading t)
    (funcall fn)
    (save-buffer)))

(defun hanxic/todo--delete-at (pos)
  (hanxic/todo--at-pos pos #'org-cut-subtree))

(defun hanxic/todo--set-state-at (pos state)
  (hanxic/todo--at-pos pos (lambda () (org-todo state))))

(defun hanxic/todo--cycle-state-at (pos)
  (hanxic/todo--at-pos pos (lambda () (org-todo 'right))))

(defun hanxic/todo--set-priority-at (pos char)
  "Set priority CHAR (?A ?B ?C or ?\\s to clear) at POS."
  (hanxic/todo--at-pos pos (lambda () (org-priority char))))

(defun hanxic/todo--set-tags-at (pos tags-str)
  "Set tags from space-separated TAGS-STR at POS."
  (hanxic/todo--at-pos pos
   (lambda () (org-set-tags (split-string (string-trim tags-str))))))

(defun hanxic/todo--schedule-at (pos date-str)
  (hanxic/todo--at-pos pos (lambda () (org-schedule nil date-str))))

;;;; ── Display Formatters ─────────────────────────────────

(defun hanxic/todo--fmt-state (state)
  (let* ((icon  (or (cdr (assoc state hanxic/todo--state-icons)) " "))
         (face  (or (cdr (assoc state hanxic/todo--state-faces)) 'default)))
    (propertize (concat icon " " state) 'face face)))

(defun hanxic/todo--fmt-priority (prio)
  (pcase prio
    ("A" (propertize "[A]" 'face 'hanxic/todo-priority-a))
    ("B" (propertize "[B]" 'face 'hanxic/todo-priority-b))
    ("C" (propertize "[C]" 'face 'hanxic/todo-priority-c))
    (_   "   ")))

(defun hanxic/todo--fmt-title (title state)
  (propertize title 'face
              (if (member state '("DONE" "CANCELLED"))
                  'hanxic/todo-done-title
                'default)))

(defun hanxic/todo--fmt-tags (tags)
  (if (string-empty-p tags)
      ""
    (propertize (concat "#" (replace-regexp-in-string " " " #" tags))
                'face 'hanxic/todo-tags)))

(defun hanxic/todo--fmt-due (due-str)
  (if (or (null due-str) (string-empty-p due-str))
      ""
    (let* ((due-time (ignore-errors (float-time (org-time-string-to-time due-str))))
           (now      (float-time))
           (diff     (when due-time (/ (- due-time now) 86400.0)))
           (display  (when due-time
                       (format-time-string "%b %d" (seconds-to-time due-time))))
           (face     (cond
                      ((null diff)  'default)
                      ((< diff 0)   'hanxic/todo-due-overdue)
                      ((< diff 1)   'hanxic/todo-due-today)
                      ((< diff 3)   'hanxic/todo-due-soon)
                      (t            'default))))
      (propertize (or display "") 'face face))))

(defun hanxic/todo--make-entries (todos)
  "Convert parsed TODOS into tabulated-list entry vectors."
  (mapcar
   (lambda (todo)
     (let ((pos   (plist-get todo :pos))
           (state (plist-get todo :state))
           (title (plist-get todo :title))
           (prio  (plist-get todo :prio))
           (tags  (plist-get todo :tags))
           (due   (plist-get todo :due)))
       (list pos
             (vector
              (hanxic/todo--fmt-state state)
              (hanxic/todo--fmt-priority prio)
              (hanxic/todo--fmt-title title state)
              (hanxic/todo--fmt-tags tags)
              (hanxic/todo--fmt-due due)))))
   todos))

;;;; ── Buffer State ────────────────────────────────────────

(defvar-local hanxic/todo--filter nil
  "Active tag filter string, or nil.")

;;;; ── Refresh ─────────────────────────────────────────────

(defun hanxic/todo--update-header ()
  (setq header-line-format
        (if hanxic/todo--filter
            (format "  Filter: #%s   (\\: clear all)  |  ?: help"
                    hanxic/todo--filter)
          "  a:add  d:del  t:cycle-state  T:set-state  p:priority  s:schedule  RET:notes  /:filter  g:refresh  q:quit"))
  (force-mode-line-update))

(defun hanxic/todo-refresh ()
  "Re-parse todos.org and redisplay."
  (interactive)
  (let* ((all      (hanxic/todo--parse))
         (filtered (if hanxic/todo--filter
                       (seq-filter
                        (lambda (todo)
                          (string-match-p
                           (regexp-quote hanxic/todo--filter)
                           (plist-get todo :tags)))
                        all)
                     all)))
    (setq tabulated-list-entries (hanxic/todo--make-entries filtered))
    (tabulated-list-print t)
    (hanxic/todo--update-header)))

;;;; ── Commands ────────────────────────────────────────────

(defun hanxic/todo-add ()
  "Prompt for title, tags (with hints), date (calendar), time, then add."
  (interactive)
  (let* ((title (read-string "New todo: "))
         (_ (when (string-empty-p title) (user-error "Title cannot be empty")))
         (tag-list (hanxic/todo--read-tags))
         (tags     (string-join tag-list " "))
         (due  (hanxic/todo--read-date-time)))
    (hanxic/todo--add title tags due)
    (hanxic/todo-refresh)
    (message "Added: %s" title)))

(defun hanxic/todo-delete ()
  "Delete the todo at point after confirmation."
  (interactive)
  (when-let* ((pos   (tabulated-list-get-id))
              (entry (tabulated-list-get-entry))
              (title (substring-no-properties (aref entry 2))))
    (when (yes-or-no-p (format "Delete \"%s\"? " title))
      (hanxic/todo--delete-at pos)
      (hanxic/todo-refresh)
      (message "Deleted."))))

(defun hanxic/todo-cycle-state ()
  "Cycle the state of the todo at point forward."
  (interactive)
  (when-let ((pos (tabulated-list-get-id)))
    (hanxic/todo--cycle-state-at pos)
    (hanxic/todo-refresh)))

(defun hanxic/todo-set-state ()
  "Choose a specific state for the todo at point."
  (interactive)
  (when-let ((pos (tabulated-list-get-id)))
    (let ((state (completing-read "State: " hanxic/todo-states nil t)))
      (hanxic/todo--set-state-at pos state)
      (hanxic/todo-refresh))))

(defun hanxic/todo-set-priority ()
  "Set priority for the todo at point."
  (interactive)
  (when-let ((pos (tabulated-list-get-id)))
    (let* ((choices '(("A — Urgent" . ?A)
                      ("B — Normal" . ?B)
                      ("C — Later"  . ?C)
                      ("none"       . ?\s)))
           (choice (completing-read "Priority: " (mapcar #'car choices) nil t))
           (char   (cdr (assoc choice choices))))
      (hanxic/todo--set-priority-at pos char)
      (hanxic/todo-refresh))))

(defun hanxic/todo-schedule ()
  "Set a due date/time for the todo at point using the org calendar picker."
  (interactive)
  (when-let ((pos (tabulated-list-get-id)))
    (when-let ((due (hanxic/todo--read-date-time)))
      (hanxic/todo--schedule-at pos due)
      (hanxic/todo-refresh))))

(defun hanxic/todo-open-notes ()
  "Open todos.org at the entry at point so you can read/write notes."
  (interactive)
  (when-let ((pos (tabulated-list-get-id)))
    (find-file-other-window hanxic/todo-file)
    (goto-char pos)
    (org-show-entry)
    (org-end-of-meta-data t)))

(defun hanxic/todo-filter ()
  "Filter the list to a single tag.  Empty input clears the filter."
  (interactive)
  (let* ((prompt (if hanxic/todo--filter
                     (format "Filter by tag (current: %s, RET to clear): "
                             hanxic/todo--filter)
                   "Filter by tag: "))
         (input  (read-string prompt)))
    (setq hanxic/todo--filter (if (string-empty-p input) nil input))
    (hanxic/todo-refresh)))

(defun hanxic/todo-clear-filter ()
  "Clear the active tag filter."
  (interactive)
  (setq hanxic/todo--filter nil)
  (hanxic/todo-refresh))

(defun hanxic/todo-open-file ()
  "Open todos.org in another window."
  (interactive)
  (find-file-other-window hanxic/todo-file))

;;;; ── Notifications ──────────────────────────────────────

(defvar hanxic/todo--notify-timer nil)
(defvar hanxic/todo--notified-keys (make-hash-table :test 'equal))

(defun hanxic/todo--fire-notification (title body)
  "Fire a macOS notification with TITLE and BODY."
  (call-process "osascript" nil nil nil "-e"
                (format "display notification %S with title %S sound name \"default\""
                        body title)))

(defun hanxic/todo--check-due ()
  "Check todos.org for items due soon and fire macOS notifications."
  (let* ((todos  (ignore-errors (hanxic/todo--parse)))
         (now    (float-time))
         (window (* hanxic/todo-notify-lookahead 60)))
    (dolist (todo todos)
      (let* ((state (plist-get todo :state))
             (due   (plist-get todo :due))
             (title (plist-get todo :title)))
        (when (and due
                   (not (string-empty-p due))
                   (not (member state '("DONE" "CANCELLED"))))
          (let* ((due-time (ignore-errors
                             (float-time (org-time-string-to-time due))))
                 (key      (concat title "|" due)))
            (when (and due-time
                       (>= due-time now)
                       (<= due-time (+ now window))
                       (not (gethash key hanxic/todo--notified-keys)))
              (puthash key t hanxic/todo--notified-keys)
              (hanxic/todo--fire-notification
               "Todo Due Soon"
               (format "%s — due at %s"
                       title
                       (format-time-string "%H:%M"
                                           (seconds-to-time due-time)))))))))))

(defun hanxic/todo-start-notifications ()
  "Start a background timer that checks for upcoming todos every 60 s."
  (interactive)
  (unless hanxic/todo--notify-timer
    (setq hanxic/todo--notify-timer
          (run-with-timer 30 60 #'hanxic/todo--check-due))
    (message "Todo notifications active.")))

(defun hanxic/todo-stop-notifications ()
  "Stop the notification timer."
  (interactive)
  (when hanxic/todo--notify-timer
    (cancel-timer hanxic/todo--notify-timer)
    (setq hanxic/todo--notify-timer nil)
    (message "Todo notifications stopped.")))

;;;; ── Mode Definition ─────────────────────────────────────

(defvar hanxic/todo-mode-map
  (let ((map (make-sparse-keymap)))
    ;; navigation (for emacs state / no evil)
    (define-key map (kbd "j")   #'next-line)
    (define-key map (kbd "k")   #'previous-line)
    ;; actions
    (define-key map (kbd "a")   #'hanxic/todo-add)
    (define-key map (kbd "d")   #'hanxic/todo-delete)
    (define-key map (kbd "t")   #'hanxic/todo-cycle-state)
    (define-key map (kbd "T")   #'hanxic/todo-set-state)
    (define-key map (kbd "p")   #'hanxic/todo-set-priority)
    (define-key map (kbd "s")   #'hanxic/todo-schedule)
    (define-key map (kbd "RET") #'hanxic/todo-open-notes)
    (define-key map (kbd "/")   #'hanxic/todo-filter)
    (define-key map (kbd "\\")  #'hanxic/todo-clear-filter)
    (define-key map (kbd "g")   #'hanxic/todo-refresh)
    (define-key map (kbd "o")   #'hanxic/todo-open-file)
    (define-key map (kbd "q")   #'quit-window)
    map)
  "Keymap for `hanxic/todo-mode'.")

(define-derived-mode hanxic/todo-mode tabulated-list-mode "Todos"
  "A dired-like interface for managing todos in an org file.
All todos are top-level headings in `hanxic/todo-file'.
Notes live as body text or sub-headings under each todo."
  (setq tabulated-list-format
        [("State"  16 t)
         ("P"       4 t)
         ("Title"  42 t)
         ("Tags"   22 t)
         ("Due"    10 nil)])
  (setq tabulated-list-padding 1)
  (tabulated-list-init-header)
  ;; Use emacs state so single-letter keys work without pressing i
  (when (fboundp 'evil-set-initial-state)
    (evil-set-initial-state 'hanxic/todo-mode 'emacs))
  (hanxic/todo-refresh))

;;;; ── Entry Point ─────────────────────────────────────────

;;;###autoload
(defun hanxic/todo ()
  "Open the todo manager buffer and start due-date notifications."
  (interactive)
  (let ((buf (get-buffer-create "*Todos*")))
    (with-current-buffer buf
      (unless (eq major-mode 'hanxic/todo-mode)
        (hanxic/todo-mode)))
    (switch-to-buffer buf))
  (hanxic/todo-start-notifications))

(provide 'todo-manager)
;;; todo-manager.el ends here
