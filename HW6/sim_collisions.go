package main

import (
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go <n_trials>")
		return
	}

	nTrials, err := strconv.Atoi(os.Args[1])
	if err != nil {
		fmt.Println("Invalid number of trials")
		return
	}

	// rand seed
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	// histogram of collision locations
	var counts [32]int
	sum := 0

	start := time.Now()

	// run nTrials simulations, add max collision count to sum
	for i := 0; i < nTrials; i++ {
		counts = [32]int{}

		for j := 0; j < 32; j++ {
			val := r.Intn(32) // [0,32)
			counts[val]++
		}

		maxCol := 0
		for j := 0; j < 32; j++ {
			if counts[j] > maxCol {
				maxCol = counts[j]
			}
		}

		sum += maxCol
	}

	duration := time.Since(start)
	average := float64(sum) / float64(nTrials)

	fmt.Printf("Sequential: Simulated %d trials in %v\n", nTrials, duration)
	fmt.Printf("Expected Max Collision Penalty: %.4f\n", average)
}
