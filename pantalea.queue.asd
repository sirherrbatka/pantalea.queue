(asdf:defsystem #:pantalea.queue
  :name "queue"
  :depends-on (#:bordeaux-threads #:log4cl)
  :serial T
  :pathname "source"
  :components ((:file "package")
               (:file "code")))
