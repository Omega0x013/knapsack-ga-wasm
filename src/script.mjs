const GENERATIONS = 50; // rounds of selection, crossover, and mutation
const ARENA_SIZE = 3; // individuals per arena
const CROSSOVER_THRESHOLD = 52428; // 52428 / 65535 = ~80%
const MUTATION_THRESHOLD = 655; // 666 / 65535 = ~1%

const chartCanvas = document.querySelector('canvas');

// Data sets and labels for the chart
const data = {
  labels: [...Array.from({ length: GENERATIONS + 1 }).keys()],
  datasets: [
    {
      label: 'Mean',
      data: [],
      borderColor: "#ff0000",
    },
    {
      label: 'Max',
      data: [],
      borderColor: "#0000ff",
    }
  ]
};

// Chart config
const config = {
  type: 'line',
  data: data,
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: 'Knapsack Fitness by Generation'
      }
    }
  },
};

// Use hoisting to gather functions
const imports = {
  knapsack: {
    random_get,
    ARENA_SIZE,
    CROSSOVER_THRESHOLD,
    MUTATION_THRESHOLD
  }
}

// Instantiate the WebAssembly module
const { instance } = await WebAssembly.instantiateStreaming(fetch(import.meta.resolve("./knapsack.wasm")), imports);

// Extract exports
const wasmMemory = new Uint8Array(instance.exports.memory.buffer);
const { Generation, CalculateFitnesses, randomSegment, randomSize, population, populationSize } = instance.exports;

/**
 * Fill a specified buffer with random data
 * @param {number} ptr Start of random array
 * @param {number} len Length or random array
 * @returns {int} Error code
 */
function random_get(ptr, len) {
  try {
    const targetArray = wasmMemory.subarray(ptr, ptr + len);
    window.crypto.getRandomValues(targetArray);
    return 0;
  } catch {
    return 1;
  }
}

// Intialise the first population
random_get(population, populationSize)

// Calculate their fitnesses
let [mean, max] = CalculateFitnesses();

const chart = new Chart(chartCanvas, config);

chart.data.datasets[0].data.push(mean);
chart.data.datasets[1].data.push(max);

chart.update();

// Run GENERATIONS generations
for (let generation = 1; generation <= GENERATIONS; generation++) {
  // Select, cross over, and mutate a new generation
  Generation();

  // Calculate their fitnesses
  [mean, max] = CalculateFitnesses();

  chart.data.datasets[0].data.push(mean);
  chart.data.datasets[1].data.push(max);

  chart.update();
}

console.log(chart.data.datasets[0])
