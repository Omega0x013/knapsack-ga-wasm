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

  (data (i32.const 12) " : ") ;; (3)
  (data (i32.const 15) "\n") ;; (1)

  ;; Dirty area for $Itoa
  (data (i32.const 16) "") ;; (16)

  ;; Weights (1 byte wide) [u8; 10]
  (data (i32.const 100) "\03") ;; 3
  (data (i32.const 101) "\08") ;; 8
  (data (i32.const 102) "\02") ;; 2
  (data (i32.const 103) "\09") ;; 9
  (data (i32.const 104) "\07") ;; 7
  (data (i32.const 105) "\01") ;; 1
  (data (i32.const 106) "\08") ;; 8
  (data (i32.const 107) "\0D") ;; 13
  (data (i32.const 108) "\0A") ;; 10
  (data (i32.const 109) "\09") ;; 9

  ;; Values (2 bytes wide) [u16; 10]
  ;; The bytes are little-endian, so keep that in mind.
  (data (i32.const 110) "\7e\00") ;; 126
  (data (i32.const 112) "\9a\00") ;; 154
  (data (i32.const 114) "\00\01") ;; 256
  (data (i32.const 116) "\0e\02") ;; 526
  (data (i32.const 118) "\84\01") ;; 388
  (data (i32.const 120) "\f5\00") ;; 245
  (data (i32.const 122) "\d2\00") ;; 210
  (data (i32.const 124) "\ba\01") ;; 442
  (data (i32.const 126) "\9f\02") ;; 671
  (data (i32.const 128) "\5c\01") ;; 348


  (start $Main)
  (func $Main
    (call $PrintGeneration (call $GetWeight (i32.const 9)) (call $GetValue (i32.const 9)))
  )

  (func $GetWeight (param $idx i32) (result i32)
    (i32.add (i32.const 100) (local.get $idx))
    i32.load8_u
  )

  (func $GetValue (param $idx i32) (result i32)
    ;; Use a idx << 1 to multiply idx by 2
    (i32.add (i32.const 110) (i32.shl (local.get $idx) (i32.const 1)))
    i32.load16_u
  )


  ;; ██████     ██  ██████  
  ;;   ██      ██  ██    ██ 
  ;;   ██     ██   ██    ██ 
  ;;   ██    ██    ██    ██ 
  ;; ██████ ██      ██████  

  ;; PrintGeneration(number int, fittest int)
  ;; > print(`${number} : ${fittest}\n`)
  (func $PrintGeneration (param $number i32) (param $fittest i32)
    ;; if Write(1, ...Itoa(number, *itoaBuffer)) != nil: throw
    i32.const 1
    (call $Itoa (local.get $number) (i32.const 16))
    call $Write
    if unreachable end

    ;; if Write(1, *" : ", 3) != nil: throw
    (call $Write (i32.const 1) (i32.const 12) (i32.const 3))
    if unreachable end

    ;; if Write(1, ...Itoa(number, *itoaBuffer)) != nil: throw
    i32.const 1
    (call $Itoa (local.get $fittest) (i32.const 16))
    call $Write
    if unreachable end

    ;; if Write(1, *"\n", 1) != nil: throw
    (call $Write (i32.const 1) (i32.const 15) (i32.const 1))
    if unreachable end
  )

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


  ;; ███    ███  █████  ████████ ██   ██ 
  ;; ████  ████ ██   ██    ██    ██   ██ 
  ;; ██ ████ ██ ███████    ██    ███████ 
  ;; ██  ██  ██ ██   ██    ██    ██   ██ 
  ;; ██      ██ ██   ██    ██    ██   ██ 

  ;; Itoa(number int, buffer *[]byte) (*[]byte, int)
  (func $Itoa (param $number i32) (param $buffer i32) (result i32 i32)
    (local $pointer i32)
    (local $end_pointer i32)
    (local $sign i32)
    (local $digit i32)

    ;; end_pointer -> buffer[10]
    ;; pointer = end_pointer
    local.get $buffer
    i32.const 10
    i32.add
    local.tee $end_pointer
    local.set $pointer

    ;; find number sign
    local.get $number
    i32.const 0
    i32.lt_s
    local.set $sign

    ;; number = |number|
    local.get $number
    call $Abs
    local.set $number

    ;; build digits
    (loop
      ;; digit = number % 10 + '0'
      local.get $number
      i32.const 10
      i32.rem_u
      i32.const 0x30
      i32.add
      local.set $digit

      ;; *pointer = digit
      (i32.store8 (local.get $pointer) (local.get $digit))

      ;; decrement pointer
      local.get $pointer
      i32.const 1
      i32.sub
      local.set $pointer

      ;; shrink number by one place value
      ;; number = number / 10
      local.get $number
      i32.const 10
      i32.div_u
      local.tee $number ;; preserving the value on the stack

      ;; while number != 0, loop
      br_if 0
    )

    local.get $sign
    if
      ;; write '-'
      (i32.store8 (local.get $pointer) (i32.const 0x2D))

      ;; decrement pointer
      local.get $pointer
      i32.const 1
      i32.sub
      local.set $pointer
    end

    (return
      (i32.add (local.get $pointer) (i32.const 1)) ;; *[]byte
      (i32.sub (local.get $end_pointer) (local.get $pointer)) ;; int
    )
  )

  ;; Abs(x int) int
  ;; https://stackoverflow.com/a/14194764
  ;; abs(x) = (x ^ y) - y
  ;; where y = x >> 31
  (func $Abs (param $x i32) (result i32)
    (local $y i32)

    ;; y = x >> 31
    local.get $x
    i32.const 31
    i32.shr_s
    local.tee $y

    ;; x ^ y
    local.get $x
    i32.xor

    ;; (x ^ y) - y
    local.get $y
    i32.sub
  )
)