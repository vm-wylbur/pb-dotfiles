;;; starting *again*

;;; some bootstrapping 

;; paths 
(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setq exec-path (append exec-path '("/usr/local/bin")))

;; packages 
(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(package-initialize)
(add-to-list 'load-path "~/.emacs.d/elpa")

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(require 'diminish)                ;; if you use :diminish
(use-package auto-compile
  :config (auto-compile-on-load-mode))

(setq use-package-verbose t)
(setq use-package-always-ensure t)
(setq load-prefer-newer t)
(require 'bind-key)

(if (require 'quelpa nil t)
    (quelpa-self-upgrade)
  (with-temp-buffer
    (url-insert-file-contents "https://raw.github.com/quelpa/quelpa/master/bootstrap.el")
    (eval-buffer)))

(quelpa
 '(quelpa-use-package
   :fetcher github
   :repo "quelpa/quelpa-use-package"))
(require 'quelpa-use-package)

;; if weird, rm ~/.emacs.d/elpa/org-plus-contrib-yyyymmdd/*elc
(use-package org
  :quelpa (org :fetcher github :repo "jwiegley/org-mode"))

;; (setq
;;  org-confirm-babel-evaluate nil
;;  org-src-fontify-natively t)
;; (org-babel-load-file "~/dotfiles/emacs/pb-init.org")
;; (message "PB init org file loaded.")

;; (if (file-exists-p "~/dotfiles/emacs/pb-init.el")
;;     (delete-file "~/dotfiles/emacs/pb-init.el"))


(message "PB dotemacs loaded.")
;; end
