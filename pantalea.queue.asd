(asdf:defsystem #:pantalea.queue
  :name "queue"
  :depends-on (#:bordeaux-threads)
  :serial T
  :pathname "source"
  :components ((:file "package")
               (:file "code")))
