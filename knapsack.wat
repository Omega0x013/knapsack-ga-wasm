;; ██   ██ ███    ██  █████  ██████  ███████  █████   ██████ ██   ██ 
;; ██  ██  ████   ██ ██   ██ ██   ██ ██      ██   ██ ██      ██  ██  
;; █████   ██ ██  ██ ███████ ██████  ███████ ███████ ██      █████   
;; ██  ██  ██  ██ ██ ██   ██ ██           ██ ██   ██ ██      ██  ██  
;; ██   ██ ██   ████ ██   ██ ██      ███████ ██   ██  ██████ ██   ██ 
;;
;; Copyright (c) 2025 Xander Bielby (github.com/Omega0x013)
;;
;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.
;;
;; ===
;;
;; This is a Genetic Algorithm handwritten by me to solve a version of the
;; knapsack problem. The question posed is: what's the most valuable set
;; of items I can fit into this bag? In this scenario there are 10 items
;; and the limiting factor is the amount of weight you can carry in your bag.
;;
;; ===
;; 
;; These massive labels look lovely in VSCode's Minimap
;; To make your own:
;; https://patorjk.com/software/taag/#p=display&f=ANSI+Regular&t=Type+Something+&x=none&v=4&h=4&w=80&we=false

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

  (memory 1) ;; Only uses ~7KiB out of the 64KiB available
  (export "memory" (memory 0)) ;; export the 0th memory

  ;; ██████   █████  ██████   █████  ███    ███ ███████ ████████ ███████ ██████  ███████ 
  ;; ██   ██ ██   ██ ██   ██ ██   ██ ████  ████ ██         ██    ██      ██   ██ ██      
  ;; ██████  ███████ ██████  ███████ ██ ████ ██ █████      ██    █████   ██████  ███████ 
  ;; ██      ██   ██ ██   ██ ██   ██ ██  ██  ██ ██         ██    ██      ██   ██      ██ 
  ;; ██      ██   ██ ██   ██ ██   ██ ██      ██ ███████    ██    ███████ ██   ██ ███████ 

  ;;
  ;; GA Parameters
  (global $generationCount i32 (i32.const 20)) ;; generations to run for
  (global $arenaCount i32 (i32.const 3)) ;; individuals per arena - if you choose to adjust this upward, you may have to make selectionRandom larger to accomodate
  (global $crossoverThreshold i32 (i32.const 52428)) ;; default = 52428 = ~80%
  (global $mutationThreshold i32 (i32.const 655)) ;; default = 655 = ~1%
  ;;
  ;; Scenario Parameters
  (global $capacity i32 (i32.const 35)) ;; 35u max weight
  ;;

  ;; ██ ███    ██ ██ ████████ ██  █████  ██      ██ ███████ ███████ ██████  
  ;; ██ ████   ██ ██    ██    ██ ██   ██ ██      ██ ██      ██      ██   ██ 
  ;; ██ ██ ██  ██ ██    ██    ██ ███████ ██      ██ ███████ █████   ██   ██ 
  ;; ██ ██  ██ ██ ██    ██    ██ ██   ██ ██      ██      ██ ██      ██   ██ 
  ;; ██ ██   ████ ██    ██    ██ ██   ██ ███████ ██ ███████ ███████ ██████  

  (global $weights i32 (i32.const 0)) ;; *Weights
  ;; Weights (1 byte wide) [u8; 10]
  (data (i32.const 0) "\03") ;; 3
  (data (i32.const 1) "\08") ;; 8
  (data (i32.const 2) "\02") ;; 2
  (data (i32.const 3) "\09") ;; 9
  (data (i32.const 4) "\07") ;; 7
  (data (i32.const 5) "\01") ;; 1
  (data (i32.const 6) "\08") ;; 8
  (data (i32.const 7) "\0D") ;; 13
  (data (i32.const 8) "\0A") ;; 10
  (data (i32.const 9) "\09") ;; 9

  (global $values i32 (i32.const 10)) ;; *Values
  ;; Values (2 bytes wide) [u16; 10]
  ;; The bytes are little-endian, which confused me a bit
  (data (i32.const 10) "\7e\00") ;; 126
  (data (i32.const 12) "\9a\00") ;; 154
  (data (i32.const 14) "\00\01") ;; 256
  (data (i32.const 16) "\0e\02") ;; 526
  (data (i32.const 18) "\84\01") ;; 388
  (data (i32.const 20) "\f5\00") ;; 245
  (data (i32.const 22) "\d2\00") ;; 210
  (data (i32.const 24) "\ba\01") ;; 442
  (data (i32.const 26) "\9f\02") ;; 671
  (data (i32.const 28) "\5c\01") ;; 348

  ;; Printable strings
  (data (i32.const 30) ": ") ;; (2)
  (data (i32.const 32) "\n") ;; (1)
  (data (i32.const 33) "Max = ") ;; (6)
  (data (i32.const 39) "Mean = ") ;; (7)
  (data (i32.const 46) ", ") ;; (2)

  ;; ██    ██ ███    ██ ██ ████████ ██  █████  ██      ██ ███████ ███████ ██████  
  ;; ██    ██ ████   ██ ██    ██    ██ ██   ██ ██      ██ ██      ██      ██   ██ 
  ;; ██    ██ ██ ██  ██ ██    ██    ██ ███████ ██      ██ ███████ █████   ██   ██ 
  ;; ██    ██ ██  ██ ██ ██    ██    ██ ██   ██ ██      ██      ██ ██      ██   ██ 
  ;;  ██████  ██   ████ ██    ██    ██ ██   ██ ███████ ██ ███████ ███████ ██████  
  ;;
  ;; This section is filled programmatically.

  (global $writePtr i32 (i32.const 100)) ;; (4) *[]byte
  (global $writeLen i32 (i32.const 104)) ;; (4) int
  (global $writeRet i32 (i32.const 108)) ;; (4) int

  ;; Dirty area for $Itoa
  (global $itoaBuffer i32 (i32.const 116)) ;; (16)

  ;; Place where the current generation is stored
  (global $population i32 (i32.const 200)) ;; (800) [200][4]byte
  (global $populationCount i32 (i32.const 200)) ;; len(population)
  (global $populationSize i32 (i32.const 800)) ;; sizeof(population)
  (global $populationEnd i32 (i32.const 1000))

  ;; Place for the next generation to be written to
  ;; Is the same size as population, but only every other u16 is written to
  (global $next i32 (i32.const 1000)) ;; (400) [200]genome
  ;; Ends at 1400

  ;; Random generation segments - filled with random_get before each generation.
  ;; $arenaSize
  (global $randomSegment i32 (i32.const 1400)) ;; Explicit start of random segment
  (global $selectionRandom i32 (i32.const 1400)) ;; (1200) [200][6]byte
  (global $crossoverRandom i32 (i32.const 2600)) ;; (1200) [200][6]byte
  (global $mutationRandom i32 (i32.const 3800)) ;; (4000) [200][20]byte
  (global $randomSize i32 (i32.const 6400)) ;; Number of random bytes to fill in
  ;; Ends at 7800

  ;; ███    ███  █████  ██████ ███    ██ 
  ;; ████  ████ ██   ██   ██   ████   ██ 
  ;; ██ ████ ██ ███████   ██   ██ ██  ██ 
  ;; ██  ██  ██ ██   ██   ██   ██  ██ ██ 
  ;; ██      ██ ██   ██ ██████ ██   ████ 
  ;;
  ;; Pseudocode:
  ;; Fill Population with Random Data
  ;; Loop
  ;;   Fill Random Segment with Random Data
  ;;   i := 0
  ;;   Calculate the Population's fitnesses
  ;;   Print the fitness of the fittest member
  ;;   Loop
  ;;     Select Left Parent
  ;;     Select Right Parent
  ;;     Left, Right = Crossover(Left, Right)
  ;;     Mutate Left
  ;;     Mutate Right
  ;;     Next Generation <- Left, Right
  ;;     i += 2
  ;;     If i < Population Count Then Repeat
  ;;   End
  ;;   Copy Next Generation -> Population
  ;;   generation += 1
  ;;   If generation < Max Generations Then Repeat
  ;; End
  ;; Calculate fitnesses of the final generation
  ;; Print the fitness of the fittest member in the final generation


  (start $Main)
  (func $Main
    (local $fitness i32) ;; int
    (local $genome i32) ;; genome
    (local $i i32) ;; int
    (local $generation i32) ;; int
    (local $left i32) ;; genome
    (local $right i32) ;; genome

    ;; Initialise the population with random individuals
    ;; random_get(&population, sizeof(population))
    global.get $population
    global.get $populationSize
    call wasi_unstable::random_get
    if unreachable end

    (loop
      ;; Fill the random data segment
      global.get $randomSegment
      global.get $randomSize
      call wasi_unstable::random_get
      if unreachable end

      ;; i = 0
      i32.const 0
      local.set $i

      ;; Calculate the population's fitnesses
      local.get $generation
      call $CalculateFitnesses
      call $PrintGeneration

      (loop
        ;; Get the left parent
        ;; fitness, genome = Select(SelectionRandomAt(i))
        local.get $i
        call $SelectionRandomAt
        call $Select
        local.set $fitness
        local.set $genome

        ;; left = genome
        local.get $genome
        local.set $left

        ;; Get the right parent
        ;; fitness, genome = Select(SelectionRandomAt(i))
        local.get $i
        call $SelectionRandomAt
        call $Select
        local.set $fitness
        local.set $genome

        ;; right = genome
        local.get $genome
        local.set $right

        ;; left, right = Crossover(left, right, &crossoverRandom)
        local.get $left
        local.get $right
        local.get $i
        call $CrossoverRandomAt
        call $Crossover
        local.set $right
        local.set $left

        ;; left = Mutate(left)
        local.get $left
        local.get $i
        call $MutationRandomAt
        call $Mutate
        local.set $left

        ;; right = Mutate(right)
        local.get $right
        local.get $i
        i32.const 1
        i32.add
        call $MutationRandomAt
        call $Mutate
        local.set $right

        ;; next[i] = left
        local.get $i
        call $NextAt
        local.get $left
        i32.store16

        ;; next[i+1] = right
        local.get $i
        i32.const 1
        i32.add
        call $NextAt
        local.get $right
        i32.store16

        ;; if i += 2; i < populationCount { continue }
        local.get $i
        i32.const 2
        i32.add
        local.tee $i
        global.get $populationCount
        i32.lt_u
        br_if 0
      )

      ;; population = next
      global.get $population
      global.get $next
      global.get $populationSize
      memory.copy

      ;; if generation += 1; generation < generationCount { continue }
      local.get $generation
      i32.const 1
      i32.add
      local.tee $generation
      global.get $generationCount
      i32.lt_u
      br_if 0
    )

    ;; Final Generation Max Fitness
    ;; Calculate the population's fitnesses
    local.get $generation
    call $CalculateFitnesses
    call $PrintGeneration
  )

  ;; ██████ ███    ██ ██████  ███████ ██   ██ 
  ;;   ██   ████   ██ ██   ██ ██       ██ ██  
  ;;   ██   ██ ██  ██ ██   ██ █████     ███   
  ;;   ██   ██  ██ ██ ██   ██ ██       ██ ██  
  ;; ██████ ██   ████ ██████  ███████ ██   ██     
  ;;
  ;; I have debated whether or not it's worth changing my indexing functions
  ;; to be a single function like: Index(base, index, sizeof) *void
  ;; However, they make my main function slightly slimmer.                          

  ;; WeightAt(n int) *byte
  ;; Indexes into the weights, returning a pointer to the correct one
  (func $WeightAt (param $n i32) (result i32)
    ;; return (n << 1) + weights
    local.get $n
    global.get $weights
    i32.add
  )

  ;; ValueAt(n int) *u16
  ;; Indexes into the values, returning a pointer to the nth one
  (func $ValueAt (param $n i32) (result i32)
    ;; Use a n << 1 to multiply n by 2
    ;; return (n << 1) + values
    local.get $n
    i32.const 1
    i32.shl
    global.get $values
    i32.add
  )

  ;; SelectionRandomAt(n int) *[6]byte
  ;; Finds the nth *[6]byte segment of selectionRandom
  (func $SelectionRandomAt (param $n i32) (result i32)
    ;; return n * 6 + selectionRandom
    local.get $n ;; n
    i32.const 6 ;; 6 bytes long
    i32.mul
    global.get $selectionRandom
    i32.add
  )

  ;; CrossoverRandomAt(n int) *[6]byte
  ;; Finds the nth *[6]byte segment of crossoverRandom
  (func $CrossoverRandomAt (param $n i32) (result i32)
    ;; return n * 6 + crossoverRandom
    local.get $n
    i32.const 6
    i32.mul
    global.get $crossoverRandom
    i32.add
  )

  ;; MutationRandomAt(n int) *[10]byte
  ;; Finds the nth *[10]byte segment of mutationRandom
  (func $MutationRandomAt (param $n i32) (result i32)
    ;; return n * 10 + mutationRandom
    local.get $n
    i32.const 10
    i32.mul
    global.get $mutationRandom
    i32.add
  )

  ;; NextAt(idx int) (*u16, *u16)
  (func $NextAt (param $idx i32) (result i32)
    ;; ptr = next + (idx << 1)
    local.get $idx
    i32.const 1
    i32.shl
    global.get $next
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
  ;;
  ;; The population functions index and modify the current population in place,
  ;; as set by $population

  ;; CalculateFitnesses() int
  ;; Calculates the fitnesses for the population, modifying the individuals in place
  ;; Returns the fitness of the fittest indivdiual
  (func $CalculateFitnesses (result i32 i32)
    (local $ptr i32)
    (local $genome i32)
    (local $fitness i32)
    (local $fittest i32)
    (local $sumFitness i32)

    ;; ptr = &population
    global.get $population
    local.set $ptr

    (loop
      ;; genome = *ptr
      local.get $ptr
      i32.load16_u
      local.set $genome

      ;; fitness = Fitness(genome)
      local.get $genome
      call $Fitness
      local.tee $fitness
      ;; if fitness > max { max = fitness }
      local.get $fittest
      i32.gt_s
      if
        local.get $fitness
        local.set $fittest
      end

      ;; sumFitness = sumFitness + fitness
      local.get $sumFitness
      local.get $fitness
      i32.add
      local.set $sumFitness

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
      global.get $populationEnd
      i32.lt_u
      br_if 0
    )

    ;; return sumFitness / populationCount, fittest
    local.get $sumFitness
    global.get $populationCount
    i32.div_u
    local.get $fittest
  )

  ;; Select(random *[6]byte) *u16
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
      (block
        ;; if genome & (1 << col) { pass }
        i32.const 1
        local.get $col
        i32.shl
        local.get $genome
        i32.and
        br_if 0

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
      )

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

  ;; Crossover(left, right u16, random *[6]byte)
  ;; Cross over two genomes
  ;; Consumes random as [u16, u32]
  ;; u16 -> crossover chance
  ;; u32 -> crossing point
  ;; Transforms parents (left, right) into (alpha, beta)
  (func $Crossover (param $left i32) (param $right i32) (param $random i32) (result i32 i32)
    (local $crossingPoint i32)
    (local $prefix i32)
    (local $suffix i32)
    (local $alpha i32)
    (local $beta i32)

    ;; Short circuit if no crossing is happening
    ;; Equivalent to !(*random < crossoverThreshold)
    ;; if *random >= crossoverThreshold { return left, right }
    local.get $random
    i32.load16_u
    global.get $crossoverThreshold
    i32.ge_u
    if
      local.get $left
      local.get $right
      return
    end

    ;; Choose a crossing point
    ;; crossingPoint = *(random+2) % 10
    local.get $random
    i32.const 2
    i32.add
    i32.load
    i32.const 10
    i32.rem_u
    local.set $crossingPoint

    ;; Generate the suffix mask first
    ;; suffix = (1 << crossingPoint) - 1
    i32.const 1
    local.get $crossingPoint
    i32.shl
    i32.const 1
    i32.sub
    local.set $suffix

    ;; Generate the prefix mask using the suffix mask
    ;; prefix = -1 ^ suffix
    i32.const -1
    local.get $suffix
    i32.xor
    local.set $prefix

    ;; Cross over [left :: right] to make alpha
    ;; alpha = (prefix & left) | (suffix & right)
    local.get $prefix
    local.get $left
    i32.and
    local.get $suffix
    local.get $right
    i32.and
    i32.or
    local.set $alpha

    ;; Cross over [right :: left] to make beta
    local.get $prefix
    local.get $right
    i32.and
    local.get $suffix
    local.get $left
    i32.and
    i32.or
    local.set $beta

    ;; return alpha, beta
    local.get $alpha
    local.get $beta
    return
  )


  ;; Mutate(genome u16, random *[20]byte) u16
  ;; Returns a mutated version of a given genome, consuming 20 bytes (10 u16s)
  ;; from the random pointer.
  (func $Mutate (param $genome i32) (param $random i32) (result i32)
    (local $col i32)

    (loop
      (block

        ;; If mutationThreshold isn't reached, short-circuit to the logic at the end of the loop
        ;; if *(random + (col << 1)) >= mutationThreshold { pass }
        local.get $col
        i32.const 1
        i32.shl
        local.get $random
        i32.add
        i32.load16_u
        global.get $mutationThreshold
        i32.ge_u
        br_if 0

        ;; Generate a mask and flip
        ;; 1 << col
        i32.const 1
        local.get $col
        i32.shl
        local.get $genome
        i32.xor
        local.set $genome
      )

      ;; if col += 1; col < 10 { continue }
      local.get $col
      i32.const 1
      i32.add
      local.tee $col
      i32.const 10
      i32.lt_u
      br_if 0
    )

    local.get $genome
  )


  ;; ██████     ██  ██████  
  ;;   ██      ██  ██    ██ 
  ;;   ██     ██   ██    ██ 
  ;;   ██    ██    ██    ██ 
  ;; ██████ ██      ██████  

  ;; PrintGeneration(number, mean, fittest int)
  ;; print(`${number} : ${fittest}\n`)
  (func $PrintGeneration (param $number i32) (param $mean i32) (param $fittest i32)
    ;; if Write(1, ...Itoa(number, *itoaBuffer)) != nil: throw
    i32.const 1
    (call $Itoa (local.get $number))
    call $Write
    if unreachable end

    ;; if Write(1, *": ", 2) != nil: throw
    (call $Write (i32.const 1) (i32.const 30) (i32.const 2))
    if unreachable end

    ;;

    ;; if Write(1, *"Mean = ", 7) != nil: throw
    (call $Write (i32.const 1) (i32.const 39) (i32.const 7))
    if unreachable end

    ;; if Write(1, ...Itoa(number, *itoaBuffer)) != nil: throw
    i32.const 1
    (call $Itoa (local.get $mean))
    call $Write
    if unreachable end

    ;; if Write(1, *", ", 2) != nil: throw
    (call $Write (i32.const 1) (i32.const 46) (i32.const 2))
    if unreachable end

    ;;

    ;; if Write(1, *"Max = ", 6) != nil: throw
    (call $Write (i32.const 1) (i32.const 33) (i32.const 6))
    if unreachable end

    ;; if Write(1, ...Itoa(number, *itoaBuffer)) != nil: throw
    i32.const 1
    (call $Itoa (local.get $fittest))
    call $Write
    if unreachable end

    ;;

    ;; if Write(1, *"\n", 1) != nil: throw
    (call $Write (i32.const 1) (i32.const 32) (i32.const 1))
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
        (local.get $descriptor) ;; Stdout
        (global.get $writePtr) ;; *[]IOVec
        (i32.const 1) ;; IOVec count
        (global.get $writeRet) ;; *nwritten
      ) ;; returns error

      (local.tee $err)
      if (return (local.get $err)) end

      ;; Return error if nwritten is 0
      (i32.eqz (local.tee $nwritten (i32.load (global.get $writeRet))))
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

  ;; Itoa(number int) (*[]byte, int)
  ;; Uses the dirty buffer provided in BSS, returning a pointer into it which
  ;; must be used to print the number before a new number can be converted
  ;; you'd want a version of this which takes itoaBuffer as a parameter instead
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