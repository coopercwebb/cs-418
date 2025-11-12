
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
