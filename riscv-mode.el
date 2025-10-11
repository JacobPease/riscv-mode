;;; riscv-mode.el --- Major-mode for RISC V assembly
;;
;; Copyright (C) 2016 Adam Niederer
;;
;; Author: Adam Niederer <https://github.com/AdamNiederer>
;; Maintainer: Adam Niederer
;; Created: September 29, 2016
;; Version: 0.1
;; Keywords: riscv assembly
;; Package-Requires: ((emacs "24.4"))
;; Homepage: https://github.com/AdamNiederer/riscv-mode
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; riscv-mode provides syntax highlighting, code execution with spike, and
;; syntactic indentation
;;
;;; Code:

(require 'thingatpt)

(defgroup riscv nil
  "Major mode for editing RISC V assembly"
  :prefix "riscv-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/AdamNiederer/riscv-mode")
  :link '(emacs-commentary-link :tag "Commentary" "riscv-mode"))

(defconst riscv-registers
  "\\bzero\\|ra\\|[sgtf]p\\|f?s1[01]\\|f?s[0-9]\\|t[0-6]\\|f?a[0-7]\\|ft[0-9]\\|ft1[01]")

(defconst riscv-keywords
  '("lui" "auipc"
    "jal" "jalr"
    "beq" "bne" "blt" "bge" "bltu" "bgeu"
    "lh" "lb" "lw" "lbu" "lhu"
    "sb" "sh" "sw"
    "add" "sub"
    "addi"
    "sll" "slt" "sltu" "xor" "srl" "sra" "or" "and"
    "slti" "sltiu" "xori" "ori" "andi" "slli" "srli" "srai"
    "fence" "fence.i"
    "scall" "sbreak" "ecall" "ebreak"
    "rdcycle" "rdcycleh" "rdtime" "rdtimeh" "rdinstret" "rdinstreth"
    "lwu" "ld" "sd"
    "addiw" "slliw" "srliw" "sraiw" "adw" "subw" "sllw" "srlw" "sraw"
    "mul" "mulh" "mulhsu" "mulhu" "div" "divu" "rem" "remu"
    "mulw" "divw" "divuw" "remw" "remuw"
    ;; Atomics
    "lr.w" "sc.w" "amoswapw" "amoadd.w" "amoxor.w" "amoand.w" "amoor.w"
    "amomin.w" "amomax.w" "amominu.w" "amomaxu.w"
    "lr.d" "sc.d" "amosdapd" "amoadd.d" "amoxor.d" "amoand.d" "amoor.d"
    "amomin.d" "amomax.d" "amominu.d" "amomaxu.d"
    ;; Floating point
    "flw" "fsw" "fmadd.s" "fmsub.s" "fnmsub.s" "fnmadd.s"
    "fadd.s" "fsub.s" "fmul.s" "fdiv.s" "fsqrt.s"
    "fsgnj.s" "fsnjn.s" "fsnjx.s"
    "fmin.s" "fmax.s" "fcvt.w.s" "fcvt.wu.s" "fmv.x.s"
    "feq.s" "flt.s" "fle.s"
    "fclass.s" "fcvt.s.w" "fcvt.s.wu" "fmv.s.x"
    "frcsr" "frrm" "frflags" "fscsr" "fsrm" "fsflags" "fsrmi" "fsflagsi"
    "fcvt.l.s" "fcvt.l.u.s" "fcvt.s.l" "fcvt.s.lu"
    ;; Double Precision
    "fld" "fsd" "fmadd.d" "fmsub.d" "fnmsub.d" "fnmadd.d"
    "fadd.d" "fsub.d" "fmul.d" "fdiv.d" "fsqrt.d"
    "fsgnj.d" "fsnjn.d" "fsnjx.d"
    "fmin.d" "fmax.d" "fcvt.w.d" "fcvt.wu.d" "fmv.x.d"
    "feq.d" "flt.d" "fle.d"
    "fclass.d" "fcvt.d.w" "fcvt.d.wu" "fmv.d.x"
    "frcsr" "frrm" "frflags" "fscsr" "fsrm" "fsflags" "fsrmi" "fsflagsi"
    "fcvt.l.d" "fcvt.l.u.d" "fcvt.d.l" "fcvt.d.lu"
    "fmv.d.x"
    ;; Pseudoinstructions
    "nop"
    "la" "li"
    "lb" "lh" "lw" "ld"
    "sb" "sh" "sw" "sd"
    "flw" "fld"
    "fsw" "fsd"
    "mv"
    "not" "neg" "negw"
    "sext"
    "seqz" "snez" "sltz" "sgtz"
    "fmv.s" "fmv.d"
    "fabs.s" "fabs.d"
    "fneg.s" "fneg.d"
    "beqz" "bnez" "blez" "bgez" "btlz" "bgtz"
    "j" "jal" "jr" "jalr" "ret" "call" "tail"))

