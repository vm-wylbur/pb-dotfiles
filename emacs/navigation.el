;;; PB's navigation

;; ace-window keys
(use-package ace-window
  :init
  (setq aw-keys '(?q ?w ?e ?r ?a ?s ?d ?f))
  :bind ("C-'" . ace-window))
