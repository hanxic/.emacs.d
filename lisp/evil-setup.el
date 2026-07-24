;;; evil-setup.el --- Evil mode and related editing bindings  -*- lexical-binding: t; -*-

;;; Helper used inside evil config
(defun hanxic/indent-for-tab-command ()
  "Run indent-for-tab-command but keep point at the same column."
  (interactive)
  (let ((col (current-column)))
    (indent-for-tab-command)
    (move-to-column col)))

;;; Evil
(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-d-scroll t
        evil-want-C-u-scroll t
        evil-want-C-i-jump t)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)
  (evil-global-set-key 'normal (kbd "TAB") #'hanxic/indent-for-tab-command)
  (evil-global-set-key 'visual (kbd "TAB") #'hanxic/indent-for-tab-command)
  (evil-set-initial-state 'message-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

;; Disable evil in doc-view-mode
(defun hanxic/disable-evil-mode-in-doc-view ()
  (when (eq major-mode 'doc-view-mode)
    (evil-mode -1)))
(add-hook 'change-major-mode-hook 'hanxic/disable-evil-mode-in-doc-view)

;; Initial state overrides
(dolist (p '(fundamental-mode
             custom-mode
             eshell-mode
             git-rebase-mode
             erc-mode
             circe-server-mode
             circe-chat-mode
             circe-query-mode
             sauron-mode
             term-mode))
  (evil-set-initial-state p 'normal))

;; Isearch ring navigation
(define-key isearch-mode-map (kbd "<down>") 'isearch-ring-advance)
(define-key isearch-mode-map (kbd "<up>")   'isearch-ring-retreat)

;;; Generic `f`/`F` text objects: prompt for a char, select between matches.
;;; `;` / `,` reuse the last char (vim-style repeat).
(defvar hanxic/evil-find-char-last nil
  "Last char used by `hanxic/evil-a-find-char' / `hanxic/evil-inner-find-char'.")

(defun hanxic/evil--find-char-read ()
  (setq hanxic/evil-find-char-last (read-char "Char: ")))

(defun hanxic/evil--find-char-repeat ()
  (or hanxic/evil-find-char-last (user-error "No previous f/F")))

(with-eval-after-load 'evil
  (evil-define-text-object hanxic/evil-a-find-char (count &optional beg end type)
    (evil-select-quote (hanxic/evil--find-char-read) beg end type count t))
  (evil-define-text-object hanxic/evil-inner-find-char (count &optional beg end type)
    (evil-select-quote (hanxic/evil--find-char-read) beg end type count nil))
  (evil-define-text-object hanxic/evil-a-find-char-repeat (count &optional beg end type)
    (evil-select-quote (hanxic/evil--find-char-repeat) beg end type count t))
  (evil-define-text-object hanxic/evil-inner-find-char-repeat (count &optional beg end type)
    (evil-select-quote (hanxic/evil--find-char-repeat) beg end type count nil))
  (dolist (k '("f" "F"))
    (define-key evil-outer-text-objects-map k #'hanxic/evil-a-find-char)
    (define-key evil-inner-text-objects-map k #'hanxic/evil-inner-find-char))
  (dolist (k '(";" ","))
    (define-key evil-outer-text-objects-map k #'hanxic/evil-a-find-char-repeat)
    (define-key evil-inner-text-objects-map k #'hanxic/evil-inner-find-char-repeat)))

;;; Evil-collection
(use-package evil-collection
  :after evil
  :config
  (setq evil-collection-mode-list
        (remove 'flycheck evil-collection-mode-list))
  (evil-collection-init))

;;; Evil mode line tags
(setq evil-normal-state-tag   (propertize "[Normal]"   'face '((:background "green"  :foreground "black")))
      evil-emacs-state-tag    (propertize "[Emacs]"    'face '((:background "orange" :foreground "black")))
      evil-insert-state-tag   (propertize "[Insert]"   'face '((:background "red")   :foreground "white"))
      evil-motion-state-tag   (propertize "[Motion]"   'face '((:background "blue")  :foreground "white"))
      evil-visual-state-tag   (propertize "[Visual]"   'face '((:background "grey80" :foreground "black")))
      evil-operator-state-tag (propertize "[Operator]" 'face '((:background "purple"))))

;;; Evil-nerd-commenter
(use-package evil-nerd-commenter
  :after evil
  :bind ("M-;" . evilnc-comment-or-uncomment-lines))

;;; Indent commands (visual and normal)
(defun hanxic/evil-calculate-region ()
  "Calculate the region selected in Evil visual mode.
Returns a cons (BEG . END) of buffer positions."
  (interactive)
  (if (use-region-p)
      (pcase evil-visual-selection
        ('char
         (cons (region-beginning) (region-end)))
        ('line
         (let* ((beg (region-beginning))
                (end (- (region-end) 1))
                (beg-line (save-excursion (goto-char beg) (line-beginning-position)))
                (end-line (save-excursion (goto-char end) (pos-eol))))
           (cons beg-line end-line))))))

(defun hanxic/evil-indent-right-1 ()
  "Indent selected lines (or current line) by one step."
  (interactive)
  (let ((cursor-marker (point-marker))
        (col (current-column))
        (line (line-number-at-pos)))
    (if (use-region-p)
        (pcase evil-visual-selection
          ('char
           (let* ((beg (region-beginning))
                  (end (region-end))
                  (beg-line (save-excursion (goto-char beg) (line-beginning-position)))
                  (end-line (save-excursion (goto-char end) (pos-eol))))
             (indent-rigidly beg-line end-line 1)
             (evil-visual-select (1+ beg) end 'char)
             (goto-char (point-min))
             (forward-line (1- line))
             (move-to-column col)))
          ('line
           (let* ((beg (region-beginning))
                  (end (region-end))
                  (beg-line (line-number-at-pos beg))
                  (end-line (1- (line-number-at-pos end)))
                  (beg-pos (save-excursion (goto-line beg-line) (line-beginning-position)))
                  (end-pos (save-excursion (goto-line end-line) (line-end-position))))
             (indent-rigidly beg-pos end-pos 1)
             (evil-visual-select beg-pos beg-pos 'line)
             (goto-char beg-pos)
             (forward-line (- end-line beg-line))
             (move-to-column col))))
      (progn
        (indent-rigidly (line-beginning-position) (line-end-position) 1)
        (goto-char cursor-marker)))))

(defun hanxic/evil-indent-left-1 ()
  "Indent selected lines (or current line) by one step to the left."
  (interactive)
  (let ((cursor-marker (point-marker))
        (col (current-column))
        (line (line-number-at-pos)))
    (if (use-region-p)
        (pcase evil-visual-selection
          ('char
           (let* ((beg (region-beginning))
                  (end (region-end))
                  (beg-line (save-excursion (goto-char beg) (line-beginning-position)))
                  (end-line (save-excursion (goto-char end) (pos-eol))))
             (indent-rigidly beg-line end-line -1)
             (evil-visual-select (1- beg) end 'char)
             (goto-char (- end (- beg-line end-line)))))
          ('line
           (let* ((beg (region-beginning))
                  (end (region-end))
                  (beg-line (line-number-at-pos beg))
                  (end-line (1- (line-number-at-pos end)))
                  (beg-pos (save-excursion (goto-line beg-line) (line-beginning-position)))
                  (end-pos (save-excursion (goto-line end-line) (line-end-position))))
             (indent-rigidly beg-pos end-pos -1)
             (evil-visual-select beg-pos beg-pos 'line)
             (goto-char beg-pos)
             (forward-line (- end-line beg-line))
             (move-to-column col))))
      (progn
        (indent-rigidly (line-beginning-position) (line-end-position) -1)
        (goto-char cursor-marker)))))

(defvar hanxic-indent-keymap (make-sparse-keymap)
  "Keymap for indentation commands after C-<tab>.")
(define-key hanxic-indent-keymap (kbd "<right>") #'hanxic/evil-indent-right-1)
(define-key hanxic-indent-keymap (kbd "<left>")  #'hanxic/evil-indent-left-1)
(global-set-key (kbd "C-<tab>") hanxic-indent-keymap)
(define-key evil-normal-state-map (kbd "C-<tab>") hanxic-indent-keymap)
(define-key evil-visual-state-map (kbd "C-<tab>") hanxic-indent-keymap)

(provide 'evil-setup)
;;; evil-setup.el ends here
