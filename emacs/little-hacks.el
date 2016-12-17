;;; PB little-hacks
;; note: all keybindings set in keybindings.el


;; duplicate current line: from emacswiki
(defun duplicate-current-line (&optional n)
  "duplicate current line, make more than 1 copy given a numeric argument"
  (interactive "p")
  (save-excursion
    (let ((nb (or n 1))
    	  (current-line (thing-at-point 'line)))
      ;; when on last line, insert a newline first
      (when (or (= 1 (forward-line 1)) (eq (point) (point-max)))
    	(insert "\n"))
      ;; now insert as many time as requested
      (while (> n 0)
    	(insert current-line)
    	(decf n)))))


;; from http://emacsredux.com/blog/2013/04/02/move-current-line-up-or-down/
(defun move-line-up ()
  "Move up the current line."
  (interactive)
  (transpose-lines 1)
  (forward-line -2)
  (indent-according-to-mode))

(defun move-line-down ()
  "Move down the current line."
  (interactive)
  (forward-line 1)
  (transpose-lines 1)
  (forward-line -1)
  (indent-according-to-mode))


(defun comment-or-uncomment-region-or-line ()
    "Comments or uncomments the region or the current line if there's no active region."
    (interactive)
    (let (beg end)
        (if (region-active-p)
            (setq beg (region-beginning) end (region-end))
            (setq beg (line-beginning-position) end (line-end-position)))
        (comment-or-uncomment-region beg end)))


;; https://github.com/bbatsov/crux/blob/master/crux.el
(defun crux-move-beginning-of-line (arg)
  "Move point back to indentation of beginning of line.
Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.
If ARG is not nil or 1, move forward ARG - 1 lines first.  If
point reaches the beginning or end of the buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))


;; http://stackoverflow.com/questions/3669511/the-function-to-show-current-files-full-path-in-mini-buffer
(defun show-file-name ()
  "Show the full path file name in the minibuffer."
  (interactive)
  (message (buffer-file-name)))


;; https://emacs.stackexchange.com/questions/22663/how-can-transparency-be-toggled
(defun toggle-transparency ()
  (interactive)
  (let ((alpha (frame-parameter nil 'alpha)))
    (if (eq
         (if (numberp alpha)
             alpha
           (cdr alpha)) ; may also be nil
         100)
        (set-frame-parameter nil 'alpha '(100 . 50))
      (set-frame-parameter nil 'alpha '(100 . 100)))))


;; https://superuser.com/questions/841178/directly-open-remote-shell-with-tramp-in-emacs
(defun aer-eshell ()
    (interactive)
    (let ((default-directory "/ssh:pball@aer:"))
      (eshell)))

(defun aerl-eshell ()
    (interactive)
    (let ((default-directory "/ssh:pball@aerl:"))
      (eshell)))


;; https://stackoverflow.com/questions/1511737/how-do-you-list-the-active-minor-modes-in-emacs
(defun which-active-modes ()
  "Give a message of which minor modes are enabled in the current buffer."
  (interactive)
  (let ((active-modes))
    (mapc (lambda (mode) (condition-case nil
                             (if (and (symbolp mode) (symbol-value mode))
                                 (add-to-list 'active-modes mode))
                           (error nil) ))
          minor-mode-list)
    (message "Active modes are %s" active-modes)))


(message "PB little-hacks loaded.")
;; end.
