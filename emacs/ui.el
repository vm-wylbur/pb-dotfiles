;;; PB's ui setup


(use-package color-theme
  :ensure t)
(use-package zenburn-theme
  :ensure t
  :diminish ""
  :config
  (load-theme 'zenburn))

(set-frame-font '(:family "DejaVu Sans Mono-13"
			  :width semi-condensed))

;; ui behaviors
(show-paren-mode 1)
(tool-bar-mode -1)
(menu-bar-mode t)
(setq show-paren-delay 0)
(setq column-number-mode 1)
(setq inhibit-startup-message t)
(setq-default cursor-type 'bar)
(setq visible-bell 1)
(add-hook 'text-mode-hook 'turn-on-visual-line-mode)

(fringe-mode '(8 . 2)) ;; make the left fringe 4 pixels wide and the right disappear


;;https://github.com/jcf/emacs.d/blob/master/init-packages.org
(use-package fill-column-indicator
  :init
  (add-hook 'prog-mode-hook 'turn-on-fci-mode)
  (add-hook 'text-mode-hook 'turn-off-fci-mode)

  (defun jcf-fci-enabled-p ()
    (and (boundp 'fci-mode) fci-mode))

  (defvar jcf-fci-mode-suppressed nil)

  (defadvice popup-create (before suppress-fci-mode activate)
    "Suspend fci-mode while popups are visible"
    (let ((fci-enabled (jcf-fci-enabled-p)))
      (when fci-enabled
        (set (make-local-variable 'jcf-fci-mode-suppressed) fci-enabled)
        (turn-off-fci-mode))))

  (defadvice popup-delete (after restore-fci-mode activate)
    "Restore fci-mode when all popups have closed"
    (when (and jcf-fci-mode-suppressed
               (null popup-instances))
      (setq jcf-fci-mode-suppressed nil)
      (turn-on-fci-mode))

    (defadvice enable-theme (after recompute-fci-face activate)
      "Regenerate fci-mode line images after switching themes"
      (dolist (buffer (buffer-list))
        (with-current-buffer buffer
          (turn-on-fci-mode))))))

(message "PB ui loaded.")

;; end.
