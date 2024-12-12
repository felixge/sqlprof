#!/usr/bin/env bash
go test -cpuprofile before-pgo.pprof -count 10 -bench BenchmarkCodeMarshal$ -run '^$' encoding/json | tee before-pgo.txt
go test -pgo before-pgo.pprof -cpuprofile after-pgo.pprof -count 10 -bench BenchmarkCodeMarshal$ -run '^$' encoding/json | tee after-pgo.txt