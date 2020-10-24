#lang racket/base

(require txexpr)

(provide (struct-out toc-item)
         is-h2?
         toc-items)

(struct toc-item (title-elements anchor))

;; Helper predicate
(define (is-h2? x)
  (and (txexpr? x)
       (equal? 'h2 (get-tag x))))

(define (toc-items doc)
  (define-values (_ headings)
    (splitf-txexpr doc (λ (x) (and (txexpr? x) (equal? 'h2 (car x))))))
  
  (for/list ([heading (in-list headings)])
    (toc-item (get-elements heading)
              (attr-ref heading 'id))))