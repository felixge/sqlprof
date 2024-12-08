package profile

import (
	"errors"
	"os"
	"runtime"
	"runtime/pprof"
	"runtime/trace"
)

func StartCPUProfile(path string) (stop func() error, err error) {
	// Default to a no-op stop function and return early if no path is provided.
	stop = func() error { return nil }
	if path == "" {
		return
	}

	// Create the file to write the profile to.
	var f *os.File
	if f, err = os.Create(path); err != nil {
		return
	}

	// Start the CPU profile or return the error and close the file.
	if err = pprof.StartCPUProfile(f); err != nil {
		return nil, errors.Join(err, f.Close())
	}

	// Return a function that stops the CPU profile and closes the file.
	stop = func() error {
		pprof.StopCPUProfile()
		return f.Close()
	}
	return
}

func StartTrace(path string) (stop func() error, err error) {
	// Default to a no-op stop function and return early if no path is provided.
	stop = func() error { return nil }
	if path == "" {
		return
	}

	// Create the file to write the trace to.
	var f *os.File
	if f, err = os.Create(path); err != nil {
		return
	}

	// Start the trace or return the error and close the file.
	if err = trace.Start(f); err != nil {
		return nil, errors.Join(err, f.Close())
	}

	// Return a function that stops the trace and closes the file.
	stop = func() error {
		trace.Stop()
		return f.Close()
	}
	return
}

func StartMemProfile(path string) func() error {
	return func() error {
		// Do nothing and return early if no path is provided.
		if path == "" {
			return nil
		}

		// Create the file to write the profile to.
		f, err := os.Create(path)
		if err != nil {
			return err
		}

		// Update the memory statistics and write the heap profile.
		runtime.GC()
		return errors.Join(pprof.WriteHeapProfile(f), f.Close())
	}
}
