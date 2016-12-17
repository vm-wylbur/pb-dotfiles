;;; init.el --- Where all the magic begins
;;
;; This file loads Org-mode and then loads the rest of our Emacs initialization from Emacs lisp
;; embedded in literate Org-mode files.

;; Load up Org Mode and (now included) Org Babel for elisp embedded in Org Mode files

(require 'org)

;; writes pb-init.el which should be removed.
(defconst pb-init-org "~/dotfiles/emacs/pb-init.org"
  "the path for PB's init file")

(defconst pb-init-el (concat (file-name-sans-extension pb-init-org) ".el"))
(org-babel-load-file pb-init-org)

(if (file-exists-p pb-init-el)
      (delete-file pb-init-el))

(message (concat "init from " pb-init-org " complete."))
;;; init.el ends here