;; (defconst riscv-defs
;;   '(".align"
;;     ".ascii"
;;     ".asciiz"
;;     ".byte"
;;     ".data"
;;     ".double"
;;     ".extern"
;;     ".float"
;;     ".globl"
;; 	 ".global"
;;     ".half"
;;     ".kdata"
;;     ".ktext"
;;     ".space"
;;     ".text"
;;     ".word"
;;     ".section"
;; 	 ".macro" ".endm"
;; 	 ".if" ".ifc" ".else" ".endif"
;; 	 ".option"
;; 	 ".set"
;; 	 ".include"))

(defconst riscv-directives
  `(".align"
	 ".extern"
	 ".globl"
	 ".global"
	 ".kdata"
	 ".ktext"
	 ".section"
	 ".macro" ".endm"
	 ".if" ".ifc" ".else" ".endif"
	 ".option"
	 ".set"
	 ".include"
	 ".text"
	 ".data"
	 ".equ" ".EQU"
	 ".bss"
	 ))

(defconst riscv-data-types
  `(".dword"
	 ".word"
	 ".half"
	 ".byte"
	 ".double"
	 ".float"
	 ".ascii"
	 ".asciz"
	 ".asciiz"
	 ".string"
	 ".space"
	 ".fill"))

(defconst riscv-defs (append riscv-directives riscv-data-types))

;; -------------------------------------------------------------------
;; Indentation levels
;; -------------------------------------------------------------------

