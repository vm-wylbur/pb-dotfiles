;;; PB's navigation

;; ace-window keys

(use-package ace-window
  :ensure t
  :init
  (progn
    (global-set-key [remap other-window] 'ace-window)
    (custom-set-faces
     '(aw-leading-char-face
       ((t (:inherit ace-jump-face-foreground :height 3.0))))) 
    )
  :bind ("C-'" . ace-window)
  :config (progn (setq
		  aw-keys '(?f ?g ?h ?j ?k ?l)
		  aw-background nil))
  )

;; (use-package ace-window
;;   :ensure t
;;   :config 
;;   (setq
;;    aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
;;    (setq aw-background nil))
;;   :bind ("C-'" . ace-window))
;; (custom-set-faces
;;  '(aw-leading-char-face
;;    ((t (:inherit ace-jump-face-foreground :height 3.0)))))


