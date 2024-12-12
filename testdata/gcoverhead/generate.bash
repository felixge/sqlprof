#!/usr/bin/env bash
GOGC=1 go test -run '^$' -bench 'BenchmarkCodeUnmarshal$' -cpuprofile cpu.pprof encoding/json