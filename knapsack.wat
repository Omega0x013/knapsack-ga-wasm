(module
  ;; ██████ ███    ███ ██████   ██████  ██████  ████████ ███████ 
  ;;   ██   ████  ████ ██   ██ ██    ██ ██   ██    ██    ██      
  ;;   ██   ██ ████ ██ ██████  ██    ██ ██████     ██    ███████ 
  ;;   ██   ██  ██  ██ ██      ██    ██ ██   ██    ██         ██ 
  ;; ██████ ██      ██ ██       ██████  ██   ██    ██    ███████ 

  ;; wasi_unstable::fd_write(descriptor int, iovec *[]IOVec, iovec_count int, written *int) error
  (import "wasi_unstable" "fd_write" (func $wasi_unstable::fd_write (param i32 i32 i32 i32) (result i32)))


  ;; ██████   █████  ████████  █████  
  ;; ██   ██ ██   ██    ██    ██   ██ 
  ;; ██   ██ ███████    ██    ███████ 
  ;; ██   ██ ██   ██    ██    ██   ██ 
  ;; ██████  ██   ██    ██    ██   ██ 

  (memory 4) ;; Pre-reserve 4 pages of memory
  (export "memory" (memory 0))

  ;; Dirty area for $Write
  (data (i32.const 0) "\00\00\00\00") ;; string ptr
  (data (i32.const 4) "\00\00\00\00") ;; string length
  (data (i32.const 8) "\00\00\00\00") ;; nwritten

  (data (i32.const 100) "Hello World!\n") ;; 13

  (start $Main)
  (func $Main
    (call $Write (i32.const 1) (i32.const 100) (i32.const 13))
    if unreachable end
  )

  ;; ██████     ██  ██████  
  ;;   ██      ██  ██    ██ 
  ;;   ██     ██   ██    ██ 
  ;;   ██    ██    ██    ██ 
  ;; ██████ ██      ██████  

  ;; Write(descriptor int, pointer *[]byte, length int) error
  ;; Takes a file descriptor to be written to (STDOUT = 1; STDERR = 2)
  ;; and a pointer to a string and the number of bytes to write.
  ;; Error is an int; if error != 0 (nil), there's an error.
  (func $Write (param $descriptor i32) (param $pointer i32) (param $length i32) (result i32)
    ;; Keep track of the number of bytes already written
    (local $written i32)
    (local $nwritten i32)
    (local $err i32)

    ;; Initialise $written with 0.
    (local.set $written (i32.const 0))

    ;; Repeatedly write the string until it's all been written.
    (loop $WriteLoop
      ;; Create the IOVec.
      (i32.store (i32.const 0) (local.get $pointer))
      (i32.store (i32.const 4) (i32.sub (local.get $length) (local.get $written)))

      ;; Syscall.
      (call $wasi_unstable::fd_write
        (i32.const 1) ;; Stdout
        (i32.const 0) ;; *[]IOVec
        (i32.const 1) ;; IOVec count
        (i32.const 8) ;; *nwritten
      ) ;; returns error

      (local.tee $err)
      if (return (local.get $err)) end

      ;; Return error if nwritten is 0
      (i32.eqz (local.tee $nwritten (i32.load (i32.const 8))))
      if (return (i32.const -1)) end

      ;; if (return (i32.const 2)) end
      ;; if (call $Panic (i32.const 108) (i32.const 13)) end
      
      ;; Increment written.
      (local.set $written (i32.add
        (local.get $written)
        (local.get $nwritten)
      ))

      ;; Increment the pointer.
      (local.set $pointer (i32.add
        (local.get $pointer)
        (i32.load (i32.const 8))
      ))

      ;; Check if we've written the entire length of the string.
      (i32.ne (local.get $written) (local.get $length))
      ;; If not, loop again.
      br_if $WriteLoop
    )

    ;; Result = Success.
    i32.const 0
  )
)