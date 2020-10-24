#lang racket/base

(require pollen/decode
         racket/file
         racket/match
         txexpr
         "epub.rkt"
         "toc.rkt")

(provide (all-defined-out)
         (all-from-out "epub.rkt")
         file->bytes)

(module setup racket
  (define poly-targets '(html epub))
  (provide poly-targets))

;; Returns a one-argument function that will replace the id attribute on
;; an h2 tag to ensure it is unique among all h2 tags passed to this function.
(define (make-unique-headings-enforcer)
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
     #:txexpr-proc (make-unique-headings-enforcer)
     #:entity-proc numberify))

  (txexpr 'div '() new-elements))

;; epub files don't seem to like named HTML entities
;; Need to use numeric ones instead
(define (numberify e)
  (match e
    ['rsquo 8217]
    ['lsquo 8216]
    ['rdquo 8221]
    ['ldquo 8220]
    ['nbsp 160]
    ['mdash 8212]
    ['hellip 8230]
    [_ e]))

(define (build-web-toc doc)
  (define toc-list-items
    (for/list ([entry (in-list (toc-items doc))])
      `(li (a [[href ,(format "#~a" (toc-item-anchor entry))]]
              ,@(toc-item-title-elements entry)))))
  `(ol ,@toc-list-items))
