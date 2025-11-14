#!/bin/bash
# Script to test henon with different n_blocks values
# Fixed parameters: threads_per_block=1024, n_iter=1000000, n_trials=5, elem_size=4

# Output files
OUTPUT_FILE="henon_results.txt"
LATEX_FILE="henon_results.tex"

# Fixed parameters
THREADS_PER_BLOCK=1024
N_ITER=1000000
N_TRIALS=5
ELEM_SIZE=4

# Clear previous results
> $OUTPUT_FILE
> $LATEX_FILE

# Print header
echo "Testing henon with varying n_blocks (steps of 10)"
echo "threads_per_block=$THREADS_PER_BLOCK, n_iter=$N_ITER, n_trials=$N_TRIALS, elem_size=$ELEM_SIZE"
echo ""

# Start LaTeX table
cat > $LATEX_FILE << 'EOF'
\begin{table}[h]
\centering
\begin{tabular}{|r|r|r|r|}
\hline
n\_blocks & n\_data & Mean Time (s) & GFLOPS \\
\hline
EOF

# Variables to track best result
MAX_GFLOPS=0
BEST_N_BLOCKS=0
BEST_TIME=0

# Loop through n_blocks values: 10, 20, 30, ..., 500
for n_blocks in $(seq 10 10 500); do
    echo "Testing n_blocks=$n_blocks..."
    
    # Run henon and capture output
    output=$(./henon $n_blocks $THREADS_PER_BLOCK $N_ITER $N_TRIALS $ELEM_SIZE 2>&1)
    
    # Extract mean time from output
    # Looking for line like: "GPU, n_blocks=100, tpb=1024, n_iter=1000000, single-precision, time elapsed: mean = 1.234e-01, stdev = 5.678e-03"
    mean_time=$(echo "$output" | grep "time elapsed: mean" | sed -n 's/.*mean = \([^,]*\).*/\1/p')
    
    if [ -z "$mean_time" ]; then
        echo "  ERROR: Could not extract mean time from output"
        echo "  Output was: $output"
        continue
    fi
    
    # Calculate total number of data points
    n_data=$((n_blocks * THREADS_PER_BLOCK))
    
    # Calculate FLOPS
    # Per iteration per point: 
    #   x_next: 2 mult (a*x*x), 1 add (+ y) = 3 ops
    #   y_next: 1 mult (b*x) = 1 op
    #   dx: 1 sub = 1 op
    #   dy: 1 sub = 1 op
    #   d2: 2 mult (dx*dx, dy*dy), 1 add = 3 ops
    #   sum_d2: 1 add = 1 op
    #   sum_d4: 1 mult (d2*d2), 1 add = 2 ops
    # Total: ~12 FLOPs per iteration per point
    flops_per_iter=12
    total_flops=$((n_data * N_ITER * flops_per_iter))
    
    # Convert to GFLOPS (using bc for floating point)
    gflops=$(echo "scale=3; $total_flops / ($mean_time * 1000000000)" | bc)
    
    # Check if under 0.5s
    under_half=$(echo "$mean_time < 0.5" | bc)
    if [ "$under_half" -eq 1 ]; then
        under_str="Yes"
        # Check if this is the best GFLOPS so far
        is_better=$(echo "$gflops > $MAX_GFLOPS" | bc)
        if [ "$is_better" -eq 1 ]; then
            MAX_GFLOPS=$gflops
            BEST_N_BLOCKS=$n_blocks
            BEST_TIME=$mean_time
        fi
    else
        under_str="No"
    fi
    
    # Print to terminal
    printf "  n_blocks=%3d, n_data=%7d, time=%10.6f s, GFLOPS=%8.2f, under_0.5s=%s\n" \
           $n_blocks $n_data $mean_time $gflops $under_str
    
    # Append to text file
    printf "%3d %7d %10.6f %8.2f %s\n" \
           $n_blocks $n_data $mean_time $gflops $under_str >> $OUTPUT_FILE
    
    # Append to LaTeX file
    printf "%d & %d & %.6f & %.2f \\\\\\\\\\n" \
           $n_blocks $n_data $mean_time $gflops >> $LATEX_FILE
done

# Close LaTeX table with caption showing max result
cat >> $LATEX_FILE << EOF
\hline
\end{tabular}
\caption{Henon GPU performance with varying n\_blocks (threads\_per\_block=1024, n\_iter=1000000). Maximum GFLOPS ($MAX_GFLOPS) achieved with n\_blocks=$BEST_N_BLOCKS.}
\label{tab:henon_nblocks}
\end{table}

% Example GFLOPS calculation for n_blocks=$BEST_N_BLOCKS:
% n_data = $BEST_N_BLOCKS × 1024 = $(($BEST_N_BLOCKS * 1024))
% FLOPs per iteration per point = 12
% Total FLOPs = $(($BEST_N_BLOCKS * 1024)) × 1,000,000 × 12 = $(($BEST_N_BLOCKS * 1024 * 1000000 * 12))
% GFLOPS = Total FLOPs / (time × 10^9) = $(($BEST_N_BLOCKS * 1024 * 1000000 * 12)) / ($BEST_TIME × 10^9) ≈ $MAX_GFLOPS
EOF

echo ""
echo "================================"
echo "Results saved to:"
echo "  - $OUTPUT_FILE (plain text)"
echo "  - $LATEX_FILE (LaTeX table)"
echo ""
echo "Best result (under 0.5s):"
echo "  n_blocks = $BEST_N_BLOCKS"
echo "  time = $BEST_TIME s"
echo "  GFLOPS = $MAX_GFLOPS"
echo ""
echo "Example GFLOPS calculation:"
echo "  n_data = $BEST_N_BLOCKS × 1024 = $(($BEST_N_BLOCKS * 1024))"
echo "  Total FLOPs = $(($BEST_N_BLOCKS * 1024)) × 1,000,000 × 12 = $(($BEST_N_BLOCKS * 1024 * 1000000 * 12))"
echo "  GFLOPS = Total FLOPs / (time × 10^9)"
echo "  GFLOPS = $(($BEST_N_BLOCKS * 1024 * 1000000 * 12)) / ($BEST_TIME × 10^9) ≈ $MAX_GFLOPS"
echo "================================"
