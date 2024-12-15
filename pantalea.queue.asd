(asdf:defsystem #:pantalea.queue
  :name "queue"
  :depends-on (#:bordeaux-threads
               #:metabang-bind
               #:iterate)
  :serial T
  :pathname "source"
  :components ((:file "package")
               (:file "code")))
