package main

import (
	"fmt"
	"strings"
	"time"

	"golang.org/x/mod/modfile"
	"golang.org/x/net/context"

	"github.com/sourcegraph/conc/pool"
)

type Ci struct {
	// +private
	Source *Directory

	// +private
	GoVersion string
}

//goland:noinspection GoUnusedExportedFunction // this is used by the dagger
func New(
	ctx context.Context,

	// The source directory to be used for the ci. If not provided, the remote repository will be checked out with the provided ref.
	// +optional
	source *Directory,

	// The reference to check out remote repository if the local source directory is not provided. `source` takes precedence over `ref`.
	// +optional
	// +default="main"
	ref string,
) (*Ci, error) {
	if source == nil && ref == "" {
		return nil, fmt.Errorf("either source or ref must be provided")
	}

	if source == nil {
		source = dag.Git("https://github.com/aweris/demo-devconf-cz-2024.git", GitOpts{KeepGitDir: true}).Ref(ref).Tree()
	}

	gv, err := parseGoVersion(ctx, source.File("go.mod"))
	if err != nil {
		return nil, fmt.Errorf("failed to parse go version: %w", err)
	}

	return &Ci{GoVersion: gv, Source: source}, nil
}

// Builds the application with the provided platform and version.
func (m *Ci) Build(
	// The platform to build the container for.
	// +optional
	platform Platform,

	// The version of the application.
	// +optional
	// +default="dev"
	version string,
) *Container {
	ldflags := fmt.Sprintf("-s -w -X main.version=%s -X main.date=%s", version, time.Now().Format(time.RFC3339))

	return m.container().
		With(func(ctr *Container) *Container {
			if platform != "" {
				segments := strings.SplitN(string(platform), "/", 3)

				ctr = ctr.WithEnvVariable("GOOS", segments[0])
				ctr = ctr.WithEnvVariable("GOARCH", segments[1])

				if len(segments) > 2 {
					ctr = ctr.WithEnvVariable("GOARM", segments[2])
				}
			}

			return ctr
		}).
		WithExec([]string{"mkdir", "-p", "build"}).
		WithExec([]string{"go", "build", "-trimpath", "-ldflags", ldflags, "-o", "build/app", "."})
}

// Returns the demo application as a service.
func (m *Ci) AsService() *Service {
	return m.Build("", "dev").
		WithExec([]string{"./build/app"}).
		WithExposedPort(8080).
		AsService()
}

// Runs the tests for the application.
func (m *Ci) Test() *Container {
	return m.container().WithExec([]string{"go", "test", "-v", "./..."})
}

// Lints the application with golangci-lint.
func (m *Ci) Lint(
	// The version of golangci-lint to use.
	// +optional
	// +default="v1.59.0"
	linterVersion string,
) *Container {
	return m.container().
		WithMountedFile("/tmp/golangci-lint/install.sh", dag.HTTP("https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh")).
		WithExec([]string{"chmod", "+x", "/tmp/golangci-lint/install.sh"}).
		WithExec([]string{"/tmp/golangci-lint/install.sh", "-b", "/usr/local/bin", linterVersion}).
		WithExec([]string{"golangci-lint", "run"})
}

// Runs the ci pipeline.
func (m *Ci) Ci(ctx context.Context) error {
	p := pool.New().WithErrors().WithContext(ctx)

	p.Go(func(ctx context.Context) error {
		_, err := m.Build("", "dev").Sync(ctx)

		return err
	})

	p.Go(func(ctx context.Context) error {
		_, err := m.Test().Sync(ctx)

		return err
	})

	p.Go(func(ctx context.Context) error {
		_, err := m.Lint("").Sync(ctx)

		return err
	})

	return p.Wait()
}

// container returns a container with the base image and mounted directories.
func (m *Ci) container() *Container {
	return dag.Container().
		From(fmt.Sprintf("golang:%s", m.GoVersion)).
		WithMountedCache("/go/pkg/mod", dag.CacheVolume("go-mod-cache")).
		WithMountedCache("/root/.cache/go-build", dag.CacheVolume("go-build-cache")).
		WithWorkdir("/src").
		WithMountedDirectory("/src", m.Source)
}

// parseGoVersion parses the go version from the go.mod file.
func parseGoVersion(ctx context.Context, gomod *File) (string, error) {
	mod, err := gomod.Contents(ctx)
	if err != nil {
		return "", err
	}

	f, err := modfile.Parse("go.mod", []byte(mod), nil)
	if err != nil {
		return "", err
	}

	return f.Go.Version, nil
}