(defcustom riscv-tab-width tab-width
  "Width of a tab for RISCV mode"
  :tag "Tab width"
  :group 'riscv
  :type 'integer)

;; Indentation group
(defgroup riscv-mode-indent nil
  "Customize indentation of RISC-V assembly constructs."
  :group 'riscv)

(defcustom riscv-label-indent-level 3
  "Indentation of RISC-V assembly labels."
  :group `riscv-mode-indent)

(defcustom riscv-code-indent-level 3
  "Indentation of RISC-V assembly code."
  :group `riscv-mode-indent)

(defcustom riscv-macro-indent-level 3
  "Indentation of RISC-V assembly macro blocks."
  :group `riscv-mode-indent)

;; -------------------------------------------------------------------
;; Riscv faces
;; -------------------------------------------------------------------

(defface riscv-labels '((t :inherit font-lock-function-name-face))
  "Face used for RISC-V assembly labels."
  :group 'font-lock-highlighting-faces)

(defface riscv-instructions '((t :inherit font-lock-keyword-face))
  "Face used for RISCV instructions."
  :group `font-lock-highlighting-faces)

;; -------------------------------------------------------------------
;; Search highlighting
;; -------------------------------------------------------------------

;; (defconst riscv-font-lock-keywords
;;   `((("\\_<-?[0-9]+\\>" 0 font-lock-constant-face)
;;      ("\"\\.\\*\\?" 0 font-lock-string-face)
;;      ("[A-z][A-z0-9_]*:" 0 font-lock-function-name-face)
;;      (,(regexp-opt riscv-keywords) 0 font-lock-keyword-face)
;;      (,(regexp-opt riscv-defs) 0 font-lock-preprocessor-face)
;;      (,riscv-registers . font-lock-type-face))))

(defconst riscv-font-lock-keywords
    (append `(("\\_<-?[0-9]+\\>" . font-lock-constant-face)             ; Decimal numbers
    ("\\_<0[xX][0-9a-fA-F]+\\>" . font-lock-constant-face)    ; Hex numbers (add if missing)
    ("\"\\.\\*\\?" . font-lock-string-face)                   ; Strings
    ("[A-Za-z0-9_]*:" . 'riscv-labels)                     ; Labels
    (,(regexp-opt riscv-keywords 'symbols) . 'riscv-instructions)          ; Instructions
    (,(regexp-opt riscv-defs) . font-lock-preprocessor-face)         ; Directives
    (,riscv-registers . font-lock-type-face))                  ; Registers
    cpp-font-lock-keywords ))


;; -------------------------------------------------------------------
;; Syntax Table
;; -------------------------------------------------------------------

(defvar riscv-mode-syntax-table
  (let ((st (make-syntax-table)))
	 (modify-syntax-entry ?/ ". 124b" st)
	 (modify-syntax-entry ?* ". 23" st)
	 (modify-syntax-entry ?# "< b" st)
	 (modify-syntax-entry ?\n "> b" st)
	 st))

(defcustom riscv-interpreter "spike"
  "Interpreter to run riscv code in"
  :tag "RISCV Interpreter"
  :group 'riscv
  :type 'string)

(defvar riscv-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "<backtab>") 'riscv-dedent)
    (define-key map (kbd "C-c C-c") 'riscv-run-buffer)
    (define-key map (kbd "C-c C-r") 'riscv-run-region)
    (define-key map (kbd "C-c C-l") 'riscv-goto-label-at-cursor)
    map)
  "Keymap for riscv-mode")

(defun riscv--interpreter-buffer-name ()
  "Return a buffer name for the preferred riscv interpreter"
  (format "*%s*" riscv-interpreter))

;; -------------------------------------------------------------------
;; Indentation functions
;; -------------------------------------------------------------------

(defconst riscv-directives-regex (regexp-opt riscv-directives))

(defun riscv--in-comment-p ()
  "Return non-nil if the current point is inside a comment."
  (nth 4 (syntax-ppss))
  )

(defun riscv--get-indent-level (&optional line)
  "Returns the number of spaces indenting the last label."
  (interactive)
  (- (save-excursion
       (goto-line (or line (line-number-at-pos)))
       (back-to-indentation)
       (current-column))
     (save-excursion
       (goto-line (or line (line-number-at-pos)))
       (beginning-of-line)
       (current-column))))

(defun riscv--last-matching-line (regexp)
  "Returns the line number of the last non-commented match."
  (save-excursion
    (let (label-line)
      (while (not label-line)
        (condition-case nil
            (progn
              (previous-line)
              (end-of-line)
              (re-search-backward regexp)
				  (setq label-line
                    (if (riscv--in-comment-p) ; Check if point is in a comment
                        nil
                      (line-number-at-pos))))
          (search-failed (setq label-line nil))))
      label-line)))

(defun riscv--last-label-line ()
  "Returns the line of the last non-commented label."
  (riscv--last-matching-line "[A-Za-z_][A-Za-z0-9_]*:"))

(defun riscv--last-directive-line ()
  "Returns the line of the last non-commented directive."
  ;; (riscv--last-matching-line "^[ \t]*\\.\\w+ ?\\(\\sw+\\)?"))
  (riscv--last-matching-line riscv-directives-regex))

(defun riscv--last-comment-line ()
  "Returns the line of the last comment."
  (save-excursion
    (previous-line)
    (end-of-line)
    (condition-case nil
		  (progn
		  (re-search-backward "^[ \t]*\\(/\\|#\\|*\\)+")
		  (line-number-at-pos))
		(search-failed nil))))

(defun riscv--check-label ()
  "Check if the current line contains a label, possibly indented."
  (save-excursion
	 (beginning-of-line)
	 (looking-at "^[ \t]*\\(\\w\\|_\\)+:"))
  )

(defun riscv--check-directive ()
  "Check if the current line contains a directive, possibly indented."
  (save-excursion
	 (beginning-of-line)
	 ;(looking-at "^[ \t]*\\.\\w+ ?\\(\\sw+\\)?")
	 (looking-at riscv-directives-regex))
  )

(defun riscv-calculate-indentation ()
  (let* ((lastlabel (riscv--last-label-line))
		  (lastdirective (riscv--last-directive-line))
		  (lastcomment (riscv--last-comment-line))
		  (lastcomment-indent (riscv--get-indent-level lastcomment)))
	 (cond
	  ((riscv--check-label) 0) ; Looking at a label
	  ((riscv--check-directive) 0) ; Looking at a directive
	  ((and (not (equal lastdirective nil)) (> lastdirective lastlabel)) 0)
	  ((equal lastlabel nil) 0) ;; Handles the case where there are no previous labels.
	  (t riscv-tab-width))
	)
  )

(defun riscv-indent ()
  (interactive)
  (let* ((savep (point))
			(indent (condition-case nil
							(save-excursion
							  (forward-line 0)
							  (skip-chars-forward " \t")
							  (if (>= (point) savep) (setq savep nil))
							  (max (riscv-calculate-indentation) 0))
							  (error 0))))
	 (if savep
		  (save-excursion (indent-line-to indent))
		(indent-line-to indent))))


  ;; (indent-line-to (+ riscv-tab-width
  ;;                    (riscv--get-indent-level (riscv--last-label-line)))))

(defun riscv-dedent ()
  (interactive)
  (indent-line-to (- (riscv--get-indent-level) riscv-tab-width)))

;; -------------------------------------------------------------------

(defun riscv-run-buffer ()
  "Run the current buffer in a riscv interpreter, and display the output in another window"
  (interactive)
  (let ((tmp-file (format "/tmp/riscv-%s" (file-name-base))))
    (write-region (point-min) (point-max) tmp-file nil nil nil nil)
    (riscv-run-file tmp-file)
    (delete-file tmp-file)))

(defun riscv-run-region ()
  "Run the current region in a riscv interpreter, and display the output in another window"
  (interactive)
  (let ((tmp-file (format "/tmp/riscv-%s" (file-name-base))))
    (write-region (region-beginning) (region-end) tmp-file nil nil nil nil)
    (riscv-run-file tmp-file)
    (delete-file tmp-file)))

(defun riscv-run-file (&optional filename)
  "Run the file in a riscv interpreter, and display the output in another window.
The interpreter will open filename. If filename is nil, it will open the current
buffer's file"
  (interactive)
  (let ((file (or filename (buffer-file-name))))
    (when (buffer-live-p (get-buffer (riscv--interpreter-buffer-name)))
      (kill-buffer (riscv--interpreter-buffer-name)))
    (start-process riscv-interpreter
                   (riscv--interpreter-buffer-name)
                   riscv-interpreter file))
  (switch-to-buffer-other-window (riscv--interpreter-buffer-name))
  (read-only-mode t)
  (help-mode))

(defun riscv-goto-label (&optional label)
  (interactive)
  (let ((label (or label (read-minibuffer "Go to Label: "))))
    (beginning-of-buffer)
    (re-search-forward (format "[ \t]*%s:" label))))

(defun riscv-goto-label-at-cursor ()
  (interactive)
  (riscv-goto-label (word-at-point)))

;; -------------------------------------------------------------------
;; Define mode
;; -------------------------------------------------------------------

;;;###autoload
(define-derived-mode riscv-mode prog-mode "RISC V"
  "Major mode for editing RISC V assembly."
  (setq-local font-lock-defaults '(riscv-font-lock-keywords nil t nil nil))
  (setq-local tab-width riscv-tab-width)
  (setq-local indent-line-function 'riscv-indent)
  (set-syntax-table (make-syntax-table riscv-mode-syntax-table))

  ;; Comments
  (setq-local comment-start "# ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "\\(?:\\s<+\\|/[/*]+\\)[ \t]*")
  (setq-local comment-end-skip "[ \t]*\\(\\s>\\|\\*+/\\)")
  )

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.riscv\\'" . riscv-mode))

(provide 'riscv-mode)
;;; riscv-mode.el ends here
