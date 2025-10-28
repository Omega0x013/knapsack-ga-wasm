# knapsack-ga-wasm
> Genetic algorithm solving the knapsack problem, written in WebAssembly Text Format.

## Run it Yourself

This program was run and tested using [`wasmtime`](https://github.com/bytecodealliance/wasmtime) v38. To run it, clone the repo and run this command in the base directory:

```
wasmtime knapsack.wat
```

## Understanding Program Output

Knapsack outputs its results to the terminal (via `STDOUT`), here is an sample:

```txt
0: Mean = 642, Max = 2172
1: Mean = 854, Max = 2172
2: Mean = 924, Max = 2172
3: Mean = 934, Max = 2046
4: Mean = 966, Max = 2034
```

Each line starts with the generation count - how many rounds of selection, crossover, and mutation the population has been through. This number starts at 0, representing the stats of the original randomly generated population. Then, two results are shown:
- The `Mean` is the mean fitness of the population. Some individuals' fitnesses are 0, because they are an invalid solution, bringing the average down.
- The `Max` is the fitness of the fittest individual in the population. Previous iterations of this same algorithm and dataset have proven that `2212` is the fitness of the optimum solution.

## Documentation

[docs/README.md](docs/README.md)
