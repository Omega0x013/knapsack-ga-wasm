# knapsack-ga-wasm
> Genetic algorithm solving the knapsack problem, written in WebAssembly Text Format.

**Try it out here: [https://omega0x013.github.io/knapsack-ga-wasm](https://omega0x013.github.io/knapsack-ga-wasm)**

In the knapsack problem, you are headed out to sell some items and you must choose which of the items to take with you. Each is worth a certain amount, and weighs a certain amount. You can only carry so much weight. Your goal is to choose the combination of items that is worth the most, but which you can still carry.

In this scenario, there are 10 items to choose from, with values ranging from £126 to £671, and with weights ranging from 1kg to 13kg. You can carry 35kg in your knapsack. This program, Knapsack, tries to find the ideal solution using a genetic algorithm, which mimics the natural processes of selection, crossover, and mutation.

Knapsack is a reimplementation of the genetic algorithm I wrote for a university assignment, originally written in JavaScript. I've also rewritten it in Julia, which can be found here: [`truck.jl`](https://gist.github.com/Omega0x013/97b606ff5a12656814027121f62da457)

## Repo Structure

This repository contains both source code (`knapsack.wat` and `src/`) and compiled output (`docs/`). This repository is deployed with GitHub Pages, using `docs/` as its source.

