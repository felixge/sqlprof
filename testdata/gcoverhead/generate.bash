#!/usr/bin/env bash
go test -run '^$' -bench 'BenchmarkUnmarshalMap$' -cpuprofile $(go env GOVERSION).pprof encoding/json