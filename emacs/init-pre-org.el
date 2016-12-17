
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
(require 'diminish)
(require 'bind-key)

(add-to-list 'load-path "~/dotfiles/emacs")
(load-library "ui")
(load-library "little-hacks")
(load-library "behaviors")
(load-library "")
