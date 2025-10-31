# Knapsack Documentation

## Parameters

You can adjust several characteristics about the genetic algorithm to see how they affect finding the solution and solution convergence:
- `$generationCount` - Total run time of the program. If you're failing to find a solution consistently, try upping this until you do, so you can see how the other factors are impacting performance. Default is 20.
- `$arenaCount` - Number of individuals per tournament. Larger number causes your GA to converge on a solution faster. Default is 3.
- `$crossoverThreshold` - Chance out of 65536 of crossover occurring. Default is 52428 (80%).
- `$mutationThreshold` - Chance out of 65536 of each bit in a genome mutating. Default is 655 (1%).

These values are stored in global constants found in lines `57`-`60`.

## Linear Memory

Here is a not-entirely-to-scale diagram of the contents of Knapsack's linear memory:

![Only a tiny portion of the memory is initialised](memory.svg)

The intialised portion is hardcoded, and is filled when the program is first loaded.
It contains the scenario data, and the strings needed to output valid CSV.

Starting at `200` is the uninitialised portion, which is filled as the program runs.
1. A small set of buffers used by `$Print` and `$Itoa`.
2. `population` - the current individuals and their fitnesses.
3. `next` - space for the next generation to be stored.
4. `selectionRandom` - random numbers used to decide which individuals are selected for the tournaments.
5. `crossoverRandom` - random numbers used to decide whether or not crossing over occurs, and at what point.
6. `mutationRandom` - random numbers used to decide which bits to flip during mutation.

At the beginning of the program, `population` is filled with random bytes, generating the intial population.
Each generation, `selectionRandom`, `crossoverRandom`, and `mutationRandom` are filled with random bytes, providing the randomness for that generation.

## Style Guide

- Variables are `snakeCase`.
- Functions are `CamelCase`.
- Use assembly-style expressions over S-expressions.
- Document functions using Go-style method signatures.

## `$Main`

To begin to explain how the program actually works, I think it's important to go over the broad strokes of how the main loop operates.

1. To begin with, the `population` is filled with random individuals.
2. The CSV header is emitted.
3. `for generation := range maxGenerations`.
    1. First, the random segment - `selectionRandom`, `crossoverRandom`, and `mutationRandom` is filled with random bytes.
    2. Next, we calculate the fitnesses of the current generation using `$CalculateFitnesses`
    3. Now, we loop over the population: `for i := range population`
        1. Use `SelectionRandomAt` to index into 