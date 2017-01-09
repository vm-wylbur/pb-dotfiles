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
(require 'package)
(package-initialize t)
;; Override the packages with the git version of Org and other packages
(add-to-list 'load-path "~/src/org-mode")
(setq package-enable-at-startup nil)

(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
	     '("marmalade" . "https://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
(setq package-archive-priorities
      '(("melpa-stable" . 20)
        ("marmalade" . 5)
        ("melpa" . 10)))
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
  :load-path "~/src/org-mode")

(load-file "~/dotfiles/emacs/init-org.el") 

;;;;; org & babel 
(setq
 org-confirm-babel-evaluate nil
 org-src-fontify-natively t)

;;; Introduction 

;;;; smart parens 
;; (use-package smartparens-config
;;     :ensure smartparens
;;     :config
;;     (progn
;;       (show-smartparens-global-mode t)))
;; (add-hook 'prog-mode-hook 'turn-on-smartparens-strict-mode)
;; (add-hook 'markdown-mode-hook 'turn-off-smartparens-strict-mode)

;; ;;;; customization
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
(show-paren-mode 1)
(tool-bar-mode -1)
(menu-bar-mode t)
(setq-default indicate-empty-lines t)
(when (not indicate-empty-lines)
  (toggle-indicate-empty-lines))
(setq show-paren-delay 0
      ring-bell-function 'ignore
      column-number-mode 1
      inhibit-startup-message t)
(setq-default cursor-type 'bar)
;; (add-hook 'text-mode-hook 'turn-on-visual-line-mode)
(fringe-mode '(8 . 2))
(use-package beacon
  :config (beacon-mode 1))

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

;;;; Navigation with avy  
(use-package avy 
  :ensure t
  :bind (("C-'" . avy-goto-char)
	 ("s-," . avy-goto-char-timer))  ; this is pretty cool
  :config (progn 
	    (setq avy-background t)
	    (setq avy-style 'post)
	    (setq avy-all-windows 'all-frames)))
(use-package ace-jump-buffer)


;; ;;;; ivy
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
(use-package ivy-hydra :ensure t)

;;;;; TODO add ivy hydra 
;;;; counsel 
(use-package counsel :ensure t
  :bind*                           ; load counsel when pressed
  (("M-x"     . counsel-M-x)       ; M-x use counsel
   ("C-x C-f" . counsel-find-file) ; C-x C-f use counsel-find-file
   ("C-x C-r" . counsel-recentf)   ; search recently edited files
   ("C-y"     . counsel-yank-pop)
  ))

;; ;;;; swiper
(use-package swiper :ensure t
  :bind* (("C-s" . swiper)
	  ("C-r" . swiper)))


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
(use-package evil-easymotion) 
(evilem-default-keybindings "M-SPC")


;;;; evil-iedit and friends
(use-package expand-region
  :bind ("C-=" . er/expand-region))
(use-package iedit)
(use-package evil-iedit-state)

;;;; escape from everything 
(use-package evil-escape
  :config
  (evil-escape-mode)
  (global-set-key (kbd "<esc>") 'evil-escape))
;; (define-key evil-visual-state-map [escape] 'keyboard-quit)
;; (define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
;; (define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
;; (define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
;; (define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
;; (define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(define-key undo-tree-visualizer-mode-map [escape] 'undo-tree-visualizer-quit)
(define-key undo-tree-map [escape] 'undo-tree-visualizer-quit)
;; (define-key ivy-minibuffer-map (kbd "<escape>") 'minibuffer-keyboard-quit)
;; (global-set-key [escape] 'evil-exit-emacs-state)
;; (global-set-key [escape] 'keyboard-quit)

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


;;; hydra 
(use-package hydra)

;; this doesn't work, but it's a good starting point.
;; critic markdown should always be on for markdown, so turning on the
;; minor mode is another start. then set the toggle.
;; other good stuff for the hydra-markdown is add a comment,
;; accept/reject changes interactively.
;; (defun pb-toggle-criticmarkup-follow ()
;;   "Toggle criticmarkup follow minor mode"
;;   (interactive)
;;   (if (get cm-follow-changes nil)
;;       (setq cm-follow-changes 1)
;;     (setq cm-follow-changes 0)))
	
(defhydra hydra-markdown (:color blue)
  ("F" (cm-follow-changes 1) "mark changes")
  ("f" (cm-follow-changes 0) "stop marking")
  ("i" cm-accept/reject-change-at-point "accept/reject change")
  ("I" cm-accept/reject-all-changes "accept/reject all"))

(defhydra hydra-applications (:color blue :columns 4)
  "Applications"
  ("g" magit-status "git")
  ("m" hydra-markdown/body "markdown")
  ("o" hydra-orgmode/body "org-mode"))

;; org-mode,  
;; need lots here, but I haven't figured it out yet. which-key might get us there.
(defhydra hydra-orgmode (:color blue :columns 5)
  "Org-mode"
  ("a" org-agenda "agenda")
  ("w" org-iswitchb "switch") 
  ("s" org-todo "change todo state")
  )

(defhydra hydra-buffer (:color blue :columns 3)
;; todo: make buffers open in new screen. 
  "Buffers"
  ("n" next-buffer "next" :color red)
  ("b" ivy-switch-buffer "switch")
  ("B" ibuffer "ibuffer")
  ("p" previous-buffer "prev" :color red)
  ("C-b" buffer-menu "buffer menu")
  ("N" evil-buffer-new "new")
  ("e" eval-buffer "eval buff") 
  ("d" kill-this-buffer "delete" :color red)
  ;; don't come back to previous buffer after delete
  ("D" (progn (kill-this-buffer) (next-buffer)) "Delete" :color red)
  ("s" save-buffer "save" :color red))

;; necessary? or should c be capture (t)odo (j)ournal?
;; (defhydra hydra-comment (:color blue))

(defhydra hydra-edit (:color blue)
  "Editing and text movement"
  ("j" move-line-down "line down" :color red)
  ("k" move-line-up "line up" :color red)
  ("y" counsel-yank-pop "browse kill ring")
  ("u" unfill-paragraph "unfill graf") 
  ("v" undo-tree-visualize "vis undo tree"))
;; iedit, crux stuff splitting/joining lines. unfilling paragraphs.
;; 

(defun save-all-buffers ()
  (interactive)
  (save-some-buffers t))
(defhydra hydra-files (:color blue :columns 3)
  "Files"
  ("s" save-buffer "save")
  ("S" save-all-buffers "save all")
  ("e" eval-buffer "eval current")
  ("r" counsel-recentf "recent")
  ("f" counsel-find-file "find")
  ("v" revert-buffer "revert"))
;; ("c" elscreen-find-file "find-new screen")
;; ("u" elscreen-find-screen-by-buffer "file or buffer-screen"))

;; ;; (defhydra hydra-help (:color blue))
;; remind C-o in ivy-hydra

;; (defhydra hydra-insert (:color blue))
;; crux stuff

(defhydra hydra-jump (:color blue)
  "Jumping"
  ("a" counsel-ag "ag")  ;; buggy! 
  ("s" swiper-all "swiper all buffs"))
; imenu+, more searching, fix ag, maybe bookmarks 

(defhydra hydra-evals (:color blue)
  ("b" eval-buffer "buffer")
  ("d" eval-defun "defun")
  ("s" eval-last-sexp "sexp")) 
;; (defhydra hydra-registers (:color blue))
; bookmarks, registers, rings 
;; (defhydra hydra-toggles (:color blue))

(defhydra hydra-windows (:color blue columns: 3)
  "Windows and screens"
  ;; ("0" (elscreen-goto 0) "goto 0")
  ;; ("1" (elscreen-goto 1) "goto 1")
  ;; ("2" (elscreen-goto 1) "goto 2")
  ;; ("3" (elscreen-goto 1) "goto 3")
  ;; ("4" (elscreen-goto 1) "goto 4")
  ;; ("5" (elscreen-goto 1) "goto 5")
  ;; ("n" elscreen-create)
  ;; ("k" delete-other-windows "keep only this win")
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
	     "SPC" 'counsel-M-x
	     "'" 'avy-goto-char
	     ";" 'comment-line
	     "/" 'swiper
	     "0" 'winum-select-window-0-or-10
	     "1" 'winum-select-window-1
	     "2" 'winum-select-window-2
	     "3" 'winum-select-window-3
	     "4" 'winum-select-window-4
	     "5" 'winum-select-window-5
	     "6" 'winum-select-window-6
	     "7" 'winum-select-window-7
	     "8" 'winum-select-window-8
	     "a" 'hydra-applications/body  
	     "b" 'hydra-buffer/body
	     "c" 'hydra-comment/body
	     "e" 'hydra-edit/body 
	     "f" 'hydra-files/body
	     "h" 'hydra-help/body
	     "i" 'hydra-insert/body
	     "j" 'hydra-jump/body
	     "n" 'ace-jump-buffer
	     "q" 'save-buffers-kill-terminal 
	     "r" 'hydra-registers/body
	     "t" 'org-capture
	     "v" 'hydra-evals/body
	     "w" 'hydra-windows/body
	     "x" 'hydra-text/body
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


;;; elscreen
;; (use-package elscreen
;;   :config
;;   (elscreen-start)
;;   (setq elscreen-tab-display-kill-screen nil)
;;   (setq elscreen-tab-display-control nil))
;; (global-unset-key (kbd "s-w"))
;; (global-set-key (kbd "s-w") 'elscreen-kill)
;; (global-unset-key (kbd "s-n"))
;; (global-set-key (kbd "s-n") 'elscreen-create)
;; (use-package elscreen-persist
;;   :config
;;   (elscreen-persist-mode 1))
;;; winum
(use-package winum)
(setq winum-auto-setup-mode-line nil)
(winum-mode)

;;; modeline 
(use-package spaceline
  :ensure t
  :config
  (require 'spaceline-config)
  (spaceline-spacemacs-theme)
  (spaceline-toggle-minor-modes-on)
  (spaceline-toggle-buffer-modified-on)
  (spaceline-toggle-buffer-size-on)
  (spaceline-toggle-version-control-off)
  (spaceline-toggle-window-number-on)
  (setq
   spaceline-highlight-face-func 'spaceline-highlight-face-evil-state
   powerline-default-separator 'contour
   spaceline-helm-mode nil
   spaceline-byte-compile t))

;;; done with port from org-mode 
(message "PB dotemacs loaded.")
;; end
