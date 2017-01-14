;;; init.el - PB's init file.

;; Copyright (C) 2017
;; Author: Patrick Ball
;; Keywords: init, emacs

;; this file is not part of GNU/emacs. It is placed in the public domain.

;;; Commentary:

;; the commenting convention is:
;;  - single semis are inline cmnts
;;  - double semis are block cmnts
;;  - triple semis are section headers
;;  - more than triple are sub* headings
;;  - imenu to jump to headers in elisp

;;; Todo
;; add flycheck to python-mode
;; imenu in editing
;;;; long-term todo

;;;; Done
;; flycheck + flyspell
;; v nice integration of critic-markup
;; s-o should close screen, s-n should open screen


;;; paths
(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setq exec-path (append exec-path '("/usr/local/bin")))
(server-start)
(setq insert-directory-program "/usr/local/bin/gls")

;;; packages
(setq package-check-signature nil) ; this is bad!
(require 'package)
(package-initialize t)
;; Override the packages with the git version of Org and other packages
(add-to-list 'load-path "~/src/org-mode")
(setq package-enable-at-startup nil)

(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/"))
(add-to-list 'package-archives
	     '("marmalade" . "https://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
(setq package-archive-priorities
      '(("melpa-stable" . 20)
        ("marmalade" . 10)
	("gnu" . 5)
        ("melpa" . 15)))
(add-to-list 'load-path "~/.emacs.d/elpa")
(add-to-list 'load-path "~/src/criticmarkup-emacs")

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(when (not package-archive-contents)
  (package-refresh-contents))

(eval-when-compile
  (require 'use-package))
(require 'diminish)
(use-package auto-compile
  :config (auto-compile-on-load-mode))

(setq use-package-verbose t)
(setq use-package-always-ensure t)
(setq load-prefer-newer t)
(require 'bind-key)

;;; Org setup from local path: git pull occasionally.
(add-to-list 'auto-mode-alist '("\\.\\(org\\|org_archive\\|txt\\)$" . org-mode))
(use-package org :ensure t
  ;; :pin local
  :load-path "~/src/org-mode")

(load-file "~/dotfiles/emacs/init-org.el")

;;;;; org & babel
(setq
 org-confirm-babel-evaluate nil
 org-src-fontify-natively t)

;;; Introduction

;;;;;; customization
(setq custom-file "~/.emacs.d/custom.el"
      kill-buffer-query-functions
      (remq 'process-kill-buffer-query-function
	    kill-buffer-query-functions)
      user-full-name "Patrick Ball"
      user-mail-address "pball@fastmail.fm")

;;;; UI and visuals

;;;;; font and theme
(defconst my/font "Monaco-13")
(set-face-attribute 'default nil :font "Monaco-13")
(set-frame-font  "Monaco-13"  nil t)
(use-package color-theme
  :ensure t)
(setq custom-safe-themes t)
(use-package hc-zenburn-theme)
(load-theme 'hc-zenburn)
(set-face-attribute 'region nil :background "#666")

;;;;; frame and window
(show-paren-mode 1)
(setq show-paren-style 'parenthesis)
;; (global-hl-line-mode 1)  ; FIXME maybe come back to this after fixing nlinum
(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode t)
(setq-default indicate-empty-lines t)
(when (not indicate-empty-lines)
  (toggle-indicate-empty-lines))
(setq show-paren-delay 0
      ring-bell-function 'ignore
      column-number-mode 1
      inhibit-startup-message t)
(use-package rainbow-delimiters
  :config
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(fringe-mode '(8 . 2))
(use-package beacon
  :config (beacon-mode 1))

;;;;; nlinum
(use-package nlinum
  :pin gnu
  :config
  (set-face-attribute 'linum nil :height 100)
  (setq nlinum-highlight-current-line 1)
  (add-hook 'prog-mode-hook 'linum-mode))

;;;;; backups, version control, backups, and history
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq delete-old-versions -1)
(setq version-control t)
(setq vc-make-backup-files t)
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))
(use-package super-save
  :init (super-save-mode +1)
  :diminish super-save-mode
  :config
     (setq super-save-auto-save-when-idle t)
     (setq auto-save-default nil))
(setq savehist-file "~/.emacs.d/savehist")
(savehist-mode 1)
(setq
 history-length t
 history-delete-duplicates t
 savehist-save-minibuffer-hise\tory 1
 savehist-additional-variables
 '(kill-ring
   search-ring
   regexp-search-ring))

;;;;; undo-tree
(use-package undo-tree
  :config (global-undo-tree-mode))

;;;;; behaviors
(setq vc-follow-symlinks t)          ; don't ask for confirmation when opening
(setq inhibit-startup-screen t)      ; inhibit useless and old-school startup screen
(setq ring-bell-function 'ignore )   ; silent bell when you make a mistake
(setq sentence-end-double-space nil) ; sentence SHOULD end with only a point.
(setq default-fill-column 80)        ; toggle wrapping text at the 80th
(delete-selection-mode 1)
(defalias 'yes-or-no-p 'y-or-n-p)
(setq tab-always-indent 'complete)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
;; deletes all the whitespace when you hit backspace or delete
(use-package hungry-delete
  :ensure t
  :config
  (global-hungry-delete-mode))

;;;;; imenu
(defun imenu-elisp-sections ()
  (setq imenu-prev-index-position-function nil)
  (add-to-list 'imenu-generic-expression '("Sections" "^;;; \\(.+\\)$" 1) t))
(add-hook 'emacs-lisp-mode-hook 'imenu-add-menubar-index)
(setq imenu-auto-rescan t)
(add-hook 'emacs-lisp-mode-hook 'imenu-elisp-sections)

;;;;; wrapping
(use-package adaptive-wrap
  :ensure t
  :defer t
  :init (add-hook 'visual-line-mode-hook #'adaptive-wrap-prefix-mode))
(use-package unfill)

;;;;; UTF-8
(setq coding-system-for-read 'utf-8)
(setq coding-system-for-write 'utf-8)

;;;;; desktop
(use-package desktop                    ; Save buffers, windows and frames
  :init (desktop-save-mode 1)
  :config
    (setq desktop-auto-save-timeout 60)
    (setq history-length 250)
    (add-to-list 'desktop-globals-to-save 'file-name-history)
    (setq desktop-path '("~/.emacs.d/")))

;;;;; flyspell
(use-package flyspell
  :init
  (progn
    (add-hook 'text-mode-hook 'flyspell-mode)
    (add-hook 'prog-mode-hook 'flyspell-prog-mode))
  :config
  (setq spell-personal-dictionary "~/.flydict"
	ispell-program-name (executable-find "aspell")
	ispell-extra-args
	(list "--sug-mode=fast" ;; ultra|fast|normal|bad-spellers
        "--lang=en_US"
        "--ignore=3"))
   :bind* ("C-;" . flyspell-auto-correct-previous-word))
(add-hook 'org-mode-hook 'turn-on-flyspell)

;;;;; indent
(use-package aggressive-indent
  :config (global-aggressive-indent-mode 1))

;;;; magit
(use-package magit
  :init (progn
	  (defadvice git-commit-commit (after delete-window activate)
	    (delete-window))
	  (defadvice git-commit-abort (after delete-window activate)
	    (delete-window))
	  ;; these two force a new line to be inserted into a commit window,
	  ;; which stops the invalid style showing up.
	  ;; From: http://git.io/rPBE0Q
	  (defun magit-commit-mode-init ()
	    (when (looking-at "\n")
	      (open-line 1)))))


;;;; which-key
(use-package which-key
  :diminish which-key-mode
  :config (progn
	    (which-key-setup-side-window-bottom)
	    (setq which-key-idle-delay 0.3)
	    (setq which-key-side-window-max-height 0.5)
	    (which-key-mode 1)))

;;; Editing hacks
;;;; personal keybindings
(global-set-key (kbd "s-/") 'comment-line)
(global-set-key (kbd "M-x") 'helm-M-x)

;;;; insert date and time
;; http://stackoverflow.com/questions/251908/how-can-i-insert-current-date-and-time-into-a-file-using-emacs
(defvar current-date-time-format "%a %b %d %H:%M:%S %Z %Y"
  "Format of date to insert with `insert-current-date-time' func
See help of `format-time-string' for possible replacements")

(defvar current-date-time-short-format "%Y-%m-%dT%H:%M%Z"
  "Format of date to insert with `insert-current-date-short' func")

(defun insert-current-date-short ()
  "insert the current date and time into current buffer.
    Uses `current-date-time-format-short for the formatting the date/time."
  (interactive)
  (insert (format-time-string current-date-time-short-format (current-time)))
  )

(defun insert-current-date-time ()
  "insert the current date and time into current buffer.
    Uses `current-date-time-format' for the formatting the date/time."
  (interactive)
  (insert (format-time-string current-date-time-format (current-time)))
  )
(global-unset-key (kbd "C-t"))
(global-set-key (kbd "C-t d") 'insert-current-date-time)
(global-set-key (kbd "C-t t") 'insert-current-date-short)

;;;; ibuffer settings
(setq ibuffer-expert t)
(add-hook 'ibuffer-mode-hook
	  '(lambda ()
	     (ibuffer-auto-mode 1)
	     (ibuffer-switch-to-saved-filter-groups "home")))

;;;; Navigation with avy
(use-package avy
  :ensure t
  :pin melpa
  :bind (("C-'" . avy-goto-char)
	 ("s-," . avy-goto-char-timer))  ; this is pretty cool
  :config (progn
	    (setq avy-background t)
	    (setq avy-all-windows 'all-frames)))

(use-package ace-jump-buffer
  :pin melpa)

;;; company-mode
(use-package company
  :diminish ""
  :init
  ;; (add-hook 'prog-mode-hook 'company-mode)
  ;; (add-hook 'comint-mode-hook 'company-mode)
  :config
  (global-company-mode)
  ;; Quick-help (popup documentation for suggestions).
  ;; (use-package company-quickhelp
  ;;   :if window-system
  ;;   :init (company-quickhelp-mode 1))
  ;; Company settings.
  (setq company-tooltip-limit 20)
  (setq company-idle-delay 0.1)
  (setq company-echo-delay 0)
  (setq company-minimum-prefix-length 3)
  (setq company-require-match nil)
  (setq company-selection-wrap-around t)
  (setq company-tooltip-align-annotations t)
  ;; weight by frequency
  (setq company-transformers '(company-sort-by-occurrence))

  (define-key company-active-map (kbd "M-n") nil)
  (define-key company-active-map (kbd "M-p") nil)
  (define-key company-active-map (kbd "TAB") 'company-complete-common-or-cycle)
  (define-key company-active-map (kbd "C-n") 'company-select-next)
  (define-key company-active-map (kbd "C-n") 'company-select-next)
  (define-key company-active-map (kbd "C-k") 'company-select-previous)
  (define-key company-active-map (kbd "C-j") 'company-select-previous)
  (define-key company-active-map (kbd "<tab>") 'company-complete-common-or-cycle)
  (define-key company-active-map (kbd "S-TAB") 'company-select-previous)
  (define-key company-active-map (kbd "<backtab>") 'company-select-previous)

  ;; =======================
  ;; Adding company backends
  ;; =======================
  (setq company-backends
	'((company-files          ; files & directory
	   company-keywords       ; keywords
	   company-elisp
	   company-capf
	   company-yasnippet
	   )
	  (company-abbrev company-dabbrev)
	  ))
  ;; Python auto completion
  (use-package company-jedi
    :init
    (setq company-jedi-python-bin "python3")
    :config
    (add-to-list 'company-backends 'company-jedi))

  (use-package company-statistics
    :config
    (add-hook 'after-init-hook 'company-statistics-mode))
  (use-package helm-company
    :config
    (progn
      ;; the idea is that M-i calls helm, as in isearch.
      (define-key company-mode-map (kbd "M-i") 'helm-company)
      (define-key company-active-map (kbd "M-i") 'helm-company))))


;;; helm
(use-package helm
  :diminish helm-mode
  :pin melpa-stable
  :init
  (progn
    (use-package helm-swoop)
    (use-package helm-ag
      :init
      (custom-set-variables
       '(helm-ag-base-command "pt -e --nocolor --nogroup")))
    (require 'helm-config)
    (setq helm-idle-delay 0.0 ; update fast sources immediately (doesn't).
	  helm-input-idle-delay 0.01  ; this actually updates things
	  helm-candidate-number-limit 100
	  helm-quick-update t
	  helm-buffers-fuzzy-matching t
	  helm-recentf-fuzzy-match t
	  helm-M-x-requires-pattern nil
	  helm-ff-file-name-history-use-recentf t
	  helm-swoop-speed-or-color t
	  helm-ff-skip-boring-files t))
  :config
  (progn
    (helm-autoresize-mode t)
    (define-key helm-map [escape] 'helm-keyboard-quit)
    (helm-mode 1)))
(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action)
(define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB work in terminal
(define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z
(global-set-key (kbd "C-h a")    #'helm-apropos)
;; (global-set-key (kbd "C-h i")    #'helm-info-emacs)
(global-set-key (kbd "C-h b")    #'helm-descbinds)

(defun spacemacs//helm-hide-minibuffer-maybe ()
  "Hide minibuffer in Helm session if we use the header line as input field."
  (when (with-helm-buffer helm-echo-input-in-header-line)
    (let ((ov (make-overlay (point-min) (point-max) nil nil t)))
      (overlay-put ov 'window (selected-window))
      (overlay-put ov 'face
                   (let ((bg-color (face-background 'default nil)))
                     `(:background ,bg-color :foreground ,bg-color)))
      (setq-local cursor-type nil))))

(add-hook 'helm-minibuffer-set-up-hook
          'spacemacs//helm-hide-minibuffer-maybe)

(require 'helm-eshell)
(add-hook 'eshell-mode-hook
          #'(lambda ()
              (define-key eshell-mode-map (kbd "C-c C-l")  'helm-eshell-history)))
(define-key minibuffer-local-map (kbd "C-c C-l") 'helm-minibuffer-history)
(ido-mode -1)

;;; evil-mode
;;;; evil itself
(use-package evil
  :ensure t
  :config (progn
	    (setcdr evil-insert-state-map nil)  ; no evil-mode in insert.
	    (define-key evil-insert-state-map [escape] 'evil-normal-state)
	    (evil-mode 1))
  (use-package evil-surround
    :ensure t
    :config
    (global-evil-surround-mode))
  (use-package evil-indent-textobject
    :ensure t)
  (use-package evil-snipe
    :pin melpa
    :ensure t
    :config
    ;; (evil-snipe-mode 1)
    (evil-snipe-override-mode 1)
    (evil-define-key 'visual evil-snipe-mode-map "z" 'evil-snipe-s)
    (evil-define-key 'visual evil-snipe-mode-map "Z" 'evil-snipe-S)
    (setq evil-snipe-scope 'whole-visible))
  )
(use-package evil-easymotion)
(evilem-default-keybindings "M-n")


;;;; evil-iedit and friends
(use-package expand-region
  :bind ("C-=" . er/expand-region))
(use-package iedit)
(use-package evil-iedit-state)

;;;; escape from everything
;; evil-escape is fantastic;
(use-package evil-escape
  :config
  (evil-escape-mode)
  (global-set-key (kbd "<esc>") 'evil-escape))
(define-key undo-tree-visualizer-mode-map [escape] 'undo-tree-visualizer-quit)
(define-key undo-tree-map [escape] 'undo-tree-visualizer-quit)

;;;; hydras

;;;; little hacks for general
;; from http://emacsredux.com/blog/2013/04/02/move-current-line-up-or-down/
(defun move-line-up ()
  "Move up the current line."
  (interactive)
  (transpose-lines 1)
  (forward-line -2))

(defun move-line-down ()
  "Move down the current line."
  (interactive)
  (forward-line 1)
  (transpose-lines 1)
  (forward-line -1))

(use-package crux)
(use-package ranger :ensure t
  :config
  (setq ranger-show-dotfiles t)
  (setq ranger-dont-show-binary t)
  (setq ranger-cleanup-eagerly t))

;;; hydra
(use-package hydra)

(defhydra hydra-applications (:color blue :columns 3)
  "Applications"
  ("g" magit-status "git")
  ("m" hydra-markdown/body "markdown")
  ("o" hydra-orgmode/body "org-mode"))

(defhydra hydra-markdown (:color blue)
  ("F" (cm-follow-changes 1) "mark changes")
  ("f" (cm-follow-changes 0) "stop marking")
  ("i" cm-accept/reject-change-at-point "accept/reject change")
  ("I" cm-accept/reject-all-changes "accept/reject all"))

;; org-mode,
;; need lots here, but I haven't figured it out yet. which-key might get us there.
(defhydra hydra-org (:color blue :columns 3)
  "Org mode"
  ("a" org-archive-subtree-default "archive TODO")
  ("t" org-todo "change TODO state")
  ;; ("g" "agenda TODOs")
  ("r" org-refile "refile")
  ("s" org-schedule "schedule")
  ("b" org-iswitchb "switch org buff"))

(defhydra hydra-buffer (:color blue :columns 3)
  "Buffers"
  ("n" next-buffer "next" :color red)
  ("b" helm-buffers-list "switch")
  ("B" ibuffer "ibuffer")
  ("p" previous-buffer "prev" :color red)
  ("C-b" buffer-menu "buffer menu")
  ("m" helm-mini "helm-mini")
  ("N" evil-buffer-new "new")
  ("e" eval-buffer "eval buff")
  ("d" kill-this-buffer "delete" :color red)
  ("D" (progn (kill-this-buffer) (next-buffer)) "Delete" :color red)
  ("s" save-buffer "save" :color red)
  ("S" bs-show "Show"))

(defhydra hydra-edit (:color blue :columns 3)
  "Editing"
  ("k" move-line-up "line up" :color red)
  ("i"  (progn (evil-insert-state) (iedit-mode)) "iedit")
  ("n" narrow-to-region "narrow")
  ("j" move-line-down "line down" :color red)
  ("r" helm-occur "occur")
  ("w" widen "widen")
  ("y" helm-show-kill-ring "browse kill ring")
  ("u" unfill-paragraph "unfill graf")
  ("v" undo-tree-visualize "vis undo tree"))
;; iedit, crux stuff splitting/joining lines. unfilling paragraphs.

(defun show-file-name ()
  "Show the full path file name in the minibuffer."
  (interactive)
  (message (buffer-file-name)))

(setq frame-title-format
      (list (format "%s %%S: %%j " (system-name))
	    '(buffer-file-name "%f" (dired-directory dired-directory "%b"))))

(defun save-all-buffers ()
  (interactive)
  (save-some-buffers t))
(defhydra hydra-files (:color blue :columns 3)
  "Files"
  ("f" helm-find-files "find")
  ("s" save-buffer "save")
  ("S" save-all-buffers "save all")
  ("e" eval-buffer "eval current")
  ("p" show-file-name "full path")
  ("m" helm-mini "helm-mini")
  ("R" ranger "ranger")  ; not working
  ("v" revert-buffer "revert"))

(defhydra hydra-jump (:color blue :columns 3)
  "Jumping" ;; add registers and bookmarks here.
  ("a" helm-ag "ag")
  ("i" imenu "imenu")
  ("h" helm-semantic-or-imenu "helm imenu")
  ("m" helm-all-mark-rings "markers")
  ("o" helm-multi-swoop-org "swoop org")
  ("r" jump-to-register "register")
  ("R" helm-register "helm register")
  ("w" helm-swoop "swoop")
  ("W" helm-multi-swoop-all "swoop all"))

(defhydra hydra-evals (:color blue)
  ("b" eval-buffer "buffer")
  ("d" eval-defun "defun")
  ("r" eval-region "region")
  ("s" eval-last-sexp "sexp"))

(defhydra hydra-registers (:color blue :columns 3)
  "Registers"
  ;; add copy to register, prepend, append, insert into buffer
  ("b" bookmark-set "bookmark")
  ("B" helm-filtered-bookmarks "show bookmarks")
  ("c" copy-to-register "copy")
  ("i" insert-register "insert")
  ("m" helm-mark-ring "show marks")
  ("e" jump-to-register "execute macro")
  ("M" kmacro-to-register "macro")
  ("j" jump-to-register "jump")
  ("l" list-registers "list")
  ("p" point-to-register "point")
  ("R" helm-register "Register view"))

(defhydra hydra-windows (:color blue :columns 3)
  "Windows and screens"
  ("k" delete-other-windows "keep only this win")
  ("o" other-window "other window" :color red)
  ("f" other-frame "other frame" :color red))

;; (defhydra hydra-text (:color blue))
;; up/downcase, unfill graf,

;; http://blog.vivekhaldar.com/post/4809065853/dotemacs-extract-interactively-change-font-size
(defun my/zoom-in ()
  "Increase font size by 10 points"
  (interactive)
  (set-face-attribute 'default nil
		      :height
		      (+ (face-attribute 'default :height)
			 10)))

(defun my/zoom-out ()
  "Decrease font size by 10 points"
  (interactive)
  (set-face-attribute 'default nil
                      :height
                      (- (face-attribute 'default :height)
                         10)))

(defhydra hydra-zoom (:color red)
  "Zoom font size"
  ("=" my/zoom-in "zoom in")
  ("-" my/zoom-out "zoom out"))

;;;; general: this is the big-picture keybinding for everything
;;     add the hydras in the previous stanza
;;     keep an eye on [this page](https://sam217pa.github.io/2016/09/23/keybindings-strategies-in-emacs/) for good customizations with general
(use-package general :ensure t
  :config (progn
	    (general-evil-setup 1)
	    (general-define-key
	     :states '(normal motion insert visual emacs)
	     :prefix "SPC"
	     :non-normal-prefix "M-SPC"
	     "SPC" 'helm-M-x
	     ";" 'comment-line
	     "/" 'helm-swoop
	     ;; "0" 'winum-select-window-0-or-10
	     "1" 'winum-select-window-1
	     "2" 'winum-select-window-2
	     "3" 'winum-select-window-3
	     "4" 'winum-select-window-4
	     "5" 'winum-select-window-5
	     ;; "6" 'winum-select-window-6
	     ;; "7" 'winum-select-window-7
	     ;; "8" 'winum-select-window-8
	     "a" 'hydra-applications/body
	     "B" 'hydra-buffer/body
	     "b" 'ace-jump-buffer
	     "c" 'org-capture
	     "e" 'hydra-edit/body
	     "f" 'hydra-files/body
	     "h" 'hydra-help/body
	     "j" 'avy-goto-char-2
	     "J" 'hydra-jump/body
	     "n" 'ace-jump-buffer
	     "o" 'hydra-org/body
	     "q" 'save-buffers-kill-terminal
	     "r" 'hydra-registers/body
	     "t" 'hydra-text/body
	     "v" 'hydra-evals/body
	     "w" 'hydra-windows/body
	     "z" 'hydra-zoom/body
	     )
	    (general-nmap "j" 'evil-next-visual-line
			  "k" 'evil-previous-visual-line)))

;;; modes
;;;; markdown
(use-package markdown-mode
  :mode ("\\.\\(m\\(ark\\)?down\\|md\\)$" . markdown-mode)
  :config
  (add-hook 'markdown-mode-hook 'visual-line-mode)
  (require 'cm-mode))

;;; winum
(use-package winum)
(setq winum-auto-setup-mode-line nil)
(winum-mode)

;;; modeline
(use-package spaceline
  :ensure t
  :pin melpa
  :config
  (require 'spaceline-config)
  (spaceline-spacemacs-theme)
  (spaceline-toggle-minor-modes-off)
  (spaceline-toggle-buffer-modified-on)
  (spaceline-toggle-buffer-size-on)
  (spaceline-toggle-version-control-off)
  (spaceline-toggle-window-number-on)
  (setq
   spaceline-highlight-face-func 'spaceline-highlight-face-evil-state
   powerline-default-separator 'contour
   spaceline-helm-mode t
   spaceline-byte-compile t))

;;; done with port from org-mode
(message "PB dotemacs loaded.")
;; end
(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-region 'disabled nil)
