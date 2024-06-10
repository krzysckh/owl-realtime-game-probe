(import
 (common)
 (owl toplevel))

(define (send-to-all-but pnot ps l)
  (print "SERVER: broadcasting from " pnot " to " ps)
  (for-each (λ (p) (when (not (equal? p pnot)) (write-bytes p l))) ps))

(λ (_)
  (lets ((sock (open-tcp-socket *port*)))
    (let ploop ((threads ()) (ports ()))
      (lets ((_ p (tcp-client sock))
             (ports (append ports (list p)))
             (_ (for-each (λ (v) (mail v ports)) threads))
             (thr (thread
                   (string->symbol
                    (string-append "server-" (number->string (time-ns))))
                   (let loop ((ports ports))
                     (let ((bvec (get-whole-block p *block-size*)))
                       (when (eof-object? bvec)
                         (print "SERVER: got eof from " p)
                         (exit-owl 0))
                       (let ((ports (let ((m (check-mail)))
                                      (if m (ref m 2) ports)))
                             (l (bytevector->list bvec)))
                         (if (ping? l)
                             (begin
                               (print "SERVER: got ping from " p)
                               (write-bytes p (make-list *block-size* 1))
                               )
                             (send-to-all-but p ports l))
                         (loop ports)))))))
        (ploop (append threads (list thr)) ports)))))
