package main

import (
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
)

var (
	// version flags
	version = "dev"
	date    = "unknown"
)

func main() {
	var showVersion bool

	flag.BoolVar(&showVersion, "version", false, "Prints version info")

	flag.Parse()

	if showVersion {
		fmt.Printf("Version    : %s\n", version)
		fmt.Printf("Build Date : %s\n", date)
		os.Exit(0)
	}

	router := http.NewServeMux()

	router.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintf(w, "<h1>Hello Brno! <small>(version: %s - %s)</small></h1>", version, date)
	})

	slog.Info("starting server", slog.String("version", version), slog.String("date", date))

	err := http.ListenAndServe(":8080", router)
	if err != nil && !errors.Is(err, http.ErrServerClosed) {
		panic(err)
	}
}
