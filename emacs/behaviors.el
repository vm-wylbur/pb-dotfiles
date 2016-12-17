;;; PB behaviors

;; backups
(setq
 backup-directory-alist '(("." . "~/.emacs.d/backups"))
 delete-old-versions -1
 version-control t
 vc-make-backup-files t
 auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))


;; history
(setq
 savehist-file "~/.emacs.d/savehist"
 history-length t
 history-delete-duplicates t
 savehist-save-minibuffer-history 1
 savehist-additional-variables
 '(kill-ring
   search-ring
   regexp-search-ring))
(savehist-mode 1)
(desktop-save-mode 1)


;; make everything utf-8
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)


;; (defun x-hydra-pre ()
;;   (insert "x")
;;   (let ((timer (timer-create)))
;;     (timer-set-time timer (timer-relative-time (current-time) 0.5))
;;     (timer-set-function timer 'hydra-keyboard-quit)
;;     (timer-activate timer)))

;; (defhydra x-hydra (:body-pre x-hydra-pre
;;                    :color blue
;;                    :hint nil)
;;   ("f" (progn (zap-to-char -1 ?x) (helm-find-files)))
;;   ("r" (progn (zap-to-char -1 ?x) (helm-recentf)))
;;   ("b" (progn (zap-to-char -1 ?x) (helm-buffers-list)))
;;   )
;; (global-set-key "x" #'x-hydra/body)



(message "PB behaviors.el loaded")
;; end
