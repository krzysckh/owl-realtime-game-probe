(import
 (common)
 (owl toplevel))

(define (send-to-all-but pnot ps l)
  (print "SERVER: brodcasting from " pnot " to " ps)
  (for-each
   (λ (p) (when (not (equal? p pnot))
            (when (writeable? p)
              (write-bytes p l))))
   ps))

(λ (_)
  (lets ((sock (open-tcp-socket *port*)))
    (let ploop ((threads ()) (ports ()))
      (lets ((_ p (tcp-client sock))
             (ports (append ports (list p))))
        (for-each (λ (v) (mail v (cons 'ports ports))) threads) ;; brodcast new ports to all threads
        (let* ((thr-name (string->symbol (string-append "server-" (number->string (time-ns)))))
               (thr (thread
                     thr-name
                     (let loop ((ports ports) (threads threads))
                       (lets ((bvec (get-whole-block p *block-size*))
                              (ports threads
                                     (let Mloop ((p ports) (t threads)) ;; drain mail
                                       (let ((M (ref (check-mail) 2)))
                                         (cond
                                          ((eqv? 'ports (car* M))
                                           (Mloop (cdr M) t))
                                          ((eqv? 'threads (car* M))
                                           (Mloop p (cdr M)))
                                          (else
                                           (values (uniq p) t)))))))
                         (if (eof-object? bvec)
                             (let ((prts (filter (λ (x) (not (eqv? p x))) ports)))
                               (print "SERVER: got eof from " p)
                               (close-port p)
                               (for-each (λ (t) (mail t (cons 'ports prts))) threads)
                               (sleep 1000)
                               (exit-thread 'eof))
                             ;; else
                             (let ((l (bytevector->list bvec)))
                               (if (ping? l)
                                   (begin
                                     (print "SERVER: got ping from " p)
                                     (write-bytes p (make-list *block-size* 1))
                                     )
                                   (send-to-all-but p ports l))))
                         (loop ports threads))))))
               (for-each (λ (v) (mail v (cons 'threads threads))) threads)
               (ploop (append threads (list thr)) ports))))))
