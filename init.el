;;; init.el --- Emacs initialization file -*- lexical-binding: t -*-
;;
;;; Commentary:
;;
;;; Code:

;;--- General Setup --------------------------------------------------

;; Setup straight.
;;
;; https://github.com/raxod502/straight.el#getting-started
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Enable use-package integration.
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; Store settings generated by the customize interface in a separate
;; file.
;;
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Saving-Customizations.html
(setq custom-file (concat user-emacs-directory "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; This directory contains additional libraries that are not available
;; via straight.
(add-to-list 'load-path (concat user-emacs-directory "lisp"))

;;--- Load Packages --------------------------------------------------

;; Provides functions for loading environment variables, which are
;; stored in files, into the running Emacs process.
(require 'parsenv)

;; Vim key bindings.
(use-package undo-tree
  :config
  (setq undo-tree-auto-save-history t)
  (global-undo-tree-mode))
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :config
  (evil-set-undo-system 'undo-tree)
  (evil-mode 1))
(use-package evil-collection
  :after evil
  :custom (evil-collection-setup-minibuffer t)
  :config
  (evil-collection-init))
(use-package evil-escape
  :after evil
  :config
  (setq-default evil-escape-key-sequence "fd")
  (setq-default evil-escape-delay 0.1)
  (evil-escape-mode 1))

;; Display available key bindings.
(use-package which-key
  :config
  (which-key-mode))

;; Extend dired with additional keybindings and features.
(use-package dired
  :straight nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom
  ((dired-listing-switches "-agho --group-directories-first"))
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer))
(use-package dired-single
  :commands (dired dired-jump))
(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

;; Completion framework (minibuffer).
(use-package ivy
  :bind
  ("M-c" . ivy-switch-buffer)
  (:map ivy-mode-map
	("C-j" . ivy-next-line)
	("C-k" . ivy-previous-line))
  :config
  (define-key evil-insert-state-map (kbd "C-k") nil)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-height 20)
  (setq ivy-count-format "(%d/%d) ")
  (setq ivy-re-builders-alist
	'((counsel-M-x . ivy--regex-fuzzy)
	  (t . ivy--regex-plus)))
  (ivy-mode 1))
(use-package swiper
  :bind
  ("C-s" . swiper-isearch)
  ("C-M-s" . swiper-all))
(use-package counsel
  :after ivy
  :bind
  ("C-c r" . counsel-recentf)
  ("C-c g" . counsel-rg)
  ("C-c l" . counsel-locate)
  :config
  (counsel-mode 1))
(use-package ivy-rich
  :config
  (ivy-rich-mode 1))
(use-package amx
  :config
  (amx-mode 1))
(use-package flx)

;; Project management.
(use-package projectile
  :init
  (projectile-mode 1)
  :bind
  (:map projectile-mode-map
	("C-c p" . projectile-command-map)))
(use-package counsel-projectile
  :config
  (counsel-projectile-mode 1))

;; Code completion (IntelliSense etc.).
(use-package company
  :hook
  ((prog-mode LaTeX-mode latex-mode) . company-mode)
  :bind ("C-<tab>" . company-complete)
  :config
  (setq company-idle-delay 0)
  (setq company-show-numbers t)
  (setq company-tooltip-align-annotations t)
  (setq company-selection-wrap-around t))

;; On-the-fly syntax checking.
(use-package flycheck
  :config
  (global-flycheck-mode))

;; C/C++ development.
(use-package rtags
  :hook
  ((c-mode c++-mode) . rtags-start-process-unless-running)
  ((kill-emacs-hook) . rtags-quit-rdm)
  :bind
  (:map c-mode-base-map
	("M-." . rtags-find-symbol-at-point)
	("M-," . rtags-find-references-at-point)
	("M-?" . rtags-display-summary))
  :config
  (define-key evil-normal-state-map (kbd "M-.") nil)
  (rtags-enable-standard-keybindings))
(use-package ivy-rtags
  :config
  (setq rtags-display-result-backend 'ivy))
(use-package company-rtags
  :config
  (setq rtags-completions-enabled t)
  (rtags-diagnostics)
  (setq rtags-autostart-diagnostics t)
  (push 'company-rtags company-backends))
(use-package flycheck-rtags
  :hook
  ((c-mode c++-mode) . setup-flycheck-rtags)
  :config
  (progn
    (defun setup-flycheck-rtags ()
      (flycheck-select-checker 'rtags)
      ;; RTags creates more accurate overlays.
      (setq-local flycheck-highlighting-mode nil)
      (setq-local flycheck-check-syntax-automatically nil)
      ;; Run flycheck two seconds after being idle.
      (rtags-set-periodic-reparse-timeout 2.0)
      )))

;; LaTeX development.
(use-package tex-site
  :straight auctex
  :init
  ;; Parse file after loading it if no style hook is found for it.
  (setq TeX-parse-self 1)
  ;;Automatically save style information when saving the buffer.
  (setq TeX-auto-save 1))

;; PDF viewer.
(use-package pdf-tools
  :config
  (pdf-loader-install))
(add-hook 'pdf-view-mode-hook
	  (lambda ()
	    (set (make-local-variable 'evil-normal-state-cursor)
		 (list nil))))

;; Enhanced mode-line.
(use-package smart-mode-line
  :config
  (smart-mode-line-enable))

;; Jump to visible text.
(use-package avy
  :config
  (setq avy-timeout-seconds 0.2))
(bind-key* "C-;" 'avy-goto-char-timer)

;; Switch active window.
(use-package ace-window
  :bind
  ("M-o" . ace-window))

;; Git client.
(use-package magit
  :bind
  ("C-x g" . magit-status))

;; Expand selection.
(use-package expand-region
  :bind
  ("C-=" . er/expand-region)
  ("M-=" . er/contract-region))

;;--- Additional Configuration ---------------------------------------

;; Load GPG environment variables into Emacs.
(defun gpg-reload-env ()
  (interactive)
  (parsenv-load-env (expand-file-name (getenv "GPG_ENV_FILE"))))
(gpg-reload-env)

;; Setup Org TODO/Agenda.
(setq org-log-done 'time)
(setq org-agenda-files '("~/Org"))
(setq org-refile-targets '((org-agenda-files . (:maxlevel . 1))))
(setq org-default-notes-file "~/Org/organizer.org")
(global-set-key (kbd "C-c c") 'org-capture)
(setq org-todo-keywords
      '((sequence
	 "TODO(t)" "WAITING(w)" "INACTIVE(i)" "MEETING(m)" "NOTE(n)"
	 "|"
	 "DONE(d)" "CANCELLED(c)")))

;; Fix spell checking of words with umlauts.
;;
;; http://larsfischer.bplaced.net/emacs_umlaute.html
(setq ispell-local-dictionary-alist nil)
(add-to-list 'ispell-local-dictionary-alist
	     '("deutsch8"
 	       "[[:alpha:]]" "[^[:alpha:]]"
	       "[']" t
	       ("-C" "-d" "deutsch")
 	        "~latin1" iso-8859-1)
 	     )

;; Switch between English and German dictionary.
;;
;; https://www.emacswiki.org/emacs/FlySpell#h5o-5
(let ((langs '("english" "deutsch8")))
      (setq lang-ring (make-ring (length langs)))
      (dolist (elem langs) (ring-insert lang-ring elem)))
(defun cycle-ispell-languages ()
      (interactive)
      (let ((lang (ring-ref lang-ring -1)))
        (ring-insert lang-ring lang)
        (ispell-change-dictionary lang)
	(flyspell-buffer)))
(global-set-key [f8] 'cycle-ispell-languages)

;; Show column number.
(setq column-number-mode 1)

;; Show matching parenthesis.
(show-paren-mode 1)

;; Disable splash screen and startup message.
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)

;; Restore position in buffers.
(save-place-mode)

;;--------------------------------------------------------------------

(provide 'init)
;;; init.el ends here
