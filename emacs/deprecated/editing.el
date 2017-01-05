;;; editing.el


;; helm
(use-package helm
  :bind (("M-x" . helm-M-x)))

(use-package swiper-helm
  :config
  :bind (("C-s" . swiper-helm)
	 ("C-r" . swiper-helm)))

(use-package helm-pydoc
  :config
  (eval-after-load "python"
    '(define-key python-mode-map (kbd "C-c C-d") #'helm-pydoc)))


(delete-selection-mode 1)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; flyspell - use aspell instead of ispell
;; Standard location of personal dictionary
(setq ispell-personal-dictionary "~/.flydict")

(setq ispell-program-name (executable-find "aspell"))
(setq ispell-extra-args
      (list "--sug-mode=fast" ;; ultra|fast|normal|bad-spellers
            "--lang=en_US"
            "--ignore=3"))

(defun my/enable-flyspell-prog-mode ()
  (interactive)
  (flyspell-prog-mode))

(use-package flyspell
  :defer t
  :diminish ""
  :init (add-hook 'prog-mode-hook #'my/enable-flyspell-prog-mode)
  :config
  (use-package helm-flyspell
    :init
    (define-key flyspell-mode-map (kbd "M-S") 'helm-flyspell-correct)))

(use-package crux
  :ensure t
  :bind (("C-c d" . crux-duplicate-current-line-or-region)
	 ("C-c r" . crux-rename-file-and-buffer)
	 ("C-c o" . crux-transpose-windows)
	 ))



(defhydra hydra-yank-pop ()
  "yank"
  ("C-y" yank nil)
  ("M-y" yank-pop nil)
  ("y" (yank-pop 1) "next")
  ("Y" (yank-pop -1) "prev")
  ("l" helm-show-kill-ring "list" :color blue)
  ("u" undo-tree-visualize "undoTree"))
(bind-key* (kbd "M-y") #'hydra-yank-pop/yank-pop)
(bind-key* (kbd "C-y") #'hydra-yank-pop/yank)


;; from Sacha

(defun my/key-chord-define (keymap keys command)
  "Define in KEYMAP, a key-chord of two keys in KEYS starting a COMMAND.
\nKEYS can be a string or a vector of two elements. Currently only elements
that corresponds to ascii codes in the range 32 to 126 can be used.
\nCOMMAND can be an interactive function, a string, or nil.
If COMMAND is nil, the key-chord is removed.

MODIFICATION: Do not define the transposed key chord.
"
  (if (/= 2 (length keys))
      (error "Key-chord keys must have two elements"))
  ;; Exotic chars in a string are >255 but define-key wants 128..255 for those
  (let ((key1 (logand 255 (aref keys 0)))
        (key2 (logand 255 (aref keys 1))))
    (define-key keymap (vector 'key-chord key1 key2) command)))
(fset 'key-chord-define 'my/key-chord-define)

(defun my/switch-to-previous-buffer ()
  "Switch to previously open buffer.
Repeated invocations toggle between the two most recently open buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun my/org-check-agenda ()
  "Peek at agenda."
  (interactive)
  (cond
   ((derived-mode-p 'org-agenda-mode)
    (if (window-parent) (delete-window) (bury-buffer)))
   ((get-buffer "*Org Agenda*")
    (switch-to-buffer-other-window "*Org Agenda*"))
   (t (org-agenda nil "a"))))

(defun my/goto-random-char ()
  (interactive)
  (goto-char (random (point-max))))


(defhydra my/find-file ()
  ("f" helm-find-files "helm-ff")
  ("r" helm-recentf "helm-re")
  ("b" ibuffer "ibuffer")
  )




(defhydra my/window-movement (:color blue
				     :hint nil)
"
^Jump^         ^Files^       ^Buffer^     ^Search
------------------------------------------------------
_y_: other    _m_: buf-rec   _b_: buff    _s_: swoop
_a_: ace-win  _r_: recent    _B_: ibuff   _S_: multswoop
_c_: char     _F_: find-oth  _r_: rename  _g_: grep
_l_: line     _f_: find      _D_: del(win)
"
  ("y" other-window)
  ("a" ace-window)
  ("c" avy-goto-char)
  ("l" avy-goto-line)
  ("f" helm-find-files)
  ("r" helm-recentf)
  ("m" helm-mini)
  ("F" helm-find-files)
  ("D" ace-delete-window)
  ("b" helm-buffers-list)
  ("B" ibuffer)
  ("r" crux-rename-file-and-buffer)
  ("s" helm-swoop)
  ("S" helm-multi-swoop-all)
  ("g" helm-grep-do-grep)
  ("q" quit-window "quit" :color blue))

;;   (defhydra join-lines ()
;;     ("<up>" join-line)
;;     ("<down>" (join-line 1))
;;     ("t" join-line)
;;     ("n" (join-line 1)))

;;   (defhydra my/org (:color blue)
;;     "Convenient Org stuff."
;;     ("p" my/org-show-active-projects "Active projects")
;;     ("a" (org-agenda nil "a") "Agenda"))
;;   (defhydra my/key-chord-commands ()
;;     "Main"
;;     ("k" kill-sexp)
;;     ("h" my/org-jump :color blue)
;;     ("x" my/org-finish-previous-task-and-clock-in-new-one "Finish and clock in" :color blue)
;;     ("i" my/org-quick-clock-in-task "Clock in" :color blue)
;;     ("b" helm-buffers-list :color blue)
;;     ("f" find-file :color blue)
;;     ("a" my/org-check-agenda :color blue)
;;     ("c" (call-interactively 'org-capture) "capture" :color blue)
;;     ("t" (org-capture nil "T") "Capture task")
;;     ("." repeat)
;;     ("C-t" transpose-chars)
;;     ("o" my/org-off-my-computer :color blue)
;;     ("w" my/engine-mode-hydra/body "web" :exit t)
;;     ("m" imenu :color blue)
;;     ("q" quantified-track :color blue)
;;     ("r" my/describe-random-interactive-function)
;;     ("l" org-insert-last-stored-link)
;;     ("L" my/org-insert-link)
;;     ("+" text-scale-increase)
;;     ("-" text-scale-decrease))
;;   (defhydra my/engine-mode-hydra (:color blue)
;;     "Engine mode"
;;     ("b" engine/search-my-blog "blog")
;;     ("f" engine/search-my-photos "flickr")
;;     ("m" engine/search-mail "mail")
;;     ("g" engine/search-google "google")
;;     ("e" engine/search-emacswiki "emacswiki"))
;;   )

(setq avy-all-windows 'all-frames)


(use-package helm-swoop)

(defun my/org-insert-link ()
  (interactive)
  (when (org-in-regexp org-bracket-link-regexp 1)
    (goto-char (match-end 0))
    (insert "\n"))
  (call-interactively 'org-insert-link))


(use-package key-chord
  :init
  (progn
    (fset 'key-chord-define 'my/key-chord-define)
    (setq key-chord-one-key-delay 0.16)
    (key-chord-mode 1)
    ;; k can be bound too
    (key-chord-define-global "uu"     'undo)
    (key-chord-define-global "jj"     'avy-goto-char)
    (key-chord-define-global "yy"     'my/window-movement/body)
    (key-chord-define-global "jl"     'avy-goto-line)
    (key-chord-define-global "hh"     'my/key-chord-commands/body)
    (key-chord-define-global "xx"     'er/expand-region)))



(message "PB editing loaded")
;; end
