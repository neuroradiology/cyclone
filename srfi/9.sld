;; TODO: this does not work yet, need (begin) to be able to inject
;; define's in its outer scope
;;
;;; This is based on the implementation of SRFI 9 from chibi scheme
(define-library (srfi 9)
  (export 
    define-record-type
    register-simple-type
    make-type-predicate
    make-constructor
    slot-set!
    type-slot-offset
  )
  (import (scheme base)
          (scheme cyclone util))
  (begin
    (define record-marker (list 'record-marker))
    (define (register-simple-type name parent field-tags)
      (let ((new (make-vector 3 #f)))
        (vector-set! new 0 record-marker)
        (vector-set! new 1 name)
        (vector-set! new 2 field-tags)
        new))
    (define (make-type-predicate pred name)
      (lambda (obj)
        (and (vector? obj)
             (equal? (vector-ref obj 0) record-marker)
             (equal? (vector-ref obj 1) name))))
    (define (make-constructor make name)
      (lambda ()
        (let* ((field-tags (vector-ref name 2))
               (field-values (make-vector (length field-tags) #f))
               (new (make-vector 3 #f))
              )
          (vector-set! new 0 record-marker)
          (vector-set! new 1 name)
          (vector-set! new 2 field-values)
          new)))
    (define (type-slot-offset name sym)
      (let ((field-tags (vector-ref name 2)))
        (list-index2 sym field-tags)))
    (define (slot-set! name obj idx val)
      (let ((vec obj)) ;; TODO: get actual slots from obj
        (vector-set! (vector-ref vec 2) idx val)))

    (define-syntax define-record-type
      (er-macro-transformer
       (lambda (expr rename compare)
         (let* ((name+parent (cadr expr))
                (name (if (pair? name+parent) (car name+parent) name+parent))
                (parent (and (pair? name+parent) (cadr name+parent)))
                (name-str (symbol->string name)) ;(identifier->symbol name)))
                (procs (cddr expr))
                (make (caar procs))
                (make-fields (cdar procs))
                (pred (cadr procs))
                (fields (cddr procs))
                (_define (rename 'define))
                (_lambda (rename 'lambda))
                (_let (rename 'let))
                (_register (rename 'register-simple-type))
                (_slot-set! (rename 'slot-set!))
                (_type_slot_offset (rename 'type-slot-offset)))
           ;; catch a common mistake
           (if (eq? name make)
               (error "same binding for record rtd and constructor" name))
           `(,(rename 'begin)
             ;; type
             (,_define ,name (,_register 
                              ,name ;,name-str 
                              ,parent 
                              ',(map car fields)))
             ;; predicate
             (,_define ,pred (,(rename 'make-type-predicate)
                              ,pred ;(symbol->string pred) ;(identifier->symbol pred))
                              ,name))
;             ;; fields
;             ,@(map (lambda (f)
;                      (and (pair? f) (pair? (cdr f))
;                           `(,_define ,(cadr f)
;                              (,(rename 'make-getter)
;                               ,(symbol->string
;                                 (cadr f)
;                                 ;(identifier->symbol (cadr f))
;                                )
;                               ,name
;                               (,_type_slot_offset ,name ',(car f))))))
;                    fields)
;             ,@(map (lambda (f)
;                      (and (pair? f) (pair? (cdr f)) (pair? (cddr f))
;                           `(,_define ,(car (cddr f))
;                              (,(rename 'make-setter)
;                               ,(symbol->string
;                                 (car (cddr f))
;                                 ;(identifier->symbol (car (cddr f)))
;                                )
;                               ,name
;                               (,_type_slot_offset ,name ',(car f))))))
;                    fields)
             ;; constructor
             (,_define ,make
               ,(let lp ((ls make-fields) (sets '()))
                  (cond
                   ((null? ls)
                    `(,_let ((%make (,(rename 'make-constructor)
                                     ,(symbol->string make) ;(identifier->symbol make))
                                     ,name)))
                       (,_lambda ,make-fields
                         (,_let ((res (%make)))
                           ,@sets
                           res))))
                   (else
                    (let ((field (assq (car ls) fields)))
                      (cond
                       ((not field)
                        (error "unknown record field in constructor" (car ls)))
                       ((pair? (cddr field))
                        (lp (cdr ls)
                            (cons `(,(car (cddr field)) res ,(car ls)) sets)))
                       (else
                        (lp (cdr ls)
                            (cons `(,_slot-set! ,name res (,_type_slot_offset ,name ',(car ls)) ,(car ls))
                                  sets)))))))))
      )
    ))))))
