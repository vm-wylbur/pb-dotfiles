;;; PB's dot-emacs
;;

(package-initialize)
(setq user-full-name "Patrick Ball")
(setq user-mail-address "pball@hrdag.org")

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(setq use-package-verbose t)
(setq use-package-always-ensure t)
(require 'use-package)
(use-package auto-compile
  :config (auto-compile-on-load-mode))
(setq load-prefer-newer t)
(require 'diminish)                ;; if you use :diminish
(require 'bind-key)                ;; if you use any :bind variant

(add-to-list 'load-path "~/dotfiles/emacs")
(load-library "ui")
(load-library "little-hacks")
(load-library "behaviors")
(load-library "")
;; (load-library "editing")
;; (load-library "keybindings")
;; (load-library "org-stuff")

(use-package hydra
  :ensure t
  )


;;; Customize below

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" "14f0fbf6f7851bfa60bf1f30347003e2348bf7a1005570fd758133c87dafe08f" default)))
 '(package-selected-packages
   (quote
    (drag-stuff ob-tangle org-install epa-file org-mode helm-swoop shackle powerline smart-mode-line helm-flyspell helm-pydoc swiper-helm fill-column-indicator helm zenburn-theme color-theme use-package))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


(message "PB dotemacs loaded.")
;; end.
