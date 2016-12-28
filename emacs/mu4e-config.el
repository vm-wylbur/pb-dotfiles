;;; mu4e-config.el

;;; mu.el --- mu email config

;;(add-to-list 'load-path "/usr/local/share/emacs/site-lisp/mu4e")
;;(require 'mu4e)

;; mu4e behaviors
(setq
 mu4e-maildir "~/Maildir"
 user-full-name "Patrick Ball"
 mu4e-use-fancy-chars nil
 mu4e-attachment-dir  "~/Downloads/Attachments"
 message-kill-buffer-on-exit t)

;; ;; from
;; (add-hook
;;  'mu4e~proc-start-hook
;;  '(lambda ()
;;     (message "Now running the 'killall mu' hook!")
;;     (shell-command "killall mu")
;;       (sleep-for 0 250)))

  ;; This is a helper to help determine which account context I am in based
  ;; on the folder in my maildir the email (eg. ~/.mail/nine27) is located in.
(defun mu4e-message-maildir-matches (msg rx)
  (when rx
    (if (listp rx)
	;; If rx is a list, try each one for a match
	(or (mu4e-message-maildir-matches msg (car rx))
	    (mu4e-message-maildir-matches msg (cdr rx)))
      ;; Not a list, check rx
      (string-match rx (mu4e-message-field msg :maildir)))))

;; Choose account label to feed msmtp -a option based on From header
;; in Message buffer; This function must be added to
;; message-send-mail-hook for on-the-fly change of From address before
;; sending message since message-send-mail-hook is processed right
;; before sending message.
(defun choose-msmtp-account ()
  (if (message-mail-p)
      (save-excursion
	(let*
	    ((from (save-restriction
		     (message-narrow-to-headers)
		     (message-fetch-field "from")))
	     (account
	      (cond
	       ((string-match "pball@fastmail.fm" from) "fastmail")
	       ((string-match "pball@hrdag.org" from) "hrdag")
	       ((string-match "wylbur@me.com" from) "icloud"))))
	  (setq message-sendmail-extra-arguments (list '"-a" account))))))

;; header windows
;; http://mbork.pl/2015-03-14_mu4e_and_human-friendly_date_format
(defun mu4e~headers-more-human-date (msg)
  "Show a 'more human' date.  If the date is today or yesterday,
show the time, otherwise, show the date. The formats used for
date and time are `mu4e-headers-date-format' and
`mu4e-headers-time-format'."
  (let ((date (mu4e-msg-field msg :date)))
    (if (equal date '(0 0 0))
	"None"
      (let ((day1 (decode-time date))
	    (day2 (decode-time (current-time))))
	(cond ((and
		(eq (nth 3 day1) (nth 3 day2))	;; day
		(eq (nth 4 day1) (nth 4 day2))	;; month
		(eq (nth 5 day1) (nth 5 day2))) ;; year
	       (format-time-string mu4e-headers-time-format date))
	      ((eq (- (time-to-days (current-time)) (time-to-days date)) 1)
	       (format-time-string mu4e-headers-yesterday-time-format date))
	      (t
	       (format-time-string mu4e-headers-date-format date)))))))

(defcustom mu4e-headers-yesterday-time-format "Y-%X"
  "Time format to use in the headers view for yesterday's
messages.  In the format of `format-time-string'."
  :type  'string
  :group 'mu4e-headers)

(add-to-list 'mu4e-header-info-custom
	     '(:more-human-date .
				(:name "Date"
				       :shortname "Date"
				       :help "Date in even more human-friendly format"
				       :function mu4e~headers-more-human-date)))
(setq
 mu4e-date-format-long "%Y-%m-%d %H:%M"
 mu4e-headers-date-format "%y.%m.%d %H:%M"
 mu4e-view-show-addresses t
 mu4e-headers-fields
 '( (:more-human-date       . 12)
    ;; (:flags   . 6)
    (:from-or-to . 22)
    (:subject    . nil)))

;; message windows
(setq
 mu4e-view-show-images t
 ;; mu4e-html2text-command "w3m -dump -T text/html"
 mu4e-html2text-command "textutil -stdin -format html -convert txt -stdout"
 mu4e-view-show-images t)
;; Use imagemagick, if available.
(when (fboundp 'imagemagick-register-types)
  (imagemagick-register-types))
(add-to-list 'mu4e-view-actions
	     '("View in browser" . mu4e-action-view-in-browser) t)

;; composing
;; Use the correct account context when sending mail based on the from header.
(setq message-sendmail-envelope-from 'header
      mu4e-compose-dont-reply-to-self t
      mu4e-compose-format-flowed t)
(add-hook 'message-send-mail-hook 'choose-msmtp-account)
(defun no-auto-fill ()
  "Turn off auto-fill-mode."
  (auto-fill-mode -1)
  (visual-line-mode-set-explicitly))
(add-hook 'mu4e-compose-mode-hook #'no-auto-fill)
(add-hook 'mu4e-compose-mode-hook 'flyspell-mode)

;; sending
(setq mail-user-agent 'mu4e-user-agent
      message-send-mail-function 'message-send-mail-with-sendmail
      sendmail-program "/usr/local/bin/msmtp")

;; indexing
(setq
 mu4e-get-mail-command "mbsync -a"
 mu4e-mu-binary "/usr/local/bin/mu"
 mu4e-index-cleanup nil
 mu4e-index-lazy-check t
 mu4e-index-update-in-background t
 mu4e-update-interval nil
 mu4e-headers-include-related nil
 message-send-mail-function 'smtpmail-send-it)

(setq mu4e-contexts
      `(,(make-mu4e-context
	  :name "icloud"
	  :enter-func (lambda () (mu4e-message "entering icloud context"))
	  :match-func (lambda(msg)
			(when msg
			  (mu4e-message-contact-field-matches msg :to "@me.com")))
	  :leave-func (lambda () (mu4e-message "leaving icloud context"))
	  :vars '(
		  (user-mail-address . "wylbur@me.com")
		  (user-full-name . "Patrick Ball")
		  (mu4e-sent-folder . "/icloud/Sent Messages")
		  (mu4e-drafts-folder . "/icloud/Drafts")
		  (mu4e-trash-folder . "/icloud/Deleted Messages")
		  (mu4e-refile-folder . "/icloud/Archive")
		  ;; (smtpmail-smtp-server . "smtp.mail.me.com")
      ;; (smtpmail-default-smtp-server . "smtp.mail.me.com")
		  ;; (smtpmail-smtp-service . 587)
		  ))
	,(make-mu4e-context
	  :name "fastmail"
	  :enter-func (lambda () (mu4e-message "entering fastmail context"))
	  :match-func (lambda(msg)
			(when msg
			  (mu4e-message-contact-field-matches msg :to "@fastmail.fm")))
	  :leave-func (lambda () (mu4e-message "entering fastmail context"))
	  :vars '(
		  (user-full-name . "Patrick Ball")
		  (user-mail-address . "pball@fastmail.fm")
		  (mu4e-sent-folder . "/fastmail/Sent Items")
		  (mu4e-drafts-folder . "/fastmail/Drafts")
		  (mu4e-trash-folder . "/fastmail/Deleted Messages")
		  (mu4e-refile-folder . "/fastmail/Archive")
		  )
	  )
	,(make-mu4e-context
	  :name "hrdag"
	  :enter-func (lambda () (mu4e-message "entering hrdag context"))
	  :match-func (lambda(msg)
			(when msg
			  (mu4e-message-contact-field-matches msg :to "@hrdag.org")))
	  :leave-func (lambda () (mu4e-message "entering hrdag context"))
	  :vars '(
		  (user-full-name . "Patrick Ball")
		  (user-mail-address . "pball@hrdag.org")
		  (mu4e-sent-folder . "/fastmail/Sent Items")
		  (mu4e-drafts-folder . "/fastmail/Drafts")
		  (mu4e-trash-folder . "/fastmail/Deleted Messages")
		  (mu4e-refile-folder . "/fastmail/Archive")
		  )
	  )
	)
      )

;; Bookmarks for common searches that I use.
(setq mu4e-bookmarks '(("m:/icloud/Inbox OR m:/fastmail/INBOX" "Inbox" ?i)
		       ("flag:unread" "Unread messages" ?u)
		       ("date:today..now" "Today's messages" ?t)
		       ("date:7d..now" "Last 7 days" ?w)
		       ("mime:image/*" "Messages with images" ?p)))
