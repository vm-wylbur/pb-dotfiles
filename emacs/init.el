;;; starting *again*

;; org is weird and buggy, from elpa directly, no use-package
;; if weird, rm ~/.emacs.d/elpa/org-yyyymmdd/*elc
;;
(package-initialize)

(require 'org)
(setq
 org-confirm-babel-evaluate nil
 org-src-fontify-natively t)
(org-babel-load-file "~/dotfiles/emacs/pb-init.org")


(message "PB dotemacs loaded.")
;; end
