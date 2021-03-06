;;;; Cyclone Scheme
;;;; https://github.com/justinethier/cyclone
;;;;
;;;; Copyright (c) 2014-2016, Justin Ethier
;;;; All rights reserved.
;;;;
;;;; This module automatically generates the following files:
;;;;
;;;; - dispatch.c => Used by apply to call native C functions.
;;;;
(import (scheme base)
        (scheme file)
        (scheme write))

(with-output-to-file 
  "dispatch.c"
  (lambda ()
    (display "
#include \"cyclone/types.h\"
#include \"cyclone/runtime.h\"

void do_dispatch(void *data, int argc, function_type func, object clo, object *b) {
  switch(argc) {" )

    (define bs "")
    (let loop ((i 0))
        (display "case " )
        (display i )
        (display ":func(" )
        (display "data,")
        (display i )
        (display ",clo" )
        (display bs )
        (display ");" )

        (set! bs (string-append bs ",*(b+" (number->string i) ")"))
        (if (< i 149)
          (loop (+ i 1))))

    (display "
  default:
  {
   char buf[1024];
   snprintf(buf, 1023, \"Unhandled number of function arguments: %d\\n\", argc); 
   Cyc_rt_raise_msg(data, buf);
  }
  }
}" )))

