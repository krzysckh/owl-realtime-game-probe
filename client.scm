(import
 (owl toplevel)
 (owl eval)
 (prefix (owl sys) sys/)
 (prefix (owl metric) m/)
 (common)
 (raylib))

(define sz 400)

(define (send-pos c pos color)
  (let ((l (append (n->bytes color 4) (n->bytes (car pos) 4) (n->bytes (cadr pos) 4))))
    (write-bytes c l)))

(define (maybe-pinger l)
  (if (ping? l) (mail 'pinger #t) #f))

(define (maybe-get-player c)
  (let ((bv (try-get-block c *block-size* #f)))
    (if (bytevector? bv)
        (let ((l (bytevector->list bv)))
          (if (maybe-pinger l)
              (values #f #f)
              (let ((color (u32->n l))
                    (p (cddddr l)))
                (values (list (u32->n p) (u32->n (cddddr p))) color))))
        (values #f #f))))

(define (L~ v) (if v v '(0 0)))
(define (cadr* l) (car* (cdr* l)))

(define ip (bytevector 127 0 0 1))
;; (define ip (sys/resolve-host "pub.krzysckh.org"))
;; (define ip (sys/resolve-host "krzysckh.org"))

(define (pinger c)
  (let loop ()
    (let ((t1 (time-ms)))
      (write-bytes c (make-list *block-size* 1))
      (wait-mail)
      (let ((t2 (time-ms)))
        (mail 'main (cons 'ping (- t2 t1)))
        (sleep 1000)
        (loop)))))

;; (define packets/s ())
(define packets/s 50)
(define (main args)
  (set-target-fps! 120)
  (set-config-flags! flag-window-resizable)
  (let* ((argv0 (lref args 0)) ;; TODO: parse args
         (cs (let ((v (car* (cdr* args)))) (if (null? v) "3" v)))
         (host (sys/resolve-host
              (let ((v (car* (cdr* (cdr* args))))) (if (null? v) "localhost" v))))
         (color (lref colors (read cs)))
         (serv (let loop ()
                 (let ((c (open-connection host *port*)))
                   (if c c (begin
                             (print "couldn't connect. retrying.")
                             (sleep 1000)
                             (loop)))))))
    (thread 'pinger (pinger serv))
    (with-window
     sz sz "client"
     (let loop ((p1 '(0 0)) (rest ()) (fctr 0) (ping 0) (bs 0) (br 0))
       (lets ((mp (map (λ (x) (max 0 x)) (mouse-pos)))
              (pl pl-c (maybe-get-player serv))
              (br (if pl (+ br *block-size*) br))
              (rest (if pl
                        (append (filter (λ (x) (not (= (car x) pl-c))) rest)
                                (let* ((L (assoc pl-c rest))
                                       (lastp (L~ (cadr* L))))
                                  (list (list pl-c
                                              pl
                                              lastp
                                              ;; (vec2- pl lastp)
                                              ;; (time-ms)
                                              ))))
                        rest))
              (fctr bs (if (>= fctr (/ (fps) packets/s))
                           (if (equal? mp p1)
                               (values 0 bs)
                               (begin (send-pos serv mp color) (values 0 (+ bs *block-size*))))
                           (values (+ 1 fctr) bs)))
              (M (ref (check-mail) 2))
              (br bs (if M (values (+ br *block-size*) (+ bs *block-size*)) (values br bs)))
              (ping (if (eqv? (car* M) 'ping) (cdr M) ping)))
         (draw
          (clear-background black)
          (draw-circle mp 8 color)
          (for-each
           (λ (v)
             (when (caddr v)
               (draw-line (cadr v) (caddr v) (car v)))
             (draw-circle (cadr v) 6 (car v)))
           rest)
          (draw-text-simple (string-append "ping " (number->string ping) "ms") '(0 0) 18 white)
          (draw-text-simple (string-append "sent " (m/format-number bs)) '(0 20) 18 white)
          (draw-text-simple (string-append "received " (m/format-number br)) '(0 40) 18 white)
          )

         (if (window-should-close?)
             0
             (loop mp rest fctr ping bs br)))))))

(λ (args)
  (thread 'main (main args)))
