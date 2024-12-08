package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"testing"

	"github.com/rogpeppe/go-internal/testscript"
	"github.com/stretchr/testify/require"
)

func TestMain(m *testing.M) {
	os.Exit(testscript.RunMain(m, map[string]func() int{
		"sqlprof": sqlprof,
	}))
}

func TestIntegration2(t *testing.T) {
	testscript.Run(t, testscript.Params{
		Dir:           "testdata/script",
		UpdateScripts: os.Getenv("UPDATE_SCRIPTS") != "",
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

func TestIntegration(t *testing.T) {
	sqlprof, err := buildSqlprof()
	require.NoError(t, err)

	testprogTrace := filepath.Join("testdata", "testprog", "go1.23.3.trace")

	tests := []struct {
		name string
		args []string
		want string
	}{
		{
			name: "one trace, one query, implicit table format",
			args: []string{"-format", "table", testprogTrace, "SELECT count(*) FROM goroutines"},
			want: strings.TrimSpace(`
+--------------+
| count_star() |
+--------------+
|            9 |
+--------------+
`) + "\n",
		},
		{
			name: "one trace, one query, csv format",
			args: []string{"-format", "csv", testprogTrace, "SELECT count(*) FROM goroutines"},
			want: "count_star()\n9\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := runSqlprof(sqlprof, tt.args...)
			require.NoError(t, err)
			require.Equal(t, tt.want, got)
		})
	}
}

func buildSqlprof() (string, error) {
	file := path.Join(os.TempDir(), "test_sqlprof")
	cmd := exec.Command("go", "build", "-o", file, ".")
	var buf bytes.Buffer
	cmd.Stdout = &buf
	cmd.Stderr = &buf
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to build: %w\n%s", err, buf.String())
	}
	return file, nil
}

func runSqlprof(sqlprof string, args ...string) (string, error) {
	cmd := exec.Command(sqlprof, args...)
	var buf bytes.Buffer
	cmd.Stdout = &buf
	cmd.Stderr = &buf
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to run: %w\n%s", err, buf.String())
	}
	return buf.String(), nil
}
