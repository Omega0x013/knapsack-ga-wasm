# knapsack-ga-wasm
> Genetic algorithm solving the knapsack problem, written in WebAssembly Text Format.

In the knapsack problem, you are headed out to sell some items and you must choose which of the items to take with you. Each is worth a certain amount, and weighs a certain amount. You can only carry so much weight. Your goal is to choose the combination of items that is worth the most, but which you can still carry.

In this scenario, there are 10 items to choose from, with values ranging from £126 to £671, and with weights ranging from 1kg to 13kg. You can carry 35kg in your knapsack. This program, Knapsack, solves this problem using a genetic algorithm, which mimics the natural processes of selection, crossover, and mutation to search the solution space.

Knapsack is a reimplementation of the genetic algorithm I wrote for a university assignment, originally written in JavaScript. I've also rewritten it in Julia, which can be found here: [`truck.jl`](https://gist.github.com/Omega0x013/97b606ff5a12656814027121f62da457)

## Run it Yourself

This program was run and tested using [`wasmtime`](https://github.com/bytecodealliance/wasmtime) v38. To run it, clone the repo and run this command in the base directory:

```
wasmtime knapsack.wat
```

## Understanding Program Output

Knapsack outputs its results to the terminal (via `STDOUT`) in CSV format, which looks something like this:

```txt
generation,mean,max
0,588,1984
1,686,1984
2,751,1984
3,920,1967
4,983,2034
```

The data has three columns:
- `generation` is the number of rounds of selection, crossover, and mutation the population has been through at this point. Notably, it starts at 0, showing the mean and max for the initial population.
- `mean` is the mean fitness score of the whole population. An individual that is an invalid solution has a fitness score of 0, reducing the average.
- `fitness` is the fitness of the fittest member of the population. Previous versions of this same algorithm in other languages have shown that `2212` is the fitness of the optimal solution for this dataset.

You can plot this data on a chart to see how the neural network is performing by piping the output into a CSV file:

```
wasmtime knapsack.wat > results.csv
```

and importing it into a spreadsheet program (like Excel or Google Sheets), which can produce charts like this:

![Chart showing both mean and max fitness only marginally increasing.](docs/Mean%20and%20Max%20Fitness%20by%20Generation.svg)

This chart highlights a flaw in this genetic algorithm - the maximum fitness can sometimes go down.
This is caused by the fittest member(s) of the population being regularly crossed over or mutated so that they are a worse (or invalid) solution.
This can be mitigated using [elitism](https://en.wikipedia.org/wiki/Selection_(evolutionary_algorithm)#Elitist_selection), which retains the fittest individuals for the next generation.

## Documentation

To delve more into how this program works, take a look at the proper documentation: [`docs/README.md`](docs/README.md)
