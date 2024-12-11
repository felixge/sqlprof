package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"runtime"
	"runtime/pprof"
	"time"

	"github.com/felixge/sqlprof/internal/profile"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run() (err error) {
	var (
		cpuProfile = flag.String("cpuprofile", runtime.Version()+".cpu.pprof", "write cpu profile to file")
		memProfile = flag.String("memprofile", runtime.Version()+".mem.pprof", "write memory profile to file")
		traceFile  = flag.String("trace", runtime.Version()+".trace", "write trace to file")
	)
	flag.Parse()

	// Create a goroutine before the trace is started and wait for it to start
	// blocking. TODO: Await the race condition of sleep wait.
	go blockForever()
	time.Sleep(100 * time.Millisecond)

	// Start the CPU profile
	var stopCPUProfile func() error
	stopCPUProfile, err = profile.StartCPUProfile(*cpuProfile)
	defer func() { err = errors.Join(err, stopCPUProfile()) }()

	// Start the memory profile
	stopMemProfile := profile.StartMemProfile(*memProfile)
	defer func() { err = errors.Join(err, stopMemProfile()) }()

	// Start the trace
	var stopTrace func() error
	stopTrace, err = profile.StartTrace(*traceFile)
	defer func() { err = errors.Join(err, stopTrace()) }()

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
	labels := pprof.Labels("func", "cpuHog", "duration", d.String())
	pprof.Do(context.Background(), labels, func(_ context.Context) {
		start := time.Now()
		for time.Since(start) < d {
		}
	})
}
