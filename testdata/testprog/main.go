package main

import (
	"flag"
	"fmt"
	"os"
	"runtime/trace"
	"time"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	flag.Parse()

	switch args := flag.Args(); len(args) {
	case 1:
		return generateTrace(args[0])
	default:
		return fmt.Errorf("expected 1 argument, but args=%v", args)
	}
}

func generateTrace(path string) error {
	// Create a goroutine before the trace is started and wait for it to start
	// blocking. TODO: Await the race condition of sleep wait.
	go blockForever()
	time.Sleep(100 * time.Millisecond)

	// Create the file to write the trace to.
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write the trace to the file.
	if err := trace.Start(file); err != nil {
		return fmt.Errorf("failed to start trace: %v", err)
	}
	defer trace.Stop()

	// Create scheduling events to trace.
	runSleep()
	chanUnblock()

	return nil
}

func blockForever() {
	select {}
}

func chanUnblock() {
	ch := make(chan struct{})
	go func() {
		time.Sleep(10 * time.Millisecond)
		ch <- struct{}{}
	}()
	<-ch
}

func runSleep() {
	for i := 0; i < 100; i++ {
		cpuHog(time.Duration(i) * time.Millisecond)
		time.Sleep(time.Duration(i) * time.Millisecond)
	}
}

func cpuHog(d time.Duration) {
	start := time.Now()
	for time.Since(start) < d {
	}
}
