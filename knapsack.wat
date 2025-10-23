;; ██   ██ ███    ██  █████  ██████  ███████  █████   ██████ ██   ██ 
;; ██  ██  ████   ██ ██   ██ ██   ██ ██      ██   ██ ██      ██  ██  
;; █████   ██ ██  ██ ███████ ██████  ███████ ███████ ██      █████   
;; ██  ██  ██  ██ ██ ██   ██ ██           ██ ██   ██ ██      ██  ██  
;; ██   ██ ██   ████ ██   ██ ██      ███████ ██   ██  ██████ ██   ██ 

(module
  ;; ██████ ███    ███ ██████   ██████  ██████  ████████ ███████ 
  ;;   ██   ████  ████ ██   ██ ██    ██ ██   ██    ██    ██      
  ;;   ██   ██ ████ ██ ██████  ██    ██ ██████     ██    ███████ 
  ;;   ██   ██  ██  ██ ██      ██    ██ ██   ██    ██         ██ 
  ;; ██████ ██      ██ ██       ██████  ██   ██    ██    ███████ 

  ;; wasi_unstable::fd_write(descriptor int, iovec *[]IOVec, iovec_count int, written *int) error
  (import "wasi_unstable" "fd_write" (func $wasi_unstable::fd_write (param i32 i32 i32 i32) (result i32)))

  ;; wasi_unstable::random_get(buffer *[]byte, length int) error
  (import "wasi_unstable" "random_get" (func $wasi_unstable::random_get (param i32 i32) (result i32)))


  ;; ██████   █████  ████████  █████  
  ;; ██   ██ ██   ██    ██    ██   ██ 
  ;; ██   ██ ███████    ██    ███████ 
  ;; ██   ██ ██   ██    ██    ██   ██ 
  ;; ██████  ██   ██    ██    ██   ██ 

  (memory 4) ;; Pre-reserve 4 pages of memory
  (export "memory" (memory 0))

  ;; GA Parameters
  ;;
  (global $arenaCount i32 (i32.const 3)) ;; individuals per arena - if you update this you'll also need to update
  (global $crossoverThreshold i32 (i32.const 52428)) ;; ~80%
  (global $mutationThreshold i32 (i32.const 3)) ;; ~1%
  (global $generationCount i32 (i32.const 5)) ;; generations to run for
  ;;
  ;;

  ;; Printable strings
  (data (i32.const 12) " : ") ;; (3)
  (data (i32.const 15) "\n") ;; (1)

  ;; Scenario Parameters
  (global $capacity i32 (i32.const 35)) ;; 35u max weight

  (global $weights i32 (i32.const 100)) ;; *Weights
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

  (global $values i32 (i32.const 110)) ;; *Values
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

  ;; ██████  ███████ ███████ 
  ;; ██   ██ ██      ██      
  ;; ██████  ███████ ███████ 
  ;; ██   ██      ██      ██ 
  ;; ██████  ███████ ███████ 

  ;; Dirty area for $Write
  (data (i32.const 0) "\00\00\00\00") ;; string ptr
  (data (i32.const 4) "\00\00\00\00") ;; string length
  (data (i32.const 8) "\00\00\00\00") ;; nwritten

  (global $writePtr i32 (i32.const 0)) ;; (4) *[]byte
  (global $writeLen i32 (i32.const 4)) ;; (4) int
  (global $writeRet i32 (i32.const 8)) ;; (4) int

  ;; Dirty area for $Itoa
  (global $itoaBuffer i32 (i32.const 16)) ;; (16)

  ;; Place where the current generation is stored
  (global $population i32 (i32.const 200)) ;; (400) map[genome]u16
  (global $populationCount i32 (i32.const 200)) ;; len(population)
  (global $populationSize i32 (i32.const 800)) ;; sizeof(population)

  ;; Place for the next generation to be written to
  (global $next i32 (i32.const 1000)) ;; (400) [200]genome

  ;; Random generation segments - filled with random_get before each generation.
  ;; $arenaSize
  (global $geneticRandom i32 (i32.const 2000)) ;; (3200) [3200]byte -- random numbers
  ;; (global $geneticRandomEnd i32 (i32.const 5200)) ;; pointer to the end of geneticRandom
  (global $selectionRandom i32 (i32.const 5200)) ;; (1200) [200][u16; 3] -- random numbers
  ;; (global $selectionRandomEnd i32 (i32.const 6400)) ;; pointer to the end of selectionRandom
  (global $randomSize i32 (i32.const 4400)) ;; sizeof(random generation segments)
  ;; Segment ends at 6400

  ;; ███    ███  █████  ██████ ███    ██ 
  ;; ████  ████ ██   ██   ██   ████   ██ 
  ;; ██ ████ ██ ███████   ██   ██ ██  ██ 
  ;; ██  ██  ██ ██   ██   ██   ██  ██ ██ 
  ;; ██      ██ ██   ██ ██████ ██   ████ 

  (start $Main)
  (func $Main
    (local $fitness i32) ;; int
    (local $genome i32) ;; genome
    (local $i i32) ;; int
    (local $generation i32) ;; int
    (local $fittest i32) ;; int
    (local $left i32) ;; genome
    (local $right i32) ;; genome

    ;; Initialise the population with random individuals
    ;; random_get(&population, sizeof(population))
    (call $wasi_unstable::random_get (global.get $population) (global.get $populationSize))
    if unreachable end

    ;; Calculate the first round of fitnesses
    call $CalculateFitnesses

    (loop
      ;; Fill the random data segment
      (call $wasi_unstable::random_get (global.get $geneticRandom) (global.get $randomSize))
      if unreachable end

      ;; i = 0
      i32.const 0
      local.set $i

      (loop
        ;; Get the left parent
        (block
          ;; = (i*3) + selectionRandom
          local.get $i
          i32.const 3
          i32.mul
          global.get $selectionRandom
          i32.add

          ;; Select(...)
          call $Select
          local.set $fitness
          local.set $genome

          ;; if fitness > fittest { fittest = fitness }
          local.get $fitness
          local.get $fittest
          i32.gt_s
          if
            local.get $fitness
            local.set $fittest
          end

          ;; left = genome
          local.get $genome
          local.set $left
        )

        ;; Get the right parent
        (block
          ;; fitness, genome = Select(SelectionRandomAt(i))
          local.get $i
          call $SelectionRandomAt
          call $Select
          local.set $fitness
          local.set $genome

          ;; if fitness > fittest { fittest = fitness }
          local.get $fitness
          local.get $fittest
          i32.gt_s
          if
            local.get $fitness
            local.set $fittest
          end

          ;; right = genome
          local.get $genome
          local.set $right
        )

        ;; ;; left, right = Crossover(left, right)
        ;; local.get $left
        ;; local.get $right
        ;; call $Crossover
        ;; local.set $right
        ;; local.set $left

        ;; if i += 2; i < populationCount { continue }
        local.get $i
        i32.const 2
        i32.add
        local.tee $i
        global.get $populationCount
        i32.lt_u
        br_if 0
      )

      (call $PrintGeneration (local.get $generation) (local.get $fittest))

      ;; if generation += 1; generation < generationCount { continue }
      local.get $generation
      i32.const 1
      i32.add
      local.tee $generation
      global.get $generationCount
      i32.lt_u
      br_if 0
    )
  )

  ;; ██████ ███    ██ ██████  ███████ ██   ██ 
  ;;   ██   ████   ██ ██   ██ ██       ██ ██  
  ;;   ██   ██ ██  ██ ██   ██ █████     ███   
  ;;   ██   ██  ██ ██ ██   ██ ██       ██ ██  
  ;; ██████ ██   ████ ██████  ███████ ██   ██                                 

  ;; WeightAt(idx int) *byte
  (func $WeightAt (param $idx i32) (result i32)
    (i32.add
      (global.get $weights)
      (local.get $idx)
    )
  )

  ;; ValueAt(idx int) *byte
  (func $ValueAt (param $idx i32) (result i32)
    ;; Use a idx << 1 to multiply idx by 2
    (i32.add
      (global.get $values)
      (i32.shl (local.get $idx) (i32.const 1))
    )
  )

  ;; GeneticRandomAt(idx int) *byte
  (func $GeneticRandomAt (param $idx i32) (result i32)
    ;; return geneticRandom + idx * sizeof([10]byte)
    local.get $idx
    i32.const 10
    i32.mul
    global.get $geneticRandom
    i32.add
  )

  ;; SelectionRandomAt(idx int) *byte
  (func $SelectionRandomAt (param $idx i32) (result i32)
    ;; return geneticRandom + idx * sizeof([3]byte)
    local.get $idx
    i32.const 3
    i32.mul
    global.get $selectionRandom
    i32.add
  )

  ;; GetIndividual(idx int) (genome, int)
  ;; Returns the actual contents of the individual, unlike the 'at' functions
  (func $GetIndividual (param $idx i32) (result i32 i32)
    (local $ptr i32)
    (local $genome i32)
    (local $fitness i32)

    local.get $idx
    i32.const 2
    i32.shl
    global.get $population
    i32.add
    local.set $ptr

    local.get $ptr
    i32.load16_u
    local.set $genome

    local.get $ptr
    i32.const 2
    i32.add
    local.tee $ptr
    i32.load16_u
    local.set $fitness

    (return (local.get $genome) (local.get $fitness))
  )

  ;; ██████   ██████  ██████  ██    ██ ██       █████  ████████ ██████  ██████  ███    ██ 
  ;; ██   ██ ██    ██ ██   ██ ██    ██ ██      ██   ██    ██      ██   ██    ██ ████   ██ 
  ;; ██████  ██    ██ ██████  ██    ██ ██      ███████    ██      ██   ██    ██ ██ ██  ██ 
  ;; ██      ██    ██ ██      ██    ██ ██      ██   ██    ██      ██   ██    ██ ██  ██ ██ 
  ;; ██       ██████  ██       ██████  ███████ ██   ██    ██    ██████  ██████  ██   ████ 

  ;; CalculateFitnesses()
  ;; Calculates the fitnesses for the population, modifying the individuals in place
  (func $CalculateFitnesses
    (local $ptr i32)
    (local $end i32)
    (local $genome i32)
    (local $fitness i32)

    ;; ptr = &population
    (local.set $ptr (global.get $population))

    ;; Get a pointer to the space immediately after the population array
    ;; end = &population + populationSize
    (local.set $end
      (i32.add
        (global.get $population)
        (global.get $populationSize)
      )
    )

    (loop
      ;; genome = *ptr
      local.get $ptr
      i32.load16_u
      local.set $genome

      ;; fitness = Fitness(genome)
      local.get $genome
      call $Fitness
      local.set $fitness

      ;; *(ptr+2) = fitness
      local.get $ptr
      i32.const 2
      i32.add
      local.get $fitness
      i32.store16

      ;; ptr += 4; ptr
      local.get $ptr
      i32.const 4
      i32.add
      local.tee $ptr

      ;; if ptr < end { continue }
      local.get $end
      i32.lt_u
      br_if 0
    )
  )

  ;; Select(random *byte) *individual
  ;; Arena selection - selects the fittest of $arenaCount randomly selected individuals
  ;; Consumes [u16; 3] from the random buffer
  (func $Select (param $random i32) (result i32 i32)
    (local $end i32)
    (local $genome i32)
    (local $fitness i32)
    (local $maxGenome i32)
    (local $maxFitness i32)
    (local $idx i32)

    ;; maxFitness := -1
    ;; Make sure that the one of the individuals is chosen
    i32.const -1
    local.set $maxFitness

    ;; end = ptr + (arenaCount << 1)
    global.get $arenaCount
    i32.const 1
    i32.shl
    local.get $random
    i32.add
    local.set $end

    (loop
      ;; genome, fitness = GetIndiviual(*random % 200)
      local.get $random
      i32.load16_u
      i32.const 200
      i32.rem_u
      local.tee $idx
      call $GetIndividual
      local.set $fitness
      local.set $genome

      ;; if fitness < maxFitness
      local.get $fitness
      local.get $maxFitness
      i32.gt_s
      if
        ;; maxGenome = genome
        local.get $genome
        local.set $maxGenome

        ;; maxFitness = fitness
        local.get $fitness
        local.set $maxFitness
      end

      ;; random += 4
      local.get $random
      i32.const 4
      i32.add
      local.tee $random
      local.get $end
      i32.lt_u
      br_if 0
    )

    ;; (call $PrintGeneration (local.get $maxGenome) (local.get $maxFitness))
    ;; (call $Write (i32.const 1) (i32.const 15) (i32.const 1))
    ;; if unreachable end

    ;; return maxGenone, maxFitness
    local.get $maxGenome
    local.get $maxFitness
    return
  )


  ;;  ██████  ███████ ███    ██  ██████  ███    ███ ███████ 
  ;; ██       ██      ████   ██ ██    ██ ████  ████ ██      
  ;; ██   ███ █████   ██ ██  ██ ██    ██ ██ ████ ██ █████   
  ;; ██    ██ ██      ██  ██ ██ ██    ██ ██  ██  ██ ██      
  ;;  ██████  ███████ ██   ████  ██████  ██      ██ ███████ 
  ;; 
  ;; Genomes are stored in u16. Individuals are [2]u16 - genome, then fitness.
  ;; Only the bottom 10 bits of the u16 are part of the solution and evaluated
  ;; for fitness. The top part is automatically filled by random_get, and is
  ;; copied around, but never interacted with meaningfully.

  ;; Fitness(genome u16) u16
  ;; Returns the fitness of a given genome, or 0 if the genome is invalid
  (func $Fitness (param $genome i32) (result i32)
    (local $col i32)
    (local $weight i32)
    (local $value i32)

    (loop
      ;; if genome & (1 << col) {
      i32.const 1
      local.get $col
      i32.shl
      local.get $genome
      i32.and
      if
        ;; weight = weight + WeightAt(col)
        local.get $col
        call $WeightAt
        i32.load8_u
        local.get $weight
        i32.add
        local.set $weight

        ;; value = value + ValueAt(col)
        local.get $col
        call $ValueAt
        i32.load16_u
        local.get $value
        i32.add
        local.set $value
      end

      ;; if col += 1; col < 10 { continue }
      local.get $col
      i32.const 1
      i32.add
      local.tee $col
      i32.const 10
      i32.lt_u
      br_if 0
    )

    ;; return weight > capacity ? 0 : value;
    i32.const 0
    local.get $value
    local.get $weight
    global.get $capacity
    i32.gt_s
    select
    return
  )

  ;; Crossover(left, right u16, ptr *[6]byte)
  ;; Cross over two genomes, using the random numbers in the pointer
  (func $Crossover (param $left i32) (param $right i32) (param $ptr i32) (result i32 i32)
    (local $a i32) ;; child a
    (local $b i32) ;; child b
    (local $crossingPoint i32)
    ;; if !(*ptr < crossoverThreshold)
    (i32.lt_u (i32.load16_u (local.get $ptr)) (global.get $crossoverThreshold))
    i32.eqz
    if ;; { return (left, right) }
      (return (local.get $left) (local.get $right))
    end

    ;; crossingPoint = *(ptr+2) % 10
    (local.set $crossingPoint
      (i32.rem_u
        (i32.load 
          (i32.add (local.get $ptr) (i32.const 2))
        )
        (i32.const 10)
      )
    )

    ;; Cross over left and right
    local.get $left
    local.get $right
  )


  ;; TODO
  (func $Mutate (param $genome i32) (param $random i32) (result i32)
    (local $col i32)

    local.get $genome
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
    (call $Itoa (local.get $number))
    call $Write
    if unreachable end

    ;; if Write(1, *" : ", 3) != nil: throw
    (call $Write (i32.const 1) (i32.const 12) (i32.const 3))
    if unreachable end

    ;; if Write(1, ...Itoa(number, *itoaBuffer)) != nil: throw
    i32.const 1
    (call $Itoa (local.get $fittest))
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
      (i32.store (global.get $writePtr) (local.get $pointer))
      (i32.store (global.get $writeLen) (i32.sub (local.get $length) (local.get $written)))

      ;; Call underlying write function
      (call $wasi_unstable::fd_write
        (i32.const 1) ;; Stdout
        (i32.const 0) ;; *[]IOVec
        (i32.const 1) ;; IOVec count
        (global.get $writeLen) ;; *nwritten
      ) ;; returns error

      (local.tee $err)
      if (return (local.get $err)) end

      ;; Return error if nwritten is 0
      (i32.eqz (local.tee $nwritten (i32.load (global.get $writeLen))))
      if (return (i32.const 1)) end

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
        (i32.load (global.get $writeLen))
      ))

      ;; Check if we've written the entire length of the string.
      (i32.ne (local.get $written) (local.get $length))
      ;; If not, loop again.
      br_if $WriteLoop
    )

    ;; Result = Success.
    i32.const 0
  )

  ;; Itoa(number int, buffer *[]byte) (*[]byte, int)
  (func $Itoa (param $number i32) (result i32 i32)
    (local $pointer i32)
    (local $end_pointer i32)
    (local $sign i32)
    (local $digit i32)

    ;; end_pointer -> buffer[10]
    ;; pointer = end_pointer
    global.get $itoaBuffer
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


  ;; ███    ███  █████  ████████ ██   ██ 
  ;; ████  ████ ██   ██    ██    ██   ██ 
  ;; ██ ████ ██ ███████    ██    ███████ 
  ;; ██  ██  ██ ██   ██    ██    ██   ██ 
  ;; ██      ██ ██   ██    ██    ██   ██ 

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