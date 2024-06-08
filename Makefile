# Project directories
ROOT_DIR        := $(CURDIR)
BUILD_DIR       := $(ROOT_DIR)/build

# Ensure everything works even if GOPATH is not set, which is often the case.
GOPATH          ?= $(shell go env GOPATH)

# Set $(GOBIN) to project directory for keeping everything in one place
GOBIN            = $(ROOT_DIR)/bin

# All go files belong to project
GOFILES          = $(shell find . -type f -name '*.go')

# Commands used in Makefile
GOCMD           := GOBIN=$(GOBIN) go
GOBUILD         := $(GOCMD) build
GOTEST          := $(GOCMD) test
GOCLEAN         := $(GOCMD) clean

GOLANGCILINT    := $(GOBIN)/golangci-lint

MODULE          := $(shell $(GOCMD) list -m)
VERSION         ?= 0.1.0+dev
BUILD_TIMESTAMP := $(shell date -u +"%Y-%m-%dT%H:%M:%S%Z")

# Build variables
BUILD_LDFLAGS   := '-s -w -X main.version=$(VERSION) -X main.date=$(BUILD_TIMESTAMP)'

# Versions
GOLANGCILINT_VERSION ?= v1.57.2

# Helper variables
V = 0
Q = $(if $(filter 1,$V),,@)
M = $(shell printf "\033[34;1m▶\033[0m")

.PHONY: help
default: help

.PHONY: build
build: ## Builds demo binary
build: main.go $(wildcard *.go) $(wildcard */*.go) $(BUILD_DIR) ; $(info $(M) building binary)
	$(Q) CGO_ENABLED=0 $(GOBUILD) -a -tags netgo -ldflags $(BUILD_LDFLAGS) -o $(BUILD_DIR)/app .

.PHONY: run
run: ## Runs demo binary
run: build ; $(info $(M) running binary)
	$(Q) $(BUILD_DIR)/app

.PHONY: lint
lint: ## Runs golangci-lint analysis
lint: $(GOLANGCILINT) ; $(info $(M) runnig golangci-lint analysis)
	$(Q) $(GOLANGCILINT) run

.PHONY: test
test: ## Runs go test
test: ; $(info $(M) runnig tests)
	$(Q) $(GOTEST) -race -cover -v ./...

.PHONY: clean
clean: ## Cleanup everything
clean: ; $(info $(M) cleaning )
	$(Q) $(GOCLEAN)
	$(Q) $(shell rm -rf $(GOBIN) $(BUILD_DIR))

.PHONY: help
help: ## Shows this help message
	$(Q) echo 'usage: make [target] ...'
	$(Q) echo
	$(Q) echo 'targets : '
	$(Q) echo
	$(Q) fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'| column -s: -t
	$(Q) echo

$(BUILD_DIR): ; $(info $(M) creating build directory)
	$(Q) $(shell mkdir -p $@)

$(GOLANGCILINT): ; $(info $(M) installing golangci-lint)
	$(Q) curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(GOBIN) $(GOLANGCILINT_VERSION)