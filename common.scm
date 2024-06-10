(define-library (common)
  (import
   (owl toplevel))

  (export
   *block-size*
   *port*
   ping?
   get-whole-block
   u32->n
   n->bytes
   )

  (begin
    (define *block-size* 12)
    (define *port* 21370)

    (define (ping? l) (all (λ (x) (= x 1)) l))

    (define (get-whole-block fd block-size)
      (let ((this (read-bytevector block-size fd)))
        (cond
         ((eof-object? this) (eof-object))
         ((not this) (eof-object))
         (else
          (let ((n (sizeb this)))
            (if (eq? n block-size)
                this
                (let ((tail (get-whole-block fd (- block-size n))))
                  (cond
                   ((eof-object? tail) (eof-object))
                   ((not tail) (eof-object))
                   (else
                    (bytevector-append this tail))))))))))

    (define (u32->n l)
      (bior (<< (lref l 3) 24)
            (bior (<< (lref l 2) 16)
                  (bior (<< (lref l 1) 8) (lref l 0)))))

    (define (n->bytes n nb)
      (let ((n (floor n)))
        (map (λ (x) (band #xff (>> n x))) (iota 0 8 (* nb 8)))))
    ))
