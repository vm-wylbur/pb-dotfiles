;;; PB keybindings

;; capslock->control on mac:
;; https://support.apple.com/kb/PH18422?locale=en_US

;; TODO: rewrite this using the (bind-key* ... ) form. see the package.
;; todo: super + should be font size increase
;; super - is font size decrease



;; useful keys:
(bind-key* [(super w)] 'kill-this-buffer) ;; also super-k
(bind-key* [(super up)] 'beginning-of-buffer)
(bind-key* [(super down)] 'end-of-buffer)
(bind-key* (kbd "C-!") 'eshell)
(bind-key* (kbd "M-p") 'backward-paragraph)  ;; these are right!
(bind-key* (kbd "M-n") 'forward-paragraph)
(bind-key* (kbd "M-o") 'other-window)


;; from little-hacks
(bind-key* [(super p)] 'move-line-up)
(bind-key* [(super n)] 'move-line-down)
(bind-key* [(super /)] 'comment-or-uncomment-region-or-line)
(bind-key* [remap move-beginning-of-line] #'crux-move-beginning-of-line)
(bind-key* (kbd "C-c o") 'crux-transpose-windows)


;; ;; loadpackages.el
;; (bind-key* (kbd "C-x g") 'magit-status)
;; (bind-key* (kbd "C-c h") 'dash-at-point)


;; override std yank to provide options.


(defhydra hydra-yank-pop ()
  "yank"
  ("C-y" yank nil)
  ("M-y" yank-pop nil)
  ("y" (yank-pop 1) "next")
  ("Y" (yank-pop -1) "prev")
  ("l" helm-show-kill-ring "list" :color blue))
(bind-key* (kbd "M-y") #'hydra-yank-pop/yank-pop)
(bind-key* (kbd "C-y") #'hydra-yank-pop/yank)

(use-package evil)
(use-package avy)
(defhydra hydra-movement ()
  "movement"
  ("c" avy-goto-char "avy char")
  ("w" ace-window "ace win")
  ("n" evil-scroll-page-down "pg dn")
  ("p" evil-scroll-page-up "pg up")
  )

(bind-key (kbd "C-x m") 'hydra-movement/body)




(message "PB keybindings loaded.")

;; end
