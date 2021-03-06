#!/bin/bash -xe

###############################################################################
#
# Install Emacs24 on a brand new Ubuntu system
#
###############################################################################

source /etc/lsb-release

BASEDIR=$(dirname $0)

if [ -z $DISTRIB_CODENAME ]
then
  set +x;
  echo;
  echo "Sorry, can't find your ubuntu version name, exiting ...";
  echo;
  exit 1;
fi

sudo apt-get install python-software-properties

sudo add-apt-repository ppa:cassou/emacs

sudo tee -a /etc/apt/sources.list <<EOF

# For Emacs 24
deb http://ppa.launchpad.net/cassou/emacs/ubuntu $DISTRIB_CODENAME main
deb-src http://ppa.launchpad.net/cassou/emacs/ubuntu $DISTRIB_CODENAME main
EOF

sudo apt-get update

yes | sudo apt-get install emacs-snapshot

emacs --version

EM_DIR=~/.emacs.d
EM_BAK="$EM_DIR""-"$(date +%F-%Hh%Mm%Ss)
if [ -e $EM_DIR ]
then
  set +x;
  echo;
  echo "$EM_DIR already exists !!! Looks like you already have an Emacs installation";
  echo;
  echo "    Do you want to archive $EM_DIR to $EM_BAK?";
  select YN in yes no;
  do 
      if [ $YN = "yes" ]; 
          then mv -v "$EM_DIR" "$EM_BAK"; break;
          else echo "Exiting..."        ; exit 1;
      fi
  done
  echo;
fi

mkdir $EM_DIR
tee "$EM_DIR"/init.el <<EOF
;; ===================================================================
;;                             Package Manager
;; ===================================================================

(require 'package)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/") t)
(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

;; Add in your own as you wish:
(defvar my-packages '(starter-kit starter-kit-lisp starter-kit-bindings clojure-mode midje-mode multi-term switch-window slime fold-dwim)
  "A list of packages to ensure are installed at launch.")

(dolist (p my-packages)
  (when (not (package-installed-p p))
    (package-install p)))

;; ===================================================================
;;                             General
;; ===================================================================

;; font 
(set-default-font "Inconsolata-11")

;; ===================================================================
;;                             org-mode
;; ===================================================================

;; org dir

(setq org-directory "~/org")

;; indentation

(setq org-startup-indented t)

;; log work done

(setq org-log-done 'time)

;; tags

(setq org-tag-alist '(("howTo" . ?h)
                      ("tech" . ?t)
                      ("emacs" . ?e)
                      ("orgMode" . ?o)
                      ("faq" . ?f)
                      ("firefox")
                      ("conkeror")
                      ("linux")))

(setq org-todo-keywords
'((sequence "TODO" "IN-PROGRESS" "PENDING" "|" "DONE" "FAIL" "DELEGATED" "CANCELLED")))

;; ===================================================================
;;                              slime
;; ===================================================================

;; prevent slime to crash when encountering non ascii char

(set-language-environment "UTF-8") 
(setq slime-net-coding-system 'utf-8-unix) 

;; ===================================================================
;;                            multi-term
;; ===================================================================

;; set shortcut for line mode in terminal

(global-set-key (kbd "C-c C-j") 'term-line-mode)

;; ===================================================================
;;                      dwim-fold (outline in emacs)
;; ===================================================================

;; allow to easily show / hide outlines 
;;     - toggle block visibility with C-c j
;;     - hide all                with C-c l
;;     - show all                with C-c ;

(require 'fold-dwim)
(global-set-key (kbd "C-c j") 'fold-dwim-toggle)
(global-set-key (kbd "C-c l") 'fold-dwim-hide-all)
(global-set-key (kbd "C-c ;") 'fold-dwim-show-all)

;; ===================================================================
;;                    find-file-in-project
;; ===================================================================

(eval-after-load 'find-file-in-project
  '(progn
     ;; add 'entreprise' files patterns (cough!)
     (setq ffip-patterns
           (append ffip-patterns
                   '("*.css" "*.csv" "*.htm" "*.java" "*.json"
                     "*.jsp" "*.php" "*.properties" "*.sql" "*.xml")))
     ;; increase the max number of files, otherwise some files will be
     ;; 'unfindable' on big projects
     (setq ffip-limit 2048)))

;; ===================================================================
;;                    lower/upper case
;; ===================================================================

;; C-x C-l
(put 'downcase-region 'disabled nil)
;; C-x C-u
(put 'upcase-region 'disabled nil)

;; ===================================================================
;;                    clojure-mode / slime
;; ===================================================================

(require 'clojure-mode)
(add-to-list 'auto-mode-alist '("\\.clj$" . clojure-mode))
(require 'midje-mode)
(add-hook 'clojure-mode-hook 'midje-mode)
(add-hook 'clojure-mode-hook (lambda () (paredit-mode +1)))

; add color into the repl via clojure-jack-in
(add-hook 'slime-repl-mode-hook
(defun clojure-mode-slime-font-lock ()
(let (font-lock-mode)
(clojure-mode-font-lock-setup))))

(add-hook 'slime-repl-mode-hook (lambda () (paredit-mode +1)))

(add-to-list 'auto-mode-alist '("\.cljs$" . clojure-mode))

EOF


