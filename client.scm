(import
 (owl toplevel)
 (owl eval)
 (prefix (owl sys) sys/)
 (common)
 (raylib))

(define sz 400)

(define (fps*)
  (let ((v (fps)))
    (if (= v 0) 1 v)))

(define (send-pos c pos color)
  (let ((l (append (n->bytes color 4) (n->bytes (car pos) 4) (n->bytes (cadr pos) 4))))
    (write-bytes c l)))

(define (maybe-pinger l)
  (if (ping? l) (mail 'pinger #t) #f))

(define (maybe-get-player c)
  (if (readable? c)
      (let ((l (bytevector->list (get-whole-block c *block-size*))))
        (if (maybe-pinger l)
            (values #f #f)
            (let ((color (u32->n l))
                  (p (cddddr l)))
              (values (list (u32->n p) (u32->n (cddddr p))) color))))
      (values #f #f)))

;; ((color pos))

(define ip (bytevector 127 0 0 1))
;; (define ip (sys/resolve-host "pub.krzysckh.org"))

(define packets/s 100)

(define (pinger c)
  (let loop ()
    (let ((t1 (time-ms)))
      (write-bytes c (make-list *block-size* 1))
      (wait-mail)
      (let ((t2 (time-ms)))
        (mail 'main (cons 'ping (- t2 t1)))
        (sleep 1000)
        (loop)))))

(define (main args)
  (set-target-fps! 120)
  (let ((color (lref colors (read (car* (cdr args)))))
        (serv (open-connection ip *port*)))
    (thread 'pinger (pinger serv))
    (with-window
     sz sz "test"
     (let loop ((p1 '(0 0)) (rest ()) (fctr 0) (ping 0))
       (lets ((mp (map (λ (x) (max 0 x)) (mouse-pos)))
              (pl pl-c (maybe-get-player serv))
              (rest (if pl (append (filter (λ (x) (not (= (car x) pl-c))) rest) (list (list pl-c pl))) rest))
              (fctr (if (>= fctr (/ (fps*) packets/s))
                        (if (equal? mp p1) 0
                            (begin (send-pos serv mp color) 0))
                        (+ 1 fctr)))
              (M (ref (check-mail) 2))
              (ping (if (eqv? (car* M) 'ping) (cdr M) ping)))

         (draw
          (clear-background black)
          (draw-circle mp 8 color)
          (for-each
           (λ (v) (draw-circle (cadr v) 6 (car v)))
           rest)
          (draw-text-simple (string-append "ping " (number->string ping) "ms") '(0 0) 22 white))

         (if (window-should-close?)
             0
             (loop mp rest fctr ping)))))))

(λ (args)
  (thread 'main (main args)))
