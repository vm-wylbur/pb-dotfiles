;;; PB's dot-emacs boostrap
;;

;; org is weird and buggy, from elpa directly, no use-package
;; if weird, rm ~/.emacs.d/elpa/org-yyyymmdd/*elc

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(require 'org)
(setq
 org-confirm-babel-evaluate nil
 org-src-fontify-natively t)
(org-babel-load-file "~/dotfiles/emacs/pb-init.org")


;; note in customize below, epg-gpg-program had to be hardcoded.
;;; Customize below

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" "14f0fbf6f7851bfa60bf1f30347003e2348bf7a1005570fd758133c87dafe08f" default)))
 '(epg-gpg-program "/usr/local/bin/gpg")
 '(package-selected-packages
   (quote
    (magit markdown-mode org org-plus-contrib drag-stuff ob-tangle org-install epa-file org-mode helm-swoop shackle powerline smart-mode-line helm-flyspell helm-pydoc swiper-helm fill-column-indicator helm zenburn-theme color-theme use-package))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(aw-leading-char-face ((t (:inherit ace-jump-face-foreground :height 3.0)))))


(message "PB dotemacs loaded.")
;; end.
