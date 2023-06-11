;; -*- coding: utf-8; lexical-binding: t; -*-

;;; Code:

;; Without this comment emacs25 adds (package-initialize) here
;; (package-initialize)

(let* ((minver "26.1"))
  (when (version< emacs-version minver)
    (error "Emacs v%s or higher is required" minver)))

(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))

(defvar my-debug nil "Enable debug mode.")

(setq *is-a-mac* (eq system-type 'darwin))
(setq *win64* (eq system-type 'windows-nt))
(setq *cygwin* (eq system-type 'cygwin) )
(setq *linux* (or (eq system-type 'gnu/linux) (eq system-type 'linux)) )
(setq *unix* (or *linux* (eq system-type 'usg-unix-v) (eq system-type 'berkeley-unix)) )
(setq *emacs28* (>= emacs-major-version 28))

;; don't GC during startup to save time
(unless (bound-and-true-p my-computer-has-smaller-memory-p)
  (setq gc-cons-percentage 0.6)
  (setq gc-cons-threshold most-positive-fixnum))

;; {{ emergency security fix
;; https://bugs.debian.org/766397
(with-eval-after-load 'enriched
  (defun enriched-decode-display-prop (start end &optional param)
    (list start end)))
;; }}

(setq my-disable-lazyflymake t)
(setq my-disable-wucuo t)

(setq *no-memory* (cond
                   (*is-a-mac*
                    ;; @see https://discussions.apple.com/thread/1753088
                    ;; "sysctl -n hw.physmem" does not work
                    (<= (string-to-number (shell-command-to-string "sysctl -n hw.memsize"))
                        (* 4 1024 1024)))
                   (*linux* nil)
                   (t nil)))

(defconst my-emacs-d (file-name-as-directory user-emacs-directory)
  "Directory of emacs.d.")

(defconst my-site-lisp-dir (concat my-emacs-d "site-lisp")
  "Directory of site-lisp.")

(defconst my-lisp-dir (concat my-emacs-d "lisp")
  "Directory of personal configuration.")

;; Light weight mode, fewer packages are used.
(setq my-lightweight-mode-p (and (boundp 'startup-now) (eq startup-now t)))

(defun require-init (pkg &optional maybe-disabled)
  "Load PKG if MAYBE-DISABLED is nil or it's nil but start up in normal slowly."
  (when (or (not maybe-disabled) (not my-lightweight-mode-p))
    (load (file-truename (format "%s/%s" my-lisp-dir pkg)) t t)))

(defun my-add-subdirs-to-load-path (lisp-dir)
  "Add sub-directories under LISP-DIR into `load-path'."
  (let* ((default-directory lisp-dir))
    (setq load-path
          (append
           (delq nil
                 (mapcar (lambda (dir)
                           (unless (string-match "^\\." dir)
                             (expand-file-name dir)))
                         (directory-files lisp-dir)))
           load-path))))

;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))
;; Which means on every .el and .elc file loaded during start up, it has to runs those regexps against the filename.
(let* ((file-name-handler-alist nil))

  (require-init 'init-autoload)
  ;; `package-initialize' takes 35% of startup time
  ;; need check https://github.com/hlissner/doom-emacs/wiki/FAQ#how-is-dooms-startup-so-fast for solution
  (require-init 'init-modeline)
  (require-init 'init-utils)
  (require-init 'init-file-type)
  (require-init 'init-elpa)

  ;; make all packages in "site-lisp/" loadable right now because idle loader
  ;; are not used and packages need be available on the spot.
  (when (or my-lightweight-mode-p my-disable-idle-timer)
    (my-add-subdirs-to-load-path (file-name-as-directory my-site-lisp-dir)))

  ;; Any file use flyspell should be initialized after init-spelling.el
;;  (require-init 'init-spelling t)
  (require-init 'init-ibuffer t)
;;  (require-init 'init-bookmark)
  (require-init 'init-ivy)
  (require-init 'init-windows)
 ;; (require-init 'init-javascript t)
  (require-init 'init-org t)
  (require-init 'init-python t)
  (require-init 'init-lisp t)
  (require-init 'init-yasnippet t)
  (require-init 'init-cc-mode t)
  (require-init 'init-linum-mode)
  (require-init 'init-git)
  (require-init 'init-gtags t)
  (require-init 'init-clipboard)
  (require-init 'init-ctags t)
  (require-init 'init-gnus t)
  (require-init 'init-lua-mode t)
  (require-init 'init-term-mode)
  (require-init 'init-web-mode t)
  (require-init 'init-company t)
;;  (require-init 'init-chinese t) ;; cannot be idle-required
  ;; need statistics of keyfreq asap
  (require-init 'init-keyfreq t)
  (require-init 'init-httpd t)

  ;; projectile costs 7% startup time

  ;; don't play with color-theme in light weight mode
  ;; color themes are already installed in `init-elpa.el'
  (require-init 'init-theme)

  ;; essential tools
  (require-init 'init-essential)
  ;; tools nice to have
  (require-init 'init-misc t)
  (require-init 'init-dictionary t)
  (require-init 'init-emms t)

  (require-init 'init-emacs-w3m t)
  (require-init 'init-shackle t)
  (require-init 'init-dired t)
  (require-init 'init-writting t)
  (require-init 'init-hydra) ; hotkey is required everywhere
  ;; use evil mode (vi key binding)
  (require-init 'init-evil) ; init-evil dependent on init-clipboard
 ;; (require-init 'init-pdf)
  (require-init 'init-rime t)
  (require-init 'init-lsp t)

  ;; ediff configuration should be last so it can override
  ;; the key bindings in previous configuration
  ;; (when my-lightweight-mode-p
  ;;   (require-init 'init-ediff))

  ;; @see https://github.com/hlissner/doom-emacs/wiki/FAQ
  ;; Adding directories under "site-lisp/" to `load-path' slows
  ;; down all `require' statement. So we do this at the end of startup
  ;; NO ELPA package is dependent on "site-lisp/".
  (unless my-disable-idle-timer
    (my-add-subdirs-to-load-path (file-name-as-directory my-site-lisp-dir)))

  ;;(require-init 'init-no-byte-compile t)

  ;; (unless my-lightweight-mode-p
  ;;   ;; @see https://www.reddit.com/r/emacs/comments/4q4ixw/how_to_forbid_emacs_to_touch_configuration_files/
  ;;   ;; See `custom-file' for details.
  ;;   (setq custom-file (concat my-emacs-d "custom-set-variables.el"))
  ;;   (if (file-exists-p custom-file) (load custom-file t t))

  ;;   ;; my personal setup, other major-mode specific setup need it.
  ;;   ;; It's dependent on *.el in `my-site-lisp-dir'
  ;;   (my-run-with-idle-timer 1 (lambda () (load "~/.custom.el" t nil))))
  )


;; @see https://www.reddit.com/r/emacs/comments/55ork0/is_emacs_251_noticeably_slower_than_245_on_windows/
;; Emacs 25 does gc too frequently
;; (setq garbage-collection-messages t) ; for debug
(defun my-cleanup-gc ()
  "Clean up gc."
  (setq gc-cons-threshold  67108864) ; 64M
  (setq gc-cons-percentage 0.1) ; original value
  (garbage-collect))

(run-with-idle-timer 4 nil #'my-cleanup-gc)
;;(load-theme 'doom-monokai-classic)

(message "*** Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time (time-subtract after-init-time before-init-time)))
           gcs-done)

(load-theme 'doom-one)
(toggle-input-method)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default bold shadow italic underline success warning error])
 '(beacon-color "#f2777a")
 '(chart-face-color-list
   '("#b52c2c" "#0fed00" "#f1e00a" "#2fafef" "#bf94fe" "#47dfea" "#702020" "#007800" "#b08940" "#1f2f8f" "#5f509f" "#00808f"))
 '(custom-safe-themes
   '("171d1ae90e46978eb9c342be6658d937a83aaa45997b1d7af7657546cae5985b" "016f665c0dd5f76f8404124482a0b13a573d17e92ff4eb36a66b409f4d1da410" "2dd4951e967990396142ec54d376cced3f135810b2b69920e77103e0bcedfba9" "aec7b55f2a13307a55517fdf08438863d694550565dee23181d2ebd973ebd6b8" "b99e334a4019a2caa71e1d6445fc346c6f074a05fcbb989800ecbe54474ae1b0" "631c52620e2953e744f2b56d102eae503017047fb43d65ce028e88ef5846ea3b" "4a201d19d8f7864e930fbb67e5c2029b558d26a658be1313b19b8958fe451b55" "34be6a46f3026dbc0eed3ac8ccf60cba5d2a6ad71aa37ccf21fbd6859f9b4d25" "02f57ef0a20b7f61adce51445b68b2a7e832648ce2e7efb19d217b6454c1b644" "a138ec18a6b926ea9d66e61aac28f5ce99739cf38566876dc31e29ec8757f6e2" "7a424478cb77a96af2c0f50cfb4e2a88647b3ccca225f8c650ed45b7f50d9525" "251ed7ecd97af314cd77b07359a09da12dcd97be35e3ab761d4a92d8d8cf9a71" default))
 '(flycheck-color-mode-line-face-to-color 'mode-line-buffer-id)
 '(flymake-error-bitmap
   '(flymake-double-exclamation-mark modus-themes-prominent-error))
 '(flymake-note-bitmap '(exclamation-mark modus-themes-prominent-note))
 '(flymake-warning-bitmap '(exclamation-mark modus-themes-prominent-warning))
 '(frame-background-mode 'dark)
 '(highlight-changes-colors nil)
 '(highlight-changes-face-list '(success warning error bold bold-italic))
 '(hl-todo-keyword-faces
   '(("TODO" . "#dc752f")
     ("NEXT" . "#dc752f")
     ("THEM" . "#2aa198")
     ("PROG" . "#268bd2")
     ("OKAY" . "#268bd2")
     ("DONT" . "#d70000")
     ("FAIL" . "#d70000")
     ("DONE" . "#86dc2f")
     ("NOTE" . "#875f00")
     ("KLUDGE" . "#875f00")
     ("HACK" . "#875f00")
     ("TEMP" . "#875f00")
     ("FIXME" . "#dc752f")
     ("XXX+" . "#dc752f")
     ("\\?\\?\\?+" . "#dc752f")))
 '(ibuffer-deletion-face 'modus-themes-mark-del)
 '(ibuffer-filter-group-name-face 'bold)
 '(ibuffer-marked-face 'modus-themes-mark-sel)
 '(ibuffer-title-face 'default)
 '(org-fontify-done-headline nil)
 '(org-fontify-todo-headline nil)
 '(org-src-block-faces 'nil)
 '(package-selected-packages
   '(flycheck amx zerodark-theme zenburn-theme zen-and-art-theme yasnippet-snippets winum white-sand-theme which-key wgrep wc-mode vterm vscode-dark-plus-theme visual-regexp vimrc-mode undo-tree undo-fu underwater-theme ujelly-theme twilight-theme twilight-bright-theme twilight-anti-bright-theme toxi-theme tao-theme tangotango-theme tango-plus-theme tango-2-theme sunny-day-theme sublime-themes subatomic256-theme subatomic-theme srcery-theme spacemacs-theme spacegray-theme soothe-theme solarized-theme soft-stone-theme soft-morning-theme soft-charcoal-theme smyx-theme shackle seti-theme scratch rvm rust-mode rime reverse-theme rebecca-theme railscasts-theme purple-haze-theme professional-theme planet-theme phoenix-dark-pink-theme phoenix-dark-mono-theme organic-green-theme omtose-phellack-theme oldlace-theme occidental-theme obsidian-theme nov nord-theme noctilux-theme neotree naquadah-theme mustang-theme monokai-theme monochrome-theme molokai-theme moe-theme modus-themes minimal-theme material-theme majapahit-themes magit madhat2r-theme lush-theme lsp-mode light-soap-theme leuven-theme legalese keyfreq kaolin-themes jbeans-theme jazz-theme ivy-hydra ir-black-theme inkpot-theme highlight-symbol heroku-theme hemisu-theme hc-zenburn-theme gruvbox-theme gruber-darker-theme grandshell-theme gotham-theme gnu-elpa-keyring-update git-timemachine git-modes gandalf-theme flatui-theme flatland-theme find-file-in-project farmhouse-themes fantom-theme eziam-themes exotica-theme evil-visualstar evil-surround evil-nerd-commenter evil-matchit evil-mark-replace evil-find-char-pinyin evil-exchange evil-escape espresso-theme emms elpy elpa-mirror dracula-theme doom-themes django-theme darktooth-theme darkokai-theme darkmine-theme dakrone-theme cyberpunk-theme counsel-css company-statistics company-native-complete company-c-headers color-theme-sanityinc-tomorrow color-theme-sanityinc-solarized color-theme clues-theme cherry-blossom-theme busybee-theme bubbleberry-theme birds-of-paradise-plus-theme base16-theme badwolf-theme auto-yasnippet auto-package-update atom-one-dark-theme atom-dark-theme async apropospriate-theme anti-zenburn-theme ample-zen-theme ample-theme alect-themes afternoon-theme ace-pinyin))
 '(rcirc-colors
   '(modus-themes-fg-red modus-themes-fg-green modus-themes-fg-blue modus-themes-fg-yellow modus-themes-fg-magenta modus-themes-fg-cyan modus-themes-fg-red-warmer modus-themes-fg-green-warmer modus-themes-fg-blue-warmer modus-themes-fg-yellow-warmer modus-themes-fg-magenta-warmer modus-themes-fg-cyan-warmer modus-themes-fg-red-cooler modus-themes-fg-green-cooler modus-themes-fg-blue-cooler modus-themes-fg-yellow-cooler modus-themes-fg-magenta-cooler modus-themes-fg-cyan-cooler modus-themes-fg-red-faint modus-themes-fg-green-faint modus-themes-fg-blue-faint modus-themes-fg-yellow-faint modus-themes-fg-magenta-faint modus-themes-fg-cyan-faint modus-themes-fg-red-intense modus-themes-fg-green-intense modus-themes-fg-blue-intense modus-themes-fg-yellow-intense modus-themes-fg-magenta-intense modus-themes-fg-cyan-intense))
 '(tetris-x-colors
   [[229 192 123]
    [97 175 239]
    [209 154 102]
    [224 108 117]
    [152 195 121]
    [198 120 221]
    [86 182 194]])
 '(window-divider-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:background nil)))))
 ;;; Local Variables:
;;; no-byte-compile: t
;;; End:
(put 'erase-buffer 'disabled nil)
