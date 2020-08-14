#lang racket

(require pollen/decode
         pollen/unstable/typography
         txexpr)

(provide (all-defined-out))

(module setup racket
  (define default-poly-targets '(html epub))
  (provide default-poly-targets))

(define (root . elements)
  (define new-elements
    (decode-elements
     elements
     #:string-proc (compose smart-dashes
                            smart-quotes)))

  (txexpr 'div '() new-elements))

(define (build-toc doc)
  (define (is-h2? x)
    (and (txexpr? x)
         (equal? 'h2 (get-tag x))))
  (define-values (_ headings)
    (splitf-txexpr doc is-h2?))

  (define toc-list-items
    (for/list ([heading headings])
      `(li (a [[href ,(format "#~a" (attr-ref heading 'id))]]
              ,@(get-elements heading)))))
  `(ol ,@toc-list-items))
