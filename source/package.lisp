(cl:defpackage #:pantalea.queue
  (:use #:common-lisp)
  (:local-nicknames)
  (:export
   #:make-queue
   #:with-locked-queue
   #:make-blocking-queue
   #:queue-push/no-lock!
   #:queue-pop/no-lock!
   #:queue-push!
   #:lock
   #:queue-pop!
   #:blocking-queue-push!
   #:blocking-queue-pop!))
