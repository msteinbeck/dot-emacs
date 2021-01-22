(require 'package)

;;--- General Setup --------------------------------------------------

;; Add additional repositories.
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)

;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Package-Installation.html
;;
;; To keep Emacs from automatically making packages available at
;; startup, change the variable package-enable-at-startup to nil. You
;; must do this in the early init file, as the variable is read before
;; loading the regular init file. Currently this variable cannot be
;; set via Customize.
;;
;; If you have set package-enable-at-startup to nil, you can still
;; make packages available either during or after startup. To make
;; installed packages available during startup, call the function
;; package-activate-all in your init file. To make installed packages
;; available after startup, invoke the command M-:
;; (package-activate-all) RET.
(setq package-enable-at-startup nil)
(package-initialize)

;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Saving-Customizations.html
;;
;; Store settings generated by the customize interface in a separate
;; file.
(setq custom-file (concat user-emacs-directory "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; Bootstrap 'use-package'.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))

;;--- Load Packages --------------------------------------------------

;; Vim key bindings in Emacs.
(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))
(use-package evil-escape
  :after evil
  :ensure t
  :config
  (setq-default evil-escape-key-sequence "fd")
  (setq-default evil-escape-delay 0.1)
  (evil-escape-mode 1))
(use-package evil-collection
  :after evil
  :ensure t
  :custom (evil-collection-setup-minibuffer t)
  :config
  (evil-collection-init))

;; Completion framework in minibuffer.
(use-package ivy
  :ensure t
  :bind
  (:map ivy-mode-map
	("C-j" . ivy-next-line)
	("C-k" . ivy-previous-line))
  :config
  (define-key evil-insert-state-map (kbd "C-k") nil)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-height 20)
  (setq ivy-count-format "(%d/%d) ")
  (ivy-mode 1))
(use-package swiper
  :ensure t
  :bind
  ("C-s" . swiper-isearch))
(use-package counsel
  :ensure t
  :after ivy
  :bind
  ("C-c k" . counsel-ag)
  ("C-c l" . counsel-locate)
  :config
  (counsel-mode 1))

;; Project management.
(use-package projectile
  :ensure t
  :init
  (projectile-mode 1)
  :bind
  (:map projectile-mode-map
	("C-c p" . projectile-command-map))
  :config
  (setq projectile-project-search-path '("~/Repositories/github/")))
(use-package counsel-projectile
  :ensure t
  :config
  (counsel-projectile-mode 1))

;; Enhanced mode-line.
(use-package smart-mode-line
  :ensure t
  :config
  (smart-mode-line-enable))

;; Jumping with avy.
(use-package avy
  :ensure t
  :config
  (setq avy-timeout-seconds 0.2))
(bind-key* "C-;" 'avy-goto-char-timer)

;; Git client.
(use-package magit
  :ensure t
  :bind
  ("C-x g" . magit-status))
(use-package evil-magit
  :ensure t)

;; Edit .tex files with AUCTex.
(use-package tex
  :defer t
  :ensure auctex
  :init
  ;; Parse file after loading it if no style hook is found for it.
  (setq TeX-parse-self 1)
  ;;Automatically save style information when saving the buffer.
  (setq TeX-auto-save 1))

;; Code completion (IntelliSense etc.).
(use-package company
  :ensure t
  :hook
  ((prog-mode LaTeX-mode latex-mode) . company-mode)
  :bind ("C-<tab>" . company-complete)
  :config
  (setq company-idle-delay 0)
  (setq company-show-numbers t)
  (setq company-tooltip-align-annotations t)
  (setq company-selection-wrap-around t))

;;--- Additional Configuration ---------------------------------------

;; http://larsfischer.bplaced.net/emacs_umlaute.html
;;
;; Fix spellchecking with umlauts.
(setq ispell-local-dictionary-alist nil)
(add-to-list 'ispell-local-dictionary-alist
	     '("deutsch8"
 	       "[[:alpha:]]" "[^[:alpha:]]"
	       "[']" t
	       ("-C" "-d" "deutsch")
 	        "~latin1" iso-8859-1)
 	     )

;; https://www.emacswiki.org/emacs/FlySpell#h5o-5
;;
;; Switch between English and German dictionary.
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
