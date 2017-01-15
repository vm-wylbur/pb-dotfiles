;;; init-org.el

;; this contains my org-mode init stuff. It's so sprawling that it gets it's own
;; file. it should refuse to eval if org-mode isn't loaded.

;;; evil keys for org-mode
;; (define-key org-agenda-mode-map "j" 'evil-next-line)
;; (define-key org-agenda-mode-map "k" 'evil-previous-line)

;;;; org-mode locations
(setq org-directory "~/Documents/notes")
(setq org-archive-location "~/Documents/notes/archive.org::* From %s")
(setq org-default-notes-file (concat org-directory "/todo.org"))
(setq org-use-fast-todo-selection t)
;; this should include all ~/Documents/notes/todo-*.org + refile b
;; (setq org-agenda-files (quote ("~/Documents/notes/refile.org"
;; 			       "~/Documents/notes/todo-misc.org"
;;                                "~/Documents/notes/todo-emacs.org"
;;                                "~/Documents/notes/todo-mbp.org"
;; 			       "~/Documents/notes/todo-SY.org"
;; 			       "~/Documents/notes/todo-fundraising.org"
;; 			       "~/Documents/notes/todo-policing.org"
;; 			       "~/Documents/notes/todo-outreach.org")))
(setq org-agenda-files (append
			'("~/Documents/notes/refile.org")
			(file-expand-wildcards "~/DOcuments/notes/todo-*.org")))

(global-set-key (kbd "C-,") 'org-cycle-agenda-files)
(setq org-refile-use-outline-path nil)
(setq org-refile-targets '((org-agenda-files :maxlevel . 2)))
(setq org-log-done 'time)
(setq org-log-into-drawer t)
(add-hook 'org-mode-hook
	  (lambda () (imenu-add-to-menubar "Imenu")))
(setq org-invisible-edits 'smart)
(defun add-property-with-date-captured ()
  "Add DATE_CAPTURED property to the current item."
  (interactive)
  (org-set-property "DATE_CAPTURED" (format-time-string "%Y-%m-%dT%H:%M%Z")))

(add-hook 'org-capture-after-finalize-hook 'add-property-with-date-captured)


;;;;; Bernt Hansen's TODO setup
(setq org-todo-keywords
      (quote ((sequence "TODO(t!)" "NEXT(n!)" "|" "DONE(d!)")
              (sequence "WAITING(w@/!)" "HOLD(h@/!)" "|" "CANCELLED(c@/!)" "PHONE" "MEETING"))))

;;;;;; todo states
(setq org-todo-keyword-faces
      (quote (("TODO" :foreground "red" :weight bold)
              ("NEXT" :foreground "blue" :weight bold)
              ("DONE" :foreground "forest green" :weight bold)
              ("WAITING" :foreground "orange" :weight bold)
              ("HOLD" :foreground "magenta" :weight bold)
              ("CANCELLED" :foreground "forest green" :weight bold)
              ("MEETING" :foreground "forest green" :weight bold)
              ("PHONE" :foreground "forest green" :weight bold))))

(global-set-key (kbd "C-c c") 'org-capture)

;;;;; Capture templates for: TODO tasks, Notes, appointments, phone calls, meetings, and org-protocol
(setq org-capture-templates
      (quote (("t" "todo" entry (file+headline "~/Documents/notes/refile.org" "Inbox")
               "* TODO %?\n%U\n")
              ("r" "respond" entry (file "~/Documents/notes/refile.org")
               "** NEXT Respond to %:from on %:subject\nSCHEDULED: %t\n%U\n%a\n" :immediate-finish t)
              ("n" "note" entry (file "~/Documents/notes/refile.org")
               "** %? :NOTE:\n%U\n%a\n")
              ("j" "Journal" entry (file+datetree "~/Documents/notes/diary.org")
               "** %?\n%U\n")
              ("w" "org-protocol" entry (file "~/Documents/notes/refile.org")
               "** TODO Review %c\n%U\n" :immediate-finish t)
              ("m" "Meeting" entry (file "~/Documents/notes/refile.org")
               "** MEETING with %? :MEETING:\n%U")
              ("p" "Phone call" entry (file "~/Documents/notes/refile.org")
               "** PHONE %? :PHONE:\n%U")
              ("h" "Habit" entry (file "~/Documents/notes/refile.org")
               "** NEXT %?\n%U\n%a\nSCHEDULED: %(format-time-string \"%&lt;&lt;%Y-%m-%d %a .+1d/3d&gt;&gt;\")\n:PROPERTIES:\n:STYLE: habit\n:REPEAT_TO_STATE: NEXT\n:END:\n"))))

;; Remove empty LOGBOOK drawers on clock out
(defun bh/remove-empty-drawer-on-clock-out ()
  (interactive)
  (save-excursion
    (beginning-of-line 0)
    (org-remove-empty-drawer-at "LOGBOOK" (point))))

(add-hook 'org-clock-out-hook 'bh/remove-empty-drawer-on-clock-out 'append)
(require 'helm-org)

;;;;;; refiling
;; Targets any file contributing to the agenda but only at 1 level deep
(setq org-refile-targets (quote ((nil :level . 1)
                                 (org-agenda-files :level . 1))))

(setq org-refile-use-outline-path t
      org-outline-path-complete-in-steps nil
      org-completion-use-ido nil
      org-completion-use-iswitchb nil
      org-completion-fallback-command helm-org-headings-max-depth
      org-refile-allow-creating-parent-nodes (quote confirm))

(setq org-todo-state-tags-triggers
      (quote (("CANCELLED" ("CANCELLED" . t))
              ("WAITING" ("WAITING" . t))
              ("HOLD" ("WAITING") ("HOLD" . t))
              (done ("WAITING") ("HOLD"))
              ("TODO" ("WAITING") ("CANCELLED") ("HOLD"))
              ("NEXT" ("WAITING") ("CANCELLED") ("HOLD"))
              ("DONE" ("WAITING") ("CANCELLED") ("HOLD")))))
(add-hook 'org-capture-mode-hook 'evil-insert-state)
(load-file "~/.emacs.d/lisp/sacha-refiling-org.el")
(global-set-key (kbd "C-t") 'org-capture) ; doesn't work
;; (org-agenda nil "a")
;; init-org end.
