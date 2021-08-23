;;; init.el --- Emacs initialization file -*- lexical-binding: t -*-
;;
;;; Commentary:
;;
;; My Emacs setup.
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
(add-to-list 'load-path (concat user-emacs-directory "libs"))

;; Remove items from mode-line.
(use-package diminish)

;; Provides functions for loading environment variables stored in
;; files into the running Emacs process.
(require 'parsenv)

;;--- Authentication -------------------------------------------------

;; Load GPG environment variables into Emacs.
(defun gpg-reload-env ()
  "(Re)load GPG environment variables."
  (interactive)
  (parsenv-load-env (expand-file-name (getenv "GPG_ENV_FILE"))))
(gpg-reload-env)

;; Setup auth-source.
(use-package auth-source-pass
  :config
  ;; password-store must be added at the end of auth-sources.
  (add-to-list 'auth-sources 'password-store t)
  ;; Clear the cache (required after each change to
  ;; #'auth-source-pass-search).
  (auth-source-forget-all-cached))

(defun auth-source-pass--build-result (host port user)
  "Build auth-source-pass entry matching HOST, PORT and USER.
This version of the function parses an entry only once."
  (let ((entry (auth-source-pass-parse-entry (auth-source-pass--find-match host user))))
    (when entry
      (let ((retval (list
                     :host host
                     :port (cdr (assoc "port" entry))
                     :user (cdr (assoc "user" entry))
                     :secret (lambda () (cdr (assoc 'secret entry))))))
        (auth-source-pass--do-debug "return %s as final result (plus hidden password)"
                                    (seq-subseq retval 0 -2)) ;; remove password
        retval))))

(defun auth-source-pass--find-all-by-entry-name (entryname user)
  "Search the store for all entries either matching ENTRYNAME/USER or ENTRYNAME.
This version of the function ignores `auth-source-pass--entry-valid-p'."
  (seq-filter (lambda (entry)
                (and
                 (or
                  (let ((components-host-user
                         (member entryname (split-string entry "/"))))
                    (and (= (length components-host-user) 2)
                         (string-equal user (cadr components-host-user))))
                  (string-equal entryname (file-name-nondirectory entry)))
                 ;(auth-source-pass--entry-valid-p entry)))
                 ))
              (auth-source-pass-entries)))

(defun auth-source-user (host)
  "Read user property of HOST."
  (let ((result (auth-source-search :host host)))
    (if result
        (plist-get (car result) :user)
        nil)))

(defun auth-source-password (host)
  "Read secret property of HOST."
  (let ((result (auth-source-search :host host)))
    (if result
        (funcall (plist-get (car result) :secret))
        nil)))

(defun auth-source-port (host)
  "Read port property of HOST."
  (let ((result (auth-source-search :host host)))
    (if result
        (plist-get (car result) :port)
        nil)))

(defun password-store-credential (host)
  "Build credential string of HOST."
  (concat (auth-source-password host)
          "\nlogin: " (auth-source-user host)))

;;--- Editor ---------------------------------------------------------

;; Display available key bindings.
(use-package which-key
  :diminish
  :config
  (which-key-mode))

;; Vim key bindings.
(use-package undo-tree
  :diminish
  :config
  (setq undo-tree-auto-save-history t)
  (global-undo-tree-mode))
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
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
  :diminish
  :config
  (setq-default evil-escape-key-sequence "fd")
  (setq-default evil-escape-delay 0.1)
  (evil-escape-mode 1))
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))
(use-package evil-matchit
  :config
  (global-evil-matchit-mode 1))
(use-package evil-exchange
  :config
  (evil-exchange-install))
(use-package evil-org
  :after org
  :hook (org-mode . (lambda () evil-org-mode))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;; Completion framework (minibuffer).
(use-package ivy
  :diminish
  :bind
  ("M-c" . ivy-switch-buffer)
  ("C-M-j" . ivy-switch-buffer)
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
  :diminish
  :bind
  ("C-c r" . counsel-recentf)
  ("C-c g" . counsel-rg)
  ("C-c l" . counsel-locate)
  :config
  (counsel-mode 1))
(use-package ivy-rich
  :config
  (ivy-rich-mode 1)
  (setq ivy-rich-parse-remote-buffer nil
        ivy-rich-parse-remote-file-path nil))
(use-package amx
  :config
  (amx-mode 1))
(use-package flx)

;; Enable flyspell in certain modes.
(use-package flyspell
  :hook
  ((prog-mode LaTeX-mode latex-mode) . flyspell-mode))

;; Enhanced mode-line.
(use-package smart-mode-line
  :config
  (smart-mode-line-enable))

;; Jump to visible text.
(use-package avy
  :config
  (setq avy-timeout-seconds 0.2))
(bind-key* "C-;" 'avy-goto-char-2)

;; Switch active window.
(use-package ace-window
  :bind
  ("M-o" . ace-window))

;; Expand selection.
(use-package expand-region
  :bind
  ("C-=" . er/expand-region)
  ("M-=" . er/contract-region))

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

;; Disable splash screen and startup message.
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)

;; Show matching parenthesis.
(show-paren-mode 1)

;; Disable tool bar.
(tool-bar-mode -1)

;; Restore position in buffers.
(save-place-mode)

;;--- File Management ------------------------------------------------

;; Extend dired with additional key bindings and features.
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

;;--- Document Viewer ------------------------------------------------

;; PDF viewer.
(use-package pdf-tools
  :config
  (pdf-loader-install))
(add-hook 'pdf-view-mode-hook
          (lambda ()
            (set (make-local-variable 'evil-normal-state-cursor)
                 (list nil))))

;;--- Development ----------------------------------------------------

;; Git client.
(use-package magit
  :bind
  ("C-x g" . magit-status))

;; Text completion framework (code completion).
(use-package company
  :diminish
  :hook
  ((prog-mode LaTeX-mode latex-mode) . company-mode)
  :bind ("C-<tab>" . company-complete)
  :config
  (setq company-idle-delay 0)
  (setq company-show-numbers t)
  (setq company-tooltip-align-annotations t)
  (setq company-selection-wrap-around t))

;; Template system.
(use-package yasnippet
  :diminish
  :config
  (yas-global-mode 1))
(use-package yasnippet-snippets)

;; Project management.
(use-package projectile
  :diminish
  :init
  (projectile-mode 1)
  :bind
  (:map projectile-mode-map
        ("C-c p" . projectile-command-map)))
(use-package counsel-projectile
  :config
  (counsel-projectile-mode 1))

;; On-the-fly syntax checking and linting.
(use-package flycheck
  :config
  (global-flycheck-mode))

;; C/C++ development.
(setq c-default-style "linux")
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

;; CMake development.
(use-package cmake-mode)
(use-package cmake-font-lock)

;; LaTeX development.
(use-package tex-site
  :straight auctex
  :init
  ;; Parse file after loading it if no style hook is found for it.
  (setq TeX-parse-self 1)
  ;;Automatically save style information when saving the buffer.
  (setq TeX-auto-save 1)
  ;; Activate interface between RefTeX and AUCTeX
  (setq reftex-plug-into-AUCTeX t)
  :hook
  ((LaTeX-mode latex-mode) . reftex-mode)
  :config
  ;; Use pdf-tools to open PDF files.
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-source-correlate-mode t
        TeX-source-correlate-start-server t)
  ;; Update PDF buffers after compilation.
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer)
  ;; This adds Make to the tex command list.
  (eval-after-load "tex"
    '(add-to-list 'TeX-command-list
                  '("Make" "make" TeX-run-compile nil t))))

;; Show spaces and tabs in prog-mode.
(setq whitespace-style
      '(face
        spaces
        tabs tab-mark
        trailing))
(custom-set-faces '(whitespace-tab ((t (:foreground "#cbcbcb")))))
(setq whitespace-display-mappings
      '((tab-mark 9 [8594 9] [92 9])))
(setq whitespace-space-regexp "\\(^\t* +\\)")
(add-hook 'prog-mode-hook 'whitespace-mode)

;; Configure indention.
;;
;; https://dougie.io/emacs/indentation
(setq default-tab-width 8)
(setq-default electric-indent-inhibit t)
(setq backward-delete-char-untabify-method 'hungry)
(defun disable-tabs ()
  "Disable tabs for indention."
  (setq indent-tabs-mode nil))
(defun enable-tabs ()
  "Enable tabs for indention."
  (setq indent-tabs-mode t)
  (setq tab-width default-tab-width))
(add-hook 'prog-mode-hook 'enable-tabs)
(add-hook 'lisp-mode-hook 'disable-tabs)
(add-hook 'emacs-lisp-mode-hook 'disable-tabs)

;;--- Mail -----------------------------------------------------------

;; Setup ERC.
(use-package erc
  :custom
  (erc-hide-list '("JOIN" "PART" "QUIT"))
  (erc-lurker-hide-list '("JOIN" "PART" "QUIT"))
  (erc-prompt-for-nickserv-password nil)
  (erc-server-reconnect-attempts 5)
  (erc-server-reconnect-timeout 3)
  (erc-track-exclude-types '("JOIN" "MODE" "NICK" "PART" "QUIT"
                             "324" "329" "332" "333" "353" "477"))
  :config
  (erc-services-mode 1)
  (erc-update-modules))
(defun erc-connect ()
  "Connect to default IRC server."
  (interactive)
  (erc :server "irc.libera.chat"
       :port (auth-source-port "irc.libera.chat")
       :nick (auth-source-user "irc.libera.chat")
       :password (auth-source-password "irc.libera.chat")))

;;--- Organizing -----------------------------------------------------

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



;;--------------------------------------------------------------------

(provide 'init)
;;; init.el ends here
