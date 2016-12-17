;; keybindings are in keybindings.el

;; fci
(require 'fill-column-indicator)
(setq fci-rule-width 1)
(setq fci-rule-color "darkblue")
(add-hook 'after-change-major-mode-hook 'fci-mode)
(define-globalized-minor-mode global-fci-mode fci-mode (lambda () (fci-mode 1)))
(global-fci-mode 1)
(setq fci-rule-column 79)

(require 'browse-kill-ring)
(browse-kill-ring-default-keybindings)

(load "dired-x")

(setq jit-lock-defer-time 0.05)

(require 'magit)
(require 'bind-key)

;; swiper and ivy
(ivy-mode 1)
(setq ivy-use-virtual-buffers t)
(setq ivy-display-style 'fancy)
(defun bjm-swiper-recenter (&rest args)
  "recenter display after swiper"
  (recenter)
  )
(advice-add 'swiper :after #'bjm-swiper-recenter)

;; (require 'flyspell-correct-ivy)
;; (setq ispell-program-name (executable-find "hunspell"))
(setq ispell-program-name (executable-find "aspell"))
(setq ispell-local-dictionary "en_US")
(flyspell-mode 1)

(require 'crux)

(require 'window-numbering)
(custom-set-faces '(window-numbering-face ((t (:foreground "DeepPink" :weight regular)))))
(window-numbering-mode 1)

(require 'buffer-move)

(require 'keyfreq)
(keyfreq-mode 1)
(keyfreq-autosave-mode 1)

;; stats stuff: pending LaTeX installation
(require 'ess-site)
(add-to-list 'auto-mode-alist '("\\.R$" . R-mode))
(add-to-list 'auto-mode-alist '("\\.r$" . R-mode))
(ess-toggle-underscore nil)

;; todo: todotxt is conflicting with swiper
(require 'todotxt)  ;; this is really important!
(setq todotxt-file "~/.todo/todo.txt")

(require 'company)       ;; tries to autocomplete everything.
(add-hook 'after-init-hook 'global-company-mode)
(setq company-show-number 1)

(require 'markdown-mode)
;; (setq markdown-enable-math 1)
(setq markdown-header-scaling nil)

(super-save-mode +1)
(setq auto-save-default 1)

(require 'yaml-mode)

(autoload 'dash-at-point "dash-at-point"
          "Search the word at point with Dash." t nil)

;; this is nice actually. It's a control-tab solution, pretty
;; straightforward, but will fail with more than 8 or so buffers. too
;; noisy.
(require 'ebs)
(ebs-initialize)


;; (require 'python-pep8)
(add-hook 'after-init-hook #'global-flycheck-mode)
(setq flycheck-python-pylint-executable "~/.pyenv/shims/pylint")
(setq flycheck-python-flake8-executable "~/.pyenv/shims/flake8")

;; (require 'pyenv-mode)
;; (pyenv-mode)

;; quick navigation
(require 'ace-window)


(message "loadpackages.el loaded")
;; end.
