;;; early-init.el --- Loaded before package system and first frame  -*- lexical-binding: t; -*-

;;; Commentary:
;; Runs before `package.el' and before the initial frame is created.
;; Used for startup-critical settings only; everything else lives in init.el.

;;; Code:

;;; GC: disable during startup, restored in init.el's `after-init-hook'.
;; The default 800 KB threshold triggers dozens of collections while loading
;; packages; raising it here removes that cost from the startup path.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;;; Packages: init.el calls `package-initialize' explicitly, so tell the
;; startup sequence not to do it a second time before init.el runs.
(setq package-enable-at-startup nil)

;;; Frames: avoid implied resizes and paint the chrome off from the start
;; instead of drawing then removing it (core-settings.el keeps them off for
;; running frames).
(setq frame-inhibit-implied-resize t)
(push '(menu-bar-lines . 0)   default-frame-alist)
(push '(tool-bar-lines . 0)   default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

;;; Skip the site-wide default init file.
(setq site-run-file nil)

;;; early-init.el ends here
