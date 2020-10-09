#lang racket/base

(require "toc.rkt"
         pollen/decode
         txexpr)

(provide (all-defined-out))

(module setup racket
  (define default-poly-targets '(html epub))
  (provide default-poly-targets))

;; Returns a one-argument function that will replace the id attribute on
;; an h2 tag to ensure it is unique among all h2 tags passed to this function.
(define (enforce-unique-headings)
  (define headings (make-hash))
  (λ (txpr)
    (cond
      [(is-h2? txpr)
       (let* ([id (attr-ref txpr 'id)]
              [ctr (hash-ref headings id 1)])
         (hash-set! headings id (+ 1 ctr))
         (if (> ctr 1)
             (attr-set txpr 'id (format "~a_~a" id ctr))
             txpr))]
      [else txpr])))
     
(define (root . elements)
  (define new-elements
    (decode-elements
     elements
     #:txexpr-proc (enforce-unique-headings)))

  (txexpr 'div '() new-elements))

(define (build-web-toc doc)
  (define toc-list-items
    (for/list ([entry (in-list (toc-items doc))])
      `(li (a [[href ,(format "#~a" (toc-item-anchor entry))]]
              ,@(toc-item-title-elements entry)))))
  `(ol ,@toc-list-items))