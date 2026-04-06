;; -*- lexical-binding: t; -*-
;; avy-dashboard, adding jump targets to dashboard items.

(require 'dashboard)
(require 'avy)

(defvar avy-dashboard--backing-item-lists
  '((recents . recentf-list)
    (bookmarks . bookmark-all-names)
    (projects . dashboard-projects-backend-load-projects)
    (registers . register-alist))
  "alist mapping dashboard types to backing lists or functions that return a list")

(defun avy-dashboard ()
  "Uses avy to provide jump targets in a dashboard buffer. While avy is
active, the dashboard shortcuts are unavailable."
  (interactive)

  (unless (eq major-mode 'dashboard-mode)
    (user-error "Can only be used in dashboard-mode buffers."))

  ;; Refresh the dashboard first, because if any of the layout changes (i.e., the banner changes, etc.) the offsets that avy
  ;; generates will be wrong.
  (dashboard-refresh-buffer)

  (let ((win (selected-window))
	(pos-list))

    (save-excursion
      (dolist (type-and-list avy-dashboard--backing-item-lists)
	(let* ((typeitem (car type-and-list))
	       (list-or-fn (cdr type-and-list))
	       (list-size (cdr (assoc typeitem dashboard-items)))
	       (backing-list (dashboard-subseq (if (functionp list-or-fn) (funcall list-or-fn) (symbol-value list-or-fn)) list-size )))

	  ;; We have a list here now, one way or another. The list should have all the items we need, we just need to search through
	  ;; the buffer for them and then add the positions to the pos-list.

	  (dolist (list-item backing-list)
	    (goto-char (point-min))

	    ;; Registers and bookmarks are composite strings. We need to reconstruct them here. Fortunately, we can mostly rely on
	    ;; dashboard's functionality for the bookmarks.
	    (pcase typeitem
	      ('registers (setq list-item (format "%c - %s" (car list-item) (register-describe-oneline (car list-item)))))
	      ('bookmarks
	       (setq list-item
		     (dashboard-bookmarks--format-name-and-path
		      list-item
		      (dashboard-shorten-path (bookmark-get-filename list-item) 'bookmarks)))))

	    ;; The regexp allows for any number of spaces at the beginning of the string, then the quoted string itself, then the end of
	    ;; the line.
	    (let ((regexp (concat "\\(^\\|[[:space:]]\\)" (regexp-quote list-item) "$"))
		  (pos))

	      ;; Find the string in the buffer, and cons it with the window--that's the format that avy likes.
	      (when (re-search-forward regexp nil t)
		(setq pos (- (match-beginning 0) 3)) ;; Offset 3 back from the start of the string for aesthetics.
		(push (cons pos win) pos-list))))
	  )))

    (let ((selection (avy-process pos-list)))
      ;; avy-process returns the 'pos' of the selected candidate
      (when (numberp selection)
	(goto-char selection)))))

(provide 'avy-dashboard)
