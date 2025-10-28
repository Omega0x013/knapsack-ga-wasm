<!-- Cut and pasted from its previous source -->

## Docs: Program Parameters

You can adjust several characteristics about the genetic algorithm to see how they affect finding the solution and solution convergence:
- `$generationCount` - Total run time of the program. If you're failing to find a solution consistently, try upping this until you do, so you can see how the other factors are impacting performance. Default is 20.
- `$arenaCount` - Number of individuals per tournament. Larger number causes your GA to converge on a solution faster. Default is 3.
- `$crossoverThreshold` - Chance out of 65536 of crossover occurring. Default is 52428 (80%).
- `$mutationThreshold` - Chance out of 65536 of each bit in a genome mutating. Default is 655 (1%).
For crossing over and mutation rates, higher values tend to lead to slower convergence.
You can find these variables on lines 57-60 of [`knapsack.wat`](knapsack.wat).
Fiddle with the values and then run the program again.

## Docs: Memory Usage

Here is a not-entirely-to-scale diagram of the contents of my program's linear memory:

![Only a tiny portion of the memory is initialised](docs/memory.svg)

The intialised portion is hardcoded, and is filled when the program is first loaded.
It contains the scenario data and the printable strings `: ` and `\n`.
It only contains 33 bytes of data, but has 100 bytes of space in case I need to add more.

The uninitialised portion is filled programmatically.
1. The section in contains buffers for the I/O functions.
2. `population` is a massive array containing pairs of genomes and fitnesses.
3. `next` has the same structure as `population`, except that its fitnesses are never filled.

At the beginning of the program, `population` is filled with random numbers,
seeding the individuals for the first generation.
The segment indicated by the dashed line is called `randomSegment`.
It contains three arrays used to make random decisions throughout the program.
To reduce overheads, these three arrays are filled all at once with a single call to `wasi_unstable::random_get`.

4. `selectionRandom` is used in three `u16`s to select the individuals in each tournament.
5. `crossoverRandom` is used in two parts:
    1. A `u16` to decide whether or not crossing over will occur.
    2. A `u32` to fairly decide the crossing point.
6. `mutationRandom` is used as 10 `u16`s to decide whether or not to flip each of the 10 bits in a genome.
