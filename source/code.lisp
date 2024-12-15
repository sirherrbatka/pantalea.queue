#|
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1) Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2) Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
|#
(cl:in-package #:pantalea.queue)


(defclass queue ()
  ((%head
    :initarg :head
    :accessor head)
   (%lock
    :initarg :lock
    :initform (bt2:make-lock :name "QUEUE lock")
    :accessor lock)
   (%tail
    :initarg :tail
    :accessor tail)))

(defmethod print-object ((object queue) stream)
  (print-unreadable-object (object stream)
    (princ (head object) stream)))

(defclass blocking-queue (queue)
  ((%cvar
    :initarg :cvar
    :initform (bt2:make-condition-variable :name "BLOCKING-QUEUE condition variable")
    :accessor cvar)))

(defun make-queue ()
  (make-instance 'queue
                 :head nil
                 :tail nil))

(defun make-blocking-queue ()
  (make-instance 'blocking-queue
                 :head nil
                 :tail nil))

(defun queue-push/no-lock! (queue value)
  (let ((new (cons value nil)))
    (if (head queue)
        (setf (cdr (tail queue)) new)
        (setf (head queue) new))
    (setf (tail queue) new))
  nil)

(defun queue-push! (queue value)
  (bt2:with-lock-held ((lock queue))
    (queue-push/no-lock! queue value))
  nil)

(defun queue-pop/no-lock! (queue)
  (let ((node (head queue)))
      (if node
          (multiple-value-prog1 (values (car node) t)
            (when (null (setf (head queue) (cdr node)))
              (setf (tail queue) nil))
            (setf (car node) nil
                  (cdr node) nil))
          (values nil nil))))

(defun queue-pop! (queue)
  (bt2:with-lock-held ((lock queue))
    (queue-pop/no-lock! queue)))

(defun blocking-queue-pop! (queue)
  (bt2:with-lock-held ((lock queue))
    (iterate
      (for (values value found) = (queue-pop/no-lock! queue))
      (when found (return-from blocking-queue-pop! value))
      (bt2:condition-wait (cvar queue) (lock queue)))))

(defun blocking-queue-push! (queue value)
  (bt2:with-lock-held ((lock queue))
    (queue-push/no-lock! queue value)
    (bt2:condition-notify (cvar queue))))

(defmacro with-locked-queue ((queue) &body body)
  `(bt2:with-lock-held ((lock ,queue))
     ,@body))

(defun queue-filter/no-lock! (queue function)
  (bind (((:accessors head tail) queue))
    (iterate
      (with p-cell = nil)
      (for cell on (head queue))
      (for content = (car cell))
      (for keep? = (funcall function content))
      (if keep?
          (setf p-cell cell)
          (progn
            (when (eq cell head)
              (setf head (cdr head)))
            (unless (null p-cell)
              (setf (cdr p-cell) (cdr cell)))
            (when (eq cell tail)
              (setf tail p-cell))))))
  queue)

(defun queue-filter! (queue function)
  (with-locked-queue (queue)
    (queue-filter/no-lock! queue function)))
