
# Notes

## Editing-distance explanation

The "editing-distance problem" in computer science is a way to measure how dissimilar two strings of text are from one another. The "distance" is defined as the minimum number of single-character edits required to change one string into the other.

This concept is most famously implemented as the Levenshtein distance.

🎯 The Goal

The core of the problem is to find the smallest number of operations to transform a source string into a target string.

For example, the edit distance between "kitten" and "sitting" is 3. Here is one of the optimal edit sequences:

    kitten → sitten (substitute "k" with "s")

    sitten → sittin (substitute "e" with "i")

    sittin → sitting (insert "g")

⚙️ The Edit Operations

The problem is almost always defined using three basic, "unit-cost" operations (where each operation counts as 1 "point" of distance):

    Insertion: Adding a character to a string.

        Example: "cat" → "cats" (1 insertion)

    Deletion: Removing a character from a string.

        Example: "boat" → "bot" (1 deletion)

    Substitution: Replacing one character with another.

        Example: "book" → "look" (1 substitution)

## Testing/Timing

```erlang
eunit:test(hw5). % runs entire testing suite within hw5
hw5_timing:ed_timing_suite_tilesize(). % timing measurements based on tile sizes
```

```shell
13> hw5_timing:ed_timing_suite_tilesize(). % timing measurements based on tile sizes

=== Testing with 5000 char strings, varied tilewidth ===

=== Test 0: BENCHMARK (SEQUENTIAL) ===
Sequential (n=10): mean = 4.058337 s, std = 0.761914 s

=== Test 1: Tile Width 2 ===
Workers (NW): 2500
Parallel: mean = 1.075795 s, std = 0.044341 s
Speedup: 3.77x

=== Test 2: Tile Width 5 ===
Workers (NW): 1000
Parallel: mean = 0.352421 s, std = 0.016580 s
Speedup: 11.52x

=== Test 3: Tile Width 10 ===
Workers (NW): 500
Parallel: mean = 0.192560 s, std = 0.005881 s
Speedup: 21.08x

=== Test 4: Tile Width 20 ===
Workers (NW): 250
Parallel: mean = 0.125761 s, std = 0.006537 s
Speedup: 32.27x

=== Test 5: Tile Width 40 ===
Workers (NW): 125
Parallel: mean = 0.110200 s, std = 0.003502 s
Speedup: 36.83x

=== Test 6: Tile Width 80 ===
Workers (NW): 63
Parallel: mean = 0.160911 s, std = 0.006686 s
Speedup: 25.22x

=== Test 7: Tile Width 160 ===
Workers (NW): 32
Parallel: mean = 0.291928 s, std = 0.013815 s
Speedup: 13.90x

=== Test 8: Tile Width 250 ===
Workers (NW): 20
Parallel: mean = 0.440605 s, std = 0.035544 s
Speedup: 9.21x

=== Test 9: Tile Width 500 ===
Workers (NW): 10
Parallel: mean = 0.837445 s, std = 0.053051 s
Speedup: 4.85x

=== Test 10: Tile Width 1000 ===
Workers (NW): 5
Parallel: mean = 1.354837 s, std = 0.132503 s
Speedup: 3.00x

=== Test 11: Tile Width 2500 ===
Workers (NW): 2
Parallel: mean = 3.161660 s, std = 0.399689 s
Speedup: 1.28x

=== Timing suite complete ===
```

## Question 2.b - Parallel Implementation Explanation

**Parallel Edit Distance Implementation:**

This implementation divides the edit distance dynamic programming tableau into rectangular tiles and processes them using a chain of worker processes. The tableau is partitioned horizontally into rows of tiles, where each row has a height of `TileHeight` and each tile within a row has a width of `TileWidth`. The chain length is determined by the number of tile rows needed to cover string S1, with a maximum of `NW` workers.

