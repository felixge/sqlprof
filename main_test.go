package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/rogpeppe/go-internal/testscript"
)

var updateFiles = os.Getenv("UPDATE") != ""

func TestMain(m *testing.M) {
	os.Exit(testscript.RunMain(m, map[string]func() int{
		"sqlprof": sqlprof,
	}))
}

func TestIntegration(t *testing.T) {
	testscript.Run(t, testscript.Params{
		Dir:           "testdata/script",
		UpdateScripts: updateFiles,
		Setup: func(e *testscript.Env) error {
			wd, err := os.Getwd()
			if err != nil {
				return err
			}
			src := filepath.Join(wd, "testdata")
			dst := filepath.Join(e.WorkDir, "testdata")
			return os.Symlink(src, dst)
		},
	})
}
