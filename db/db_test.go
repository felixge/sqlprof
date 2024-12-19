package db_test

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/felixge/sqlprof/db"
	"github.com/felixge/sqlprof/db/dbutil"
	"github.com/stretchr/testify/require"
	"golang.org/x/tools/txtar"
)

var updateFiles = os.Getenv("UPDATE") != ""

func TestQueries(t *testing.T) {
	traces := []*struct {
		path      string
		db        *db.DB
		whitelist []string // limit which query archives to run
	}{
		{
			path: filepath.Join("..", "testdata", "testprog", "go1.23.3.trace"),
		},
		{
			path:      filepath.Join("..", "testdata", "testprog", "go1.23.3.cpu.pprof"),
			whitelist: []string{"table_stack_samples", "view_stacks", "table_frames", "table_label_sets"},
		},
		{
			path:      filepath.Join("..", "testdata", "gcoverhead", "go1.23.3.pprof"),
			whitelist: []string{"query_gc_overhead"},
		},
	}
	for _, trace := range traces {
		data, err := os.ReadFile(trace.path)
		require.NoError(t, err)

		trace.db, err = db.Create("", db.Profile{
			Filename: trace.path,
			Data:     bytes.NewReader(data),
		})
		require.NoError(t, err)
		defer trace.db.Close()
	}

	tarPaths, err := filepath.Glob(filepath.Join("..", "testdata/queries/*.txtar.sql"))
	require.NoError(t, err)
	for _, tarPath := range tarPaths {
		archive, err := txtar.ParseFile(tarPath)
		require.NoError(t, err)
		updatedArchive := cloneArchive(archive)

		tarName := filepath.Base(tarPath)
		t.Run(tarName, func(t *testing.T) {
			for _, queryFile := range archive.Files {
				if filepath.Ext(queryFile.Name) != ".sql" {
					continue
				}

				queryName := filepath.Base(queryFile.Name)
				t.Run(queryName, func(t *testing.T) {
					var got bytes.Buffer
					for _, trace := range traces {
						isWhitelisted := func() bool {
							if trace.whitelist == nil {
								return true
							}
							for _, name := range trace.whitelist {
								if strings.TrimSuffix(tarName, ".txtar.sql") == name {
									return true
								}
							}
							return false
						}
						if !isWhitelisted() {
							continue
						}

						fmt.Fprintf(&got, "%s:\n", trace.path)
						rows, err := trace.db.Query(string(queryFile.Data))
						require.NoError(t, err)
						tw := dbutil.NewASCIITableWriter(&got)
						require.NoError(t, tw.Rows(rows))
						tw.Flush()
					}

					wantFilename := strings.TrimSuffix(queryName, ".sql") + ".txt"
					wantFile := findFile(updatedArchive, wantFilename)
					if wantFile == nil {
						wantFile = insertFileAfter(updatedArchive, queryFile.Name, txtar.File{
							Name: wantFilename,
							Data: []byte(""),
						})
					}

					if updateFiles {
						wantFile.Data = got.Bytes()
					}

					if !bytes.Equal(got.Bytes(), wantFile.Data) {
						t.Fatalf("unexpected query output (run with UPDATE=true to update)\ngot:\n%s\n\nwant:\n%s\n", got.String(), wantFile.Data)
					}
				})
			}
		})

		if updateFiles {
			require.NoError(t, os.WriteFile(tarPath, txtar.Format(updatedArchive), 0644))
		}
	}
}

// cloneArchive returns a deep copy of the given Archive.
func cloneArchive(a *txtar.Archive) *txtar.Archive {
	clone := &txtar.Archive{
		Comment: make([]byte, len(a.Comment)),
		Files:   make([]txtar.File, 0, len(a.Files)),
	}
	copy(clone.Comment, a.Comment)

	for _, file := range a.Files {
		cloneFile := txtar.File{
			Name: file.Name,
			Data: make([]byte, len(file.Data)),
		}
		copy(cloneFile.Data, file.Data)
		clone.Files = append(clone.Files, cloneFile)
	}
	return clone
}

func findFile(a *txtar.Archive, name string) *txtar.File {
	for i, file := range a.Files {
		if file.Name == name {
			return &a.Files[i]
		}
	}
	return nil
}

// insertFileAfter inserts a file into the Archive after the last file with a name
// less than the new file's name.
func insertFileAfter(a *txtar.Archive, afterName string, file txtar.File) *txtar.File {
	// Find the position to insert the file.
	position := -1
	for i, f := range a.Files {
		if f.Name == afterName {
			position = i + 1
			break
		}
	}
	if position == -1 {
		panic(fmt.Sprintf("file %q not found", afterName))
	}

	// Insert the file.
	a.Files = append(a.Files, txtar.File{})
	copy(a.Files[position+1:], a.Files[position:])
	a.Files[position] = file
	return &a.Files[position]
}