The key insight (as provided by the hint), is that tiles overlap at their boundaries: the right column of one tile becomes the left column of its right neighbor, and the bottom row of one tile becomes the top row of the tile below it. The `segment_list/2` helper function creates these overlapping segments from the input strings. Each worker in the chain is responsible for computing one horizontal row of tiles. Workers use the `hw5_lib:ed_tile/3` function to compute individual tiles, receiving their top row from the previous worker in the chain and sending their bottom row to the next worker. This creates a pipeline where each worker processes tiles from left to right across its assigned row while coordinating with adjacent workers through message passing.

The master process initializes the chain with operation costs and left column segments, then feeds the top row segments (representing string S2) one at a time to the first worker. Each segment propagates through the chain as workers compute their respective tiles. The final edit distance is extracted from the last element of the bottom row produced by the final worker after processing the last tile column. This approach achieves parallelism while amortizing communication costs through tile-based computation, as each worker performs `TileHeight × TileWidth` operations between communications.

### henon cpu timings

webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 10000 5 4
CPU: rms-step-size = 1.698, var = 2.663
CPU: n_data= 10000, n_iter=   10000, t_elapsed=      0.3125
GPU: rms-step-size = 1.698, var = 2.662
GPU, n_blocks=100, tpb= 100, n_iter=   10000, single-precision, time elapsed: mean =      8.8e-06, stdev =    1.397e-05
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 10000 5 4
CPU: rms-step-size = 1.698, var = 2.663
CPU: n_data= 10000, n_iter=   10000, t_elapsed=      0.3079
GPU: rms-step-size = 1.698, var = 2.662
GPU, n_blocks=100, tpb= 100, n_iter=   10000, single-precision, time elapsed: mean =    0.0001384, stdev =    0.0001019
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 10000 5 4
CPU: rms-step-size = 1.698, var = 2.663
CPU: n_data= 10000, n_iter=   10000, t_elapsed=      0.3109
GPU: rms-step-size = 1.698, var = 2.662
GPU, n_blocks=100, tpb= 100, n_iter=   10000, single-precision, time elapsed: mean =     0.000182, stdev =    7.575e-05
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 10000 5 4
CPU: rms-step-size = 1.698, var = 2.663
CPU: n_data= 10000, n_iter=   10000, t_elapsed=      0.3117
GPU: rms-step-size = 1.698, var = 2.662
GPU, n_blocks=100, tpb= 100, n_iter=   10000, single-precision, time elapsed: mean =    0.0001792, stdev =    7.335e-05
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 10000 5 4
CPU: rms-step-size = 1.698, var = 2.663
CPU: n_data= 10000, n_iter=   10000, t_elapsed=      0.3071
GPU: rms-step-size = 1.698, var = 2.662
GPU, n_blocks=100, tpb= 100, n_iter=   10000, single-precision, time elapsed: mean =     0.000138, stdev =    0.0001016

### henon gpu timings

webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 1000000 5 4
GPU: rms-step-size = 1.699, var = 2.663
GPU, n_blocks=100, tpb= 100, n_iter= 1000000, single-precision, time elapsed: mean =      0.02039, stdev =    0.0001755
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 1000000 5 4
GPU: rms-step-size = 1.699, var = 2.663
GPU, n_blocks=100, tpb= 100, n_iter= 1000000, single-precision, time elapsed: mean =      0.02045, stdev =    0.0001237
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 1000000 5 4
GPU: rms-step-size = 1.699, var = 2.663
GPU, n_blocks=100, tpb= 100, n_iter= 1000000, single-precision, time elapsed: mean =      0.02034, stdev =     0.000199
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 1000000 5 4
GPU: rms-step-size = 1.699, var = 2.663
GPU, n_blocks=100, tpb= 100, n_iter= 1000000, single-precision, time elapsed: mean =      0.01896, stdev =    7.089e-05
webb47@lin15:~/cs-418/HW5/src$ ./henon 100 100 1000000 5 4
GPU: rms-step-size = 1.699, var = 2.663
GPU, n_blocks=100, tpb= 100, n_iter= 1000000, single-precision, time elapsed: mean =      0.02045, stdev =    0.0002099
