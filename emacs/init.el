;;; init.el - PB's init file. 

;; Copyright (C) 2016
;; Author: Patrick Ball
;; Keywords: init, emacs

;; this file is not part of GNU/emacs. It is placed in the public domain.

;;; Commentary:

;; the commenting convention is:
;;  - single semis are inline cmnts
;;  - double semis are block cmnts
;;  - triple semis are section headers
;;  - more than triple are sub* headings
;; 

;;; paths 
(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setq exec-path (append exec-path '("/usr/local/bin")))

;;; packages 
(require 'package)
(package-initialize t)
;; Override the packages with the git version of Org and other packages
(add-to-list 'load-path "~/src/org-mode")
(setq package-enable-at-startup nil)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(package-initialize)
(add-to-list 'load-path "~/.emacs.d/elpa")

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

;;; Org setup from local path 
(use-package org
	     :load-path "~/src/org-mode")

;;; beginning the port from org-mode el to straight el

(setq
 org-confirm-babel-evaluate nil
 org-src-fontify-natively t)

;;; Introduction 

;;;; smart parens 
(use-package smartparens-config
    :ensure smartparens
    :config
    (progn
      (show-smartparens-global-mode t)))
(add-hook 'prog-mode-hook 'turn-on-smartparens-strict-mode)
(add-hook 'markdown-mode-hook 'turn-on-smartparens-strict-mode)

;;;; customization
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

;;;;; frame and window
(setq ring-bell-function 'ignore)
(show-paren-mode 1)
(tool-bar-mode -1)
(menu-bar-mode t)
(setq show-paren-delay 0
      column-number-mode 1
      inhibit-startup-message t)
(setq-default cursor-type 'bar)
;; (add-hook 'text-mode-hook 'turn-on-visual-line-mode)
(fringe-mode '(8 . 2))

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
(setq history-length t)
(setq history-delete-duplicates t)
(setq savehist-save-minibuffer-history 1)
(setq savehist-additional-variables
      '(kill-ring
        search-ring
        regexp-search-ring))

;;;;; behaviors
(setq vc-follow-symlinks t)          ; don't ask for confirmation when opening
(setq inhibit-startup-screen t)      ; inhibit useless and old-school startup screen
(setq ring-bell-function 'ignore )   ; silent bell when you make a mistake
(setq sentence-end-double-space nil) ; sentence SHOULD end with only a point.
(setq default-fill-column 80)        ; toggle wrapping text at the 80th

;;;;; wrapping 
(use-package adaptive-wrap
  :ensure t
  :defer t
  :init (add-hook 'visual-line-mode-hook #'adaptive-wrap-prefix-mode))

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

;;;; which-key
(use-package which-key 
  :diminish which-key-mode
 :config (progn
    (which-key-setup-side-window-bottom)
    (setq which-key-idle-delay 0.3)
    (setq which-key-side-window-max-height 0.5)
    (which-key-mode 1)))

;;; Editing hacks 

;;;; Navigation with avy  
(use-package avy 
  :ensure t
  :bind (("s-," . avy-goto-char))
  :config (progn 
    (setq avy-background t)
    (setq avy-style 'post)
    (setq avy-all-windows 'all-frames)))

;;;; ivy
(use-package ivy :ensure t
  :diminish (ivy-mode . "") ; does not display ivy in the modeline
  :init (ivy-mode 1)        ; enable ivy globally at startup
  :bind (:map ivy-mode-map  ; bind in the ivy buffer
         ("C-'" . ivy-avy)) ; C-' to ivy-avy
  :config (progn
    (setq ivy-use-virtual-buffers t)   ; extend searching to bookmarks and …
    (setq ivy-virtual-abbreviate 'full) ; Show the full virtual file paths
    (setq ivy-extra-directories nil) ; default value: ("../" "./")
    (setq ivy-height 20)               ; set height of the ivy window
    (setq ivy-count-format "(%d/%d) ") ; count format, from the ivy help page
    (define-key ivy-minibuffer-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  ))

;;;;; TODO add ivy hydra 

;;;; counsel 
(use-package counsel :ensure t
  :bind*                           ; load counsel when pressed
  (("M-x"     . counsel-M-x)       ; M-x use counsel
   ("C-x C-f" . counsel-find-file) ; C-x C-f use counsel-find-file
   ("C-x C-r" . counsel-recentf)   ; search recently edited files
  ))

;;;; swiper
(use-package swiper :ensure t
  :bind* (("C-s" . swiper)))


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
  )

;;;; evil-iedit and friends
(use-package expand-region
  :bind ("C-=" . er/expand-region))
(use-package iedit)
(use-package evil-iedit-state)

;;;; escape from everything 
(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(global-set-key [escape] 'evil-exit-emacs-state)

;;;; hydras

;; a - applications
;; b - buffers
;; 0-9 - tabs
;; x - text 

;;;; little hacks for general
;; from http://emacsredux.com/blog/2013/04/02/move-current-line-up-or-down/
(defun move-line-up ()
  "Move up the current line."
  (interactive)
  (transpose-lines 1)
  (forward-line -2)
  (indent-according-to-mode))

(defun move-line-down ()
  "Move down the current line."
  (interactive)
  (forward-line 1)
  (transpose-lines 1)
  (forward-line -1))

;;;; general: this is the big-picture keybinding for everything 
;;     add the hydras in the previous stanza
;;     keep an eye on [this page](https://sam217pa.github.io/2016/09/23/keybindings-strategies-in-emacs/) for good customizations with general
;;     add the little-hacks to move lines up and down to the general nvmap n/m
(use-package general :ensure t
   :config (progn 
     (general-evil-setup 1)
     (general-define-key
       :states '(normal motion insert visual emacs)
       :prefix "SPC"
       :non-normal-prefix "M-SPC"
       "SPC" 'counsel-M-x
       "l" 'avy-goto-line
       "a" 'align-regexp
       )
    (general-nvmap "j" 'evil-next-visual-line
		   "k" 'evil-previous-visual-line
		   "n" 'move-line-down
		   "m" 'move-line-up)))

;;; modes 
;;;; markdown
(use-package markdown-mode
  :mode ("\\.\\(m\\(ark\\)?down\\|md\\)$" . markdown-mode)
  :config (progn 
   (add-hook 'markdown-mode-hook 'visual-line-mode)))


;;; elscreen
(use-package elscreen
  :config
  (elscreen-start)
  (setq elscreen-tab-display-kill-screen nil)
  (setq elscreen-tab-display-control nil)
  )
(use-package elscreen-persist
  :config
  (elscreen-persist-mode 1))

;;; modeline
(use-package powerline
  :defer t
  :config (setq powerline-default-separator 'utf-8))

(use-package spaceline
  :ensure t)

(require 'spaceline-config)
(spaceline-spacemacs-theme)
(spaceline-toggle-minor-modes-off)
(spaceline-toggle-buffer-size-off)
(spaceline-toggle-hud-on)


;;; done with port from org-mode 
(message "PB init loaded.")
;;(if (file-exists-p "~/dotfiles/emacs/pb-init.el")
;;    (delete-file "~/dotfiles/emacs/pb-init.el"))
(message "PB dotemacs loaded.")
;; end
